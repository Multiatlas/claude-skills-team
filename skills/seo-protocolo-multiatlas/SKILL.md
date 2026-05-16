---
name: seo-protocolo-multiatlas
description: Protocolo SEO completo de <TuEmpresa> para clientes con WordPress o Next.js. Cubre setup técnico (GA4, Search Console, sitemap, robots, schema), on-page (meta tags, contenido, internal linking), y monitorización. Activa con frases tipo "hacer SEO a X", "SEO completo cliente Y", "configurar GA4 Z", "Search Console", "auditoría SEO inicial cliente W". Para auditoría de un sitio ya con SEO, usar seo-audit. Para crear pages a escala, usar programmatic-seo.
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

- Email: `<your-ops-repo>@fourth-elixir-477220-c3.iam.gserviceaccount.com`
- Clave en VPS: `<secrets-vault>/google-search-console.json` (chmod 600)
- Propiedades ya con acceso (Propietario):
  - <tudominio>.com
  - liquidacioncomplementaria.com
  - miaucanveterinarios.com
  - <cliente-ecommerce>.com
  - piscinasibiza.com
  - rayarealoficial.es
  - <cliente-calderas>.com

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

### Fase 1.5 — Auditoría SEO por intent (cliente WP heredado con tracking ya)

Aplica cuando el cliente **ya tiene web en producción** (no setup desde cero). El objetivo es decidir qué necesita re-trabajar por página real, no recomendaciones genéricas. Validado 12-may-2026 con dos casos reales de clientes B2B (HVAC + SAT electrodomésticos).

#### Cuándo activar esta fase

- Cliente WP / Next.js heredado con tracking ya instalado (GA4/GTM ya hay)
- PSI Performance ≥ 70 + SEO/A11y/BP ≥ 90 (ver `feedback_seo_real_sobre_pagespeed_maximalista.md` — no perder tiempo más en PSI, pivotar a SEO real)
- Petición el admin tipo "haz SEO técnico real a X" o "SEO por intent en Y"

#### 1.5.A Detección de patologías sistémicas (antes de auditar página a página)

Hay 5 patologías que indican que tocará **mu-plugin con overrides por URL** (no editar Yoast página a página):

| Síntoma | Severidad | Causa típica |
|---|---|---|
| Múltiples páginas con `<title>` IDÉNTICO | 🔴 contenido duplicado para Google | Cliente nunca configuró title por página en Yoast → Yoast usa el title del tipo de página/template |
| `<title>` con formato `post_title - site_name` en MINÚSCULAS | 🔴 Yoast default sin tocar | Cliente nunca tocó SEO en wp-admin |
| `<meta name="description">` VACÍA en muchas páginas | 🔴 SERP sin descripción persuasiva | Cliente nunca lo rellenó |
| 0 `<h1>` en página clave (home, fichas marca) | 🔴 SEO crítico | Theme/Elementor solo genera h2s por defecto |
| `<a href>` en home llevando varias categorías al MISMO destino | 🔴 internal linking roto | Bug copy-paste Elementor |

Si detectas 2+ de estas en el mismo cliente: **patología sistémica = mu-plugin** (ver sección "Patrón canónico: Mu-plugin overrides SEO por URL" más abajo).

#### 1.5.B Batch audit con curl + node

NO revisar página a página manualmente. Usar script `seo-extract.mjs` (genérico, copia local desde memoria del agente):

```javascript
// c:/tmp/seo-extract.mjs — batch SEO metadata extractor
const urls = process.argv.slice(2);

function clean(s, max = 120) {
  return s.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim().slice(0, max);
}

async function audit(url) {
  const res = await fetch(url, { headers: { 'User-Agent': 'MA-SEO-Audit' }, redirect: 'follow' });
  const html = await res.text();
  const title = (html.match(/<title>([^<]*)<\/title>/) || [])[1] || 'NONE';
  const desc = (html.match(/<meta\s+name=["']description["']\s+content=["']([^"']*)["']/i) || [])[1] || 'NONE';
  const canon = (html.match(/<link\s+rel=["']canonical["']\s+href=["']([^"']*)["']/i) || [])[1] || 'NONE';
  const h1s = [...html.matchAll(/<h1[^>]*>([\s\S]*?)<\/h1>/gi)].map(m => clean(m[1], 100));
  const h2s = [...html.matchAll(/<h2[^>]*>([\s\S]*?)<\/h2>/gi)].map(m => clean(m[1], 100));
  const robots = (html.match(/<meta\s+name=["']robots["']\s+content=["']([^"']*)["']/i) || [])[1] || '(default)';
  const ogImage = (html.match(/<meta\s+property=["']og:image["']\s+content=["']([^"']*)["']/i) || [])[1] || 'NONE';
  const schemaTypes = [...html.matchAll(/"@type"\s*:\s*"([^"]+)"/g)].map(m => m[1]);

  console.log(`\n===== ${url} (${res.status}) =====`);
  console.log(`TITLE: ${title}`);
  console.log(`META : ${desc.slice(0, 200)}`);
  console.log(`CANON: ${canon}`);
  console.log(`ROBOTS: ${robots}`);
  console.log(`OG:IMG: ${ogImage.slice(0, 100)}`);
  console.log(`H1 (${h1s.length}): ${JSON.stringify(h1s)}`);
  console.log(`H2 (${h2s.length}): ${JSON.stringify(h2s.slice(0, 10))}`);
  console.log(`SCHEMA: ${[...new Set(schemaTypes)].join(', ')}`);
}

for (const u of urls) await audit(u);
```

