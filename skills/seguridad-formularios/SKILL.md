---
name: seguridad-formularios
description: Hardening de formularios (honeypot, rate limit, CSRF, validación). Invocar al añadir contact form o lead magnet.
---

# 🛡️ Skill: Seguridad de Formularios — Hardening Anti-Spam/Bot

> **Origen:** una web de servicios locales a la que le entraban decenas de leads basura al día.
> **Aplica a:** cualquier formulario de captación — contacto, presupuesto, lead magnet.

## Objetivo

Todo formulario de captación debería llevar al menos 4 de estas 5 capas. Un formulario sin protección no solo te llena la bandeja de basura: si tu backend reenvía por correo, **acabas quemando la reputación del dominio** y los leads de verdad se van a spam.

---

## Capa 1: 🍯 Honeypot (OBLIGATORIA)

Campo invisible que solo los bots rellenan.

### HTML:
```html
<form id="contactForm">
  <!-- Honeypot anti-bot: campo invisible para humanos -->
  <div style="position:absolute;left:-9999px;opacity:0;height:0;overflow:hidden;" aria-hidden="true">
    <label for="website">Website</label>
    <input type="text" id="website" name="website" tabindex="-1" autocomplete="off">
  </div>
  <!-- ... campos normales ... -->
</form>
```

### JavaScript:
```javascript
const honeypot = document.getElementById('website');
if (honeypot && honeypot.value !== '') {
  console.warn('Bot detectado (honeypot)');
  // IMPORTANTE: Simular éxito para que el bot no sepa que fue detectado
  window.location.href = '/gracias.html';
  return;
}
```

**Clave:** Redirigir a la página de gracias para que el bot piense que tuvo éxito.

## Capa 2: ⏱️ Timestamp Anti-Bot (OBLIGATORIA)

Los bots envían formularios instantáneamente. Los humanos tardan mínimo 3-5 segundos.

```javascript
let formLoadedAt = 0;
const MINIMUM_SUBMIT_TIME_MS = 3000;

// Registrar cuando se muestra el formulario
formLoadedAt = Date.now();

// En el handler de submit:
const now = Date.now();
if (formLoadedAt > 0 && (now - formLoadedAt) < MINIMUM_SUBMIT_TIME_MS) {
  console.warn('Envío demasiado rápido (posible bot)');
  window.location.href = '/gracias.html'; // Simular éxito
  return;
}
```

**Si el form está en modal:** Resetear `formLoadedAt` cada vez que se abre el modal usando un `MutationObserver`.

## Capa 3: 🧹 Sanitización de Inputs (OBLIGATORIA)

NUNCA confiar en el input del usuario. Siempre sanitizar antes de enviar.

```javascript
function sanitizeInput(str, maxLength) {
  if (!str) return '';
  return str
    .replace(/<[^>]*>/g, '')          // Eliminar tags HTML
    .replace(/[<>"'`;]/g, '')         // Eliminar caracteres peligrosos
    .trim()
    .substring(0, maxLength || 200);
}

// Uso:
const nombre = sanitizeInput(document.getElementById('nombre').value, 100);
const telefono = sanitizeInput(document.getElementById('telefono').value, 20);
const email = sanitizeInput(document.getElementById('email').value, 100);
const problema = sanitizeInput(document.getElementById('problema').value, 500);
```

**También añadir `maxlength` en HTML** como segunda capa:
```html
<input type="text" name="nombre" maxlength="100" minlength="2" required>
<input type="tel" name="telefono" maxlength="20" pattern="[0-9\s\-\+\(\)]{6,20}" required>
<input type="email" name="email" maxlength="100" required>
```

## Capa 4: ✉️ Validación Estricta de Email (RECOMENDADA)

Más allá de `type="email"` del HTML, validar con regex y bloquear dominios desechables.

```javascript
function isValidEmail(email) {
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(email)) return false;
  
  const disposableDomains = [
    'mailinator.com', 'tempmail.com', 'throwaway.email', 'guerrillamail.com',
    'sharklasers.com', 'yopmail.com', 'trashmail.com', 'maildrop.cc',
    'dispostable.com', 'fakeinbox.com', '10minutemail.com', 'temp-mail.org'
  ];
  const domain = email.split('@')[1].toLowerCase();
  return !disposableDomains.includes(domain);
}
```

## Capa 5: 🚦 Rate Limiting por Sesión (RECOMENDADA)

```javascript
const RATE_LIMIT_MS = 60000; // 1 envío por minuto
let lastSubmitTime = 0;

// En el handler:
if (lastSubmitTime > 0 && (now - lastSubmitTime) < RATE_LIMIT_MS) {
  alert('Por favor, espera un momento antes de enviar otra solicitud.');
  return;
}
lastSubmitTime = now;
```

**Nota:** esto es solo en el navegador y se salta trivialmente. Para un límite de verdad por IP hace falta hacerlo en el backend (o en el automatizador que reciba el formulario). Sirve para frenar el envío accidental por doble clic, no a un bot decidido.

## Checklist de Implementación

- [ ] Honeypot field añadido al HTML (`display:none`, `aria-hidden`, `tabindex=-1`)
- [ ] Timestamp check (mínimo 3 segundos)
- [ ] `sanitizeInput()` aplicada a TODOS los campos
- [ ] `maxlength` en todos los inputs HTML
- [ ] Validación de email con lista de dominios desechables
- [ ] Rate limiting (1 envío/60s mínimo)
- [ ] Los bots detectados son redirigidos a gracias.html (NUNCA mostrar error)
- [ ] Validación de teléfono (solo dígitos, 6-15 caracteres)

## Errores Comunes

| Error | Solución |
|-------|----------|
| Honeypot visible | Usar `position:absolute;left:-9999px` NO `display:none` solo |
| Bot sabe que fue detectado | SIEMPRE redirigir a gracias.html |
| Sanitización solo en el cliente | Repetirla **siempre** en el backend: lo del navegador es comodidad, no seguridad |
| Límite solo en el cliente | Aceptable en una landing; en un SaaS, hazlo en servidor |
