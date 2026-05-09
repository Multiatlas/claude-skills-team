---
name: seo-protocolo-multiatlas
description: Protocolo SEO completo de MultiAtlas para clientes con WordPress o Next.js. Cubre setup técnico (GA4, Search Console, sitemap, robots, schema), on-page (meta tags, contenido, internal linking), y monitorización. Activa con frases tipo "hacer SEO a X", "SEO completo cliente Y", "configurar GA4 Z", "Search Console", "auditoría SEO inicial cliente W". Para auditoría de un sitio ya con SEO, usar seo-audit. Para crear pages a escala, usar programmatic-seo.
---

# Skill: Protocolo SEO MultiAtlas

> Procedimiento completo cuando se contrata el servicio "SEO" a un cliente.
> Lo que se hace en cada fase, en qué orden, y cómo dejarlo documentado.

## Cuándo activar este skill

- "Hacer SEO al cliente X"
- "SEO completo a Y"
- "Configurar GA4 / Search Console para Z"
- "Auditoría SEO inicial de W"
- "Activar SEO IA en Q"
- "Setup SEO" / "SEO inicial"

Si solo es **diagnóstico de un sitio ya con SEO** → usar `seo-audit`.
Si es **crear muchas pages a escala** → usar `programmatic-seo`.

## Stack y herramientas MultiAtlas

| Herramienta | Para qué |
|---|---|
| **Google Search Console** | Indexación, queries, CTR, errores cobertura |
| **Google Analytics 4** | Tráfico, conversiones, comportamiento usuario |
| **Sitemap XML** | Índice para Google (auto-WP por Yoast/RankMath, manual Next.js) |
| **robots.txt** | Reglas crawl, link al sitemap |
| **Schema.org** (JSON-LD) | Datos estructurados (LocalBusiness, Service, Article…) |
| **Yoast SEO o RankMath** | Plugin WP para meta tags + sitemap (Yoast por defecto MultiAtlas) |
| **Google Search Console API** | Lectura programática (service account ya configurada) |
| **SEO IA** | Generación de contenido y meta optimizados con LLM |
| **OpenRouter / Gemini** | Modelo IA usado para generación SEO |

## Service Account Google Search Console (existente)

- Email: `agente-it-multiatlas@fourth-elixir-477220-c3.iam.gserviceaccount.com`
- Clave en VPS: `/root/.secrets/google-search-console.json` (chmod 600)
- Propiedades ya con acceso (Propietario):
  - multiatlas.net
  - liquidacioncomplementaria.com
  - miaucanveterinarios.com
  - nectaran.es
  - piscinasibiza.com
  - rayarealoficial.es
  - tecnicalderas.com

→ Para clientes nuevos, **añadir el service account como propietario** desde Search Console del cliente (Ajustes → Usuarios y permisos → Añadir usuario → email del service account → Propietario).

## Fases del protocolo

### Fase 1 — Auditoría inicial (0-1 día)

Antes de tocar nada:

1. **Lee la ficha del cliente** en `clientes/<slug>/ficha.md` para saber qué stack tiene.
2. Crea `clientes/<slug>/seo/` para documentación SEO.
3. Auditoría rápida del estado actual:

   ```bash
   # robots.txt
   curl -sS https://<dominio>/robots.txt
   
   # sitemap
   curl -sS https://<dominio>/sitemap.xml | head -20
   curl -sS https://<dominio>/sitemap_index.xml | head -20
   
   # meta tags de homepage
   curl -sS https://<dominio>/ | grep -iE 'title|description|og:|twitter:|canonical' | head -20
   
   # estado HTTP
   curl -sSI https://<dominio>/ | head -10
   ```

4. Comprobar si ya tiene:
   - GA4 (buscar `gtag` en HTML)
   - GTM (buscar `googletagmanager`)
   - Schema (buscar `application/ld+json`)
   - hreflang (si multilenguaje)

5. **Reportar hallazgos** en `clientes/<slug>/seo/auditoria-inicial-YYYY-MM-DD.md` con:
   - Lo que ya tiene ✅
   - Lo que falta ❌
   - Problemas técnicos (404s, redirects rotas, schema mal formado)

