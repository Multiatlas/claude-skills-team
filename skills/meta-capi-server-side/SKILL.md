---
name: meta-capi-server-side
description: >-
  Implementar Meta Conversions API (CAPI) server-side con deduplicación vía
  event_id (UUID) compartido cliente↔servidor, para cualquier funnel/SaaS con
  Meta Ads. Recupera el 30-50% de conversiones que pierde el Pixel solo por
  iOS 14+/ATT y ad-blockers → mejor atribución → CPL ~15-25% más bajo. Invocar
  al integrar Meta Pixel en una web con campañas activas, o cuando Events
  Manager avisa "tu servidor está enviando menos eventos que el píxel".
---

# Meta Conversions API (CAPI) server-side, con deduplicación

> Aporte de **MultiAtlas** a la comunidad SaaS Factory. Genérico y sanitizado: todos los IDs, dominios y rutas son placeholders — pon los tuyos. Ejemplos en Next.js (App Router) + Supabase, pero el patrón vale para cualquier stack con servidor.

## Cuándo invocar
- Cualquier web/funnel con **Meta Ads activos** y conversiones medibles (Lead, Purchase, CompleteRegistration…).
- La web ya tiene el **Pixel cliente** y en Events Manager aparece el aviso *"tu servidor está enviando X eventos menos que el píxel"*.
- **Antes de lanzar** campañas Meta nuevas (para que el algoritmo optimice bien desde el día 1).

## Por qué CAPI (el problema real)
Solo con Pixel cliente, Meta pierde típicamente **30-50%** de las conversiones:

| Causa | % eventos perdidos típico |
|---|---|
| Safari / iOS 14+ ATT | 30-40% |
| Ad-blockers (uBlock, Brave) | 10-15% |
| Cierre del navegador antes de enviar el Pixel | ~5% |
| Conexión interrumpida | ~2% |

Menos conversiones vistas → el algoritmo optimiza peor → **CPL más alto del necesario**. Con CAPI server-side complementario: cobertura ~55% → ~95%, **CPL −15-25%** (métricas oficiales de Meta), y lo que cobras cuadra con lo que Meta atribuye.

## Pieza clave: deduplicación por `event_id`
El Pixel cliente **y** el CAPI server envían el **mismo evento** con el **mismo `event_id` (UUID)**. Meta los reconoce como uno y se queda con el que llegue (normalmente el server, más fiable). Si los IDs no coinciden → **cuenta doble**, no deduplica. Esta es la regla de oro de toda la skill.

## Roles implicados
| Rol | Responsabilidad |
|---|---|
| **Quien gestione Meta Ads** (trafficker) | Genera el `META_CAPI_ACCESS_TOKEN` en Events Manager (o como System User, ver más abajo). |
| **Dev** | Implementa el helper `sendCapiEvent`, lo integra en el server, y comparte el `event_id` cliente↔server. |
| **Owner** | Aprueba el rollout, guarda el token en un secrets manager, lo rota si se filtra. |

## Estructura y variables de entorno
```
src/lib/integrations/meta-capi.ts     ← helper sendCapiEvent (server-only)
src/components/MetaPixel.tsx           ← Pixel cliente con Consent Mode
src/features/<feature>/actions.ts      ← server action: llama a sendCapiEvent (fire-and-forget)
src/features/<feature>/components/Form.tsx  ← cliente: genera event_id UUID + lo pasa al server
```
```bash
NEXT_PUBLIC_META_PIXEL_ID=<id de pixel, 15-16 dígitos>
META_CAPI_ACCESS_TOKEN=<token EAA..., ~200 chars — NUNCA en el repo>
# Opcional, solo para validar en Events Manager > Test Events ANTES de ir a producción:
META_CAPI_TEST_EVENT_CODE=TESTxxxxx
```
> **Stub mode**: si falta `META_CAPI_ACCESS_TOKEN`, el helper loguea y retorna OK sin enviar nada. La app sigue funcionando con solo Pixel cliente → ideal para staging/dev sin contaminar producción.

