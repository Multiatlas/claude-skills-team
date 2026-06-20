---
name: 2fa-telegram-push-pattern
description: Patrón para 2FA con push de Telegram en logins de PWAs y paneles admin. Aprobación con botones ✅/❌, mensaje genérico SIN info sensible + auto-destrucción a los 30s + comando /quiet. Gratis (sin SMS/Twilio), sin app extra. Diseñado para sobrevivir a un móvil robado desbloqueado. Úsalo cuando construyas/añadas 2FA a un login cuyos usuarios ya usan Telegram.
type: protocol-skill
---

# Skill: 2FA con push de Telegram

> Patrón canónico para implementar 2FA push en cualquier login de PWA/panel admin. Reutiliza **tus propios bots de Telegram** (`@TuBot_bot`) sin servicios externos de pago. Diseñado para sobrevivir a un móvil robado **desbloqueado**: el chat queda siempre limpio.

---

## ¿Cuándo usar este patrón?

- Al construir el login de una PWA productiva.
- Al añadir 2FA a un panel admin existente.
- Cuando quieres "push 2FA gratis sin instalar app extra".
- Cuando te preocupa la exposición del chat de Telegram a terceros (móvil robado, enseñar el bot a alguien, etc.).

**NO usar para**:
- Apps con miles de usuarios (escala mejor con Authy/Twilio Verify por costes y rate limits).
- Apps cuyos usuarios no tienen Telegram ni un bot autorizado.

---

## Por qué este patrón existe

1. **Gratis** — la Bot API de Telegram es 100% gratuita, sin tier ni cuotas.
2. **Sin app extra** — el usuario ya tiene Telegram en el móvil para hablar con tu bot.
3. **Infra propia** — el bot vive en tu propio VPS; no dependes de Authy/Twilio/Duo.
4. **Logs centralizados** — cada push se registra en tu BD (aquí, Supabase).
5. **Sobrevive a móvil robado desbloqueado** — el chat queda siempre limpio (mensajes auto-destructivos + texto genérico sin info sensible).

> Decisión clave: **NO se muestra info sensible en el chat** (email, IP, dispositivo, dominio). Eso vive solo dentro de la PWA tras el login completo. El push es solo un *trigger*.

---

## Flujo del patrón

```
┌─────────────────┐
│  Usuario hace   │
│  login PWA      │
│  (email + pwd)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Backend valida pwd + verifica   │
│  email en allowed_users          │
│                                  │
│  Genera token TTL 5 min          │
│  Guarda pending_login en BD      │
└────────┬─────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Bot manda push al usuario:      │
│                                  │
│  🔐 Login pendiente              │
│  [✅ Sí]  [❌ No]                │
│                                  │
│  (sin info sensible alguna)      │
│                                  │
│  Programa cron: deleteMessage    │
│  en 30s si no hay acción         │
└────────┬─────────────────────────┘
         │
         ▼ Usuario tap [✅ Sí] o [❌ No]
         │
┌─────────────────────────────────┐
│  Bot recibe callback_query       │
│                                  │
│  1. deleteMessage inmediato      │
│     (mensaje desaparece del chat)│
│  2. Marca pending_login como     │
│     approved/rejected en BD      │
│  3. PWA hace polling y entra     │
│     (o redirige a error)         │
└──────────────────────────────────┘
```

---

## Mensaje genérico estándar

**Todos tus bots** que envíen pushes 2FA usan este texto **literal**, sin variar:

```
🔐 Login pendiente
[✅ Sí]  [❌ No]
```

❌ NO mostrar:
- Nombre del dominio (`app.tudominio.com`)
- Email del usuario
- IP / ciudad / dispositivo / hora
- Nombre de la app

✅ Toda esa info detallada vive en `audit_log` de la BD, accesible solo dentro de la PWA tras el login completo.

> Razón: si alguien roba el móvil desbloqueado o el usuario enseña el bot a un conocido, no aprende nada útil del chat.

---

## Auto-destrucción del mensaje

El bot llama a `bot.deleteMessage(chat_id, message_id)` en estos casos:

| Evento | Tiempo | Resultado |
|---|---|---|
| Usuario tap [✅ Sí] o [❌ No] | Inmediato (1s) | Mensaje desaparece, la PWA procesa la acción |
| 30 segundos sin acción | TTL automático (cron) | Mensaje desaparece, login fail server-side |
| Usuario manda `/quiet 10` | Pausa 10 min | El bot suprime nuevos pushes durante 10 min |

> Limitación técnica de Telegram: solo se pueden borrar mensajes de <48h. Suficiente para TTL de segundos/minutos.

---

## Stack técnico

```
- Backend: Next.js API route (TypeScript)
- BD: Supabase, tabla `pending_logins`
- Bot: node-telegram-bot-api o python-telegram-bot
- Hosting bot: tu VPS (PM2) — o cualquier proceso siempre-activo
- Comunicación PWA ↔ bot: callback_query API + polling al endpoint /api/auth/check-status
```