→ Para auditoría más profunda, invocar `seo-audit`.

### Fase 2 — Setup técnico base (1-2 días)

Por cada elemento que falte:

#### 2.1 Google Search Console
1. Cliente debe tener cuenta Google → solicitar acceso o usar la que ya use
2. Añadir propiedad: dominio (preferido) o URL prefix
3. Verificar (DNS TXT record o HTML upload)
4. **Añadir service account `agente-it-multiatlas@fourth-elixir-477220-c3.iam.gserviceaccount.com` como Propietario** (clave para automation futura)
5. Enviar sitemap

#### 2.2 Google Analytics 4
1. Crear propiedad GA4 en `analytics.google.com`
2. Configurar stream web con dominio
3. Copiar Measurement ID (`G-XXXXXXX`)
4. Insertar en sitio:
   - **WordPress**: plugin "Site Kit by Google" o tag manager
   - **Next.js**: en `app/layout.tsx` con `<Script src="https://www.googletagmanager.com/gtag/js?id=G-..." />`
5. **Definir conversiones** (formularios, clics CTA, compras)
6. Vincular GSC ↔ GA4 desde GA4 → Admin → Product links → Search Console links

#### 2.3 robots.txt
Estándar MultiAtlas:
```
User-agent: *
Allow: /
Disallow: /wp-admin/
Disallow: /wp-includes/
Disallow: /admin
Disallow: /api/
Disallow: /*?s=*

Sitemap: https://<dominio>/sitemap.xml
```

#### 2.4 sitemap.xml
- **WordPress**: Yoast SEO genera auto en `/sitemap_index.xml`
- **Next.js**: usar `next-sitemap` o generar manual con `app/sitemap.ts`

#### 2.5 Schema.org JSON-LD
Mínimo según tipo de cliente:
- **Empresa local**: `LocalBusiness` con dirección + horarios + teléfono
- **Servicios**: `Service` por cada servicio principal
- **Productos** (si ecommerce): `Product` con price + availability
- **Artículos** (blog): `Article` por post

#### 2.6 Meta tags
Cada página principal debe tener:
- `<title>` único, 50-60 chars, palabra clave principal
- `<meta name="description">` 150-160 chars, persuasivo, con CTA
- `<link rel="canonical">` apuntando a sí mismo (auto en WP/Next.js)
- Open Graph (`og:title`, `og:description`, `og:image`, `og:url`)
- Twitter Card (`twitter:card`, `twitter:title`, etc.)

#### 2.7 `llms.txt` — SEO para motores de búsqueda IA (ChatGPT, Perplexity, Claude, Google AI Overviews)

Estándar emergente (2024-2026) similar al `robots.txt` pero específico para LLMs y AI search engines. Le dice a las IAs **qué contenido pueden indexar y cómo entender el sitio**.

Crear `/llms.txt` en la raíz del dominio con formato Markdown:

```markdown
# <Nombre de la empresa>

> <Descripción breve de qué hace y para quién, 1-2 frases>

## Servicios principales

- [Servicio 1](https://dominio.com/servicio-1.md): descripción
- [Servicio 2](https://dominio.com/servicio-2.md): descripción

## Sobre nosotros

[Sobre nosotros](https://dominio.com/about.md): historia, misión, equipo.

## Contacto

- Web: https://dominio.com
- Email: contacto@dominio.com
- Teléfono: +34 XXX XXX XXX
```

**Por qué importa**: las IAs buscadoras (ChatGPT con web search, Perplexity, Claude con web tool, Google AI Overviews) consultan `llms.txt` para entender el sitio rápido sin tener que parsear HTML completo. Posicionarse aquí es **el nuevo SEO**.

**Variantes opcionales** (recomendadas):
- `/llms-full.txt` con TODO el contenido del sitio en Markdown plano (para LLMs avanzados)
- Cada página con versión `.md` (ej. `https://dominio.com/servicio-1.md` con el contenido en MD limpio)

**Implementación**:
- **WordPress**: plugin "LLMs.txt" o crear archivo manual subido a la raíz
- **Next.js**: `app/llms.txt/route.ts` que sirva el contenido estático

#### 2.8 Optimización contenido para AI search engines