Uso:
```bash
node /c/tmp/seo-extract.mjs https://cliente.com/ https://cliente.com/servicio-1/ https://cliente.com/marcas/x/
```

Ahorro estimado: **2-3h por cliente** vs revisión manual en navegador.

También útil para **smoke test post-deploy** del mu-plugin: re-correr con `?_cb=$(date +%s)` (cache busting) sobre las URLs cambiadas y verificar que los titles/metas/schemas nuevos aparecen.

#### 1.5.C Definición de intent por página

Para cada URL estratégica, identificar:

- **Tipo de intent**: informacional / transaccional / navegacional / comparativo / local
- **Keyword principal** (1 palabra/frase) + 2-3 variantes (Google "personas también preguntan", autocompletado, "búsquedas relacionadas")
- **Audiencia esperada**: ¿qué busca el usuario que aterriza ahí?

Ejemplos sector servicio técnico hogar:
- `/reparacion-lavadoras-pamplona/` → intent transaccional local urgente. Keyword: "reparacion lavadoras Pamplona"
- `/aire-acondicionado-no-enfria/` → intent informacional + decisión. Keyword: "aire acondicionado no enfría"
- `/marcas/bosch/` → intent transaccional marca específica. Keyword: "servicio técnico Bosch Madrid"

#### 1.5.D Matriz de evaluación por página

Para cada página estratégica, evaluar 9 ejes y proponer fix concreto:

| Aspecto | ¿OK? | Recomendación |
|---|---|---|
| `<title>` ≤ 60 chars, keyword principal al inicio, marca al final | ✅ / ❌ | Texto exacto propuesto |
| `<meta description>` ≤ 155 chars, intent + USP + CTA | ✅ / ❌ | Texto exacto propuesto |
| `<h1>` único, con keyword principal | ✅ / ❌ | Texto exacto propuesto |
| Jerarquía h2/h3 ordenada (no salta niveles) | ✅ / ❌ | Reorden propuesto |
| Schema apropiado al intent (LocalBusiness/Service/Article/FAQPage) | ✅ / ❌ | Tipo a añadir |
| Canonical correcto | ✅ / ❌ | — |
| Internal links a páginas hermanas y madre | ✅ / ❌ | Lista de links a añadir |
| Alt de imagen LCP con keyword | ✅ / ❌ | Alt propuesto |
| CTA principal matchea intent | ✅ / ❌ | Cambio CTA |

#### 1.5.E Entregable canónico — `clientes/<slug>/seo-audit-por-intent.md`

Plantilla replicable:

```markdown
# Auditoría SEO por intent — <Cliente>

> **Fecha:** YYYY-MM-DD
> **Auditor:** <your-ops-repo>
> **Scope:** Páginas estratégicas indexables. Excluye legales, gracias, paginación, archive.

## Resumen ejecutivo

### 🔴 Crítico
1. <hallazgo top>
2. <hallazgo>

### 🟡 Mejorable
…

### ✅ Lo que ya está bien
…

## Matriz por página

### Home `/`
| Aspecto | Actual | Propuesta |
|---|---|---|
| **Intent** | Transaccional + local | — |
| **Keyword principal** | <keyword> | — |
| **Title** | "<actual>" | **"<propuesto>"** |
| **Meta description** | "<actual>" | **"<propuesto>"** |
| **H1** | ❌ NO EXISTE / ✅ "<actual>" | **"<propuesto>"** |
| **Jerarquía** | <h2 actuales> | <h2 reordenados> |
| **Schema** | <tipos actuales> | <tipos a añadir> |
| **Internal links** | <faltan> | <links a añadir> |
| **Acción** | mu-plugin: <X>  •  Elementor: <Y> | — |

### <Página 2> …
(repetir matriz)

## Plan de aplicación

### Fase A — Fixes vía mu-plugin (lo que NO requiere Elementor)
1. Filter `pre_get_document_title` con map de overrides por URL
2. Filter `wpseo_metadesc` con overrides
3. Schema `Service` / `LocalBusiness` / `FAQPage` por URL

### Fase B — HTML estático (si lo hay)
- Cambios directos a `landing.html` / `aire-acondicionado/index.html` etc.

### Fase C — Lista Elementor para el admin
| Página | Acción | Estimado |
|---|---|---|
| Home | Añadir `<h1>` "<texto>" | 2 min |
| <página> | <acción> | <tiempo> |

## Preguntas para el admin antes de aplicar
1. <decisión a validar>
```

