---
name: claude-code-sin-dar-ok
description: Dejar de darle "Yes" a Claude Code en cada paso, sin quedarte sin red. Configura bypassPermissions con una lista de deny que sigue bloqueando lo destructivo, un hook que para las decisiones que son tuyas, y la parte de VS Code que casi nadie configura y hace que el bypass no se aplique. Invocar cuando alguien diga "estoy todo el rato dando OK", "quiero que trabaje solo", "cómo dejo a Claude Code trabajando de noche", o cuando una sesión larga se pase el rato pidiendo permiso.
---

# Que Claude Code deje de pedirte permiso a cada paso (sin pegarte un tiro en el pie)

> **El problema real no es la confianza, es la configuración.** Si llevas media hora dando «Yes» a
> comandos que ya aprobaste diez veces, no es que Claude sea pesado: es que tienes tres piezas sin
> configurar y una de ellas está en un sitio donde nadie mira.
>
> Esto no va de quitar los frenos. Va de **cambiar un freno que pregunta por todo por uno que
> bloquea solo lo que de verdad importa**, y de que las decisiones que son tuyas te sigan llegando.

---

## Lo que casi todo el mundo hace mal

Buscas cómo quitar los permisos, encuentras `--dangerously-skip-permissions`, lo pones, y pasa una
de estas dos:

1. **Sigue preguntando** (si trabajas en VS Code). Ver el apartado de VS Code, que es la pieza que
   falta.
2. **Deja de preguntar del todo**, incluidas las cosas que no querías que hiciera sola.

La configuración buena tiene **tres capas** y hay que poner las tres. Cuesta diez minutos.

---

## Capa 1 · Permisos: `bypassPermissions` + una lista de `deny`

En `~/.claude/settings.json`:

```jsonc
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "deny": [
      "Bash(rm -rf:*)", "Bash(rm -fr:*)", "Bash(rm -r:*)",
      "Bash(sudo:*)", "Bash(shutdown:*)", "Bash(mkfs:*)",
      "Bash(git push --force:*)", "Bash(git push -f:*)",
      "Bash(git push origin --delete:*)"
    ],
    "ask": [
      "Bash(git reset --hard:*)", "Bash(git clean:*)", "Bash(git branch -D:*)"
    ]
  }
}
```

**El dato que lo hace seguro y que mucha gente no sabe:**

> 🔑 **`deny` SIGUE VIGENTE en modo bypass.** No es «bypass = barra libre». El modo se salta el
> *preguntar*, no las prohibiciones. Y las listas **se fusionan entre niveles** (usuario + proyecto),
> no se sobrescriben: puedes tener una red global y añadir prohibiciones por proyecto.

Así que lo destructivo se bloquea **sin preguntar** y todo lo demás pasa **sin preguntar**. Que es
exactamente lo que querías.

`ask` es la vía intermedia: lo que no quieres prohibir pero tampoco que pase solo.

---

## Capa 2 · Un hook para las decisiones que son TUYAS

Los permisos saben de comandos, no de consecuencias. `curl` no es peligroso… salvo cuando manda un
correo a un cliente. Para eso va un hook `PreToolUse` que mira cada comando y para en tus fronteras.

Define **tus** fronteras. Un ejemplo de agencia pequeña, cinco:

1. **Dinero real** — comprar, contratar, renovar, subir cuotas.
2. **Comunicación externa a clientes** — correos, publicar en redes.
3. **Git destructivo en ramas compartidas** — force push, reescribir historia.
4. **Legal** — firmar o enviar contratos.
5. **Irreversible que afecte a más de un cliente** — reiniciar servicios compartidos, DNS, firewall.

> 🔑 **Y aquí el detalle que cuesta un disgusto**: el hook tiene que devolver **`deny` con el motivo**,
> **no `escalateToUser`**. En modo bypass, Claude Code **ignora `escalateToUser`** y la acción sale
> igual. Nos costó descubrirlo con un correo de prueba que se envió de verdad.

El flujo queda: el agente intenta la acción → el hook la bloquea y explica por qué → el agente te lo
cuenta en el chat → si le dices que sí, la relanza con una variable de entorno que el hook reconoce
(`OK_HUMANO=1` o como la llames), y **queda registrada en el log**.

---

## Capa 3 · VS Code: la pieza que falta y por la que crees que no funciona

