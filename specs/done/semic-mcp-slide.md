# SEMIC-slide: «What about AI?» (MCP-serverane)

## Bakgrunn

Utkast til ei slide i SEMIC 2026-malen som forklarer dei tre MCP-serverane i repoet (`src/mcp-linkml-modell-utkast`, `src/mcp-linkml-begrep-utkast`, `src/mcp-linkml-validator`; registrerte i `.mcp.json`). Brukaren bad om eit utkast; same metode som `specs/done/semic-tooling-slide.md` og `semic-findings-slide.md`.

## Steg

1. Les serverane (README, `server.py`) for kva dei gjer og kva verktøy dei eksponerer.
2. Bygg slida: tittel «What about AI?», tagline, AI-agent til venstre, tre serverkort til høgre, koplingar mellom.
3. Generer, valider XML, forhandsvis.

## Handlingsliste

- [x] 1. Kartlegg serverane
- [x] 2. Bygge slida
- [x] 3. Generere, validere XML, forhandsvise

## Avgjerder

- **Bodskap «AI proposes. The tooling decides what is right.»:** samanfattar kvifor serverane finst (utkast frå AI, deterministisk validering mot policyar). Orda er mine; brukaren kan endre dei.
- **Verktøynamn viste som i `server.py`/MCP-konfigurasjonen** (norske namn som `opprett_begrep`), i monospace, fordi dei er det agenten faktisk ser.
- **Delt kode i `slides/semic_pptx_lib.py`** for det nye scriptet (`semic-mcp-pptx.py`). `semic-tooling-pptx.py` og `semic-findings-pptx.py` har framleis eigne kopiar av same kode; å flytte dei til biblioteket er ei DRY-opprydding som krev eksplisitt løyve (CLAUDE.md), og står som tilbod.
- **«MCP servers run locally, in containers»:** henta frå `.mcp.json` (`podman run -i --rm …`).

## Utført

- `src/tmp/semic-mcp-slide.pptx` (utkast), byggescript `src/assets/scripts/demo/slides/semic-mcp-pptx.py` og delt `semic_pptx_lib.py`.
- Forhandsvist med QuickLook (serif-reservefont); ikkje opna i PowerPoint.