### Tabla `pending_logins`

```sql
CREATE TABLE pending_logins (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT NOT NULL REFERENCES allowed_users(email),
  ip              TEXT NOT NULL,
  user_agent      TEXT,
  status          TEXT NOT NULL CHECK (status IN ('pending','approved','rejected','expired')),
  telegram_msg_id BIGINT,           -- para deleteMessage
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at     TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT now() + INTERVAL '5 minutes'
);

CREATE INDEX idx_pending_logins_email_status ON pending_logins(email, status);
CREATE INDEX idx_pending_logins_expires ON pending_logins(expires_at) WHERE status = 'pending';
```

### Tabla `audit_log` (toda la info sensible vive aquí, NO en el chat)

```sql
CREATE TABLE audit_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       TEXT NOT NULL,
  event       TEXT NOT NULL,    -- 'login_attempt', 'login_success', 'login_rejected', etc.
  ip          TEXT,
  user_agent  TEXT,
  metadata    JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Endpoint backend Next.js: POST `/api/auth/login`

```typescript
// app/api/auth/login/route.ts
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { sendTelegramPush } from '@/lib/telegram';

export async function POST(req: Request) {
  const { email, password } = await req.json();
  const supabase = createClient();

  // 1. Verificar email en allowed_users
  const { data: allowed } = await supabase
    .from('allowed_users')
    .select('email, password_hash, telegram_chat_id')
    .eq('email', email)
    .single();

  if (!allowed) return NextResponse.json({ error: 'No autorizado' }, { status: 403 });

  // 2. Verificar password (bcrypt/argon2)
  const valid = await verifyPassword(password, allowed.password_hash);
  if (!valid) {
    await logEvent(supabase, email, 'login_failed', req);
    return NextResponse.json({ error: 'Credenciales inválidas' }, { status: 401 });
  }

  // 3. Crear pending_login en BD
  const { data: pending } = await supabase
    .from('pending_logins')
    .insert({
      email,
      ip: req.headers.get('x-forwarded-for') ?? 'unknown',
      user_agent: req.headers.get('user-agent') ?? 'unknown',
      status: 'pending',
    })
    .select()
    .single();

  // 4. Mandar push Telegram (texto genérico)
  //
  // ⚠️ LÍMITE DURO 64 BYTES en callback_data (Telegram Bot API).
  // Si te pasas → la API responde "Bad Request: BUTTON_DATA_INVALID" y el push
  // falla silenciosamente. Mantén prefijos cortos ("a:y:" / "a:n:") y usa UUID
  // (36 bytes) o token de 16B hex (32 chars). NUNCA tokens de 32B hex (64 chars
  // ya excede con cualquier prefijo). Lección aprendida en producción.
  const msgId = await sendTelegramPush({
    chatId: allowed.telegram_chat_id,
    text: '🔐 Login pendiente',
    inlineKeyboard: [
      [
        { text: '✅ Sí', callback_data: `approve:${pending.id}` },
        { text: '❌ No', callback_data: `reject:${pending.id}` },
      ],
    ],
  });

  // 5. Guardar message_id para deleteMessage posterior
  await supabase
    .from('pending_logins')
    .update({ telegram_msg_id: msgId })
    .eq('id', pending.id);

  // 6. Programar auto-delete a 30s
  setTimeout(async () => {
    const { data: stillPending } = await supabase
      .from('pending_logins')
      .select('status, telegram_msg_id')
      .eq('id', pending.id)
      .single();

    if (stillPending?.status === 'pending') {
      await deleteTelegramMessage(allowed.telegram_chat_id, stillPending.telegram_msg_id);
      await supabase
        .from('pending_logins')
        .update({ status: 'expired', resolved_at: new Date().toISOString() })
        .eq('id', pending.id);
    }
  }, 30_000);

  return NextResponse.json({ pendingId: pending.id });
}
```

### Bot handler para callback_query (Node.js + node-telegram-bot-api)

```typescript
import TelegramBot from 'node-telegram-bot-api';
import { createClient } from '@supabase/supabase-js';

const bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN!, { polling: true });
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

const ALLOWED_CHAT_IDS = process.env.ALLOWED_CHAT_IDS!.split(',').map(Number);

bot.on('callback_query', async (q) => {
  // 1. Whitelist chat_id
  if (!ALLOWED_CHAT_IDS.includes(q.from.id)) {
    return bot.answerCallbackQuery(q.id, { text: 'No autorizado' });
  }

  const [action, pendingId] = q.data!.split(':');
  const newStatus = action === 'approve' ? 'approved' : 'rejected';

  // 2. Actualizar BD
  await supabase
    .from('pending_logins')
    .update({ status: newStatus, resolved_at: new Date().toISOString() })
    .eq('id', pendingId)
    .eq('status', 'pending');  // solo si sigue pending (idempotente)

  // 3. Borrar mensaje del chat (auto-destrucción inmediata)
  await bot.deleteMessage(q.message!.chat.id, q.message!.message_id).catch(() => {});

  // 4. Confirmación silenciosa al usuario
  await bot.answerCallbackQuery(q.id, {
    text: newStatus === 'approved' ? '✅' : '❌',
    show_alert: false,
  });
});

