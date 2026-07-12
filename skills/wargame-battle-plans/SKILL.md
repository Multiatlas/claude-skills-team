---
name: wargame-battle-plans
description: Convierte una misión técnica arriesgada (deploy, migración, envío masivo, operación destructiva) en un battle-plan ejecutable a ciegas — acción, observación esperada, fallo probable, contramaniobra, triggers de bifurcación y condiciones de aborto. Genera el plan con el mejor modelo disponible (redactor), lo somete a red-team adversarial y lo repara, para que después lo ejecute un modelo más barato con ese criterio ya embotellado. Invocar antes de cualquier misión donde el "camino feliz" no basta y un fallo silencioso cuesta caro.
type: protocol-skill
---

# Skill: War-games — battle-plans ejecutables a ciegas

> **Usa Sonnet u Opus con el criterio del mejor modelo (Fable 5) sin pagar el modelo top.**
>
> Destilas el juicio del modelo más caro y capaz que tengas hoy en un documento estático — un *battle-plan* — y dejas que un modelo más barato lo ejecute con ese criterio ya pre-cocinado. Un plan normal asume el camino feliz. Un war-game lucha la misión sobre el papel, movimiento a movimiento, anticipando cada fallo probable, sus señales y su contramaniobra. Patrón probado en producción.

---

## ¿Cuándo usar este patrón?

- Antes de una **misión técnica con riesgo real**: un deploy a producción, una migración de datos, un envío masivo de emails a clientes, una operación destructiva (borrar, `force-push`, tocar DNS o una BD viva).
- Cuando el coste de un **fallo silencioso** es alto: un email que llega a quien no debía, un cron que vacía el crontab del servidor, un doble envío, una tabla pisada.
- Cuando quieres que **el ejecutor sea otro agente** (más barato, o en otra sesión, o dentro de un mes) y no tendrá tu contexto actual.
- Cuando la realidad puede **cambiar entre que se planifica y se ejecuta** (estados de ramas, servicios vivos, decisiones pendientes de un humano).

**NO usar para**:
- Tareas triviales o reversibles de un solo paso. Es sobre-ingeniería.
- Cosas que vas a ejecutar tú mismo, ahora, con todo el contexto en la cabeza. El war-game vale precisamente porque separa quien piensa de quien ejecuta.

---

## Por qué este patrón existe

1. **El modelo top es caro y a veces efímero.** El mejor modelo disponible en cualquier momento (hoy puede ser Fable 5; mañana, otro) tiene un criterio que los modelos baratos no replican por sí solos: anticipa fallos, lee señales, sabe cuándo abortar. Ese criterio se puede **embotellar una vez** y reutilizar muchas.
2. **Un plan del camino feliz miente.** "Haz A, luego B, luego C" no dice qué haces cuando B devuelve un 403, o cuando C ya se ejecutó ayer sin que lo sepas. El war-game convierte cada paso en una bifurcación con salida.
3. **El ejecutor no tiene tu contexto.** El agente que corre la misión dentro de dos semanas no vio esta conversación. Si algo no está escrito en el battle-plan o enlazado por ruta, para él no existe.
4. **Model-agnostic y future-proof.** Cuando salga un modelo mejor, no reescribes tus runbooks: **re-generas** los war-games con él y el criterio embotellado sube de nivel solo.

---

## El principio central: un war-game NO es un plan

| | Plan normal | War-game |
|---|---|---|
| Supuesto | Camino feliz, lineal | Cada movimiento puede fallar |
| Contenido | Acción → acción → acción | Acción → **observación esperada** → **fallo probable** → **contramaniobra** |
| Bifurcaciones | Implícitas ("si algo va mal, mira el error") | **Triggers explícitos**: "si observas X → ruta A; si Y → ruta B" |
| Fin | "debería funcionar" | **Pasadas de verificación medibles** + **condiciones de aborto** |
| Ejecución | Quien lo escribió | **Otro agente**, sin el contexto original |
| Frescura | Se asume vigente | **Foto fechada** que arranca re-verificando la realidad (RECON) |

