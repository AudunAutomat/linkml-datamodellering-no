# ./mkdocs

Her ligg alt som gjeld generering av dokumentasjonsportal med mkdocs (utenom testopplegget som ligg under /tests).

| Sti | Innhald |
|---|---|
| `publish.sh` | Hovudscriptet bak `make docs-publish`: genererer portalinnhald per språk, byggjetre og mkdocs-konfig |
| `lib/sections/`, `lib/utils/`, `lib/scripts/` | Seksjonar på skjemasidene og hjelpescript for `publish.sh` |
| `lib/i18n/strings.yaml` | Strengkatalogen for all generert portaltekst (nynorsk + engelsk) |
| `lib/i18n/strings.lock.yaml` | Generert: hash av nynorsk original per engelsk katalognøkkel (`make i18n-stamp`) |
| `lib/templates/` | Malar med i18n-markørar (404-side) |
| `docs/` | Handskrivne rettleiingssider (nynorsk, omsette sider som `x.en.md`) og generert innhald for standardspråket |
| `build/` | Generert: arbeidstre for andre språk, byggjetre per språk, `rot/` (artefakter og vidaresendingar) og `mkdocs.<lang>.yml` |
| `site/` | Generert: ferdig bygd portal (`make docs-build`), det som vert publisert til GitHub Pages |

Sjå [Fleirspråkleg portal](docs/automasjon/fleirsprak.md) for korleis språkversjonane vert bygde og omsette, og `COMMANDS.md` (§ Dokumentasjonsportal) for kommandoane.
