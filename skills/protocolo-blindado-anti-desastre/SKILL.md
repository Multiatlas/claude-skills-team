---
name: protocolo-blindado-anti-desastre
description: CRÍTICO. Backup obligatorio a git ANTES de tocar una web de cliente (WordPress). Invocar SIEMPRE antes de actualizar plugins, WP core, base de datos o configuración. Nacida de un incidente real - un agente rompió una web en producción sin backup previo.
type: reference-skill
---

# 🛡️ Skill: Protocolo Blindado Anti-Desastre (WordPress)

> **Categoría:** SEGURIDAD CRÍTICA / LECTURA OBLIGATORIA
> **Severidad:** MÁXIMA — este protocolo es INNEGOCIABLE
> **Origen:** un incidente real (abril 2026) en el que un agente IA tocó una web de cliente en producción **sin backup previo**.

---

## 🚨 EL INCIDENTE QUE LO MOTIVÓ

Un agente IA ejecutó cambios en la web de un cliente **SIN HACER BACKUP PREVIO**. Resultado:
- Web completamente rota (sin diseño, sin imágenes, sin formularios).
- Cliente enfadado, **con publicidad activa apuntando a una web rota** (dinero quemándose).
- Pérdida económica directa + dependencia de que el hosting tuviera su propio backup para restaurar.

**Que no te pase. Esta skill lo previene.**

---

## 🏗️ Arquitectura de seguridad: dos redes

```
HOSTING (tu proveedor)
  └── Backups diarios automáticos ← RED #1 (la de ellos; no controlas el cuándo)

GIT (repo privado por cliente)
  └── Backup ANTES de cada cambio ← RED #2 (la tuya, bajo tu control)
      └── BD exportada (SIN la tabla de usuarios) + archivos críticos
      └── NUNCA subir wp-config.php ni credenciales
      └── Si algo se rompe → restaurar desde git en minutos
      └── No carga el servidor (se sube y se borra lo local)
```

**¿Por qué git y no solo el backup del hosting?** Te da un backup **externo** (si el servidor entero muere, no pierdes nada), **historial de versiones** (vuelves a cualquier punto), y **no carga el servidor**. El backup del hosting es la red #1; git es la #2 — defensa en profundidad.

---

## 🔒 REGLA #1: ANTES DE CUALQUIER CAMBIO → BACKUP A GIT

```
═══════════════════════════════════════════════════════
  N I N G Ú N   A G E N T E   T O C A   U N A   W E B
  D E   C L I E N T E   S I N   S U B I R   A N T E S
  E L   E S T A D O   A C T U A L   A   G I T
═══════════════════════════════════════════════════════
```

### Flujo obligatorio para CADA cambio:

```
1. EXPORTAR estado actual
   └── BD: wp db export → .sql   ·   Archivos: tar de wp-content/
2. SUBIR A GIT
   └── commit "Pre-cambio: [descripción]" + push al repo backup-DOMINIO
3. BORRAR temporales del servidor (no cargarlo)
4. HACER EL CAMBIO (actualizar plugin, BD, etc.)
5. VERIFICAR que la web funciona (curl HTTP 200 + revisión VISUAL en navegador)
6. SI FUNCIONA → push del nuevo estado ("Post-cambio OK: [descripción]")
7. SI FALLA → RESTAURAR desde git inmediatamente (clone → import → verificar)
```

---

## 🚫 REGLA #2: lo que NUNCA se hace sin push previo

| PROHIBIDO | POR QUÉ | EN SU LUGAR |
|---|---|---|
| Actualizar plugins sin push | Puede romper la web | Push → verificar versión PHP → actualizar |
| Actualizar el page-builder (Elementor, etc.) sin push | Borra metadatos de diseño | Push → verificar PHP → actualizar |
| `wp db query DELETE` | Pérdida irreversible | NUNCA sin push previo |
| Cambiar `wp_options` (URLs del sitio) | Puede romper el sitio entero | Push → cambiar → verificar |
| Desactivar/borrar plugins | Puede perder configuración | Push → desactivar → verificar |

---

## 🔒 REGLA #3: para agentes IA (Telegram u otros)

```
═══════════════════════════════════════════════════════
  SI UN AGENTE VA A TOCAR WORDPRESS DE UN CLIENTE:
  1. ¿Hay permiso explícito del responsable? Si no → NO se toca.
  2. Con permiso → se sube el estado actual a git PRIMERO.
  3. Tras el cambio → se verifica VISUALMENTE.
  4. Si funciona → push del nuevo estado.
  5. Si falla → restaurar desde git.
  Si NO puedes hacer backup → NO HAGAS EL CAMBIO.
═══════════════════════════════════════════════════════
```