## Helper canónico — `src/lib/integrations/meta-capi.ts`
```typescript
import "server-only";
import { createHash } from "node:crypto";

// ⚠️ Meta deprecia versiones de la Graph API cada ~2 años y RECHAZA las antiguas
// (desde sep-2025 exige >= v22.0). Pon la última estable de
// developers.facebook.com/docs/graph-api/changelog y revísala ~cada 12 meses.
const META_API_VERSION = "v23.0";

interface UserData {
  email?: string;          // se hashea SHA-256
  phone?: string;          // solo dígitos, se hashea SHA-256
  firstName?: string;      // se hashea
  clientIpAddress?: string;// NO se hashea
  clientUserAgent?: string;// NO se hashea
  fbp?: string;            // cookie _fbp del navegador (NO se hashea)
  fbc?: string;            // click id de Meta (NO se hashea)
}

const hashSha256 = (v: string) =>
  createHash("sha256").update(v.trim().toLowerCase()).digest("hex");

export async function sendCapiEvent(input: {
  eventName: string;
  eventId: string;          // UUID compartido con el Pixel cliente para dedup
  eventSourceUrl?: string;
  userData: UserData;
  customData?: { value?: number; currency?: string; content_name?: string };
}) {
  const pixelId = process.env.NEXT_PUBLIC_META_PIXEL_ID;
  const accessToken = process.env.META_CAPI_ACCESS_TOKEN;
  const testEventCode = process.env.META_CAPI_TEST_EVENT_CODE;

  if (!pixelId || !accessToken) {
    console.log(`[meta-capi:STUB] ${input.eventName} eventId=${input.eventId}`);
    return { ok: true, stub: true };
  }

  const payload = {
    data: [{
      event_name: input.eventName,
      event_id: input.eventId,
      event_time: Math.floor(Date.now() / 1000),
      action_source: "website",
      event_source_url: input.eventSourceUrl,
      user_data: {
        ...(input.userData.email && { em: hashSha256(input.userData.email) }),
        // phone: normalízalo a E.164 SIN '+' (antepón el código de país) ANTES de hashear,
        // o el hash no coincidirá con el del Pixel cliente y se pierde el matching.
        ...(input.userData.phone && { ph: hashSha256(input.userData.phone.replace(/\D/g, "")) }),
        ...(input.userData.firstName && { fn: hashSha256(input.userData.firstName) }),
        ...(input.userData.clientIpAddress && { client_ip_address: input.userData.clientIpAddress }),
        ...(input.userData.clientUserAgent && { client_user_agent: input.userData.clientUserAgent }),
        ...(input.userData.fbp && { fbp: input.userData.fbp }),
        ...(input.userData.fbc && { fbc: input.userData.fbc }),
      },
      custom_data: input.customData ?? {},
    }],
    ...(testEventCode && { test_event_code: testEventCode }),
  };

  const res = await fetch(
    `https://graph.facebook.com/${META_API_VERSION}/${pixelId}/events?access_token=${encodeURIComponent(accessToken)}`,
    { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) },
  );
  const data = await res.json();
  return { ok: res.ok && !data.error, fbtrace_id: data.fbtrace_id, error: data.error?.message };
}
```

## Invocación desde el server (fire-and-forget)
```typescript
"use server";
import { headers } from "next/headers";
import { randomUUID } from "node:crypto";
import { sendCapiEvent } from "@/lib/integrations/meta-capi";

export async function registrarLead(input: any) {
  // ... validar + guardar el lead en tu BD ...
  const eventId = input.event_id ?? randomUUID();   // ideal: viene del cliente
  const h = await headers();
  const clientIp = h.get("x-forwarded-for")?.split(",")[0]?.trim();
  const userAgent = h.get("user-agent") ?? undefined;

  // void + .catch: NO bloquea la respuesta al usuario
  void sendCapiEvent({
    eventName: "Lead",
    eventId,
    eventSourceUrl: `${process.env.SITE_URL}/registro/`,
    userData: { email: input.email, phone: input.phone, firstName: input.nombre?.split(" ")[0],
                clientIpAddress: clientIp, clientUserAgent: userAgent, fbp: input.fbp, fbc: input.fbc },
    customData: { value: 10, currency: "EUR", content_name: "lead" },
  }).catch((e) => console.error("[CAPI Lead]", e));
}
```

## Cliente (form) — genera el `event_id` y dispara el Pixel con él
```tsx
"use client";
function getCookie(n: string): string | undefined {
  const m = document.cookie.match(new RegExp(`(?:^|; )${n}=([^;]*)`));
  return m ? decodeURIComponent(m[1]) : undefined;
}

