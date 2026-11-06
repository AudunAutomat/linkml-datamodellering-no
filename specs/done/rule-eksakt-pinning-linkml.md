# Rule: eksakt og lik pinning av linkml og linkml-runtime

## Bakgrunn

Linkml-pinninga feila stille to gonger i same økt (2026-11-06):

1. `Dockerfile.mcp-linkml` hadde `linkml>=1.11.1,<2.0.0`. Ei nybygging gav 1.12.1, og
   `linkml_relative_import_patch` hoppa over `imports_closure()`-patchen. BUG-24-workarounden forsvann
   utan at bygget feila (`specs/done/linkml-relative-import-patch-1-12.md`).
2. `Dockerfile.linkml` pinna berre `linkml==1.11.1`. Ei nybygging gav `linkml-runtime` 1.12.1, altså
   blanda versjonar (`specs/done/oppgrader-linkml-1-12-1.md`, Funn).

## Steg

1. Ny underseksjon i `.claude/rules/container-images.md`
2. Oppdater `description` i frontmatter

## Handlingsliste

- [x] Underseksjon «linkml og linkml-runtime skal pinnast eksakt og likt»
- [x] `description` utvida

## Avgjerder

- **Utvid `container-images.md`, ikkje ny fil.** Rula gjeld `Dockerfile*` under `src/assets/containers/`, som allereie er i scopet til `container-images.md`.
- **Både `linkml` og `linkml-runtime`, og same versjon i alle bilete.** Dei to hendingane var ulike variantar av same feilklasse: ope krav og manglande runtime-pin. Ei rule som berre dekte den eine, ville ikkje ha fanga den andre.
- **`mkdocs/lib/sections/kom_i_gang.sh` er ikkje med.** `pip install linkml-runtime` der er ei rettleiing for eksterne brukarar, ikkje ein del av bileta i repoet.

## Utført

- `.claude/rules/container-images.md`: ny underseksjon og utvida `description`
