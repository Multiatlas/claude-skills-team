---
name: cross-surface-chat-memory
description: Patrón para que un agente IA conserve UN solo hilo de memoria entre superficies (chat web ↔ bot Telegram ↔ WhatsApp ↔ ...). BD como fuente única de history + conversation singleton por canal alternativo + carga cross con ventana temporal. Invocar al construir un agente que vive en dos o más canales y "no se acuerda" de lo hablado en el otro.
type: protocol-skill
---

# Skill: Memoria cruzada multi-superficie para agentes IA

> Patrón para que un agente IA que vive en varias superficies (web + Telegram + WhatsApp + ...) conserve un único hilo de memoria coherente. Probado en producción.

---

## ¿Cuándo usar este patrón?

- Al construir un agente IA que vive en **dos o más canales simultáneamente** (chat web embebido + bot Telegram, etc.).
- Cuando el usuario percibe "el agente no se acuerda de lo que le dije esta mañana en la otra superficie".
- En cualquier proyecto que reutilice un mismo bot/agente en varias interfaces.

**NO usar para**:
- Agentes mono-superficie (un único canal). Es overkill.
- Multi-tenant SaaS donde los usuarios no deben ver memoria cruzada (pero el patrón sirve igual filtrando por `user_id` rigurosamente).

---

## Por qué este patrón existe

1. **El usuario no piensa en "el bot" vs "la web"** — piensa en "mi asesor". La memoria debe ser una.
2. **La RAM no vale** — los bots se reinician (PM2 restart, deploy) y pierden el history. La pérdida es invisible para el usuario pero degrada la experiencia.
3. **La BD ya la tienes** (p. ej. Supabase) — dos INSERT por turno son gratis.
4. **El prompt caching** (Anthropic, Gemini) absorbe el coste del history extra.

---

## Principios del patrón

1. **BD como fuente única de history**. Tabla `messages` con FK a `conversations`, ambas con `user_id`.
2. **Conversation singleton por superficie alternativa**: la web suele tener N conversations (el usuario las gestiona); los demás canales mejor un singleton fijo por usuario, identificado por título tipo `[Telegram]`, `[WhatsApp]`, etc.
3. **Persistencia obligatoria por turno**: cada mensaje (user + model) se inserta en BD nada más generarse. NO history en RAM.
4. **Construcción del contexto del modelo**:
   - **Superficie secundaria** (Telegram, WhatsApp, etc.): cargar los últimos N mensajes mezclados de TODAS las conversations del usuario en una ventana temporal (24-48 h), ASC. Ignorar cualquier history en RAM.
   - **Superficie primaria** (web con conversations propias gestionadas): prependear los últimos K mensajes de las conversations secundarias al `history` que manda el frontend, con guarda anti-duplicación por si el usuario navegase la conversation secundaria desde la web.

---

## Implementación de referencia

`src/lib/cross-chat-memory.ts`:

```ts
import { supabaseAdmin, getAppUserId } from '@/lib/supabase/admin';

const TELEGRAM_CONV_TITLE = '[Telegram]';

export async function getOrCreateTelegramConversation(): Promise<string> {
  const sb = supabaseAdmin();
  const userId = getAppUserId();
  const { data: existing } = await sb
    .from('advisor_conversations')
    .select('id')
    .eq('user_id', userId)
    .eq('title', TELEGRAM_CONV_TITLE)
    .maybeSingle();
  if (existing?.id) return existing.id;
  const { data: created, error } = await sb
    .from('advisor_conversations')
    .insert({ user_id: userId, title: TELEGRAM_CONV_TITLE })
    .select('id')
    .single();
  if (error || !created) throw new Error(`No se pudo crear la conversation Telegram: ${error?.message}`);
  return created.id;
}

export type CrossContextMessage = {
  role: 'user' | 'model';
  content: string;
  created_at: string;
};

/**
 * Últimos N mensajes mezclados de TODAS las conversations del user
 * en las últimas H horas, ASC. Memoria cruzada para superficie secundaria.
 */
export async function loadCrossContext(opts?: {
  hoursBack?: number;
  maxMessages?: number;
}): Promise<CrossContextMessage[]> {
  const hoursBack = opts?.hoursBack ?? 24;
  const maxMessages = opts?.maxMessages ?? 16;
  const sb = supabaseAdmin();
  const userId = getAppUserId();
  const cutoff = new Date(Date.now() - hoursBack * 3600 * 1000).toISOString();

  const { data: convs } = await sb
    .from('advisor_conversations')
    .select('id')
    .eq('user_id', userId);
  if (!convs?.length) return [];

  const { data: msgs } = await sb
    .from('advisor_messages')
    .select('role, content, created_at')
    .in('conversation_id', convs.map(c => c.id))
    .gte('created_at', cutoff)
    .order('created_at', { ascending: false })
    .limit(maxMessages);

  return (msgs ?? []).reverse() as CrossContextMessage[];
}

/**
 * Solo mensajes de la conversation secundaria (Telegram). Para inyectar
 * en superficie primaria sin pisar el hilo activo.
 */
export async function loadTelegramRecentMessages(opts?: {
  hoursBack?: number;
  maxMessages?: number;
}): Promise<CrossContextMessage[]> {
  const hoursBack = opts?.hoursBack ?? 24;
  const maxMessages = opts?.maxMessages ?? 8;
  const sb = supabaseAdmin();
  const userId = getAppUserId();
  const cutoff = new Date(Date.now() - hoursBack * 3600 * 1000).toISOString();

  const { data: conv } = await sb
    .from('advisor_conversations')
    .select('id')
    .eq('user_id', userId)
    .eq('title', TELEGRAM_CONV_TITLE)
    .maybeSingle();
  if (!conv?.id) return [];

  const { data: msgs } = await sb
    .from('advisor_messages')
    .select('role, content, created_at')
    .eq('conversation_id', conv.id)
    .gte('created_at', cutoff)
    .order('created_at', { ascending: false })
    .limit(maxMessages);

  return (msgs ?? []).reverse() as CrossContextMessage[];
}

export async function appendTelegramMessage(role: 'user' | 'model', content: string): Promise<void> {
  const sb = supabaseAdmin();
  const conversationId = await getOrCreateTelegramConversation();
  await sb.from('advisor_messages').insert({ conversation_id: conversationId, role, content });
  await sb.from('advisor_conversations').update({ updated_at: new Date().toISOString() }).eq('id', conversationId);
}
```

