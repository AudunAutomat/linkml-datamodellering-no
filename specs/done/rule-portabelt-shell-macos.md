# Plan: Rule mot GNU-spesifikt shell i script og make-oppskrifter

**Kortnavn:** `rule-portabelt-shell-macos`
**Dato:** 2026-11-17

---

## Bakgrunn

macOS er offisielt støtta miljø (`specs/done/check-prereqs-macos.md`). macOS leverer BSD-verktøy, bash 3.2 og Apple make 3.81. Fem av funna i den spec-en (F10-F14) var GNU-spesifikke konstruksjonar i script/make-oppskrifter som aldri feila på WSL2/Ubuntu eller i CI, og som først vart fanga då `make test` og `docs-publish` vart køyrde på ein Mac: `date +%s%3N`, `/proc/uptime`, `mktemp ..._XXXXXX.log`, `cp -t`, `sed -i` utan suffiks og `\L`, `.SHELLFLAGS` (make 3.82). Feila viste seg som aritmetikkfeil, «Fil manglar» og stille tapt `pipefail`, langt frå årsaka. Utan ei rule kjem same klasse inn att ved neste nye script.

Mekanisme (jf. `ny-rule` steg 2): ei rule — gjeld berre når scripta/make-filene vert rørte, ikkje ubetinga.

## Steg

1. Avgjer scope: eksisterande `make-conventions.md` dekkjer `make/**`, `src/assets/scripts/**`, `mkdocs/lib/scripts/**`. Manglar: `Makefile`, `mkdocs/lib/**` (t.d. `copy_artifacts.sh`), `mkdocs/publish.sh`, `tests/**/*.sh`.
2. Legg til ny subseksjon «Portabelt shell: macOS (BSD) og Linux (GNU)» i `make-conventions.md`, og utvid `paths:` og `description:`.
3. Verifiser at innhaldet ikkje dupliserer `COMMANDS.md § macOS` (peik dit) og at grep-kommandoen i rula finn dei kjende tilfella i eit kjent eksempel.
4. Skriv `## Utført`, flytt til `specs/done/`, utkast til commit-melding.

## Handlingsliste

- [x] 1. Scope avgjort
- [x] 2. Subseksjon + frontmatter i `make-conventions.md`
- [x] 3. Grep-kommando verifisert
- [x] 4. Spec avslutta

## Avgjerder

1. **Ny subseksjon i `make-conventions.md`, ikkje ny fil:** emnet (shell/make-script) delar scope med resten av rula. Fire stiar vart lagt til i `paths:` (`Makefile`, `mkdocs/lib/**`, `mkdocs/publish.sh`, `tests/**/*.sh`); det gjer at heile `make-conventions.md` no òg lastast ved arbeid med desse filene, noko som er akseptert fordi innhaldet der (stille feil, make help, batching, orkestratorar) òg gjeld dei.
2. **Tabell i staden for lang prosa:** konstruksjon → problem → portabelt alternativ, sidan same feilklasse gjeld mange verktøy og lista skal vere grep-bar.
3. **Peikar til `COMMANDS.md § macOS` og `check-prereqs`** for installasjonskrav (make >= 4, bash >= 4, PyYAML) i staden for å gjenta dei (DRY).

## Utført

2026-11-17. Ny subseksjon «Portabelt shell: macOS (BSD) og Linux (GNU)» i `.claude/rules/make-conventions.md`: forbod mot GNU-spesifikke konstruksjonar utan portabelt alternativ, tabell (konstruksjon → problem → alternativ), grep-kommando, framgangsmåte og konkret tilfelle frå `specs/done/check-prereqs-macos.md` (F10-F14). `paths:` utvida med `Makefile`, `mkdocs/lib/**`, `mkdocs/publish.sh`, `tests/**/*.sh`; `description:` oppdatert.

Verifisert: grep-kommandoen i rula gir 4/4 treff på kjent dårleg kode og berre kommentarar/vaktsette treff på dei fiksa filene. Ikkje verifisert: at rula lastar for dei nye stiane i ei ny økt (krev ny Claude Code-økt).