### Fase 2 — Setup técnico base (1-2 días)

Por cada elemento que falte:

#### 2.1 Google Search Console
1. Cliente debe tener cuenta Google → solicitar acceso o usar la que ya use
2. Añadir propiedad: dominio (preferido) o URL prefix
3. Verificar (DNS TXT record o HTML upload)
4. **Añadir service account `<your-ops-repo>@fourth-elixir-477220-c3.iam.gserviceaccount.com` como Propietario** (clave para automation futura)
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

## Decisiones <TuEmpresa> estándar

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

## Patrón canónico — Mu-plugin overrides SEO por URL (WP heredados)

Validado 12-may-2026 en dos clientes WordPress reales con catálogos similares. Ver memoria `feedback_seo_overrides_por_url_mu_plugin.md` para detalle completo.

### Cuándo aplicar este patrón

Cuando la Fase 1.5 detecta 2+ de las patologías sistémicas (titles idénticos, formato Yoast default, metas vacías masivas, 0 H1 sistémico). NO editar Yoast página a página — el patrón es mu-plugin con overrides.

### Por qué mu-plugin y no editor Yoast

- Cliente no lo puede pisar (no aparece en wp-admin)
- Versionado en `clientes/<slug>/mu-plugins/` (git)
- Deployable con scp en 30 segundos
- Replicable: cambias el map de URLs y se actualiza la web
- Permite Schema dinámico contextual (Service con Brand por marca, EmergencyService, LocalBusiness variante por geo)
- Sobrevive a updates del theme/Elementor

### Plantilla canónica del mu-plugin