Si usas la extensión de VS Code y después de configurar todo lo anterior **sigue preguntando**, es
por esto. La extensión decide el modo de **cada conversación** por su cuenta, en este orden:

1. `claudeCode.initialPermissionMode` (ajuste de la extensión)
2. Lo último que elegiste en el selector de modo
3. `defaultMode` de `~/.claude/settings.json`
4. El default de tu plan

> 🔑 **Dos cosas que hay que saber, y las dos son literales de la documentación oficial:**
>
> - La extensión **NUNCA lee el `settings.local.json` del proyecto** para decidir el modo. Puedes
>   tener el proyecto perfectamente configurado y dará igual.
> - **Sin `"claudeCode.allowDangerouslySkipPermissions": true`, un valor bypass arranca la
>   conversación en MANUAL.** O sea: lo configuraste bien y no se aplica.

En `settings.json` de VS Code (el de usuario):

```jsonc
{
  "claudeCode.allowDangerouslySkipPermissions": true,
  "claudeCode.initialPermissionMode": "bypassPermissions"
}
```

Después: **Reload Window + conversación NUEVA** — el modo se fija al arrancar cada conversación, así
que la que ya tenías abierta sigue como estaba. Comprueba que bajo el cuadro de texto pone
**«Bypass permissions»**.

**Síntoma de que te falta esto**: cada «Yes» que das va añadiendo una regla de `allow` a tu
settings. Si tu lista de `allow` ha crecido sola hasta doscientas reglas, es esto.

---

## Cómo comprobar que funciona de verdad

Aquí es muy fácil engañarse, y merece la pena hacerlo bien:

> 🔑 **`git` o `ssh` NO valen como prueba.** Llevan meses en tu lista de `allow` de tanto darles al
> «Yes», así que pasan igual en modo manual. Si pruebas con eso, verás que «funciona» sin que
> funcione nada.

**La prueba buena**, cuatro comprobaciones:

| Prueba | Qué debe pasar |
|---|---|
| Un comando que **no esté en ninguna lista**: `printf x >> /dev/null` | Pasa sin cuadro de permiso |
| `rm -rf /tmp/loquesea` | **Se niega**, sin preguntar |
| Algo que cruce una de tus fronteras (un correo de prueba a una dirección tuya) | **Bloqueado, con el motivo** |
| Volver un proyecto a modo normal | Ese proyecto vuelve a preguntar; la red sigue puesta |

---

## ⚠️ Dos avisos que no suelen contarte

**1. `additionalDirectories` no limita a `bash`.** Es fácil pensar que si acotas los directorios de
trabajo, el agente queda encerrado ahí. **No**: esa acotación limita las herramientas de fichero
(Read/Edit/Write), no lo que ejecutes por línea de comandos. Comprobado: en modo bypass se puede
leer un fichero de una ruta que no está en ninguna lista.

**La contención real va por `deny`**, no por la lista de directorios. Si tienes llaves SSH,
credenciales o carpetas sincronizadas en la nube bajo tu carpeta de usuario, ponlas en `deny`
explícitamente:

```jsonc
"deny": [
  "Read(~/.ssh/**)", "Read(~/.claude/.credentials.json)", "Read(**/*.pem)"
]
```

**2. El agente no puede concederse el bypass a sí mismo**, y está bien que sea así. El harness lo
bloquea. Lo configura la persona, una vez por máquina. Si le pides a Claude que se active el modo
autónomo, no puede — y es exactamente lo que queremos prevenir.

---

## Cuándo NO hacer esto

- **En una máquina con acceso a producción y sin lista de `deny`.** El orden es: primero la red,
  después el bypass. Nunca al revés.
- **Si no tienes copia de seguridad de lo que el agente puede tocar.** El bypass multiplica lo que
  puede hacer por minuto, incluidas las equivocaciones.
- **En un repositorio compartido, sin fronteras para lo destructivo.** Un force push a la rama de
  otro se deshace mal.

---

## Resumen en cuatro líneas

1. `deny` **sigue funcionando** en bypass: pon la red antes de quitar el freno.
2. El hook devuelve **`deny` con motivo**, nunca `escalateToUser` (en bypass se ignora).
3. En VS Code hace falta **`allowDangerouslySkipPermissions`** o el bypass no se aplica.
4. Prueba con un comando **que no esté en `allow`**, o te engañarás.