### Uso en endpoint del bot (Telegram)

```ts
// Antes de llamar al modelo: ignorar history RAM, cargar de BD.
const crossContext = await loadCrossContext({ hoursBack: 24, maxMessages: 14 })
  .catch((e) => { console.warn('loadCrossContext falló:', e); return []; });
const history = crossContext.map((m) => ({
  role: m.role,
  parts: [{ text: m.content }],
}));

// ... llamada al modelo ...

// Tras generar respuesta: persistir el turno.
try {
  await appendTelegramMessage('user', userMessageText);
  await appendTelegramMessage('model', finalText);
} catch (err) {
  console.warn('No se pudo persistir el turno:', err);
}
```

### Uso en endpoint web

```ts
// Prependear últimos turnos de Telegram al history del frontend.
const telegramRecent = await loadTelegramRecentMessages({ hoursBack: 24, maxMessages: 8 })
  .catch(() => []);
if (telegramRecent.length > 0) {
  const tgTurns = telegramRecent.map((m) => ({ role: m.role, content: m.content }));
  // Guarda anti-duplicación si el user navegase la conversation [Telegram] desde la web.
  const existingFirst = history[0]?.content;
  if (!existingFirst || existingFirst !== tgTurns[0]?.content) {
    history.unshift(...tgTurns);
  }
}
```

---

## Tradeoffs del diseño

| Decisión | Coste | Beneficio |
|---|---|---|
| Mezclar superficies | Pierdes "limpieza" del hilo web | Continuidad real percibida por el usuario |
| Ventana 24 h | "Olvido" al día siguiente (puede reabrirse al ajustar) | Evita acumulación de ruido viejo |
| BD por turno | 2 INSERT extra | Sobrevive a restarts, sirve de auditoría |
| 14 turnos cross | +tokens vs. 6 en RAM | Con prompt caching son centavos |

Si el caso de uso pide más memoria, subir `hoursBack` a 48-72 y/o `maxMessages` a 24. A más ventana, más tokens — equilibrar con caching.

---

## Anti-patrones

- ❌ **NO usar RAM para history en bots** que pueden reiniciarse. Perderás contexto invisible al usuario.
- ❌ **NO mezclar usuarios** en multi-tenant — `loadCrossContext` debe filtrar `user_id` SIEMPRE.
- ❌ **NO prependear sin guarda** en superficie primaria — si el usuario navega la conversation singleton secundaria desde el frontend, los mismos mensajes podrían duplicarse. Comparar el primer contenido del history con el primer cross.
- ❌ **NO** olvidar que el frontend web ya persiste sus mensajes vía su propio endpoint; no doble-insertar desde el endpoint del modelo.
- ❌ **NO** olvidar tolerancia a fallos: la persistencia y la carga deben capturar excepciones y degradar (history vacío) en lugar de tirar la respuesta al usuario.

---

## Ejemplos de aplicación

| Caso | Superficies | Notas |
|---|---|---|
| Asesor/asistente de un SaaS | Web (`/api/advisor`) + bot Telegram | Singleton `[Telegram]` por usuario; `cross-chat-memory.ts` |
| Soporte/atención | Web + WhatsApp | Mismo patrón, título `[WhatsApp]` |
| Varios agentes | Variable | Patrón replicable, un singleton por canal alternativo |

---

## Skills relacionadas

- `2fa-telegram-push-pattern` — auth multi-canal reutilizando el mismo bot.
- `telegram-bot-resilience` — `safeSend` + `polling_error` + watchdog para que el bot no muera y la persistencia funcione siempre.