```php
<?php
/**
 * Plugin Name: <TuEmpresa> SEO <Cliente>
 * Description: Overrides SEO por URL + Schema dinámico contextual.
 * Version: 1.0.0
 * Author: MultiAtlas
 */

if (!defined('ABSPATH')) exit;

// ============================================================================
// 1. Helper: ruta normalizada (lowercase, sin trailing slash, "/" para home)
// ============================================================================
function ma_<slug>_current_path() {
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
    if (!is_string($path) || $path === '') return '/';
    $path = strtolower($path);
    return $path !== '/' ? rtrim($path, '/') : '/';
}

// ============================================================================
// 2. Catálogo de páginas estáticas (home, contacto, servicios, hubs)
// ============================================================================
function ma_<slug>_static_overrides() {
    static $map = null;
    if ($map !== null) return $map;
    $map = array(
        '/' => array(
            'title'    => 'Keyword principal en Geo — Variantes secundarias | Marca',
            'metadesc' => 'Empresa de X en Geo. USPs claros (técnicos homologados, garantía, urgencia). CTA implícito.',
        ),
        '/servicio-1' => array(
            'title'    => 'Servicio 1 en Geo — Variantes | Marca',
            'metadesc' => '...',
        ),
        // ...
    );
    return $map;
}

// ============================================================================
// 3. (Si aplica) Catálogo de fichas marca categorizado
// ============================================================================
function ma_<slug>_brands_catalog() {
    static $cat = null;
    if ($cat !== null) return $cat;
    $cat = array(
        // path => array(brand, cat)  donde cat = 'electro' | 'caldera' | 'aire' | etc.
        '/marcas/servicio-tecnico-bosch-madrid' => array('brand' => 'Bosch', 'cat' => 'electro'),
        '/servicio-tecnico-vaillant-…'          => array('brand' => 'Vaillant', 'cat' => 'caldera'),
        '/servicio-tecnico-daikin-…'            => array('brand' => 'Daikin', 'cat' => 'aire'),
        // ...
    );
    return $cat;
}

function ma_<slug>_brand_title_meta($brand, $cat) {
    if ($cat === 'electro') {
        return array(
            'title'    => "Servicio Técnico {$brand} en Geo — Reparación de Electrodomésticos | Marca",
            'metadesc' => "Servicio técnico no oficial de electrodomésticos {$brand} en Geo: lavadoras, frigoríficos, lavavajillas, hornos. Reparación con garantía por escrito.",
        );
    } elseif ($cat === 'caldera') {
        return array(
            'title'    => "Servicio Técnico {$brand} en Geo — Reparación de Calderas | Marca",
            'metadesc' => "Servicio técnico de calderas {$brand} en Geo: gas, gasoil, condensación. Reparación urgente, mantenimiento. Piezas originales.",
        );
    } else { // aire
        return array(
            'title'    => "Servicio Técnico {$brand} en Geo — Reparación de Aire Acondicionado | Marca",
            'metadesc' => "Servicio técnico de aire acondicionado {$brand} en Geo: split, multisplit, conductos. Reparación urgente, recarga de gas, mantenimiento.",
        );
    }
}

function ma_<slug>_resolve_seo_override($path) {
    $static = ma_<slug>_static_overrides();
    if (isset($static[$path])) return $static[$path];
    $brands = ma_<slug>_brands_catalog();
    if (isset($brands[$path])) return ma_<slug>_brand_title_meta($brands[$path]['brand'], $brands[$path]['cat']);
    return null;
}

// ============================================================================
// 4. Filter <title> via pre_get_document_title priority 99
//    (gana a Yoast que usa wp_title con prioridad estándar)
// ============================================================================
add_filter('pre_get_document_title', function ($title) {
    $o = ma_<slug>_resolve_seo_override(ma_<slug>_current_path());
    return $o && !empty($o['title']) ? $o['title'] : $title;
}, 99);

// ============================================================================
// 5. Filter meta description via wpseo_metadesc priority 99 (Yoast)
// ============================================================================
add_filter('wpseo_metadesc', function ($metadesc) {
    $o = ma_<slug>_resolve_seo_override(ma_<slug>_current_path());
    return $o && !empty($o['metadesc']) ? $o['metadesc'] : $metadesc;
}, 99);

// ============================================================================
// 6. Fallback wp_head si Yoast NO está activo (guard function_exists)
// ============================================================================
add_action('wp_head', function () {
    if (function_exists('YoastSEO')) return; // Yoast lo gestiona
    $o = ma_<slug>_resolve_seo_override(ma_<slug>_current_path());
    if ($o && !empty($o['metadesc'])) {
        echo '<meta name="description" content="' . esc_attr($o['metadesc']) . '">' . "\n";
    }
}, 1);

// ============================================================================
// 7. Schema LocalBusiness en home (tipo según cliente)
//    HVACBusiness   — empresa climatización
//    HomeAndConstructionBusiness — servicio mixto (electro+calderas+AC)
//    EmergencyService — páginas /urgencias-…/
//    Service        — páginas /<servicio>/
// ============================================================================
add_action('wp_head', function () {
    if (ma_<slug>_current_path() !== '/') return;
    $schema = array(
        '@context' => 'https://schema.org',
        '@type'    => 'HomeAndConstructionBusiness',  // o HVACBusiness, etc.
        '@id'      => home_url('/#localbusiness'),
        'name'     => '<Cliente>',
        'description' => '...',
        // ... areaServed, serviceType array, openingHours, etc.
    );
    echo '<script type="application/ld+json">' . wp_json_encode($schema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT) . '</script>';
}, 100);

// ============================================================================
// 8. Schema Service+Brand por ficha marca (dinámico por categoría)
// ============================================================================
add_action('wp_head', function () {
    $path = ma_<slug>_current_path();
    $brands = ma_<slug>_brands_catalog();
    if (!isset($brands[$path])) return;
    $brand = $brands[$path]['brand'];
    $cat = $brands[$path]['cat'];

    // Mapear $cat → serviceType de schema.org
    $serviceType = ($cat === 'electro') ? 'Appliance repair'
                 : (($cat === 'caldera') ? 'Boiler repair' : 'Air conditioning repair');

    $schema = array(
        '@context'    => 'https://schema.org',
        '@type'       => 'Service',
        'name'        => "Servicio Técnico {$brand} en Geo",
        'serviceType' => $serviceType,
        'brand'       => array('@type' => 'Brand', 'name' => $brand),
        'provider'    => array('@id' => home_url('/#localbusiness')),  // referencia LocalBusiness raíz
        'areaServed'  => array(
            array('@type' => 'AdministrativeArea', 'name' => 'Geo principal'),
            array('@type' => 'AdministrativeArea', 'name' => 'Geo secundaria'),
        ),
        'url' => home_url($path . '/'),
    );
    echo '<script type="application/ld+json">' . wp_json_encode($schema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT) . '</script>';
}, 100);
```

