---
name: deploy-quirurgico-next-vps
description: >-
  Desplegar un cambio CONTENIDO EN UNA API ROUTE de Next.js (output "standalone")
  + PM2 en tu propio VPS SIN re-subir el build entero (~90 MB) y sin Vercel. Build
  local, parsear el `.nft.json` de la route y md5-comparar TODOS sus invariantes
  (webpack-runtime + chunks compartidos + client-reference-manifest) contra
  producción; si son idénticos, subir por scp solo el `route.js` (+ su manifest si
  cambió), swap atómico con backup y `pm2 restart` pasando el FICHERO ecosystem.
  Invocar al actualizar una API route en una app Next.js self-hosted, cuando
  "subir un cambio tarda o sube demasiado", o para salir de Vercel sin perder
  agilidad de deploy.
---

# Skill: Deploy quirúrgico de API routes Next.js en VPS propio (sin Vercel)

> **El dolor:** cambias una línea de una API route y, para verla en producción, tu
> pipeline vuelve a subir **los ~90 MB del build entero** por una tubería lenta.
> Si estás en Vercel, el marrón es otro: la factura crece con el tráfico y **tu
> infra no es tuya** (vendor lock-in).
>
> Esta skill enseña a subir **solo el artefacto que cambió** (KB, no MB) en una app
> Next.js `output: "standalone"` + PM2 en tu propio servidor: **control total,
> coste fijo, cero lock-in**. Tu código, tu servidor, tus reglas.

> ⚠️ **Alcance honesto.** El atajo aplica cuando el cambio queda **contenido en una
> única API route** (el caso frecuente: tocas la lógica de un endpoint). Para
> cambios en **páginas, componentes o chunks compartidos**, el atajo NO sirve y hay
> que hacer **deploy completo** (sección final). No te engaño: el 90 % de esta guía
> es el caso de la API route, que es donde más se sufre y más se gana.

---

## Cómo es un `route.js` por dentro (la base del atajo)

Cuando Next compila `app/<ruta>/route.ts` con `output: "standalone"`, genera
`.next/server/app/<ruta>/route.js`. Ese fichero **inlinea el código de TU ruta**,
pero **NO es autocontenido**: al final hace algo como

```js
var b=require("../../../webpack-runtime.js");
b.C(a); var c=b.X(0,[331,692],()=>b(b.s=57833));
```

es decir, **depende de `webpack-runtime.js` y carga PEREZOSAMENTE los chunks
compartidos por id** (`[331,692]` → `chunks/331.js`, `chunks/692.js`) desde disco
en runtime. Además tiene un hermano obligatorio: **`route_client-reference-manifest.js`**.

👉 Conclusión: el atajo "subo solo `route.js`" es seguro **solo si los invariantes
externos (runtime + esos chunks + el manifest) son idénticos** en local y en prod.
Si difieren, el server queda desincronizado. Por eso el paso del `md5` es innegociable.

---

## Prerrequisitos

- App Next.js con `output: "standalone"` en `next.config.ts`.
- VPS propio con **PM2** + un servidor web delante (Nginx, Caddy, LiteSpeed…).
- Acceso **SSH** al servidor.
- ⚠️ **Primer deploy completo**: `next build` **no copia** `.next/static` ni `public`
  dentro de `.next/standalone/` — hay que copiarlos a mano la primera vez. Tras eso,
  el layout de `.next/standalone/` (local) replica el de la carpeta de la app en prod.

Convenciones (sustituye por los tuyos): `<dominio>` = carpeta de la app
(`/home/<dominio>/app`), `usuario@tu-vps` = tu SSH, `<app>` = nombre del proceso PM2,
`<ruta>` = ruta de la API route.

---

## Procedimiento

### 1. Build local + que compile

```bash
npm run build     # genera .next/standalone/
```

> **`git push` ≠ desplegado.** Si no compila en local, no va a desplegar bien.

### 2. Comparar TODOS los invariantes con `md5` (local vs producción)

