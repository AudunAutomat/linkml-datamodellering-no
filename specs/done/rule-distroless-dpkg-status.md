# Rule: innkopierte bibliotek i distroless må ha dpkg-oppføring

## Bakgrunn

I distroless-piloten for `mcp-linkml-validator` (`specs/backlog/evaluering-distroless-baseimage.md`)
vart 12 delte bibliotek frå `python:3.15-slim-trixie` kopierte inn i `gcr.io/distroless/cc-debian13`
med `COPY`. Biblioteka var funne med `ldd` og kopierte utan pakkemetadata.

Trivy les pakkelista frå `/var/lib/dpkg/status.d/` og såg difor ikkje desse biblioteka. 25 CVE-funn,
9 av dei HIGH (mellom anna i libsqlite3 og libuuid), var usynlege. Første skanning viste 45 funn i
staden for 70, og tryggleiksbiletet såg betre ut enn det var. Feilen vart oppdaga fordi skanninga
fann null funn i biblioteka som faktisk var kopierte inn.

## Steg

1. Utvid `.claude/rules/container-images.md` med ein underseksjon om pakkemetadata for innkopierte bibliotek
2. Lenk til konkret hending i pilot-specen

## Handlingsliste

- [x] Ny underseksjon i `.claude/rules/container-images.md`
- [x] Oppdater `description` i frontmatter

## Avgjerder

- **Utvid eksisterande rule.** `container-images.md` dekkjer allereie `src/assets/containers/**`, som er scopet for alle `Dockerfile*`. Ei ny fil hadde ikkje fått eit anna scope.
- **Generell formulering, ikkje berre distroless.** Problemet gjeld alle bilete der binærfiler blir kopierte inn utanom pakkehandsamaren (`COPY --from=...` av `.so`-filer). Distroless er det konkrete tilfellet, og det er nemnt eksplisitt.
- **Referanse til backlog-spec.** Pilot-specen ligg framleis i `specs/backlog/`, fordi avgjerda om utrulling er open. Lenkja må oppdaterast dersom specen blir flytta til `specs/done/`.

## Utført

- `.claude/rules/container-images.md`: ny underseksjon «Innkopierte bibliotek må ha pakkemetadata» og utvida `description`