// Comando /quiet — pausa pushes durante N minutos
bot.onText(/\/quiet (\d+)/, async (msg, match) => {
  if (!ALLOWED_CHAT_IDS.includes(msg.from!.id)) return;
  const minutes = parseInt(match![1]);
  if (minutes < 1 || minutes > 120) return bot.sendMessage(msg.chat.id, 'Rango: 1-120 min');

  await supabase.from('quiet_periods').insert({
    chat_id: msg.from!.id,
    expires_at: new Date(Date.now() + minutes * 60_000).toISOString(),
  });

  const reply = await bot.sendMessage(msg.chat.id, `🔇 Pausa ${minutes} min`);
  setTimeout(() => bot.deleteMessage(msg.chat.id, reply.message_id).catch(() => {}), 5_000);
});
```

---

## Variables de entorno requeridas

```bash
# Bot
TELEGRAM_BOT_TOKEN=                    # token de BotFather
ALLOWED_CHAT_IDS=                      # CSV de chat_ids autorizados, ej: "123456,789012"

# Supabase
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=             # solo backend, nunca al cliente
```

---

## Tests de aceptación obligatorios

Antes de habilitar acceso a usuarios reales, validar:

- [ ] Login con email NO en `allowed_users` → rechazo 403 (sin push)
- [ ] Login con pwd incorrecta → rechazo 401 + log en `audit_log`
- [ ] Login OK → push llega a Telegram con texto literal `🔐 Login pendiente` (sin info adicional)
- [ ] Tap [✅ Sí] → mensaje desaparece en <2s + PWA entra
- [ ] Tap [❌ No] → mensaje desaparece + PWA muestra "rechazado"
- [ ] Sin tap durante 30s → mensaje desaparece automático + login expira (PWA muestra timeout)
- [ ] Mismo `pending_id` aprobado dos veces → idempotente (segundo tap no hace nada)
- [ ] `chat_id` no autorizado tap botón → "No autorizado" silencioso, sin afectar al pending_login
- [ ] `/quiet 5` → bloquea pushes por 5 min; un login que llegue → la PWA muestra timeout sin push

---

## Ejemplos de aplicación

Este patrón encaja en cualquier login de un equipo pequeño/medio cuyos usuarios ya usan Telegram:

| Caso | Bot | Notas |
|---|---|---|
| **Panel admin interno** | Bot dedicado del panel | 2FA para el equipo que gestiona el backoffice |
| **PWA productiva** | Bot del proyecto | Capa de aprobación de login P0 del sprint de auth |
| **Varios proyectos** | Un bot por proyecto | Mismo patrón replicable; aísla `chat_id` por proyecto |

Probado en producción (PWA real con login por aprobación Telegram).

---

## Errores comunes a evitar

- ❌ **NO superar 64 bytes en `callback_data`**. Telegram lo rechaza con `Bad Request: BUTTON_DATA_INVALID` (silenciosamente — solo lo ves en `data.description` de la respuesta de `sendMessage`). Mantén el prefijo corto y usa UUID (36 bytes) o token de 16B hex (32 chars).
- ❌ **NO meter info sensible** en el mensaje del bot (email, IP, dominio). Si lo metes, el patrón pierde su propósito anti-móvil-robado.
- ❌ **NO** asumir que `deleteMessage` siempre funciona — Telegram puede fallar (mensaje >48h, bot expulsado, etc.). Captura la excepción y NO bloquees el flujo.
- ❌ **NO** dejar `pending_login` en BD eternamente — límpialos con un cron diario (los `expired` de >7 días).
- ❌ **NO** reutilizar el mismo `pending_id` — un solo uso, después expira.
- ❌ **NO** olvidar `show_alert: false` en `answerCallbackQuery` — si lo pones a `true`, sale un popup con info que un tercero podría ver.
- ❌ **NO** activar `/quiet` desde un `chat_id` no autorizado — verifica siempre la whitelist primero.

---

## Cómo combinarlo

El push 2FA es **una capa**, no el stack completo de auth. Combínalo con: rate limit en `/api/auth/login`, captcha tras N intentos, sesiones `httpOnly`/`Secure`, RLS en la BD y un `audit_log` que registre cada intento. El push solo decide "¿eres tú quien está entrando ahora mismo?".

---

## Cuándo se invoca

- Se diseña/desarrolla el auth de cualquier PWA productiva.
- El usuario pide "2FA gratis sin app extra" o "push al móvil".
- Se planifica un panel admin con login.
