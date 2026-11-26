# SEMIC-slide: «easy to do the right thing»

## Bakgrunn

Ei ny slide i SEMIC 2026-malen (`src/tmp/PPT TEMPLATE SEMIC 2026 .pptx`) som presenterer verktøyet rundt LinkML. Spørsmålet «With LinkML at its core, can we make tooling that enables "easy to do the right thing"?» er overskrift, og åtte påstandar er illustrerte grafisk (hub-and-spoke med nettverksstil frå malen), ikkje som punktliste.

Avklart med brukaren: éi slide, ny `.pptx` i `src/tmp/`, påstandane kortast til stikkord (3-6 ord).

## Steg

1. Kartlegg malen (layoutar, bakgrunnar, fargar, fontar) med `slide_text.py` og `thumbnail.py`.
2. Vel layout og lag stikkord for dei åtte påstandane.
3. Bygg slida frå malen: hub («LinkML») i midten, åtte noder med ikon rundt, kantar i same stil som nettverksgrafikken i malen.
4. Valider (`validate.py --original`), render til bilete og gjennomgå visuelt.
5. Rett opp feil, lever fila.

## Stikkord

| Påstand | Stikkord |
|---|---|
| Is opensource and can be used by anyone | Open source |
| Uses automation to generate additional value from a datamodel | Generate from the model |
| Validate against profiles (standards, regulations, FAIR) | Validate against profiles |
| Analyze the model to identify anomalies | Analyze for anomalies |
| Bridge between traditional and semantic formats | Bridge to semantic formats |
| Publish model and concepts to public data catalogs | Publish to data catalogs |
| Cooperate across organizations | Cooperate across organizations |
| Enables the use of AI in the datamodelling process | AI in the modelling process |

## Handlingsliste

- [x] 1. Kartlegg malen
- [x] 2. Velje layout
- [x] 3. Bygge slida
- [x] 4. Validere og rendre
- [x] 5. Visuell gjennomgang og retting

## Avgjerder

- **Layout «Content» (lys), ikkje den mørke «Title Only».** Dei mørke layoutane i malen (Title Only, Questions, Title) har teksten («THANK YOU», «QUESTIONS?») baka inn i bakgrunnsbiletet, så han skin gjennom slida. «Content» har ei rein bakgrunn.
- **Ikon bygde av enkle former (ellipse, roundRect, can, leftRightArrow, star4), ikkje heart/gear6/donut/egendefinert geometri.** QuickLook (einaste tilgjengelege renderar) teiknar ikkje dei siste; former som teiknar trygt gir verifisert forhandsvising.
- **Éi slide i fila.** Dei ti malslidene er fjerna; layout, master og tema frå malen er uendra.
- **Bygd med Python (stdlib) direkte mot OOXML.** `node`, `python-pptx` og `soffice` finst ikkje, og podman er blokkert i sandkassen; ingen avhengigheiter vart installerte.
- **Stikkorda er justerte frå utkastet i spec-tabellen**: «Generate value from the model», «Validate against standards and FAIR», «Open source, for anyone».

## Utført

- `src/tmp/semic-tooling-slide.pptx`: éi slide, spørsmålet som tittel, «LinkML» som nav, åtte noder med ikon og stikkord i bane rundt (med klokka: open source, generering, validering, analyse, bru til semantikk, publisering, samarbeid, AI).
- Byggescript: `src/assets/scripts/demo/slides/semic-tooling-pptx.py` (stdlib, `python3 -I`; same utdata som den leverte fila).
- Forhandsvist med QuickLook. Fonten i forhandsvisinga er ein serif-reserve; i PowerPoint brukar slida malens temafont. Ikkje opna i PowerPoint, og `validate.py` er ikkje køyrt (manglar python-pptx/defusedxml).