Tres reglas que definen el método:

- **No es un plan.** Lucha la misión movimiento a movimiento: acción → observación esperada → fallo más probable (causa + señales) → contramaniobra → triggers de bifurcación → condiciones de aborto.
- **No duplica documentación.** El war-game **enlaza** a los PRDs, READMEs, fichas y notas que ya existen; solo aporta la capa dinámica que esos documentos no tienen.
- **No se ejecuta al redactarse.** Se escribe en papel. Lo ejecuta después otro modelo/agente, con un humano en el bucle allí donde el war-game lo exija.

---

## El estándar de los 8 puntos

Un battle-plan solo está TERMINADO si cumple los 8. El red-team (ver más abajo) los verifica uno por uno, intentando romperlo.

1. **Observaciones esperadas.** Cada movimiento declara QUÉ VERÁS si funcionó y QUÉ VERÁS si no: comando + salida esperada, pantalla esperada, estado esperado. Sin observación esperada, un ejecutor barato no sabe si va bien.

2. **Contramaniobras.** Cada movimiento lleva su fallo MÁS PROBABLE con su causa, sus señales observables y la contramaniobra concreta — no "revisar el error", sino los pasos exactos.

3. **Triggers de bifurcación.** Cada fork del camino tiene un trigger explícito: "si observas X → ruta A; si observas Y → ruta B". El ejecutor nunca decide a ojo.

4. **Flags de recon + VARIABLES marcadas.** El war-game abre con una fase de RECONOCIMIENTO (qué re-verificar en runtime antes del primer movimiento). Todo supuesto que el redactor NO pudo resolver queda marcado como `(VARIABLE: descripción)` y volcado a un LEDGER. Nada inventado, nada asumido en silencio.

5. **Condiciones de aborto.** Lista explícita de situaciones en las que el ejecutor DEBE parar y escalar al humano-en-el-bucle (pérdida de acceso, datos en riesgo, coste inesperado, supuesto crítico roto) — **con el estado en que debe dejar las cosas** al abortar (rollback / como estaba).

6. **Pasadas de verificación.** Al final, la batería de comprobaciones del resultado completo: smoke tests, comandos, URLs, criterios de aceptación medibles. No "debería funcionar".

7. **Red-team pass.** Un agente DISTINTO del redactor ha intentado romper el war-game contra estos 8 puntos y sus hallazgos están incorporados. La autoevaluación no cuenta.

8. **Ejecutabilidad a ciegas.** Un modelo SIN acceso a la conversación original ni contexto previo puede ejecutar el war-game: rutas completas, comandos completos, referencias a documentos por ruta, credenciales señaladas por su UBICACIÓN (gestor de secretos / `.env` — **jamás el valor**), y el ejecutor objetivo declarado en la cabecera.

---

## El workflow generador: redactor → red-team → reparador

El battle-plan de calidad no sale de una sola pasada. Es un pipeline de 3 etapas, idealmente lanzado como workflow multi-agente:

```
   ┌─────────────┐      ┌──────────────────┐      ┌──────────────┐
   │  REDACTOR   │  →   │    RED-TEAM      │  →   │  REPARADOR   │
   │ mejor modelo│      │ agente DISTINTO  │      │ aplica los   │
   │ disponible  │      │ intenta romperlo │      │ hallazgos    │
   │ (p.ej. Fable│      │ contra los 8     │      │ al plan      │
   │  5)         │      │ puntos           │      │              │
   └─────────────┘      └──────────────────┘      └──────────────┘
```