Bloque listo para pegar en las instrucciones de tu bot:

```
REGLA ABSOLUTA: antes de CUALQUIER cambio en una web de cliente (plugins, BD,
configuración) DEBES: 1) exportar BD + archivos críticos, 2) subir ese snapshot a
git como backup, 3) verificar compatibilidad de versiones (PHP), 4) ejecutar el
cambio, 5) verificar que la web sigue funcionando, 6) si OK push del nuevo estado,
7) si falla restaurar desde el último push. Si no puedes hacer backup, NO toques nada.
```

---

## 🔐 Qué NUNCA se sube a git (aunque el repo sea privado)

```
- wp-config.php (contraseñas de BD)
- .env / .env.* (API keys)
- la tabla de usuarios del SQL (hashes de contraseñas)
- archivos de sesión o tokens
- claves SSH o certificados SSL
```

> Defensa en profundidad: si alguien accediera a la cuenta de git, no encontraría credenciales.

---

## 🗂️ Convención de repos

- Un repo **privado** por cliente: `backup-DOMINIO` (ej. `backup-midominio-com`).
- Al dar de alta un cliente nuevo, crear SIEMPRE su repo de backup.
- (Mantén tu propio inventario interno de qué dominio → qué repo; no lo publiques.)

---

## 🔧 Script: backup a git antes de un cambio (genérico)

> Adáptalo a tu infra: sustituye `<TU_ORG>`, la clave SSH y las rutas del hosting (este ejemplo asume un Plesk típico).

```bash
#!/bin/bash
# backup-to-git.sh <dominio> <usuario@servidor> <descripcion_cambio>
DOMINIO=$1; SERVIDOR=$2; MENSAJE=$3
SSH_KEY="$HOME/.ssh/id_deploy"           # tu clave de acceso al servidor
PHP="/opt/plesk/php/8.3/bin/php"          # ajusta a tu hosting
WP="/usr/local/bin/wp"
HTDOCS="/var/www/vhosts/$DOMINIO/httpdocs"
REPO_NAME="backup-$(echo $DOMINIO | tr '.' '-')"
TEMP="/tmp/backup-$DOMINIO"

echo "🔒 BACKUP PRE-CAMBIO: $DOMINIO ($MENSAJE)"

# 1. Exportar BD SIN la tabla de usuarios
ssh -i "$SSH_KEY" "$SERVIDOR" \
  "$PHP $WP db export /tmp/${DOMINIO}.sql --exclude_tables=wp_users --path=$HTDOCS --allow-root"

# 2. Descargar BD + archivos (SIN wp-config.php)
mkdir -p $TEMP
scp -i "$SSH_KEY" "$SERVIDOR:/tmp/${DOMINIO}.sql" $TEMP/database.sql
scp -r -i "$SSH_KEY" "$SERVIDOR:$HTDOCS/wp-content/themes/"  $TEMP/themes/
scp -r -i "$SSH_KEY" "$SERVIDOR:$HTDOCS/wp-content/plugins/" $TEMP/plugins/

# 3. Push a git con .gitignore de seguridad
cd $TEMP && git init -q
cat > .gitignore << 'EOF'
wp-config.php
.env
.env.*
*.key
*.pem
*.p12
node_modules/
*.log
wp-content/cache/
wp-content/upgrade/
EOF
git add -A
git commit -qm "Pre-cambio: $MENSAJE"
git remote add origin https://github.com/<TU_ORG>/$REPO_NAME.git
git push -u origin main --force

# 4. Limpiar servidor y local (no dejar rastro)
ssh -i "$SSH_KEY" "$SERVIDOR" "rm /tmp/${DOMINIO}.sql"
rm -rf $TEMP
echo "✅ Backup en git (sin credenciales). Ya puedes hacer el cambio."
```

---

## 📖 Lecciones (universales)

1. **Los backups diarios de Plesk NO incluyen las BD de los sitios** — solo `psa`, `roundcubemail`, etc. No te fíes.
2. **El backup del hosting es la red #1; git es la #2** — backup externo que no carga el servidor.
3. **Los page-builders (Elementor) guardan TODO en `wp_postmeta`** — si se borra, la web queda en texto plano.
4. **PHP CLI ≠ PHP-FPM** en muchos hostings (versiones distintas) — usa la ruta de PHP correcta para WP-CLI.
5. **Un agente IA sin protocolo de backup es un peligro** — este documento lo previene.

---

*Aporte de MultiAtlas a la comunidad SaaS Factory. Sanitizado, sin datos del equipo. OBLIGATORIO para cualquier agente que toque webs de clientes.*