No basta con `webpack-runtime.js`: hay que comparar **todo lo que la route referencia**
(runtime + chunks compartidos + el `client-reference-manifest`). El propio
`route.js.nft.json` los lista, pero **con rutas relativas al directorio de la route**
(`../../../chunks/331.js`, `../../../webpack-runtime.js`). Por eso hay que resolverlas
**desde el dir de la route** en ambos lados — si no, en prod fallan en silencio y crees
que todo coincide cuando no has comparado nada:

```bash
RUTA="app/<ruta>"                                   # relativo a .next/server
LOCAL=".next/standalone/.next/server/$RUTA"
PROD="/home/<dominio>/app/.next/server/$RUTA"

# Invariantes que pueden invalidar el atajo, tal y como los nombra el nft.json
INV=$( { jq -r '.files[]' "$LOCAL/route.js.nft.json" \
           | grep -E 'webpack-runtime\.js$|chunks/[^/]+\.js$'; \
         echo route_client-reference-manifest.js; } | sort -u )

# Hash LOCAL desde el dir de la route (donde los ../ del nft resuelven de verdad)
( cd "$LOCAL" && for f in $INV; do [ -f "$f" ] && md5sum "$f"; done ) | sort > /tmp/inv-local.txt

# Hash PROD con los MISMOS paths relativos
ssh usuario@tu-vps "cd '$PROD' && for f in $INV; do [ -f \"\$f\" ] && md5sum \"\$f\"; done" | sort > /tmp/inv-prod.txt

# Veredicto explícito (nada de "parece que coincide")
diff /tmp/inv-local.txt /tmp/inv-prod.txt && echo "✓ invariantes idénticos -> atajo seguro" \
                                          || echo "✗ difieren -> ve a Deploy completo"
```

- **`diff` vacío (✓)** → el cambio quedó contenido en `route.js` (+ su manifest si
  cambió). El atajo es seguro. Continúa.
- **`diff` con diferencias (✗)** → runtime/chunk/manifest cambió → **NO uses el atajo**:
  ve a *Deploy completo* abajo.

> ⚠️ **Comprueba que el `diff` listó filas de verdad** (no 0 ficheros): si `INV` sale
> vacío o los paths no resuelven, el `diff` da "✓" engañoso sin haber comparado nada.
> Debes ver tantas líneas como invariantes (runtime + N chunks + manifest).

### 3. Prueba el `route.js` en LOCAL antes de subir  ⚠️ el paso que la gente se salta

Algunos paquetes grandes (p. ej. SDKs de cloud) se empaquetan **dentro** del
`route.js` y su bundling es **no determinista**: un build sale bien y el siguiente
sale roto **con el mismo código fuente**. Síntoma: la ruta da **500 al inicializar
el módulo** → **todas** las peticiones fallan. El `md5` de chunks **no detecta esto**.

Arranca el server standalone y golpea la ruta:

```bash
# next build NO copia static/public al standalone: cópialos para probar de verdad
cp -r .next/static .next/standalone/.next/static
cp -r public .next/standalone/public 2>/dev/null

PORT=3001 HOSTNAME=127.0.0.1 node .next/standalone/server.js &
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://127.0.0.1:3001/<endpoint>   # debe ser 200, no 500
```

### 4. Swap atómico con backup

```bash
# Sube route.js (+ su client-reference-manifest si cambió en el paso 2)
scp ".next/standalone/.next/server/app/<ruta>/route.js" usuario@tu-vps:/tmp/route.js.new

ssh usuario@tu-vps '
  cd /home/<dominio>/app/.next/server/app/<ruta> &&
  cp route.js "route.js.bak-$(date +%Y%m%d-%H%M%S)" &&   # backup OBLIGATORIO antes del swap
  mv /tmp/route.js.new route.js
'
```

### 5. Reiniciar PM2 — pasa el FICHERO, no el nombre

```bash
ssh usuario@tu-vps 'cd /home/<dominio> && pm2 restart ecosystem.config.js --only <app>'
```