- **REDACTOR** — el mejor modelo que tengas. Lee el brief y los documentos de referencia, y produce el battle-plan luchando la misión sobre el papel. Marca como `(VARIABLE: …)` todo lo que no puede resolver.
- **RED-TEAM** — un agente **distinto** (no el redactor: la autoevaluación no cuenta). Su única misión es romper el plan: buscar movimientos sin observación esperada, contramaniobras vagas, bifurcaciones implícitas, supuestos no verificados, comandos que asumen contexto. Devuelve una lista de hallazgos.
- **REPARADOR** — aplica los hallazgos del red-team al battle-plan. El resultado es el documento final, firmado con quién redactó, quién hizo red-team y qué hallazgos se incorporaron.

**El LEDGER de variables.** Todas las `(VARIABLE: …)` sin resolver se consolidan en una tabla, para que el humano las resuelva ANTES de que el ejecutor llegue a los movimientos que las necesitan:

| ID | Variable | Bloquea | Default propuesto | Resuelve |
|---|---|---|---|---|
| V1 | Censo definitivo de destinatarios | Mov. 3, 10 | Solo el cliente ya validado | `[humano]` |
| V2 | Día del cron (1 vs 3 del mes) | Mov. 9 | Día 1 | `[humano]` |
| V3 | Umbral de métricas mínimas | Mov. 4 | Sin umbral | `[humano]` |

- `[recon]` = se resuelve en runtime, durante la fase de RECON (no necesita a nadie).
- `[humano]` = decisión de negocio o de riesgo que **solo un humano** puede tomar.

---

## La plantilla del battle-plan (las 8 secciones)

Todo battle-plan sigue esta estructura. Escríbelo en un fichero por misión (`wargames/<Mxx>-<slug>.md`).

1. **Cabecera** — tabla con: fecha de redacción (es una foto fechada), misión (1 párrafo denso), ejecutor objetivo, tiempo estimado, regla de oro de la misión, y **documentos de referencia por ruta** (leer ANTES de ejecutar). Si el recon del redactor descubre algo que contradice el brief, un bloque "hallazgo del reconocimiento".

2. **Fase RECON** — qué re-verificar en runtime ANTES del primer movimiento. Cada check `R1, R2, …` con: comando concreto → qué esperar → trigger si no cuadra. **Ningún check de recon modifica nada** (solo lectura). La realidad de hoy puede no ser la del día de ejecución.

3. **Movimientos numerados** — el cuerpo. Cada `Mov. N` con:
   - **Acción** (comandos/pasos literales)
   - **Observación esperada** (si funcionó / si no)
   - **Fallo más probable** (causa + señales observables)
   - **Contramaniobra** (pasos concretos)
   - 🔀 **Triggers** de bifurcación donde el camino se abre.

4. **Triggers de bifurcación** — integrados en los movimientos (marcados 🔀). Nunca "usa tu criterio": siempre "si X → A; si Y → B".

5. **VARIABLES** — supuestos irresolubles marcados `(VARIABLE V#: …)` en el texto Y volcados al LEDGER.

6. **Condiciones de aborto** — tabla: situación → señales → **estado en que dejar las cosas**. Con una regla transversal de qué hacer siempre al abortar (dejar en modo seguro, log intacto, nota fechada).

7. **Pasadas de verificación** — batería numerada y medible que se corre al final (y de nuevo tras el primer ciclo real).

8. **Firma** — quién redactó (y con qué modelo), quién hizo el red-team, qué hallazgos se incorporaron.

### Reglas de seguridad del método (no negociables)

- **Idioma consistente.** El battle-plan en el idioma del equipo; comandos y rutas literales.
- **Jamás valores de secretos.** Solo su UBICACIÓN (gestor de secretos, ruta de un fichero `600`, variable de entorno). Nunca el valor en claro.
- **Operaciones destructivas** (BD, DNS, borrados, `force-push`): SIEMPRE detrás de tres cosas — (a) una condición de **"ventana con el responsable"** (un humano presente y avisado), (b) **backup previo verificado**, (c) **plan de rollback como primer movimiento** de la rama destructiva.
- **Cabecera con fecha + ejecutor objetivo + tiempo estimado.** Un war-game caduca; la fecha y el RECON lo protegen.

