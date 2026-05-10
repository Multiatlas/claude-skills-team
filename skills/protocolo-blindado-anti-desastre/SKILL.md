---
name: protocolo-blindado-anti-desastre
description: CRÍTICO. Backup obligatorio a GitHub antes de TOCAR una web de cliente. Invocar SIEMPRE antes de actualizar plugins, WP core, BD o configuración. Origen: incidente cliente WordPress abril 2026.
type: reference-skill
---

# 🛡️ Skill: Protocolo Blindado Anti-Desastre WordPress

> **Versión:** 2.0 — 15 abril 2026
> **Categoría:** SEGURIDAD CRÍTICA / LECTURA OBLIGATORIA
> **Origen:** Incidente cliente WordPress — abril 2026
> **Severidad:** MÁXIMA — Este protocolo es INNEGOCIABLE

---

## 🚨 INCIDENTE QUE MOTIVÓ ESTE PROTOCOLO

El 15 de abril de 2026, un agente IA (Telegram) ejecutó cambios en la web de
un cliente (cliente-ejemplo.com) **SIN HACER BACKUP PREVIO**. El resultado:
- Web completamente rota (sin diseño, sin imágenes, sin formularios)
- Cliente enfadado con publicidad activa apuntando a una web rota
- Pérdida económica directa para MultiAtlas y el cliente
- Necesidad de pedir a Almacenaz restauración de backup

**ESTO NO PUEDE VOLVER A PASAR NUNCA MÁS.**

---

## 🏗️ ARQUITECTURA DE SEGURIDAD

```
ALMACENAZ (Hosting)
  └── Backups diarios automáticos ← RED DE SEGURIDAD #1 (la de ellos)

GITHUB (Repos privados por cliente)
  └── Backup antes de cada cambio ← RED DE SEGURIDAD #2 (la nuestra)
      └── BD exportada (sin tabla wp_users) + archivos críticos
      └── NUNCA subir wp-config.php ni credenciales
      └── Si algo se rompe → restaurar desde GitHub
      └── No carga los servidores (se sube y se borra local)
```

### ¿Por qué GitHub y no en el servidor?
- Almacenaz **ya tiene backups** en el servidor — no necesitamos duplicar
- GitHub nos da un **backup EXTERNO** — si el servidor entero muere, no perdemos nada
- Git nos da **historial de versiones** — podemos volver a cualquier punto
- **No carga el servidor** — subimos a GitHub y borramos del servidor

---

## 🔒 REGLA #1: ANTES DE CUALQUIER CAMBIO → BACKUP A GITHUB

```
═══════════════════════════════════════════════════════
  N I N G Ú N   A G E N T E   P U E D E   T O C A R
  U N A   W E B   D E   C L I E N T E   S I N   S U B I R
  E L   E S T A D O   A C T U A L   A   G I T H U B
═══════════════════════════════════════════════════════
```

### Flujo obligatorio para CADA cambio:

```
1. EXPORTAR estado actual del servidor
   └── BD: wp db export → archivo .sql
   └── Archivos: tar de wp-content/

2. SUBIR A GITHUB
   └── git push al repo backup-DOMINIO
   └── Commit message: "Pre-cambio: [descripción del cambio]"

3. BORRAR archivos temporales del servidor
   └── rm los .sql y .tar.gz locales (no cargar servidor)

4. HACER EL CAMBIO
   └── Actualizar plugin, modificar BD, etc.

5. VERIFICAR que la web funciona
   └── curl HTTP 200 + Browser Agent visual

6. SI FUNCIONA → Subir nuevo estado a GitHub
   └── Commit: "Post-cambio OK: [descripción]"

7. SI FALLA → RESTAURAR desde GitHub inmediatamente
   └── git clone → mysql import → verificar
```

---

## 🚫 REGLA #2: LO QUE NUNCA JAMÁS SE PUEDE HACER

| PROHIBIDO | POR QUÉ | QUÉ HACER EN SU LUGAR |
|-----------|---------|----------------------|
| Actualizar plugins sin push a GitHub | Puede romper la web | Push primero → Verificar PHP → Actualizar |
| Actualizar Elementor sin push a GitHub | Borra metadatos de diseño | Push primero → Verificar versión PHP → Actualizar |
| Ejecutar `wp db query DELETE` | Pérdida irreversible | NUNCA sin push a GitHub previo |
| Cambiar `wp_options` del sitio | Puede romper URLs | Push primero → Cambiar → Verificar |
| Desactivar/borrar plugins | Puede perder configuración | Push primero → Desactivar → Verificar |

---

## 🔒 REGLA #3: PARA AGENTES DE TELEGRAM / OTROS AGENTES IA

```
═══════════════════════════════════════════════════════
  S I   O T R O   A G E N T E   P I D E   H A C E R
  C A M B I O S   E N   W O R D P R E S S :

  1. EL AGENTE DEBE PREGUNTAR: "¿Rubén ha dado permiso?"
  2. SIN PERMISO EXPLÍCITO → NO SE TOCA NADA
  3. CON PERMISO → SE SUBE ESTADO ACTUAL A GITHUB PRIMERO
  4. DESPUÉS DEL CAMBIO → SE VERIFICA VISUALMENTE
  5. SI FUNCIONA → Push del nuevo estado a GitHub
  6. SI FALLA → Restaurar desde GitHub
═══════════════════════════════════════════════════════
```

### Mensaje para incluir en las instrucciones del bot de Telegram:

