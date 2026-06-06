---
name: handoff-continuidad-sesion
description: Continuidad anti-crash para sesiones largas de agente. Mantén un documento HANDOFF vivo en el repo (docs/HANDOFF-<fecha>.md), actualízalo cada ~1 hora y tras cada hito, y commitea+pushea SIEMPRE para que persista en git. Si la sesión se corrompe (fallo de API, compactación de contexto, crash del IDE) y pierdes la memoria del chat, un chat nuevo lee ese archivo y retoma sin perder nada. Activar en CUALQUIER sesión de trabajo larga o con cambios en producción.
---

# Skill — Handoff de continuidad de sesión (anti-crash)

> **Caja negra para tu agente.** En una sesión larga, un fallo de API o una compactación de contexto puede dejar al chat **sin memoria de forma irrecuperable**. Si pasa a mitad de un trabajo complejo, pierdes horas. La solución: un documento de traspaso vivo, persistido en git.

## El problema

Una sesión de agente (Claude Code u otro) puede:
- Recibir errores de API que corrompen o truncan su contexto.
- Sufrir una **compactación** que resume/pierde detalle de lo que estabas haciendo.
- Cerrarse por timeout, crash del IDE, etc.

Si ocurre **a mitad de un trabajo complejo** (varios frentes abiertos, decisiones tomadas, deploys en curso), se pierde el hilo y hay que reconstruirlo de cero — caro y propenso a errores.

## La solución: HANDOFF vivo en git

Mantén un documento de traspaso **persistido en el repo** (sobrevive a la muerte del chat porque está en GitHub) y actualízalo periódicamente.

### Cuándo actualizar el handoff

1. **Cada ~1 hora** de trabajo continuo (cadencia objetivo).
2. **Tras cada HITO**: un deploy a producción, una decisión de arquitectura, un commit grande, resolver un incidente, terminar una tarea de la lista.
3. **Cuando haya varios frentes abiertos** simultáneamente.
4. **Si detectas que la sesión es larga/compleja** (muchos mensajes, varios subproyectos).
5. **Si el usuario avisa de inestabilidad** ("guarda por si acaso").

> Regla práctica: **si perder el chat AHORA dolería, el handoff está desactualizado → actualízalo.**

### Dónde y cómo

- Archivo: **`docs/HANDOFF-<fecha>.md`** en el repo del proyecto en curso.
- **SIEMPRE `git add` + `git commit` + `git push`** tras actualizarlo. Si solo está en local y el disco/chat muere, no sirve: la persistencia real es el remoto (GitHub).
- Un solo archivo por día/sesión; se va actualizando (no crear 10 archivos).

### Qué contiene (estructura canónica)

```markdown
# HANDOFF SESIÓN <fecha> — traspaso completo

## 0. Contexto general
- Usuario, idioma, rol del agente
- Repos (nombre, rama actual, ruta local)
- Servidores/accesos (alias SSH, qué vive en cada uno)
- Credenciales POR REFERENCIA (path del secreto, NUNCA el valor)

## 1. EN CURSO AHORA (verificar al retomar)
- Tareas a medias, comandos en background, qué falta confirmar

## 2. COMPLETADO en esta sesión
- Por bloques, con qué se hizo y estado (verificado en prod / pendiente)

## 3. PENDIENTES VIVOS
- Lista accionable de lo que queda, con quién/qué bloquea

## 4. Decisiones y aprendizajes
- Decisiones de arquitectura tomadas

## 5. Commits clave
- Hashes + repo + rama de los commits importantes (todo pusheado)
```

### Cómo lo usa el chat NUEVO

Si la sesión muere y abres un chat nuevo:
1. Le dices: **"lee `docs/HANDOFF-<fecha>.md`"**.
2. El chat nuevo lo lee (+ tu fichero de tareas vivas y memorias si las tienes).
3. Retoma exactamente donde se quedó, **en 30 segundos**, sin perder contexto.

## Relación con otras prácticas

- **Lista de tareas vivas** (tipo `PENDIENTES.md`): largo plazo, entre sesiones.
- **`HANDOFF-<fecha>.md`**: foto detallada del estado de UNA sesión (corto plazo, anti-crash). Más granular.
- **Memorias persistentes**: aprendizajes/reglas reutilizables. El handoff las referencia, no las duplica.

## Forzarlo automáticamente (avanzado)

Para no depender de que el agente se acuerde:
- Recordatorio en el `CLAUDE.md` del repo: *"actualiza docs/HANDOFF cada hora y tras cada deploy"*.
- O un hook en `settings.json` que recuerde periódicamente.

La cadencia objetivo es **1 hora**, pero lo importante es el principio: **nunca dejes que un crash borre horas de trabajo no documentado.**

---

*Skill publicada por MultiAtlas para la comunidad SaaS Factory. Nacida de un caso real: fallos de API que dejaban el chat sin memoria a mitad de sesión. Convierte un crash catastrófico en un bache de un minuto.*