---

## Ejemplo completo (anonimizado): informe mensual automático a clientes por email

> Misión genérica reutilizable: cada día 1 del mes, un cron en `<servidor>` genera un informe HTML de marca con las métricas del mes de cada cliente (analítica web + rendimiento en buscadores) y lo envía por email. Con censo de clientes, idempotencia (jamás doble envío), reintentos, un mes de *preview* obligatorio (todo al equipo, cero a clientes) y verificación con clientes control.

Este ejemplo muestra la anatomía real de un battle-plan. Adáptalo a tu stack.

### Cabecera

| Campo | Valor |
|---|---|
| **Fecha de redacción** | (foto fechada — re-verificar TODO en RECON) |
| **Misión** | Industrializar el informe mensual por email a cada cliente: métricas de analítica (usuarios, sesiones, conversiones) + buscadores (clics, impresiones, posición, consultas top) + disponibilidad de la web, en HTML de marca, vía cron el día 1 de cada mes. Con censo, idempotencia, reintentos, mes de preview y verificación con 3 clientes control. |
| **Ejecutor objetivo** | Un modelo más barato que el redactor (p. ej. Sonnet/Opus), en otra sesión, sin este contexto. |
| **Tiempo estimado** | Build + deploy + simulacro: 4-6 h. Ciclo hasta el primer envío real: ~2 meses (mes de preview antes de activar). |
| **Regla de oro** | En NINGÚN movimiento anterior a la activación real (Mov. 11) puede salir un email a un buzón de cliente. Todo envío previo va SOLO a buzones del equipo (allowlist dura). |

**Documentos de referencia** (por ruta): el molde de un notifier/allowlist ya probado, el script piloto mono-cliente si existe, la config de secretos, la doc del CRM de clientes.

### Fase RECON (solo lectura — cada check con su trigger)

- **R1 — ¿Existe ya un piloto?** `git log --oneline -5 -- scripts/informe-mensual/`. Esperado: aparece el script base. **Trigger**: si no existe, buscar antes de asumir (`git log --all | grep -i informe`); si sigue sin aparecer → construir desde el molde notifier, pero **parar y preguntar** (aborto A6): un piloto validado no desaparece solo.
- **R2 — Estado en el servidor.** `ssh <servidor> 'ls -la <ruta>/informe-mensual/ ; crontab -l | grep informe'`. Trigger A: carpeta + cron → adoptar y extender. Trigger B: carpeta sin cron → el cron se instala en Mov. 9. Trigger C: no existe → el deploy de Mov. 8 la crea (sin backup previo, no hay nada que pisar).
- **R3 — Secretos presentes** (solo existencia y permisos, JAMÁS el contenido). `ssh <servidor> 'ls -l <ruta-secretos>/'`. Esperado: los ficheros existen, permisos `600`, owner correcto. Si falta el secreto SMTP → buscarlo en el gestor de secretos; su instalación la hace un humano por el protocolo de rotación (scp directo, sin pasar por el chat). NO continuar a movimientos de envío sin él.
- **R4 — La lectura de datos sigue viva** (smoke de solo lectura, sin envío). Ejecutar el script en modo `--dry` sobre un cliente conocido. Esperado: `HTML generado` + cifras > 0. **Fallo probable**: `403 PERMISSION_DENIED` → la service account perdió acceso; contramaniobra: re-grant. Si `invalid_grant` → key rotada: escalar (aborto A2). ⚠️ Ojo con las variables de entorno obligatorias: sin la variable que apunta a la key, el default del script puede ser una ruta de otro sistema operativo y dar `FileNotFoundError` — eso NO es problema de permisos.
- **R5 — CRM de clientes accesible** (para el censo). GET de solo lectura. Anota qué columnas hay: interesa si existe un campo de email de contacto. **Trigger**: si no hay columna de email → la fuente de emails es la allowlist + fichas + el humano (VARIABLE V1). NUNCA inventar un email.
- **R6 — Dependencias en el servidor** (runtime + CLI que usen las verificaciones). Comprobar imports y binarios. Contramaniobra si falta: usar el venv correcto y ajustar el wrapper.
- **R7 — Entregabilidad DNS vigente** (SPF/DKIM del dominio remitente). `nslookup -type=TXT <dominio>`. **Trigger**: si el SPF no incluye el servidor de correo → NO activar ningún envío (ni preview): llegarían como sospechosos. Escalar (es cambio DNS, fuera del alcance). El build puede continuar.

