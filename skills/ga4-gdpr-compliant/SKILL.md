---
name: ga4-gdpr-compliant
description: Instalar Google Analytics 4 cumpliendo GDPR (cookie banner + Consent Mode v2) para webs en la UE. Patrón vanilla JS (WordPress simple) y patrón canónico Next.js (App Router) con Consent Mode v2 default-denied + Meta Pixel gateado. Invocar para añadir tracking LEGAL (GA4/Google Ads/Meta) sin perder señales ni exponerte a sanción.
type: reference-skill
---

# 📊 GA4 + Google Tag Manager — GDPR Compliant

> **Categoría:** Analytics / GDPR / Tracking
> **Requisito:** ID de medición GA4 (`G-XXXXXXXXXX`)

---

## Objetivo

Implementar Google Analytics 4 de forma que:
1. **Cumpla GDPR** — solo carga tras el consentimiento del usuario.
2. **Mida engagement** — scroll, clics en CTA, envíos de formulario, clic a teléfono.
3. **Sea reutilizable** — el mismo patrón en todos tus proyectos.

---

## 🔧 Implementación GDPR-Compliant (vanilla JS — WordPress simple)

### Paso 1: Script condicional (solo tras consentimiento)
```html
<!-- GA4 — Solo carga si el usuario acepta cookies -->
<script>
function loadGA4() {
  // Solo cargar si hay consentimiento
  if (localStorage.getItem('cookies-accepted') !== 'true') return;

  const script = document.createElement('script');
  script.src = 'https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX';
  script.async = true;
  document.head.appendChild(script);

  script.onload = function() {
    window.dataLayer = window.dataLayer || [];
    function gtag(){ dataLayer.push(arguments); }
    gtag('js', new Date());
    gtag('config', 'G-XXXXXXXXXX', {
      'anonymize_ip': true,           // GDPR: anonimizar IP
      'cookie_flags': 'SameSite=None;Secure',
      'send_page_view': true
    });

    // Eventos de engagement
    setupEngagementEvents();
  };
}

// Llamar al aceptar cookies
function acceptCookies() {
  localStorage.setItem('cookies-accepted', 'true');
  document.getElementById('cookieBanner').style.display = 'none';
  loadGA4();  // ← Carga GA4 solo aquí
}

// Si ya aceptó antes, cargar al inicio
if (localStorage.getItem('cookies-accepted') === 'true') {
  loadGA4();
}
</script>
```

### Paso 2: Eventos de engagement
```javascript
function setupEngagementEvents() {
  // Evento: Scroll profundo (25%, 50%, 75%, 100%)
  let scrollThresholds = [25, 50, 75, 100];
  let scrollFired = {};
  window.addEventListener('scroll', function() {
    const scrollPercent = Math.round(
      (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
    );
    scrollThresholds.forEach(threshold => {
      if (scrollPercent >= threshold && !scrollFired[threshold]) {
        scrollFired[threshold] = true;
        gtag('event', 'scroll_depth', {
          'event_category': 'engagement',
          'event_label': threshold + '%',
          'value': threshold
        });
      }
    });
  });

  // Evento: Clic en CTA principal
  document.querySelectorAll('.btn-primary').forEach(btn => {
    btn.addEventListener('click', function() {
      gtag('event', 'cta_click', {
        'event_category': 'conversion',
        'event_label': this.textContent.trim()
      });
    });
  });

  // Evento: Envío de formulario
  const form = document.getElementById('contactForm');
  if (form) {
    form.addEventListener('submit', function() {
      gtag('event', 'form_submit', {
        'event_category': 'conversion',
        'event_label': 'presupuesto'
      });
    });
  }

  // Evento: Clic en teléfono
  document.querySelectorAll('a[href^="tel:"]').forEach(link => {
    link.addEventListener('click', function() {
      gtag('event', 'phone_click', {
        'event_category': 'conversion',
        'event_label': this.href
      });
    });
  });
}
```

---

## ⚠️ Normativa GDPR — Requisitos Obligatorios

| Requisito | Cómo lo cumplimos |
|-----------|-------------------|
| Consentimiento previo | GA4 solo carga tras `acceptCookies()` |
| Información clara | Banner de cookies con enlace a política |
| Opción de rechazo | Botón "Solo necesarias" que NO carga GA4 |
| Anonimización IP | `'anonymize_ip': true` en config |
| Derecho de eliminación | GA4 tiene retención configurable (2/14 meses) |
| Sin cookies de terceros | GA4 usa first-party cookies por defecto |

---

## 📋 Checklist por Proyecto

- [ ] Crear cuenta en analytics.google.com
- [ ] Obtener el ID de medición (`G-XXXXXXXXXX`)
- [ ] Guardar el ID en `.env.local` como `GA4_MEASUREMENT_ID`
- [ ] Implementar carga condicional post-consentimiento
- [ ] Configurar eventos: scroll, CTA click, form submit, phone click
- [ ] Configurar retención de datos en GA4: 2 meses (mínimo GDPR)
- [ ] Verificar en GA4 Realtime que llegan eventos
- [ ] Añadir GA4 a la Política de Cookies del sitio

---

## 🟦 CANÓNICO Next.js (App Router) — Consent Mode v2 + banner (OBLIGATORIO webs UE)

