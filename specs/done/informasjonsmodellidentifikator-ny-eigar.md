# `informasjonsmodellidentifikator` etter flytting til AudunAutomat

## Bakgrunn

Repoet er flytta frå `brreg/linkml-datamodellering-no` til
`AudunAutomat/linkml-datamodellering-no`, med ny portal på
<https://audunautomat.github.io/linkml-datamodellering-no/>. Sjå
`specs/backlog/ci-etter-origin-flytting-audunautomat.md`, der denne specen er
steg 9.7.

Modellkatalog-datafilene inneheld framleis identifikatorar som peikar på den
gamle portalen:

```yaml
informasjonsmodellidentifikator: https://brreg.github.io/linkml-datamodellering-no/<domene>/<modell>/
```

Desse vart med vilje haldne utanfor utskiftinga av URL-ar i hovudspecen (steg
5 og 9.6), fordi ei endring kunne vere ei identitetsendring mot eksterne
katalogar. Denne specen vurderer kva som skal gjerast.

## Kartlegging (2026-09-26)

### Omfang

| Datafil | `brreg.github.io`-identifikatorar |
|---|---|
| `src/linkml/modellkatalog/brreg-modellkatalog/data/brreg-modellkatalog/brreg-modellkatalog.yaml` | 13 av 13 |
| `src/linkml/modellkatalog/digdir-modellkatalog/data/digdir-modellkatalog/digdir-modellkatalog.yaml` | 10 av 10 |
| `src/linkml/modellkatalog/novari-modellkatalog/data/novari-modellkatalog/novari-modellkatalog.yaml` | 7 av 7 |
| `src/linkml/modellkatalog/kartverket-modellkatalog/data/kartverket-modellkatalog/kartverket-modellkatalog.yaml` | 2 av 2 |
| `src/linkml/modellkatalog/ksdigital-modellkatalog/data/ksdigital-modellkatalog/ksdigital-modellkatalog.yaml` | 1 av 1 |
| `src/linkml/modellkatalog/skatteetaten-modellkatalog/data/skatteetaten-modellkatalog/skatteetaten-modellkatalog.yaml` | 1 av 1 |
| **Sum** | **34** i 6 filer, det vil seie alle identifikatorar i alle katalogar |

### Kva feltet er, og kva det ikkje er

- `informasjonsmodellidentifikator` har `slot_uri:
  modelldcatno:informationModelIdentifier`, `range: string`
  (`src/linkml/ap-no/modelldcat-katalog/modelldcat-katalog-schema.yaml:332`).
  Det er ein **literal** som skildrar identifikatoren til modellen «i
  domenet».
- Det er **ikkje** ressurs-URI-en til modellen. Den er `id` (og
  `identifikator_literal`), som er org-basert:
  `https://<org-domene>/modellkatalogar/<katalog-slug>/<modell>`
  (`generate-modellkatalog.py`, `convert_to_org_uri`). `id` inneheld ikkje
  `brreg.github.io` og vert **ikkje** påverka av flyttinga.
- Ei endring av `informasjonsmodellidentifikator` endrar altså ein
  eigenskapsverdi på same RDF-ressurs. Det lagar ingen ny ressurs.

### Publiseringsstatus

- Alle 6 katalogane har `publish_external: true` i `build.yaml`.
- Alle 6 `published-uris.lock` står som **«Sist oppdatert: (ikkje publisert
  enno)»** og har ingen låste URI-ar. Ingen av katalogane er difor høsta av
  Felles datakatalog, og ingen ekstern konsument kan ha teke identifikatorane
  i bruk.

### Kva som skjer ved neste generering (viktig)

Eigaren av datafilene er `make gen-modellkatalog-instance`
(`generate-modellkatalog.py`). `update-modellkatalog.py` er erstatta av det
skriptet og har ikkje noko make-target lenger. `generate-modellkatalog.py` set

```python
org_modell['informasjonsmodellidentifikator'] = modell.get('heimeside')
```