> ⚠️ **Lo clave es pasar el FICHERO `ecosystem.config.js`.** `pm2 restart <nombre>`
> (por nombre) **NO relee** el ecosystem: usa el dump guardado en memoria, así que
> **no carga variables de entorno nuevas**. Si cambiaste env, reinicia pasando el
> fichero. (`--update-env` solo refresca el env del shell actual; no sustituye a
> pasar el fichero.)

---

## Verificación (3 puertas antes de decir "desplegado")

1. **Build local SUCCESS** (paso 1).
2. **Proceso sano:** `pm2 list` → `<app>` **online**, uptime reseteado, sin reinicios
   en bucle; `pm2 logs <app> --err` limpio.
3. **El cambio se VE en producción** — el valor concreto, no "responde 200":
   ```bash
   ssh usuario@tu-vps 'grep -c "<string único del cambio>" /home/<dominio>/app/.next/server/app/<ruta>/route.js'
   curl -s https://<dominio>/<endpoint> | grep -c "<marcador>"
   ```

---

## Rollback inmediato (ante un 500 tras el deploy)

```bash
ssh usuario@tu-vps '
  cd /home/<dominio>/app/.next/server/app/<ruta> &&
  cp "$(ls -1 route.js.bak-* | sort -r | head -1)" route.js &&   # sort por NOMBRE, no por mtime
  cd /home/<dominio> && pm2 restart ecosystem.config.js --only <app>
'
```

> Usa `ls -1 ... | sort -r`, **no `ls -t`**: `ls -t` ordena por fecha de
> modificación, y tras un rollback el `mtime` puede no coincidir con el sufijo de
> fecha del nombre → restaurarías la copia equivocada.

---

## Deploy completo (cuando el atajo NO aplica)

Si en el paso 2 difieren runtime/chunks/manifest, o tocaste páginas/componentes:
sincroniza el build de forma **consistente** (no mezcles versiones):

```bash
# sube .next/server y .next/static juntos y coherentes (rsync ahorra lo no cambiado)
rsync -az --delete .next/standalone/.next/server/ usuario@tu-vps:/home/<dominio>/app/.next/server/
rsync -az --delete .next/static/               usuario@tu-vps:/home/<dominio>/app/.next/static/
ssh usuario@tu-vps 'cd /home/<dominio> && pm2 restart ecosystem.config.js --only <app>'
```

---

## Trampas que esta skill te ahorra

- **Bundle no determinista con SDKs grandes** → pruébalo en local (paso 3); o, si
  solo cambian **strings**, parchéalos sobre el `route.js` que **ya funciona** en
  prod (con un `re.subn`) en vez de rebuildear; o externaliza el paquete con
  `serverExternalPackages: ['<paquete>']` en `next.config.ts` (se carga de
  `node_modules` en runtime, estable, y no se bundlea).
- **Backups dentro del árbol del proyecto** rompen el siguiente build → guarda los
  `.bak` **fuera** de la app (los `route.js.bak-*` valen porque no son módulos
  importables, pero **rótalos**: `ls -1t route.js.bak-* | tail -n +6 | xargs -r rm`).
- **Carpeta del proyecto sincronizada en la nube** (OneDrive/Drive) → `rm -rf .next`
  puede fallar con "Device or resource busy" mientras sincroniza; pausa la sync.

---

## Por qué (la filosofía)

Re-subir el build entero en cada cambio es lento, caro y propenso a desincronizar
server↔chunks. Comparar **todos** los invariantes con `md5` te **garantiza** que el
cambio quedó contenido, y el swap atómico con backup hace el deploy **reversible en
segundos**. Sin Vercel, sin lock-in, sin sorpresas en la factura.

---

> Aporte de **MultiAtlas** a la comunidad SaaS Factory. Sanitizada: todos los hosts,
> rutas, dominios y nombres son placeholders genéricos — sustituye por los tuyos.
> Verificada contra builds standalone reales de Next.js. Úsala, abre un issue o
> mándanos feedback. Licencia: ver `LICENSE` del repo.
