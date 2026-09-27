# Rule: portal-adresser er identifikatorar og haustingsadresser

## Bakgrunn

Under steg 2 i `specs/backlog/lokalisering-dokumentasjonsportal.md` valde
brukaren adressestrukturen L2 (`/nn/` og `/en/`) for fleirspråkleg portal. Ei
kartlegging etter valet viste at portal-adressene vert brukte maskinelt:
`heimeside` i alle modellmanifest (sett av `generate_mkdocs_url()` i
`generate-informasjonsmodell.py`) er `informasjonsmodellidentifikator` i
modellkatalogen (`generate-modellkatalog.py`), og katalog-`.ttl`-filer vert
hausta frå portal-stiar (`publisering-begrep.md:207`, `publisering-modell.md:166`,
`publisering-oversikt.md:350`). GitHub Pages har ikkje HTTP-vidaresending. Ei
naiv flytting ville difor ha broten identifikatorar og hausting utan synleg feil.
Dette var ikkje dokumentert nokon stad. Brukaren bad om at det vert fanga som rule.

## Steg

1. Utvid `.claude/rules/mkdocs-portal.md` med ein subseksjon om maskinelle
   konsumentar av portal-adresser og korleis ein flyttar sider trygt.

## Handlingsliste

- [x] 1. Ny subseksjon «Portal-adresser er identifikatorar og haustingsadresser»

## Avgjerder

- **Utvida eksisterande rule:** emnet (portalstruktur, `publish.sh`) deler scope
  (`mkdocs/**`) med resten av `mkdocs-portal.md`. Rula lastar ikkje ved endring i
  `generate-informasjonsmodell.py` (`src/assets/scripts/**`). Ein kryssreferanse
  der vart vurdert, men er ikkje lagd til, sidan ingen endring i den fila har
  utløyst problemet.

## Utført

- `.claude/rules/mkdocs-portal.md`: ny subseksjon med kartlegging av konsumentar, forbod, framgangsmåte i fem steg og referanse til tilfellet.