Además del SEO clásico para Google, optimizar para **AI search**:

- **Encabezados claros y semánticos**: las IAs leen el HTML y prefieren H1/H2/H3 lógicos
- **Contenido factual y citable**: AI search engines **citan fuentes** — escribir contenido que pueda ser citado (datos, estadísticas, comparativas)
- **Respuestas directas a preguntas**: las queries en AI search son conversacionales ("¿cuál es el mejor seguro para…?") → tu contenido debe responder explícitamente con esa estructura
- **Schema markup robusto** (ver 2.5): las IAs lo usan para entender entidades

**Prompt para Claude/Gemini al generar contenido SEO**:

> Eres un copywriter especializado en SEO clásico Y AI search. Genera contenido que: (1) responda directamente a la query del usuario en el primer párrafo, (2) use H2/H3 con preguntas naturales, (3) incluya datos verificables y citables, (4) tenga estructura escaneable (bullets, tablas, ejemplos). Optimiza para que tanto Google como ChatGPT/Perplexity citen este contenido.

#### 2.9 Calidad de contenido — criterios oficiales de Google

Google publica los criterios E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness) en [Google Search Central](https://developers.google.com/search/docs/fundamentals/creating-helpful-content).

**Top 10 criterios destilados** (extracto operativo):

1. **Experiencia personal demostrada**: el contenido refleja experiencia directa con el tema
2. **Profundidad y completitud**: cubre el tema más allá de lo obvio
3. **Información verificable**: cita fuentes, datos, ejemplos concretos
4. **Sin keyword stuffing**: el lenguaje fluye natural
5. **Valor añadido vs competencia**: aporta algo único, no es resumen de otros
6. **Autor identificable y experto**: bio del autor visible si aplica
7. **Sin contenido autogenerado de baja calidad**: si usas IA, revisa y enriquece
8. **Title y description honestos**: lo que prometen es lo que entrega
9. **Buena UX**: legible en móvil, sin pop-ups invasivos, carga rápida
10. **Actualizado**: si la info cambia, refrescar el contenido (Google premia frescura en categorías como tech, salud, legal)

**Aplicar como instructions a la IA al generar contenido**:

> Sigue estos 10 criterios E-E-A-T de Google al escribir esta página. Si alguno no se puede cumplir desde el contexto que tienes, márcalo como "[NECESITA INPUT HUMANO]" en lugar de inventar.

### Fase 3 — On-page (3-5 días)

Por cada página principal del cliente:

1. **Investigación keywords**:
   - Usar Google "Personas también preguntan" para queries
   - Search Console del cliente (si ya tiene histórico)
   - Herramientas: Ahrefs, SEMrush, Ubersuggest, o **modelos IA con conocimiento del sector**

2. **Optimizar títulos H1/H2** con keyword principal + variaciones semánticas
3. **Reescribir contenido** con copywriting + marketing-psychology (skills disponibles)
4. **Imágenes** con `alt` descriptivo + lazy loading + WebP
5. **Internal linking**: cada página → 2-3 links a otras páginas del mismo sitio

### Fase 4 — SEO IA / contenido a escala (opcional)

Si el cliente quiere muchas pages similares (ej. servicios por ciudad):

1. **Definir template** de página (estructura, secciones)
2. **Definir variables** (ej. servicio + ubicación)
3. **Generar contenido con IA** (usar `programmatic-seo` skill o pipeline propio Multiatlas):
   - Prompt con datos cliente + sector + intención búsqueda
   - Modelo: Gemini Pro o GPT-4 (según preferencia)
   - Validación humana de output antes de publicar
4. **Schema apropiado** por cada page generada
5. **Internal linking** masivo (ej. desde index a cada page generada)

### Fase 5 — Monitorización (continuo)

Configurar reporting:
1. **Mensual**: comparar tráfico GA4, queries GSC, ranking principales keywords
2. **Alertas**: cuando una keyword cae >X posiciones, cuando aparece error de cobertura
3. **Documentar en `clientes/<slug>/seo/reportes/YYYY-MM.md`**

Skill futura idea: **bot IT recibe Telegram → consulta API GSC → manda reporte mensual** (parte de Business OS).

## Decisiones MultiAtlas estándar

- **Dominio principal con www**: `https://www.dominio.com` (no naked) — redirect 301 desde `dominio.com → www.dominio.com`
- **HTTPS obligatorio** con redirect 301 desde HTTP
- **Idiomas**: si cliente solo opera en España → `lang="es"`. Si multi → `hreflang` por idioma.
- **Mobile-first**: tema/diseño responsive obligatorio
- **Velocidad**: Core Web Vitals ≥ 75 (LCP, FID, CLS)

## Plantilla informe SEO mensual cliente

`clientes/<slug>/seo/reportes/2026-04.md`:

```markdown
# Reporte SEO <Nombre cliente> — Abril 2026

## Resumen ejecutivo
- Tráfico orgánico: X visitas (vs mes anterior +/-Y%)
- Keywords top 10: N (vs mes anterior +/-M)
- Conversiones desde orgánico: K

## Search Console
- Impresiones totales: X (+Y% MoM)
- Clics totales: N (+M% MoM)
- CTR medio: Z%
- Posición media: P

### Top 5 queries
| Query | Impresiones | Clics | CTR | Posición |
|---|---|---|---|---|

### Páginas top
| URL | Clics | Impresiones |
|---|---|---|

## Acciones realizadas este mes
- [ ] …

## Próximos pasos
- [ ] …
```

## Errores comunes a evitar

- ❌ NO instalar GA4 + GTM + Yoast tracking + plugin SEO simultáneamente (medición duplicada)
- ❌ NO usar 301 si vas a cambiar la redirección luego (los 301 los cachea Chrome → verificar SIEMPRE con `curl`, no con browser)
- ❌ NO publicar contenido SEO IA sin revisión humana (factual errors)
- ❌ NO meter keywords stuffing en títulos/descripciones
- ❌ NO bloquear /wp-admin/ con `noindex` directamente — usar robots.txt
- ❌ NO olvidar añadir el service account como Propietario de Search Console (sin esto, no hay automation futura)

## Referencias en el ecosistema MultiAtlas

- Lecciones aprendidas: `PROGRESO.md` línea 213+ ("WordPress .htaccess", "301 cacheadas en browser")
- Service account GSC: `PROGRESO.md` Bloque 5
- 7 propiedades GSC actuales: ver Bloque 5 PROGRESO.md
- Skills relacionadas: `seo-audit`, `programmatic-seo`, `copywriting`, `marketing-psychology`

## Trigger del skill

Esta skill se activa cuando se solicita SEO completo a un cliente. Sigue las 5 fases en orden, no saltar ninguna. La Fase 1 (auditoría) es obligatoria antes de Fase 2 (setup) para no romper config existente.

---

## 🔧 PLAYBOOK OPERATIVO v2 — Optimización PageSpeed/SEO técnico (probado 8-may-2026 Tecniclima)

> Cuando el PageSpeed Insights da scores bajos (<90), aplicar este playbook en BLOQUES estrictos.
> v2 (8-may noche): añadidos Bloques D, E, F, G, H tras auditoría profunda Tecniclima.
> v2 corrige A2: el approach `<Files "robots.txt">` en .htaccess NO funciona cuando Yoast intercepta vía PHP — pasa a mu-plugin.

### Workflow obligatorio

1. **NO empezar a aplicar fixes inmediatamente**. Pedir inventario completo de hallazgos PSI Ordenador + Móvil
2. Construir tabla de hallazgos: hallazgo + impacto + causa raíz + prioridad
3. Aplicar **bloques en orden estricto** A → B → C → D → E → F → G → H
4. Backup defensivo SIEMPRE antes de tocar
5. Smoke test post-fix con `?_x=$(date +%s)` para forzar cache miss

### 🔴 BLOQUE A — Errores críticos rojos

#### A1 — Mixed Content (HTTP en HTTPS)

**Causa típica MA**: CSS de Elementor Google Fonts con `http://<dominio>/wp-content/uploads/elementor/google-fonts/fonts/<nombre>.woff2`.

**Diagnóstico**:
```bash
ssh s2 'find /var/www/vhosts/<dominio>/httpdocs/wp-content/uploads/elementor -name "*.css" | xargs grep -l "http://<dominio>"'
```

**Fix con backup**:
```bash
ssh s2 'cd /var/www/vhosts/<dominio>/httpdocs/wp-content/uploads/elementor/google-fonts/css/ && \
mkdir -p _backup_$(date +%Y%m%d) && \
for f in *.css; do
  cp -n $f _backup_$(date +%Y%m%d)/
  sed -i "s|http://<dominio>|https://<dominio>|g" $f
done'
```

**⚠️ CRÍTICO — Purgar cache nginx proxy** (sin esto sigue sirviendo Brotli pre-cacheado con HTTP):
```bash
ssh s2 'for css in *.css; do
  files=$(grep -lr "$css" /var/cache/nginx/<dominio>_proxy/ 2>/dev/null)
  [ -n "$files" ] && echo "$files" | xargs rm -v
done'
```

#### A2 — robots.txt con header `X-Robots-Tag: noindex` (Yoast) — ⚠️ CORREGIDO v2

**Síntoma**: PageSpeed → SEO: "robots.txt no es válido"

**Causa**: Yoast intercepta `/robots.txt` vía PHP (NO archivo físico) y aplica `X-Robots-Tag: noindex, follow`.

**❌ APPROACH FALLIDO v1**: `<Files "robots.txt"> Header unset X-Robots-Tag` en .htaccess. NO funciona porque Yoast sirve robots.txt vía PHP, no archivo físico — directivas Apache `<Files>` no aplican.

**✅ APPROACH CORRECTO v2**: mu-plugin con doble defensa.

```php
// Action en do_robotstxt
add_action('do_robotstxt', function () {
    if (!headers_sent()) {
        header_remove('X-Robots-Tag');
    }
}, 999);

// Filter en wp_robots
add_filter('wp_robots', function ($robots) {
    if (function_exists('is_robots') && is_robots()) {
        unset($robots['noindex'], $robots['follow'], $robots['nofollow']);
    }
    return $robots;
}, 999);
```

Purgar cache nginx del robots.txt y verificar:
```bash
ssh s2 'find /var/cache/nginx/<dominio>_proxy/ -type f | xargs grep -l "robots.txt" 2>/dev/null | xargs rm -v'
curl -sI "https://<dominio>/robots.txt?_x=$(date +%s)" | grep -i x-robots
# (sin output = OK)
```

### 🟡 BLOQUE B — Performance base

#### B1 — Cache headers HTTP estáticos

Añadir al `.htaccess`:
```apache
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
    ExpiresByType font/woff "access plus 1 year"
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresDefault "access plus 1 day"
</IfModule>

<IfModule mod_headers.c>
    <FilesMatch "\.(jpg|jpeg|png|gif|webp|svg|ico|woff|woff2|css|js)$">
        Header set Cache-Control "public, max-age=31536000, immutable"
    </FilesMatch>
</IfModule>
```

#### B2 — WP Rocket: verificar settings + diagnosticar RUCSS roto

Si cliente tiene WP Rocket:
```bash
ssh s2 '/opt/plesk/php/8.3/bin/php /usr/local/bin/wp --allow-root --path=/var/www/vhosts/<dominio>/httpdocs option get wp_rocket_settings --format=json'
```

Verificar que están a `1`: `defer_all_js`, `delay_js`, `minify_js`, `minify_css`, `optimize_css_delivery`, `lazyload`, `image_dimensions`, `cache_webp`, `remove_unused_css`.

**⚠️ HALLAZGO CRÍTICO Tecniclima 8-may**: incluso con `remove_unused_css: 1` activo, RUCSS puede estar **ROTO desde meses**. En Tecniclima llevaba fallando desde junio 2025 (12 entradas con `failed` y 6 retries c/u). El servicio API externo de WP Rocket (`api.wp-rocket.me`) no respondía.

**Diagnóstico cola RUCSS**:
```bash
ssh s2 '/opt/plesk/php/8.3/bin/php /usr/local/bin/wp --allow-root --path=/var/www/vhosts/<dominio>/httpdocs db query "SELECT status, COUNT(*) FROM wp_wpr_rucss_used_css GROUP BY status;"'
```

Si ves muchos `failed`:
1. Truncar tabla y reintentar: `TRUNCATE TABLE wp_wpr_rucss_used_css;`
2. Limpiar cachés WP Rocket + nginx
3. Encolar URLs principales con `curl ?_warmup=$(date +%s)`
4. Si tras 1h sigue failed → escalar a Almacena para revisar firewall a `api.wp-rocket.me`
5. Como fallback: actualizar WP Rocket a versión última

**⚠️ wp-cli `wp rocket` NO está registrado por defecto** — usar `wp eval` o `wp db query`.

#### B3 — Defer/Delay JS

Si WP Rocket está y configurado: ya hace `defer_all_js` + `delay_js`. **NO defer-ear manualmente** — riesgo de romper jQuery/Elementor/Astra.

### 🔍 BLOQUE C — Indexación Search Console

#### C1 — Sitemap_index abandonado

Re-enviarlo desde SC → Sitemaps → "Eliminar" + "Añadir nuevo sitemap".

#### C2 — Páginas no indexadas

NO confiar en campo `indexed: 0` del Sitemaps API (ver `feedback_search_console_indexed_field_unreliable.md`). Usar URL Inspection API:
```javascript
fetch('https://searchconsole.googleapis.com/v1/urlInspection/index:inspect', {
  method: 'POST',
  headers: { 'Authorization': 'Bearer ' + accessToken },
  body: JSON.stringify({
    inspectionUrl: 'https://<dominio>/<ruta>/',
    siteUrl: 'sc-domain:<dominio>',
    languageCode: 'es-ES'
  })
});
```

### 🧹 BLOQUE D-bis — GTM zombie cleanup (NUEVO v3, validado 9-may Tecniclima)

**Síntoma**: PSI Diagnósticos muestra 2+ contenedores GTM cargando (`GTM-XXXX` + `GTM-YYYY`).

**Workflow** (si MA gestiona el cliente, hacerlo nosotros):

1. Buscar TODOS los IDs GTM en BD + archivos:
```bash
ssh <server> 'grep -rE "GTM-[A-Z0-9]+" /var/www/vhosts/<dominio>/httpdocs/wp-content/'
```

2. Buscar dónde se inyectan (típicos):
- WPCode (`wp_posts` post_type=wpcode + option `wpcode_snippets`)
- IHAF Insert Header and Footer (options `ihaf_insert_header` + `ihaf_insert_body`)
- Site Kit (oficial — mantener)
- PixelYourSite (gestor Facebook píxel — mantener si se usa Meta Ads)

3. **CLAVE**: verificar que las conversiones Google Ads (`AW-XXXX`) NO están en GTMs del WP — en MA suelen estar en landings .html standalone, así que eliminar GTMs WP NO afecta a las conversiones del media buyer.

4. Backup → vaciar IHAF options → cambiar status WPCode snippets a draft → **vaciar option `wpcode_snippets`** (clave: el plugin tiene cache propio, sin esto sigue inyectando) → limpiar caches.

5. Verificar: home WP YA no carga los GTM eliminados, pero SÍ siguen GA4 (G-...) + Pixel Meta (/tr?id=...) + conversiones AW en landings.

**Resultado típico**: ~285 KiB JS bloqueante eliminado. En Tecniclima 9-may, LCP móvil bajó de 15.3s → 12.2s (-3.1s).

### 🚀 BLOQUE D — LCP + Terceros (NUEVO v2)

#### D1 — Imagen LCP: preload + fetchpriority

Hero de Elementor suele ser `background-image` en CSS (no `<img>`) → preloader del browser no la encuentra → ~500ms retraso.

Identificar imagen LCP: PSI da el `data-id` de la sección. Buscar en CSS:
```bash
curl -s "https://<dominio>/wp-content/uploads/elementor/css/post-<ID-PAGE>.css" | grep -B1 -A1 "elementor-element-<DATA-ID-LCP>"
```

Fix vía mu-plugin (solo en home):
```php
add_action('wp_head', function () {
    if (is_front_page() || is_home()) {
        $lcp = 'https://<dominio>/wp-content/uploads/<año>/<mes>/<imagen-hero>.jpg';
        echo '<link rel="preload" as="image" href="' . esc_url($lcp) . '" fetchpriority="high">' . "\n";
    }
}, 1);
```

#### D2 — Preconnect a terceros bloqueantes

Identificar terceros desde "Árbol de dependencia de red" PSI. Típicos en MA: `consent.cookiebot.com`, `consentcdn.cookiebot.com`, `cdn.trustindex.io`.

Fix vía mu-plugin (mismo `wp_head`):
```php
echo '<link rel="preconnect" href="https://consent.cookiebot.com" crossorigin>' . "\n";
echo '<link rel="preconnect" href="https://consentcdn.cookiebot.com" crossorigin>' . "\n";
```

#### D3 — 2 contenedores GTM activos

PSI muestra 2 cargas de GTM diferentes (ej. `GTM-XXXXXX` + `GT-YYYYYY`).

**NO eliminar nadie sin auditar**. Requiere acceso a `tagmanager.google.com`. Marcar como **DECISIÓN cliente/marketing** — NO actuar sin OK.

### 📐 BLOQUE E — CLS y imágenes adaptativas (NUEVO v2)

#### E1 — Carrusel logos sin width/height

Síntoma: "Los elementos de imagen no tienen width y height explícitos" en Elementor swiper.

Fix vía mu-plugin (filter `the_content`):
```php
add_filter('the_content', function ($content) {
    if (strpos($content, 'swiper-slide-image') === false) return $content;
    $content = preg_replace_callback(
        '/<img\s+([^>]*class="[^"]*swiper-slide-image[^"]*"[^>]*)>/i',
        function ($matches) {
            $attrs = $matches[1];
            if (preg_match('/\swidth\s*=/i', $attrs) || preg_match('/\sheight\s*=/i', $attrs)) {
                return $matches[0];
            }
            return '<img width="250" height="150" ' . $attrs . '>';
        },
        $content
    );
    return $content;
}, 100);
```

Dimensiones nativas thumb Elementor: 250×150 (ajustar según theme).

#### E2 — Imágenes sin srcset óptimo

Síntoma: "Image más grande de lo necesario (NxM) para las dimensiones mostradas (XxY)".

Causa: Elementor pide `attachment-full` por defecto. Fix: editar widget Elementor → Image Size → cambiar de "Full" a "Medium" o "Large". **DECISIÓN cliente/diseñador**.

### 🖼️ BLOQUE F — Logo header sobredimensionado (NUEVO v2)

Logo PNG de 800-1500 px ancho mostrado a 200-300 px → 4-7× overdraw.

Fix directo en server con backup:
```bash
ssh s2 'cd /var/www/vhosts/<dominio>/httpdocs/wp-content/uploads/<año>/<mes>/
cp logo.png logo.png.bak.original.$(date +%Y%m%d-%H%M%S)
convert logo.png -resize <ancho_retina>x<alto_retina> -strip -quality 92 logo.png
ls -lh logo.png logo.png.bak.original.*
find /var/cache/nginx/<dominio>_proxy/ -type f | xargs grep -l "logo.png" 2>/dev/null | xargs rm -v'
```

`<ancho_retina>` = 2× el ancho real renderizado (para retina).

### 🎨 BLOQUE G — Conversión WebP automática (NUEVO v2)

#### G1 — Plugin: Converter for Media (RECOMENDADO MA)

**Por qué Converter for Media** (no Imagify, no ShortPixel, no Optimole):
- Gratis 100% (sin cuotas mensuales que rompen)
- 100% local en server (no depende de servicio externo)
- 700k+ instalaciones
- Funciona con `cache_webp: 1` de WP Rocket automáticamente

Verificar capacidades:
```bash
ssh s2 '/opt/plesk/php/8.3/bin/php /usr/local/bin/wp --allow-root --path=/var/www/vhosts/<dominio>/httpdocs eval "echo class_exists(\"Imagick\") ? \"Imagick OK\" : \"NO Imagick\"; echo function_exists(\"imagewebp\") ? \"GD WebP OK\" : \"NO GD WebP\";"'
```

#### G2 — Bulk regeneration WebP (cuando solo se han convertido nuevas)

Patrón Converter for Media: WebP en `/wp-content/uploads-webpc/uploads/<ruta>.<ext>.webp`.

**⚠️ wp-cli `wp webpc` NO está registrado** — usar script bash directo:

```bash
#!/bin/bash
UPLOADS=/var/www/vhosts/<dominio>/httpdocs/wp-content/uploads
WEBPC=/var/www/vhosts/<dominio>/httpdocs/wp-content/uploads-webpc/uploads
cd "$UPLOADS" || exit 1
processed=0; generated=0; skipped=0; failed=0
while IFS= read -r img; do
  rel="${img#./}"
  webp_path="$WEBPC/$rel.webp"
  webp_dir=$(dirname "$webp_path")
  [ -f "$webp_path" ] && { skipped=$((skipped+1)); continue; }
  [[ "$rel" == *bak* ]] || [[ "$rel" == *original* ]] && { skipped=$((skipped+1)); continue; }
  mkdir -p "$webp_dir"
  if convert "$img" -strip -quality 85 "$webp_path" 2>/dev/null; then
    orig_size=$(stat -c%s "$img"); webp_size=$(stat -c%s "$webp_path")
    if [ "$webp_size" -ge "$orig_size" ]; then rm -f "$webp_path"; skipped=$((skipped+1));
    else generated=$((generated+1)); fi
    chown <propietario>:psacln "$webp_path" 2>/dev/null
  else failed=$((failed+1)); fi
  processed=$((processed+1))
done < <(find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "*backup*" ! -path "*bak*")
echo "RESULT: processed=$processed generated=$generated skipped=$skipped failed=$failed"
```

Lanzar en background: `nohup bash /tmp/regen-webp.sh > /tmp/regen-webp.log 2>&1 &`.

Verificar serve WebP:
```bash
curl -sI -H "Accept: image/webp,*/*;q=0.8" "https://<dominio>/<ruta-imagen>.jpg" | grep -iE "content-type|content-length"
# content-type: image/webp ← CORRECTO
```

### 🛡️ BLOQUE H — Headers seguridad básicos (NUEVO v2 — SIN HSTS)

**⚠️ HSTS NO se aplica desde este playbook**. Razón: navegadores cachean HSTS mínimo 6 meses tras primera visita. Si hay que revertir, queda atrapado en clientes meses. Requiere decisión explícita "este dominio HTTPS para siempre" → escalar a Almacena.

Headers seguros y reversibles — añadir al `.htaccess`:
```apache
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
</IfModule>
```

CSP NO se añade por defecto — cada cliente tiene scripts diferentes (GTM, Cookiebot, Trustindex). Una CSP mal configurada rompe el sitio. **Auditoría individual por cliente**.

### Resultados esperados

Tras aplicar A + B + D + G en una WordPress típica:

| Score | Antes típico | Después típico |
|---|---|---|
| Ordenador SEO | 90-92 | **100** |
| Ordenador Prácticas | 70-75 | **100** |
| Ordenador Rendimiento | 65-75 | **85-95** |
| Móvil SEO | 90-95 | **100** |
| Móvil Prácticas | 70-80 | **100** |
| Móvil Rendimiento | 50-65 | **75-85** |

### ⚠️ Reglas operativas obligatorias

- **REGLA INVIOLABLE WooCommerce**: si tiene clientes/pedidos vivos, ver `feedback_woocommerce_no_tocar_bd_pedidos_clientes.md`. Backup defensivo obligatorio.
- **Backup `.htaccess`** SIEMPRE: `cp .htaccess .htaccess.bak.$(date +%Y%m%d-%H%M%S)`
- **Backup mu-plugin** SIEMPRE: `cp <plugin>.php <plugin>.php.bak.v<X>.$(date +%Y%m%d-%H%M%S)`
- **Backup imagen original** antes de reescalar
- **NO instalar plugins nuevos** sin OK Rubén explícito
- **NO HSTS** (irreversible en clientes)
- **NO eliminar contenedores GTM** sin auditar dashboard
- **NO modificar widget Elementor srcset** sin acceso al editor cliente
- **Smoke test post-fix**: HTTP 200 + curl con cache busting + nuevo PageSpeed

Memoria persistente del playbook completo: `feedback_seo_optimizacion_pagespeed_playbook.md`.
