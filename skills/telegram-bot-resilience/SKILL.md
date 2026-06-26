---
name: telegram-bot-resilience
description: Blindar bots de Telegram (node-telegram-bot-api) contra restart-loops y "zombis" silenciosos — helper safeSend + handler polling_error + listeners de proceso + watchdog de 3 barreras (polling_error fatal, healthcheck getMe, reinicio preventivo). Invocar antes de poner un bot en producción o cuando PM2 muestre el contador de reinicios subiendo.
---

# Telegram Bot Resilience (node-telegram-bot-api)

## Cuándo aplicar

Cualquier bot de Telegram que use `node-telegram-bot-api` con `polling: true`. Ejecutar **antes de poner el bot en producción** o cuando `pm2 status` muestre el contador `↺` subiendo en pocas horas.

## Síntoma típico

`pm2 status` muestra `↺ 13` en 5h. Los logs apuntan a líneas distintas de `bot.sendMessage` cada vez. PM2 reinicia → restart-loop visible pero causa raíz oculta.

## Causa raíz

Dos puntos ciegos de `node-telegram-bot-api`:

1. **`bot.sendMessage(...)` sin `await` ni `.catch`** → un 502/ETIMEDOUT genera `unhandledRejection` → Node mata el proceso.
2. **Sin handler `polling_error`** → errores transitorios del long-polling (502, ETIMEDOUT) se propagan como rejection sin manejar.

## Patrón a aplicar

Pega esto justo después del `new TelegramBot(token, { polling: true })`:

```js
function safeSend(chatId, text, options) {
  return bot.sendMessage(chatId, text, options).catch((err) => {
    console.error(`[BOT] safeSend fallo (${chatId}):`, err.code || err.message);
  });
}

bot.on('polling_error', (err) => {
  console.error('[BOT] polling_error:', err.code || err.message);
});

process.on('unhandledRejection', (reason) => {
  console.error('[BOT] unhandledRejection:', reason && (reason.stack || reason.message || reason));
});
process.on('uncaughtException', (err) => {
  console.error('[BOT] uncaughtException:', err && (err.stack || err.message));
});
```

Después reemplaza todas las llamadas `bot.sendMessage(...)` no-await por `safeSend(...)`. Las que ya van con `await` dentro de `try/catch` no las toques.

## Regla de uso

| Caso | Uso |
|------|-----|
| Acuse rápido en `if/return` | `safeSend` |
| Mensaje de error en `catch` | `safeSend` |
| Respuesta principal del flujo | `await bot.sendMessage` dentro de `try/catch` |
| Chunks ordenados de texto largo | `await bot.sendMessage` |

Si te da igual que falle (feedback de UI) → `safeSend`. Si el flujo posterior depende de que llegó → `await + try/catch`.

## Verificación post-deploy

```bash
pm2 restart <bot-name>
sleep 60
pm2 status <bot-name>   # ↺ no debe subir por errores transitorios
pm2 logs <bot-name> --lines 50 --nostream | grep '\[BOT\]'
```

Si el `↺` sigue subiendo: queda algún `bot.sendMessage` sin convertir.

```bash
grep -n 'bot\.sendMessage(' run-bot.js | grep -v await | grep -v safeSend
```

---

## Auto-borrado de mensajes sensibles

**Problema**: cuando el usuario envía mensajes con datos sensibles (PIN de login, API keys, contraseñas, IBANs), quedan persistidos en el histórico del chat. Si el móvil se pierde/roba con la sesión desbloqueada, el atacante hace scroll y los lee.

**Solución**: tras detectar un comando con dato sensible, llamar a `bot.deleteMessage(chat_id, msg.message_id)` inmediatamente. Telegram permite borrar mensajes del usuario en chats privados durante las primeras 48h.