### Movimientos (extracto — cada uno con la estructura completa)

**Mov. 1 — Base operativa desde el molde.** Copiar el molde notifier (allowlist + preview por defecto + doble flag para envío real). *Observación esperada*: carpeta con los ficheros; `git status` los muestra nuevos. *Fallo probable*: duda de "¿dónde vive el código?". *Contramaniobra (decisión cerrada aquí)*: el operativo vive en el repo operativo; cualquier copia en otro repo queda como molde genérico. No dos fuentes de verdad.

**Mov. 2 — Censo de clientes elegibles (propuesta, NO decisión).** Cruzar 4 fuentes de solo lectura (CRM, propiedades accesibles por la service account, mapping de analítica, allowlist de emails). Regla de elegibilidad cerrada: con datos accesibles = elegible; sin ninguna fuente = NO elegible (se lista aparte). Email sin fuente verificable = fila marcada `⚠️ SIN EMAIL VERIFICADO`. **Entregar el censo al responsable y PARAR** el alta de clientes hasta su OK. `(VARIABLE V1: censo definitivo + emails por cliente — decisión del humano)`. *Fallo probable*: tentación de rellenar emails "obvios" (`info@dominio`) sin verificar. *Contramaniobra*: prohibido. Sin entrada verificada en la allowlist → no se envía. 🔀 *Trigger*: mientras V1 no esté resuelta, los Mov. 3-9 (build, deploy, simulacro con clientes control) pueden ejecutarse igual; el Mov. 10 exige V1.

**Mov. 3 — Config externa (separar datos de código).** Un `clientes.json` sustituye al dict hardcodeado. `destinatarios` SOLO con emails aprobados en V1. Bcc fijo no configurable al buzón del equipo (archivo central + visibilidad). *Fallo probable*: emails de cliente commiteados a un repo público. *Contramaniobra*: el `clientes.json` SOLO en el repo privado operativo y en el servidor. Jamás en un repo público.

**Mov. 4 — Extender el generador (modos de envío + idempotencia).** Modos que sustituyen al `--test` ambiguo: `--dry` (genera, no envía) · `--preview` (envía TODO a la allowlist del equipo — cero clientes) · `--send-real` (destinatarios reales). Sin flag → `--dry` (default seguro). **Assert duro**: en `--preview`, si algún destinatario no está en la allowlist → `raise` antes de tocar SMTP. Registro idempotente en sqlite con `PRIMARY KEY(slug, mes, modo)`: antes de cada envío real, `SELECT` — si ya existe → skip con log (jamás doble envío). El INSERT solo tras el envío sin excepción. *Fallo probable*: refactor rompe el import. *Contramaniobra*: `python -m py_compile` antes de cada prueba.

**Mov. 8 — Deploy al servidor (con backup, sin tocar el cron todavía).** Backup de la versión anterior antes de pisar; `mkdir -p` del subdirectorio de la BD (un scp de varios ficheros NO crea el destino). Dejar el interruptor de modo en `preview`. *Rollback de este movimiento* (primer ciudadano de la rama): `mv <ruta>.bak-<fecha> <ruta>`. *Fallo probable*: pisar una versión del servidor más nueva que la de git. *Contramaniobra*: antes del scp, `scp` inverso + diff; si hay cambios no recogidos, incorporarlos primero. El `.bak` es el rollback en cualquier caso.

