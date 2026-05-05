# 🛠️ Claude Skills — Equipo MultiAtlas

> **Skills compartidas del equipo MultiAtlas para Claude Code.**
> Versionadas en este repo para que cualquier miembro del equipo (Rubén, Desi, Isaac, futuros) tenga la misma capacidad operacional en su Claude Code local.

---

## 🎯 Filosofía

- **Una sola fuente de verdad**: este repo. Si una skill cambia, se cambia aquí, se commitea, y todos hacen `git pull` + `install.ps1`.
- **No hay skills "personales" en este repo**: solo lo que sirve a TODO el equipo. Skills personales se quedan en `~/.claude/skills/` sin versionar.
- **Skills versionadas**: cada cambio queda en `git log`. Si una skill rompe algo, `git revert` y todos vuelven a la versión anterior.

## 📦 Skills incluidas

| Skill | Para qué |
|---|---|
| `setup-vscode-multiatlas-team` | Onboarding técnico de un miembro nuevo: extensiones VS Code, config Claude Code, repos, hooks gitleaks |
| `protocolo-cierre-multiatlas-team` | Protocolo estándar de cierre de sesión: git status, commit + push, memoria persistente, resumen al usuario |
| `git-workflow-multiatlas` | Flujo Git unificado: branching, commits convencionales, tags semver, runbooks de recovery |

---

## 🚀 Instalación inicial (cada miembro, una vez)

### Windows (PowerShell)

```powershell
# 1. Clona este repo en tu carpeta de developer
cd C:\Users\$env:USERNAME\OneDrive\Documentos\DEVELOPER
git clone https://github.com/Multiatlas/claude-skills-team.git

# 2. Ejecuta el instalador (copia las skills a ~/.claude/skills/)
cd claude-skills-team
.\install.ps1

# 3. Reinicia VS Code para que Claude Code detecte las skills nuevas
```

### Mac/Linux (bash)

```bash
cd ~/Developer  # o donde tengas tus repos
git clone https://github.com/Multiatlas/claude-skills-team.git
cd claude-skills-team
./install.sh
```

Tras la instalación, abre VS Code y pídele a tu Claude Code:

```
Lista las skills que tienes instaladas
```

Deberían aparecer las 3 skills del equipo + las que ya tuvieses tú.

---

## 🔄 Actualizar (cuando alguien añade una skill o modifica una existente)

```powershell
# Windows
cd C:\Users\$env:USERNAME\OneDrive\Documentos\DEVELOPER\claude-skills-team
.\update.ps1
```

```bash
# Mac/Linux
cd ~/Developer/claude-skills-team
./update.sh
```

Estos scripts hacen `git pull` y vuelven a copiar las skills a `~/.claude/skills/`.

**Recomendación**: actualizar cada lunes por la mañana, así arrancas la semana con todo al día.

---

## ✏️ Añadir o modificar una skill

1. **Edita o crea** la skill dentro de `skills/<nombre-skill>/SKILL.md`
2. **Prueba en local**: ejecuta `.\install.ps1` y prueba la skill desde tu Claude Code
3. **Commit con Conventional Commits**:
   ```bash
   git add skills/<nombre-skill>/
   git commit -m "skill(<nombre>): qué cambia y por qué"
   git push origin master
   ```
4. **Avisa al equipo** por WhatsApp/Telegram para que hagan `update.ps1`

### Convenciones para nuevas skills

- Nombre carpeta: `kebab-case` y descriptivo (`mantenimiento-wordpress-cliente`, no `mwc`)
- Frontmatter obligatorio en `SKILL.md`:
  ```markdown
  ---
  name: Nombre Legible
  description: Una línea — para qué sirve y cuándo invocarla. Verbos en imperativo.
  ---
  ```
- Solo entran skills que **sirven a más de un miembro del equipo**. Skills muy personales se quedan en local.

---

## 🚫 Qué NO entra en este repo

- **Skills personales** (proyecto individual, atajos de un solo dev)
- **Skills con secretos** (API keys, tokens, paths privados) — usar memoria persistente local en su lugar
- **Skills experimentales no probadas** — termínalas en local primero, súbelas cuando funcionen

---

## 📞 Si algo falla

- **`install.ps1` no encuentra `~/.claude/skills/`**: créala manualmente con `mkdir -p ~/.claude/skills` y reintenta
- **Una skill no aparece en Claude Code**: reinicia VS Code completamente. Si sigue sin aparecer, verifica que existe `~/.claude/skills/<nombre>/SKILL.md` con frontmatter válido
- **Conflicto al hacer `git pull`**: alguien tocó una skill al mismo tiempo. Resuelve manualmente o pregunta al equipo

---

## 🔗 Referencias cruzadas

- Manual operativo del equipo (Drive): `SAAS FACTORY/SYNC-ANTIGRAVITY/2026-05-05_de-ruben_para-desiree_manual-operativo-multiatlas-it.md`
- Repo principal del ecosistema: `Multiatlas/agente-it-multiatlas`
- Repo template SaaS: `Multiatlas/multiatlas-setup-saas`
