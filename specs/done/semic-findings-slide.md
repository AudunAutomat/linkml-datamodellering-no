# SEMIC-slide: findings (upstream-bugs i LinkML)

## Bakgrunn

Ei slide i SEMIC 2026-malen (`src/tmp/PPT TEMPLATE SEMIC 2026 .pptx`) som viser dei sju upstream-issuane repoet har meldt i `linkml/linkml` (#4285-#4291, sjå `specs/backlog/upstream-linkml-bugrapportar.md` § Meldte issues). Kvar bug har ei kort engelsk overskrift og ei klikkbar lenkje til GitHub-issuen.

Avklart med brukaren: dei sju meldte issuane (ikkje alle 24 bugs i `BUGS.md`), kort tekst som hyperlenkje (ikkje full URL), korte engelske stikkord (ikkje ordrette issue-titlar).

## Steg

1. Skriv byggescript `src/assets/scripts/demo/slides/semic-findings-pptx.py` (stdlib, OOXML, same metode som `semic-tooling-pptx.py`).
2. Bygg slida: tittel, sju kort (2 kolonner x 4 rader) med kategori-etikett, overskrift og hyperlenkje, og eit åttande felt med oppsummering.
3. Generer `src/tmp/semic-findings-slide.pptx`, valider XML og relasjonar, og forhandsvis.
4. Retta feil, lever.

## Innhald

| Issue | Overskrift | Kategori |
|---|---|---|
| #4285 | Duplicate slot_uri breaks RDF loading | RDF loader |
| #4286 | Attribute shadows a global slot on RDF load | RDF loader |
| #4287 | Custom dateTime type loses the T on load | RDF loader |
| #4288 | rdf:langString written as invalid RDF, silently lost | RDF dumper and loader |
| #4289 | Re-declared imported class: crash or silent slot loss | Generators |
| #4290 | Broken Mermaid links for built-in types | gen-doc |
| #4291 | gen-rdf fetches a missing context.jsonld (404) | gen-rdf |

## Handlingsliste

- [x] 1. Byggescript
- [x] 2. Bygge slida
- [x] 3. Generere, validere, forhandsvise
- [x] 4. Retting

## Avgjerder

- **Eige script, ikkje ein modus i `semic-tooling-pptx.py`:** begge bygg éi slide til éi fil med same OOXML-plumbing (to tilfelle, under DRY-terskelen på tre). Delt modul vil krevje omskriving av det eksisterande scriptet utan eksplisitt løyve.
- **Same layout og metode som tooling-slida:** lys «Content»-layout (dei mørke har tekst baka inn i bakgrunnen), enkle formar, ingen avhengigheiter.
- **Fargekoding:** blå = RDF loader/dumper (U1-U3, U5), lilla = generatorar (U6-U8). Åttande feltet er ei oppsummering (7 issues, reprodusert på 1.12.1 og main).
- **Hyperlenkjer** som eksterne relasjonar i `slide1.xml.rels` (`TargetMode="External"`); tekst «linkml#NNNN» understreka.

## Utført

- `src/tmp/semic-findings-slide.pptx`: éi slide, 7 kort (2 kolonner) med kategori, overskrift og klikkbar lenkje til #4285-#4291, pluss oppsummeringsfelt.
- Byggescript: `src/assets/scripts/demo/slides/semic-findings-pptx.py`.
- Forhandsvist med QuickLook (serif-reservefont; i PowerPoint brukar slida malens temafont). XML og relasjonar velforma; ikkje opna i PowerPoint, og hyperlenkjene er ikkje klikktesta.