async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault();
  const eventId = crypto.randomUUID();            // ← compartido con el server
  const fbp = getCookie("_fbp");
  const fbc = getCookie("_fbc");
  window.fbq?.("track", "Lead", { value: 10, currency: "EUR" }, { eventID: eventId });
  await registrarLead({ ...formData, event_id: eventId, fbp, fbc });
}
```

## GDPR / consentimiento (UE — obligatorio)
- El cookie banner guarda el consentimiento; el Pixel hace `fbq('consent','grant'|'revoke')` según el banner.
- **Si el usuario NO consintió → NO llames a `sendCapiEvent`** (el server simplemente no lo invoca). CAPI también está sujeto al consentimiento.
- Cuando consiente, ambos canales activos → deduplicación natural por `event_id`.

## Aprendizajes que ahorran horas
- **El aviso "tu servidor envía menos eventos" es normal sin CAPI** — lo genera Meta automáticamente; desaparece 24-48 h tras activar CAPI con el token correcto. No es un bug.
- **El token CAPI no caduca** (a diferencia de los User/Page tokens). Solo se rota a mano si se filtra.
- **`event_id` idéntico cliente y server o NO hay dedup.** Si el cliente no lo pasa, el server genera uno nuevo y cuenta doble (degrada, pero pierdes la ventaja). Hazlo que lo genere el cliente.
- **Hashea SHA-256 (lowercase+trim) el PII**: email, phone, firstName. Si los mandas en claro → HTTP 400 *"user_data not properly hashed"*. `client_ip_address`, `client_user_agent`, `fbp`, `fbc` NO se hashean.
- **Test Events antes de ir a live**: genera un `TEST_EVENT_CODE`, ponlo en la env, valida en la pestaña "Test Events" en tiempo real sin contaminar campañas. Luego quita la env.
- **Fire-and-forget siempre**: `void sendCapiEvent({...}).catch(...)`. Un fallo de Meta nunca debe degradar la UX de quien está convirtiendo.
- **Stub mode** (sin token → no envía) permite tests E2E en staging sin tocar el Pixel de producción.
- **Verificación post-activación**: Events Manager → Pixel → Información general: deberías ver el evento con 2 canales (Pixel + Server) y % de deduplicación cercano al 100%. El aviso de Diagnóstico desaparece en 24-48 h.

## Generar el token (System User, no caduca) — con las 2 trampas
> Para enviar CAPI desde tu servidor necesitas un token de **Usuario del sistema** con permiso `ads_management` (no caduca). El flujo tiene 2 trampas que dejan el botón "Generar identificador" en **gris**:

En **Business Settings** (`business.facebook.com/settings`):
1. **Usuarios → Usuarios del sistema** → crea uno (rol Admin).
2. 🚩 **Trampa 1 — App en el portafolio**: el botón sale gris si NO hay una App **dentro del portafolio** (Cuentas → Aplicaciones). Una app solo *asignada* no basta. Si no tienes, añádela ahí; si "Crear" no la enlaza, usa **"Conectar un identificador de la aplicación"** con el **App ID**. La app necesita el caso de uso *"Crear y administrar anuncios con la API de marketing"* (incluye CAPI). En **modo desarrollo** funciona para tu propio píxel.
3. 🚩 **Trampa 2 — Asignar activos**: en el usuario del sistema, **"…" → Asignar activos** → añade el **Píxel/Conjunto de datos** con **Control total**.
4. **Generar identificador** → App + permiso `ads_management` → copia el token (solo se ve una vez).

**Atajo sin System User** (solo enviar): Events Manager → píxel → **Configuración → API de conversiones → "Configurar sin Dataset Quality API" → Generar token**. ⚠️ La variante **"con Dataset Quality API"** genera un token de **solo lectura** que NO sirve para enviar eventos (da `(#100) Missing Permission`).

**Verifica el token** con Graph API `debug_token`: scopes deben incluir `ads_management`; `expires_at: 0` = permanente. **Guárdalo solo en un secrets manager** (chmod 600 / vault), nunca en repo, web o Drive compartido.

## ⚠️ Trampa de producción: un píxel por sitio
Al clonar una plantilla web entre proyectos, es fácil dejar el `META_PIXEL_ID` copy-pasteado y que un site dispare el píxel de **otro** → contaminación de datos y atribución cruzada. Síntoma: en Events Manager → píxel → "Confirmar dominios" aparecen dominios que no son tuyos (o de staging). **Audita el pixel ID por sitio**; cada uno con el suyo (o sin píxel si no tiene campañas). Verifica con `GET /{pixel_id}?fields=name,last_fired_time`.

## Notas de robustez (producción)
- **Versión de la API deriva**: Meta sube versión ~3 veces/año y deprecia a ~2 años. No la dejes clavada en silencio — revisa `META_API_VERSION` ~cada 12 meses (una versión vieja **falla con HTTP de versión no soportada**).
- **Maneja el error recurrente**: el helper devuelve `{ ok, error, fbtrace_id }`. Con fire-and-forget puro nunca te enteras si el **token caducó/se revocó**. Loguea los `ok:false` y pon una alerta si se repiten (si no, dejas de enviar conversiones sin saberlo).
- **Maximiza el Event Match Quality**: además de `em/ph/fn`, envía (hasheados) `ln` (apellido), `external_id` (tu user id), y sin hashear `fbp`/`fbc`. Más señales = mejor matching = menor CPL.
- **GDPR — orden importa**: no setees las cookies `_fbp`/`_fbc` ni dispares el Pixel **antes** del `grant` de consentimiento. Carga el Pixel tras el consentimiento (o con `fbq('consent','revoke')` por defecto).
- **IP real del visitante**: `x-forwarded-for` puede traer la IP del proxy/CDN según tu hosting; verifica que el primer valor es la IP del cliente (y contempla IPv6), o el matching por IP degrada.
- **Serverless** (Vercel/Lambda/edge): el `void ...catch()` puede perder el evento si la función se congela antes de que termine el `fetch`. Usa `waitUntil()`/`after()` o un `await` con timeout corto. En un servidor Node persistente (PM2/VPS) el fire-and-forget va bien.
- **Header `Origin` duplicado**: algunos proxies lo envían como `https://a, https://a` y rompen `new URL(headers.origin)` con un 500 silencioso en server actions; normaliza tomando el primer valor antes de la coma.
- **Batch**: el ejemplo manda 1 evento por request; la API admite hasta ~1000 eventos en `data[]` si adaptas el patrón a envíos en lote.

---
> Skill en uso real en producción. Úsala, ábrele un issue o mándanos feedback. Licencia: ver `LICENSE` del repo.