altså `heimeside` frå `src/linkml/**/metadata/<modell>-manifest.yaml`. Desse
manifesta vart regenererte i hovudspecen sitt steg 9.6, og
`generate-informasjonsmodell.py` skriv no
`heimeside: https://audunautomat.github.io/linkml-datamodellering-no/<domene>/<modell>/`.

**Konsekvens:** Neste `make gen-modellkatalog-instance` byter alle 34
identifikatorar til `audunautomat.github.io` automatisk. Å behalde dei gamle
URI-ane krev difor ei aktiv handling, medan å byte dei krev berre at targetet
vert køyrt. `update-modellkatalog.py` (`PORTAL_BASE`, bytt i steg 5) har same
retning, men vert ikkje lenger brukt.

## Alternativ

| | Kva | For | Mot |
|---|---|---|---|
| **A** | Byt til `audunautomat.github.io` ved å køyre `make gen-modellkatalog-instance` | Identifikatoren peikar på ei side som finst og vert oppdatert. Same kjelde som resten av portalen. Ingen kodeendring. Ingen eksterne konsumentar å bryte (ikkje publisert). | Vert endra att dersom eigaren eller portal-domenet vert flytta på nytt. Identifikatoren er framleis bunden til ein hostingstad |
| **B** | Behald `brreg.github.io` som stabil identifikator | Ingen endring i data | Krev at generatoren vert endra (eller at `heimeside` og identifikator vert skilde), elles vert dei overskrivne ved neste køyring. Peikar på ein portal som ikkje lenger vert oppdatert og kan forsvinne |
| **C** | Byt og legg til kopling til gammal URI (`owl:sameAs`/`dct:replaces`) | Sporbart for konsumentar som kjenner den gamle verdien | Det finst ingen slike konsumentar (ikkje publisert). Krev ny slot i `modelldcat-katalog`-skjemaet. Er ein URI-relasjon for ein verdi som er ein literal |
| **D** | Innfør ein hostinguavhengig identifikator (t.d. `https://data.norge.no/…` eller org-domene, som `id`) | Overlever framtidige flyttingar | Større endring i generator og konvensjon. Bør vurderast saman med ModelDCAT-AP-NO-rettleiinga for feltet. Er ikkje naudsynt for å rydde etter flyttinga |

## Tilråding

**A.** Katalogane er ikkje publiserte. Feltet er ein literal og ikkje
ressurs-identiteten. Generatoren går uansett i retning A. Då er A den
minste og mest konsistente endringa. **D** kan vurderast separat før første
eksterne publisering, dersom ein vil ha ein identifikator som ikkje er
bunden til hosting. Det er ei konvensjonsendring og ikkje ei opprydding etter
flyttinga.

Viktig tidsfrist: avgjerda må takast **før første eksterne publisering**
(når `published-uris.lock` får innhald). Etter det kostar kvart alternativ
meir.

## Steg

1. **Avgjer alternativ** (brukaren, sjå Opne spørsmål O1).
2. Ved **A**:
   1. `make gen-modellkatalog-instance`
   2. Kontroller diffen: berre `informasjonsmodellidentifikator` skal endre seg
      frå `brreg.github.io` til `audunautomat.github.io`. Den same
      regenereringa kan òg dra inn andre felt som har drive frå manifesta. Ta
      stilling til dei på same måte som i hovudspecen 9.6.
   3. `make validate-modellkatalog-instance ORG=<alias>` for dei 6 org-ane
      (`brreg`, `digdir`, `novari`, `kartverket`, `ksdigital`, `skatteetaten`).
   4. `grep -rn 'brreg.github.io' src/linkml/modellkatalog/*/data` → ingen treff.
3. Ved **B**: endre `generate-modellkatalog.py` slik at eksisterande
   `informasjonsmodellidentifikator` vert bevart (same mønster som
   `inneholder_modellelement`, som `main()` alt bevarer), og dokumenter
   konvensjonen. Då må òg `ingen stille feil`-regelen følgjast dersom verdien
   manglar.
4. Ved **C** eller **D**: skriv eigen spec for skjema- og generatorendringa før
   noko vert gjort.
5. Oppdater hovudspecen: kryss av 9.7.

## Handlingsliste