```js
if (text.startsWith('/login ')) {
  bot.deleteMessage(chatId, msg.message_id).catch((err) => {
    console.error(`[BOT] No se pudo borrar mensaje /login: ${err.code || err.message}`);
  });
  // ... validación + respuesta del bot ...
}
```

**Comandos típicos a auto-borrar**: `/login <PIN>`, `/key <API_KEY>`, capturas con IBAN visible.

**Mantiene**: respuestas del bot, resto del histórico operativo. **Borra**: solo el mensaje con el dato sensible.

**Caveats**:
- Si Telegram falla el delete (red/permisos/>48h), el mensaje queda visible. El `.catch` evita el crash y loguea para revisar.
- En grupos requiere `can_delete_messages`. En chats 1-a-1 con el dueño no hace falta config.
- El borrado es server-side: desaparece en todos los dispositivos sincronizados.

---

## 🐺 Watchdog anti-zombi

**Problema**: PM2 reporta el bot como "online" pero el long-polling de Telegram está muerto. Síntoma: el usuario escribe y nadie responde. No hay errores en logs porque el `polling_error` ya pasó (y se ignoró) o el cliente HTTP interno se atascó sin emitir nada. Solo se arregla con `pm2 restart` manual. **Visto en producción de forma reincidente — no es un caso aislado.**

### Tres barreras que cierran el agujero

```js
// 1) polling_error fatal — códigos terminales no se recuperan solos.
bot.on('polling_error', (err) => {
  const code = err.code || '';
  const msg = err.message || '';
  console.error('[BOT] polling_error:', code || msg);
  if ((code === 'ETELEGRAM' || msg.includes('ETELEGRAM')) && (msg.includes('401') || msg.includes('409'))) {
    console.error('[BOT] polling_error FATAL — saliendo para que PM2 reinicie');
    process.exit(1);
  }
});

// 2) Healthcheck activo: bot.getMe() cada 60s. 3 fallos seguidos = morir.
const HEALTH_PROBE_MS = 60_000;
const HEALTH_FAIL_THRESHOLD = 3;
let healthFails = 0;
setInterval(async () => {
  try {
    await bot.getMe();
    if (healthFails > 0) console.log(`[BOT] healthcheck recuperado tras ${healthFails} fallos`);
    healthFails = 0;
  } catch (err) {
    healthFails++;
    console.error(`[BOT] healthcheck fail ${healthFails}/${HEALTH_FAIL_THRESHOLD}: ${err.code || err.message}`);
    if (healthFails >= HEALTH_FAIL_THRESHOLD) {
      console.error('[BOT] healthcheck KO repetido — saliendo para que PM2 reinicie');
      process.exit(1);
    }
  }
}, HEALTH_PROBE_MS);

// 3) Reinicio preventivo cada N horas (default 6, override con env).
const PREVENTIVE_RESTART_HOURS = Number(process.env.BOT_PREVENTIVE_RESTART_HOURS ?? 6);
setTimeout(() => {
  console.log(`[BOT] reinicio preventivo (uptime ${PREVENTIVE_RESTART_HOURS}h alcanzado)`);
  process.exit(0);
}, PREVENTIVE_RESTART_HOURS * 60 * 60 * 1000);
```

### Por qué las tres juntas

| Pieza | Cubre | NO cubre |
|---|---|---|
| `polling_error` fatal | 401 (token revocado), 409 (otra instancia haciendo polling) | Polling muerto sin emisión de error |
| Healthcheck `getMe()` | DNS roto, red caída, API inaccesible | Cliente HTTP atascado en otra ruta interna |
| Reinicio preventivo | Cualquier zombi silencioso, drift, fugas de memoria | Detección rápida — solo es la cota superior |

PM2 reinicia automáticamente al `process.exit()`, da igual que el código sea 0 o 1.

> Requiere PM2 (o cualquier supervisor que reinicie al salir el proceso). El reinicio preventivo es seguro si tu bot no mantiene estado en memoria que se pierda; si lo mantiene, persístelo antes.