**Mov. 9 — Cron con reintentos (idempotencia probada ANTES de instalarlo).** Primero, en el servidor y en modo preview, ejecutar el generador DOS veces sobre el mismo cliente/mes → la 2ª debe hacer skip. Después instalar el cron **con protección del crontab**: un `crontab -l` fallido encadenado a `| crontab -` VACÍA el crontab entero. Por eso: backup primero, comprobar que el backup tiene >0 líneas, y solo entonces recomponer. Día 1 = envío; días 2-3 = reintentos (el sqlite hace que los ya enviados hagan skip). *Fallo probable*: el `grep -v` borra de más otra línea del crontab. *Contramaniobra*: `diff` entre backup y crontab nuevo — la única diferencia admisible es la línea añadida; si no, restaurar del backup.

**Mov. 10 — Ventana de preview + revisión del responsable.** Simulacro inmediato en modo preview: todos los informes del mes cerrado llegan al equipo. **Verificar la entrega REAL en el buzón destino** (INBOX + Spam): el log del emisor NO basta — "aceptado por el relay" ≠ "entregado". "Mostrar original" → `SPF: PASS`, `DKIM: PASS`. 🔀 *Trigger*: si el responsable pide cambios → iterar Mov. 4 + redeploy + nuevo preview; si da OK → Mov. 11.

**Mov. 11 — Activación del envío real (SOLO tras OK explícito).** Es el único movimiento que abre la puerta a buzones de cliente — **ventana con el responsable**. Cambiar el interruptor de modo a `real`. Vigilancia activa ese día: log, resumen, y consulta al registro sqlite. *Fallo probable*: un cliente con email erróneo (rebote). *Contramaniobra*: marcar ese slug `activo: false`, corregir SOLO con dato verificado, reactivar; el reintento NO reenvía a los demás (sqlite).

### Condiciones de aborto (parar + escalar + estado a dejar)

| # | Situación | Señales | Estado en que dejar las cosas |
|---|---|---|---|
| **A1** | Un email llegó a un cliente en preview / antes de su OK | destinatario fuera de allowlist en el log | 🔴 PARAR TODO: cron fuera (con backup) + interruptor a `preview`. Reportar el destinatario y el contenido exactos. El peor fallo posible de la misión. |
| **A2** | Key de la service account inválida/rotada (`invalid_grant`) | R4 falla en todas las propiedades | Nada nuevo desplegado; si ya, dejar en `preview`. La rotación sigue el protocolo de secretos, fuera de este war-game. |
| **A5** | SMTP rechaza autenticación (535) | error de auth en log + aviso | CERO envíos salen (el script falla limpio, jamás se degrada a otro remitente por su cuenta). Pass rotada → gestor de secretos. |
| **A6** | El RECON contradice un supuesto crítico | R1/R2 devuelven algo inesperado | No tocar nada. Fotografiar el estado y escalar con el diff frente a lo esperado. |

**Regla transversal al abortar**: dejar el interruptor en modo seguro (`preview` o cron desinstalado con backup), log intacto, `git push` de lo commiteado, y una nota fechada con el punto exacto de parada.

### Pasadas de verificación (batería medible)

1. **Crontab íntegro**: 1 línea nueva Y todas las previas intactas (`crontab -l | wc -l` ≥ backup).
2. **Idempotencia (el test estrella)**: ejecutar el wrapper DOS veces el mismo día → 2ª corrida: log `skip` en todos, CERO emails nuevos, sqlite sin duplicados (`GROUP BY … HAVING COUNT(*)>1` → vacío).
3. **Allowlist preview**: con modo `preview`, grep del log → ningún destinatario fuera de la allowlist del equipo. Cero coincidencias de dominios de cliente.
4. **Entrega real verificada en destino**: informes en INBOX (no Spam); `SPF: PASS`, `DKIM: PASS`.
5. **Cifras cuadran (3 clientes control)**: informe vs UI de analítica/buscadores (±5% por consolidación) y vs una lectura API independiente (código distinto, misma fuente → detecta bugs de rangos).
6. **Cliente sin una fuente**: informe parcial se genera sin tarjetas vacías/None.
7. **Sin secretos en el diff**: `git log -p | grep -iE "BEGIN PRIVATE|smtp_pass *="` → vacío.

