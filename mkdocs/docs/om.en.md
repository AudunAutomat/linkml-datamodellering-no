---
i18n:
  source: om.md
  source_hash: sha256:9d0d7e9b4cb138d3d6042cf25e956a70b6be172a2b34bdd6dcc569244162f9fd
---
# About this repository {#om-dette-repoet}

!!! note "Background"

    This repository is developed by the Brønnøysund Register Centre (Brønnøysundregistrene) with the aim of becoming a national resource for information modeling work, in line with
    [Digdir's Framework for Information Management](https://www.digdir.no/informasjonsforvaltning/rammeverk-informasjonsforvaltning/3626) (Rammeverk for informasjonsforvaltning).

    It is intended to make it easier for public bodies and businesses to model, validate and publish concept and information models according to Norwegian and European standards (DCAT-AP-NO, SKOS-AP-NO and more), and to share common tools and models across organizations. 

This repository encourages collaboration and sharing through standardized formats, common tools and a shared infrastructure, following the principle "Easy to do it right!" (Lett å gjere rett!)

Not least, it makes it possible to export models and data in W3C semantic formats, which — together with the use of public ontologies and shared concepts — makes the data inherently linkable across datasets.

## Contact {#kontakt}

**Repository administrator:** Audun Vindenes Egge ([ave@brreg.no](mailto:ave@brreg.no))

## Contribute and give feedback {#bidra-og-gje-tilbakemelding}

- [GOVERNANCE.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/GOVERNANCE.md) —
  roles, authority and how decisions are made
- [CONTRIBUTING.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/CONTRIBUTING.md) —
  how to contribute models, bug fixes or tool development
- [Open a GitHub Issue](https://github.com/AudunAutomat/linkml-datamodellering-no/issues) —
  for bug reports, questions or proposals for new models/features
- [SECURITY.md](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/SECURITY.md) —
  how to report security vulnerabilities

## License {#lisens}

This repository is licensed under the [MIT license](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/LICENSE).
The individual models have their own licenses for use — see the `license` field in each schema.

## Attributions {#attribusjoner}

This repository builds and publishes container images
(`ghcr.io/audunautomat/linkml-local`, `mcp-linkml-validator`, `mcp-linkml-modell-utkast`,
`mcp-linkml-begrep-utkast` and more) and this documentation portal using the
following third-party tools. Tools that are only used internally in CI or in
local build steps — and are never bundled in a published container image or in
the published portal — are omitted.

| Tool | License | Used for |
|---|---|---|
| [LinkML](https://github.com/linkml/linkml) | Apache License 2.0 | Schema validation and generation |
| [rdflib](https://github.com/RDFLib/rdflib) | BSD 3-Clause License | RDF processing |
| [Graphviz](https://gitlab.com/graphviz/graphviz) | Eclipse Public License 2.0 | ER diagram generation |
| [PyYAML](https://github.com/yaml/pyyaml) | MIT License | YAML processing |
| [pytest](https://github.com/pytest-dev/pytest) | MIT License | Testing |
| [openapi-spec-validator](https://github.com/python-openapi/openapi-spec-validator) | Apache License 2.0 | OpenAPI validation |
| [avrotize](https://github.com/clemensv/avrotize) | MIT License | Schema conversion (Avro/XSD and more) |
| [AsyncAPI CLI](https://github.com/asyncapi/cli) | Apache License 2.0 | AsyncAPI specification generation |
| [Python](https://www.python.org/) | PSF License 2.0 | Runtime environment in the container images |
| [mkdocs-material](https://github.com/squidfunk/mkdocs-material) | MIT License | Theme for this documentation portal |
| [Git](https://git-scm.com/) | GNU General Public License v2.0 | `git log` lookups in the python-pytest image (schema creation date for check-scaffold-todo-age.py) |

A complete overview of all tools that have been assessed — including those
that do not require attribution, and why — is available in
[`specs/done/verktoy-lisensoversikt.md`](https://github.com/AudunAutomat/linkml-datamodellering-no/blob/main/specs/done/verktoy-lisensoversikt.md).