### Pipeline de deploy seguro (lint PHP antes de mv)

```bash
TS=$(date +%Y%m%d-%H%M%S)
SLUG=<slug>
WP_PATH=<vhosts-base>/<dominio>/httpdocs
MU=<vhosts-base>/<dominio>/httpdocs/wp-content/mu-plugins/multiatlas-seo-<slug>.php

# 1. Backup defensivo del v anterior
ssh <server> "cp ${MU} ${MU}.bak.v<old>.${TS}"

# 2. SCP a staging /tmp (NO al destino)
scp clientes/<slug>/mu-plugins/multiatlas-seo-<slug>.php <server>:/tmp/multiatlas-seo-<slug>.php.v<new>

# 3. ⚠️ LINT PHP REAL antes del mv (CRÍTICO — evita romper la web)
ssh <server> "/opt/plesk/php/8.3/bin/php -l /tmp/multiatlas-seo-<slug>.php.v<new>"
# → "No syntax errors detected" antes de continuar

# 4. mv a destino + chown + chmod
ssh <server> "mv /tmp/multiatlas-seo-<slug>.php.v<new> ${MU} && chown <wp_owner>:psacln ${MU} && chmod 644 ${MU}"

# 5. Cache flush (WP + nginx proxy)
ssh <server> "/opt/plesk/php/8.3/bin/php /usr/local/bin/wp --allow-root --path=${WP_PATH} cache flush; find /var/cache/nginx/<dominio>_proxy/ -type f -delete 2>/dev/null"

# 6. Smoke test en producción (cache busting)
node /c/tmp/seo-extract.mjs "https://<dominio>/?_cb=$(date +%s)" "https://<dominio>/<path>/?_cb=$(date +%s)"

# 7. Si algo falla: rollback inmediato
# ssh <server> "cp ${MU}.bak.v<old>.${TS} ${MU}"
```

### Lo que el mu-plugin NO puede (lista para el admin / Elementor)

Importante alinear expectativas al cliente:

- **Añadir `<h1>` real al DOM** — requiere editor Elementor / theme. Mu-plugin solo cambia `<title>` (head), no headings (body).
- **Reordenar jerarquía de headings** (h2 → h3 dentro del flujo)
- **Reescribir contenido** dentro del cuerpo de la página
- **Fix bugs copy-paste Elementor** (H2 que dice "CARRIER" en página Mitsubishi por copy-paste sin revisar)
- **Internal linking en widgets Elementor** (los `<a href>` dentro de bloques Elementor)

Estos van a "Fase C — Lista Elementor para el admin" del documento entregable.

## Errores comunes a evitar

- ❌ NO instalar GA4 + GTM + Yoast tracking + plugin SEO simultáneamente (medición duplicada)
- ❌ NO usar 301 si vas a cambiar la redirección luego (los 301 los cachea Chrome → verificar SIEMPRE con `curl`, no con browser)
- ❌ NO publicar contenido SEO IA sin revisión humana (factual errors)
- ❌ NO meter keywords stuffing en títulos/descripciones
- ❌ NO bloquear /wp-admin/ con `noindex` directamente — usar robots.txt
- ❌ NO olvidar añadir el service account como Propietario de Search Console (sin esto, no hay automation futura)
- ❌ NO editar páginas marca una a una en Yoast cuando hay patología sistémica — usar el patrón mu-plugin
- ❌ NO subir mu-plugin a producción sin lint PHP previo (`php -l`) — un syntax error rompe TODA la web
- ❌ NO olvidar el `crossorigin` en preconnect cuando el recurso se solicita con CORS

## Referencias en el ecosistema MultiAtlas

- Lecciones aprendidas: `PROGRESO.md` línea 213+ ("WordPress .htaccess", "301 cacheadas en browser")
- Service account GSC: `PROGRESO.md` Bloque 5
- 7 propiedades GSC actuales: ver Bloque 5 PROGRESO.md
- Skills relacionadas: `seo-audit`, `programmatic-seo`, `copywriting`, `marketing-psychology`

## Trigger del skill

Esta skill se activa cuando se solicita SEO completo a un cliente. Sigue las 5 fases en orden, no saltar ninguna. La Fase 1 (auditoría) es obligatoria antes de Fase 2 (setup) para no romper config existente.