### Firma

*Battle-plan redactado por el redactor (mejor modelo disponible) · red-team pass (punto 7 del estándar) ejecutado por un agente DISTINTO: N hallazgos incorporados (variables de entorno en el smoke de RECON, semántica de modos unificada, `mkdir` en deploy, LEDGER poblado, backup de crontab fiable, allowlist cerrada).*

---

## Anti-patrones

- ❌ **NO** escribir "si algo va mal, revisa el error". Eso no es una contramaniobra: escribe la causa, las señales y los pasos.
- ❌ **NO** dejar bifurcaciones al criterio del ejecutor barato. Si no hay trigger explícito ("si X → A"), el ejecutor decide a ojo y falla.
- ❌ **NO** que el redactor se autoevalúe. El red-team lo hace un agente distinto o no cuenta.
- ❌ **NO** asumir supuestos en silencio. Todo lo que el redactor no pueda verificar → `(VARIABLE: …)` en el texto y en el LEDGER.
- ❌ **NO** poner el valor de un secreto en el battle-plan. Solo su ubicación.
- ❌ **NO** ejecutar operaciones destructivas sin ventana con un humano, backup verificado y rollback como primer movimiento de esa rama.
- ❌ **NO** ejecutar un war-game viejo a ciegas. Es una foto fechada: la fase RECON re-verifica la realidad antes del primer movimiento. Si el recon contradice un supuesto crítico, sigue el trigger o aborta.
- ❌ **NO** parchear a ciegas un war-game cuando la misión cambia de forma sustancial. Re-genéralo.

---

## Tradeoffs del diseño

| Decisión | Coste | Beneficio |
|---|---|---|
| Redactar con el modelo top | Más tokens/dinero en la redacción | Se ejecuta N veces con un modelo barato: el coste se amortiza |
| Pipeline de 3 etapas | Más pasos que "escribe un plan" | El red-team caza los huecos que el redactor no ve |
| RECON en cada ejecución | Unos minutos antes de empezar | Evita ejecutar sobre supuestos caducados (el fallo más caro) |
| Battle-plan verboso | Documento largo | Ejecutable a ciegas: quien ejecuta no necesita tu contexto |
| Foto fechada + re-generar | Mantenimiento periódico | Future-proof: cada modelo mejor sube el nivel del runbook |

---

## Ejemplos de aplicación

| Misión | Por qué war-game | Movimiento destructivo típico |
|---|---|---|
| Envío masivo de emails a clientes | Un email al destinatario equivocado no se deshace | Interruptor `preview`→`real` tras OK humano |
| Migración de datos entre esquemas/tenants | Pisar datos vivos es irreversible | Backup verificado + rollback como Mov. 1 de la rama |
| Deploy a producción con dependencias | Un servicio caído afecta a usuarios reales | `.bak` + smoke + rollback documentado |
| Cambio de DNS / cutover de dominio | Propagación lenta, difícil de revertir | Ventana con el responsable + verificación por resolver externo |
| Endurecer políticas de acceso (RLS, permisos) | Un lockout te deja fuera de tu propia BD | Auditoría adversarial antes de aplicar el FORCE |

---

## Skills relacionadas

- Cualquier skill de **deploy / VPS**: el war-game es la capa de "qué puede salir mal" sobre el runbook de deploy.
- Cualquier skill de **git destructivo**: el war-game exige backup + rollback como primer movimiento de la rama destructiva.
- Cualquier skill de **manejo de secretos**: el war-game solo señala la ubicación, nunca el valor.

---

*Patrón aportado por MultiAtlas a la comunidad SaaS Factory. Probado en producción; ejemplo completamente anonimizado.*