```
REGLA ABSOLUTA: Antes de hacer CUALQUIER cambio en una web de cliente 
(actualizar plugins, modificar BD, cambiar configuración), DEBES:

1. Exportar la BD y archivos críticos del sitio
2. Subir ese snapshot a GitHub como backup
3. Verificar compatibilidad de las versiones
4. Solo entonces ejecutar el cambio
5. Verificar que la web sigue funcionando después
6. Si funciona → push del nuevo estado a GitHub
7. Si falla → restaurar desde el último push de GitHub

Si NO puedes hacer backup → NO HAGAS EL CAMBIO.

NUNCA actualices Elementor, WordPress core, o plugins críticos 
sin verificar primero que la versión de PHP del servidor es compatible.
```

---

## 🔐 SEGURIDAD: QUÉ NUNCA SE SUBE A GITHUB

```
═══════════════════════════════════════════════════════
  N U N C A   S U B I R   A   G I T H U B :
  - wp-config.php (tiene contraseñas de BD)
  - .env, .env.local (tienen API keys)
  - Tabla wp_users del SQL (tiene hashes de contraseñas)
  - Archivos de sesión o tokens
  - Claves SSH o certificados SSL
═══════════════════════════════════════════════════════
```

> Aunque los repos son PRIVADOS, aplicamos defensa en profundidad.
> Si alguien accediera a la cuenta de GitHub, no encontraría credenciales.

---

## 📦 REPOS GITHUB DE BACKUP (recomendación de organización)

Mantén un repo PRIVADO de backup por cada web/cliente que toques en producción. Patrón sugerido de nombre:

```
github.com/<tu-org>/backup-<dominio-sin-tld>
```

Ejemplo: para `cliente-ejemplo.com` → repo `backup-cliente-ejemplo-com`.

Al dar de alta un nuevo proyecto/cliente, crear su repo `backup-<dominio>` antes del primer cambio. Mantén un índice interno (en tu propio sistema, no público) con dominio + servidor + repo asociado.

> **REGLA:** Backup en GitHub ANTES de tocar producción. Sin excepciones.

---

## 🔧 SCRIPT: Backup a GitHub antes de un cambio

Ejecutar desde S3 (VPS relay) antes de tocar cualquier web:

```bash
#!/bin/bash
# backup-to-github.sh <dominio> <servidor_ip> <descripcion_cambio>
# Ejemplo: bash backup-to-github.sh cliente-ejemplo.com <IP_VPS> "actualizar elementor"

DOMINIO=$1
SERVIDOR=$2
MENSAJE=$3
PHP="/opt/plesk/php/8.3/bin/php"
WP="/usr/local/bin/wp"
HTDOCS="/var/www/vhosts/$DOMINIO/httpdocs"
REPO_NAME="backup-$(echo $DOMINIO | tr '.' '-')"
TEMP="/tmp/backup-$DOMINIO"

echo "🔒 BACKUP PRE-CAMBIO: $DOMINIO"
echo "Motivo: $MENSAJE"

# 1. Exportar BD (SIN tabla wp_users por seguridad)
ssh -i /root/.ssh/id_agente_plesk root@$SERVIDOR \
  "$PHP $WP db export /tmp/${DOMINIO}_backup.sql --exclude_tables=wp_users --path=$HTDOCS --allow-root"

# 2. Descargar BD + archivos al VPS relay (SIN wp-config.php)
mkdir -p $TEMP
scp -i /root/.ssh/id_agente_plesk root@$SERVIDOR:/tmp/${DOMINIO}_backup.sql $TEMP/database.sql
scp -r -i /root/.ssh/id_agente_plesk root@$SERVIDOR:$HTDOCS/wp-content/themes/ $TEMP/themes/
scp -r -i /root/.ssh/id_agente_plesk root@$SERVIDOR:$HTDOCS/wp-content/plugins/ $TEMP/plugins/
# ⚠️ NO copiar wp-config.php — tiene credenciales de BD

# 3. Push a GitHub con .gitignore de seguridad
cd $TEMP
git init
cat > .gitignore << 'EOF'
# SEGURIDAD: Nunca subir credenciales
wp-config.php
.env
.env.*
*.key
*.pem
*.p12
# Archivos pesados innecesarios
node_modules/
*.log
wp-content/cache/
wp-content/upgrade/
wp-content/ai1wm-backups/
EOF
git add -A
git commit -m "Pre-cambio: $MENSAJE — $(date +%Y-%m-%d\ %H:%M)"
git remote add origin https://github.com/Multiatlas/$REPO_NAME.git
git push -u origin main --force

# 4. Limpiar servidor y VPS (no dejar nada)
ssh -i /root/.ssh/id_agente_plesk root@$SERVIDOR "rm /tmp/${DOMINIO}_backup.sql"
rm -rf $TEMP

echo "✅ BACKUP SUBIDO A GITHUB (sin credenciales) — Puedes hacer los cambios"
echo "Repo: https://github.com/Multiatlas/$REPO_NAME"
```

---

## 📖 LECCIONES DEL INCIDENTE 15-ABR-2026

1. **Los dumps diarios de Plesk NO incluyen las BDs de clientes** — solo `psa`, `roundcubemail`, etc.
2. **Almacenaz SÍ tiene backups diarios propios** — son nuestra red de seguridad #1
3. **GitHub es nuestra red de seguridad #2** — backup externo que no carga el servidor
4. **Elementor almacena TODO en `wp_postmeta`** — si se borra, la web queda en texto plano
5. **PHP CLI (7.2) ≠ PHP-FPM (8.3)** en Plesk — SIEMPRE usar `/opt/plesk/php/8.3/bin/php`
6. **Un agente IA sin protocolo de backup es un peligro** — este documento lo previene

---

*Skill creado: 15 abril 2026 — Incidente cliente-ejemplo.com*
*Versión 2.0: Backups en GitHub, no en servidor*
*OBLIGATORIO para TODOS los agentes que toquen webs de clientes.*