> ⚠️ **Desde marzo 2024 Google EXIGE Consent Mode v2** para que GA4 y, sobre todo,
> Google Ads / remarketing / Meta sigan midiendo legalmente en la UE. Sin él, las
> campañas pierden señales y hay exposición RGPD (sanción AEPD). **Ninguna web con
> GA4/Ads/Pixel debería salir a producción sin esto** (mételo en tu checklist de pre-producción).
> El patrón JS vanilla de arriba sirve para WordPress simple; en Next.js usa ESTE.

**Regla de oro**: los tags NO se cargan a pelo. Se declara `consent default = denied`
ANTES de cargar nada (GTM/gtag/Pixel), y solo se hace `consent update = granted` cuando
el usuario ACEPTA en el banner. El Pixel de Meta (sin consent mode nativo) se **gatea**:
no se ejecuta `fbq('init'/'track')` hasta el consentimiento.

### 1) Consent Mode v2 default-denied — lo PRIMERO del `<head>`/Tracking

```tsx
// components/site/Tracking.tsx — antes de GTM/gtag/Pixel
import Script from "next/script";

export function Tracking() {
  return (
    <>
      {/* 1. Consent Mode v2 DEFAULT denied — debe ejecutarse ANTES que cualquier tag */}
      <Script id="consent-default" strategy="beforeInteractive">{`
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        window.gtag = gtag;
        gtag('consent', 'default', {
          ad_storage: 'denied',
          ad_user_data: 'denied',
          ad_personalization: 'denied',
          analytics_storage: 'denied',
          functionality_storage: 'granted',
          security_storage: 'granted',
          wait_for_update: 500
        });
        // Reaplica consentimiento previo (si el usuario ya eligió)
        try {
          var c = localStorage.getItem('site-consent');
          if (c === 'granted') gtag('consent','update',{
            ad_storage:'granted', ad_user_data:'granted',
            ad_personalization:'granted', analytics_storage:'granted'
          });
        } catch(e){}
      `}</Script>

      {/* 2. GTM / gtag Ads / GA4 — ya respetan el consent state de arriba */}
      <Script id="gtag-base" strategy="afterInteractive"
        src="https://www.googletagmanager.com/gtag/js?id=AW-XXXX" />
      <Script id="gtag-config" strategy="afterInteractive">{`
        gtag('js', new Date());
        gtag('config', 'AW-XXXX');
        gtag('config', 'G-XXXX', { anonymize_ip: true });
      `}</Script>

      {/* 3. Meta Pixel GATEADO: init solo tras consentimiento (no tiene consent mode nativo) */}
      <Script id="meta-pixel" strategy="afterInteractive">{`
        try {
          if (localStorage.getItem('site-consent') === 'granted') {
            !function(f,b,e,v,n,t,s){/* snippet fbq estándar */}(window,document,'script',
              'https://connect.facebook.net/en_US/fbevents.js');
            fbq('init','PIXEL_ID'); fbq('track','PageView');
          }
        } catch(e){}
      `}</Script>
    </>
  );
}
```

### 2) Banner de consentimiento (client component)

```tsx
// components/site/CookieConsent.tsx
"use client";
import { useEffect, useState } from "react";

export function CookieConsent() {
  const [show, setShow] = useState(false);
  useEffect(() => { try { if (!localStorage.getItem("site-consent")) setShow(true); } catch {} }, []);

  function decide(granted: boolean) {
    try { localStorage.setItem("site-consent", granted ? "granted" : "denied"); } catch {}
    if (granted && typeof window.gtag === "function") {
      window.gtag("consent", "update", {
        ad_storage: "granted", ad_user_data: "granted",
        ad_personalization: "granted", analytics_storage: "granted",
      });
      // Carga diferida del Pixel de Meta tras aceptar (no estaba inicializado)
      if (typeof window.fbq !== "function") {/* inyectar snippet fbq + init + PageView */}
    }
    setShow(false);
  }
  if (!show) return null;
  return (
    <div className="fixed inset-x-0 bottom-0 z-[80] ...">
      <p>Usamos cookies propias y de terceros para analítica y publicidad. Puedes aceptarlas o seguir solo con las necesarias. <a href="/politica-de-cookies">Más info</a>.</p>
      <button onClick={() => decide(false)}>Solo necesarias</button>
      <button onClick={() => decide(true)}>Aceptar</button>
    </div>
  );
}
```

### Reglas y trampas (Next.js)

- **Orden**: `consent default denied` con `strategy="beforeInteractive"` SIEMPRE antes que GTM/gtag/Pixel. Si se carga después, Google ya disparó con el consentimiento por defecto y no sirve.
- **Meta Pixel**: no tiene consent mode → **gatear el `fbq('init')`** tras aceptar. Si lo cargas siempre, incumples.
- **`functionality_storage`/`security_storage`** sí `granted` (no son tracking).
- **Banner ≠ bloqueo total**: "Solo necesarias" deja la web 100% usable; nunca bloquear el contenido tras el banner (eso es *cookie wall*, ilegal en ES salvo alternativa real).
- **Política de cookies** debe listar GA4 + Ads + Pixel con su finalidad y duración.
- **Verifica en navegador real**: Network → sin aceptar NO debe salir `collect?` (GA) ni `/tr?` (Meta); al aceptar, sí. (`curl` no basta para tracking — comprueba la carga real en el navegador.)
- Si usas **GTM como orquestador**, puedes gestionar el consent dentro de GTM (plantilla Consent Mode); con tags hardcodeados en `Tracking.tsx` se hace en código como arriba.

---

## 🔗 Qué se necesita

1. **ID de medición GA4** (`G-XXXXXXXXXX`) — gratis en analytics.google.com.
2. **Nada más** — no se necesita API key ni acceso especial.
