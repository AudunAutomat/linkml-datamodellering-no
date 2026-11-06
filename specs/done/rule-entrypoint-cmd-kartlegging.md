# Rule: kartlegg kommandooverstyringar ved endring av ENTRYPOINT/CMD

## Bakgrunn

Første versjon av distroless-piloten for `mcp-linkml-validator`
(`specs/backlog/evaluering-distroless-baseimage.md`) bytte `CMD ["python", "server.py"]` ut med
`ENTRYPOINT ["/usr/local/bin/python3"]` + `CMD ["server.py"]`. Kartlegginga av invokeringsstader (steg 3)
leitte berre etter `--entrypoint`-overstyringar og fann ingen.

`make mcp-linkml-valider-modell-test` (`make/60-mcp.mk`) køyrer derimot `$(MCP_IMAGE) python3
/work/tests/test_mcp_policies.py`. Alt etter image-navnet erstattar CMD, men vert lagt etter ENTRYPOINT.
Kommandoen ville difor blitt `python3 python3 /work/...` og feila. Feilen vart funnen først ved neste
testrunde (trimming av stdlib-utvidingar), og retta ved å gå tilbake til berre `CMD`.

## Steg

1. Utvid `.claude/rules/container-images.md` med ein underseksjon om ENTRYPOINT/CMD-endringar
2. Oppdater `description` i frontmatter

## Handlingsliste

- [x] Ny underseksjon i `.claude/rules/container-images.md`
- [x] Oppdater `description`

## Avgjerder

- **Utvid eksisterande rule.** Same scope (`src/assets/containers/**`, `make/60-mcp.mk`, `Makefile` m.fl.) som dei andre container-reglane. Ei ny fil hadde ikkje gitt eit anna scope.
- **Eigen seksjon, ikkje ein ekstra punkt i «full kartlegging av monteringsstader».** Den seksjonen handlar om filmonteringar for delte moduler. Her er det kommandosemantikken som er endra. Lista over invokeringsstader overlappar, så seksjonen viser til ho i staden for å gjenta ho (DRY).
- **Tilrådd standard: berre `CMD`.** Bileta i repoet vert køyrde med eksplisitt kommando etter image-navnet. `CMD` utan `ENTRYPOINT` gir same semantikk som i dag og krev ingen endring hos kallarane.

## Utført

- `.claude/rules/container-images.md`: ny underseksjon «Endring av ENTRYPOINT/CMD krev kartlegging av kommandooverstyringar» og utvida `description`
