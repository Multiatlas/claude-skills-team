---
name: delegacion-orquestador-worker
description: Reparto orquestador–worker para estirar tokens sin sacrificar calidad. El modelo caro (Opus) hace plan, arquitectura, lógica core y la revisión; delega a modelos baratos (Sonnet/Haiku) SOLO el trabajo que pasa un umbral estricto de 4 candados. Activar en tareas con volumen mecánico (boilerplate, baterías de tests, transformaciones repetidas, búsqueda/resumen) donde el modelo top haría de más. Complementa a wargame-battle-plans: misma idea "piensa caro, ejecuta barato", aplicada al día a día del código.
---

# Delegación orquestador–worker

> «Piensa con el caro, ejecuta con el barato» — pero en el trabajo cotidiano, con
> un umbral concreto para que el ahorro sea REAL. Extiende la tesis de
> `wargame-battle-plans` del terreno de las misiones de riesgo al del código diario.

## Por qué existe

El reflejo "usa un modelo barato para ahorrar" rompe proyectos: el barato ejecuta
rápido pero no tiene el criterio del caro (arquitectura, lógica entrelazada,
anticipar fallos). Y hacer TODO con el caro quema tokens en trabajo que un barato
haría igual de bien. La solución no es elegir uno: es repartir. Además, delegar mal
cuesta MÁS — el subagente arranca en frío (re-lee archivos, re-deriva contexto), hay
que escribirle un brief y revisar su salida. Por eso hace falta un umbral.

## Reparto por modelo

- **Orquestador (modelo top, p. ej. Opus):** plan, arquitectura, modelo de datos,
  seguridad (RLS, auth, pagos), migraciones, lógica core entrelazada, el reparto en
  sí, y SIEMPRE la revisión/integración final.
- **Worker capaz (p. ej. Sonnet):** código real bien especificado que NO es difícil
  de arquitectura — un CRUD siguiendo un patrón, un servicio con I/O claro.
- **Worker barato (p. ej. Haiku):** trivial y voluminoso — boilerplate/scaffolding,
  baterías de tests con un molde definido, la misma transformación en muchos
  archivos, fixtures/seeds, y búsqueda/resumen ruidoso.

## El umbral: delega SOLO si se cumplen los 4 candados

1. **Volumen** — ~≥5 archivos de trabajo mecánico similar, o una generación
   repetitiva (~20+ ítems casi idénticos). Por debajo, lo hace el orquestador.
2. **Baja complejidad para el worker elegido** — cero arquitectura, cero lógica
   entrelazada. Sigue un patrón existente o una spec exacta.
3. **Verificable objetivo y barato** — éxito medido con typecheck / tests verdes /
   calce con un patrón, para validar SIN re-leer línea por línea.
4. **Autocontenido** — se describe en un brief corto.

## Comportamiento

- **Automático:** si un subtrabajo cumple los 4 candados, delega y anuncia en una
  línea qué delega y a qué modelo.
- **Elección por tarea:** worker capaz por defecto; el barato solo si es trivial.
- **Verificación obligatoria:** valida la salida (typecheck/tests/patrón). Nunca a
  ciegas. Si falla → lo arregla el orquestador o re-delega con mejor brief.
- **Grande pero NO worker-safe:** no se fuerza a un worker; se avisa al humano para
  bajar el modelo de la sesión.
- **Por debajo del umbral:** lo hace el orquestador. No fragmentar tareas chicas
  solo para delegar.

## El límite honesto

La delegación mueve volumen a una tarifa más barata; no crea presupuesto nuevo.
Ahorro real = diferencial de tarifa − (brief + cold-start + revisión). Por eso el
umbral es estricto: sobre-delegar cuesta más.

## Nota sobre effort / thinking (modelos con adaptive thinking)

En modelos de razonamiento adaptativo (Opus 4.7/4.8, Sonnet 5, Fable 5) el
presupuesto fijo `MAX_THINKING_TOKENS` ya NO aplica: su magnitud se ignora. El dial
real de calidad/costo es el effort level (low/medium/high/xhigh). `high` (default)
razona profundo en lo complejo y salta lo trivial; `xhigh` piensa a fondo siempre.
Para "frugal pero seguro", `high` suele ser el punto dulce; con este reparto, el
effort solo pesa en los turnos del orquestador.

## Anti-patrones

- ❌ Delegar lógica core, arquitectura, seguridad o migraciones a un worker barato.
- ❌ Delegar trozos pequeños: el overhead supera el ahorro.
- ❌ Confiar en la salida del worker sin verificarla.
- ❌ Fragmentar una tarea artificialmente solo para poder delegar.
- ❌ Creer que subir `MAX_THINKING_TOKENS` mejora la calidad en modelos adaptativos.

---

*Contribución complementaria a `wargame-battle-plans` (MultiAtlas). Patrón genérico, sin datos sensibles.*