- [x] 1. Avgjer alternativ (A/B/C/D) → A
- [x] 2. Gjennomfør valt alternativ
- [x] 3. Valider alle 6 modellkatalogar
- [x] 4. Oppdater `specs/backlog/ci-etter-origin-flytting-audunautomat.md` (9.7)

## Opne spørsmål

- ~~**O1:** Kva alternativ?~~ **Løyst 2026-09-26:** Brukaren godkjende A.
- **O2:** Skal den gamle, ubrukte `update-modellkatalog.py` fjernast, sidan han
  er erstatta av `generate-modellkatalog.py` og ikkje har make-target? Det er
  utanfor scopet til denne specen, men vart observert under kartlegginga.

## Avgjerder

- O1 → A (brukaren, 2026-09-26).
- Steg 2.2 (brukarval 2026-09-26): full regenerering vart behalden, sjølv om
  `make gen-modellkatalog-instance` gjorde meir enn å byte identifikatorane.
  Katalogane er no ein funksjon av dagens manifest, same val som for manifesta
  i hovudspecen 9.6. Alternativet var å setje filene tilbake til HEAD og berre
  byte identifikator og kontakt-URL.
- `aktoerer[].id` i `brreg-modellkatalog` er retta for hand frå
  `github.com/brreg/…` til `github.com/AudunAutomat/…`. `aktoerer` vert
  vedlikehalde for hand og teke med uendra av generatoren. Etter regenereringa
  peika alle `kontaktpunkt` på den nye URL-en, medan aktøren framleis hadde den
  gamle id-en.
- Specen er berre ei kartlegging med tilråding. Ingen datafiler er endra.
  Specen står difor i `specs/backlog/`, jf. unntaket i CLAUDE.md for
  spec-berre-leveransar.
- Omfanget er avgrensa til `informasjonsmodellidentifikator`. `id` og
  `identifikator_literal` er org-baserte og vart ikkje påverka av flyttinga.

## Utført

Gjennomført 2026-09-26 (alternativ A):

1. `make gen-modellkatalog-instance` → exit 0, 6 katalogfiler endra, ingen
   nye filer. Alle 34 `informasjonsmodellidentifikator` er no
   `https://audunautomat.github.io/linkml-datamodellering-no/<domene>/<modell>/`.
2. Endringar utover identifikatorbytet (behaldne etter brukarval):
   - **13 nye modelloppføringar:** kvar av dei 6 katalogane har fått ei
     oppføring for seg sjølv. `brreg-modellkatalog` har i tillegg fått
     `brreg-felles-{aktoer,digital-adresse,geografisk-adresse,tid,typer}` og
     `referansemodell-{bronze,silver,gold}` (13 → 21 modellar).
   - `status` `Completed` → `UnderDevelopment` for 15 modellar.
     `versjonsnummer`/`endringsdato` (og for `ngr-*` `beskrivelse`) følgjer
     no manifesta.
   - `kontaktpunkt` er `github.com/AudunAutomat/…/CONTRIBUTING.md#rapportering-av-feil`.
3. `aktoerer[].id` i `brreg-modellkatalog` er retta for hand (sjå Avgjerder).
   Alle `kontaktpunkt` viser no til ein aktør som finst (kontrollert for
   brreg, kartverket, novari og skatteetaten).
4. `make validate-modellkatalog-instance ORG=<alias>` → exit 0 for alle 6
   (`brreg`, `digdir`, `novari`, `kartverket`, `ksdigital`, `skatteetaten`).
5. `grep -rn 'brreg.github.io\|github.com/brreg' src/linkml/modellkatalog/*/data`
   → 0 treff.

Observasjon: `validate-modellkatalog-instance` gjekk gjennom sjølv med
`kontaktpunkt` som peika på ein aktør-id som ikkje fanst i fila (før
handrettinga i punkt 3). Referanseintegritet mellom `kontaktpunkt` og
`aktoerer` vert altså ikkje validert. Kandidat for eigen bug eller
policy-sjekk, ikkje handtert her.

O2 (fjerne ubrukt `update-modellkatalog.py`) står framleis ope, og er utanfor
scopet til denne specen.
