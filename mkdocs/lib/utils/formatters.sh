#!/usr/bin/env bash
# Formateringsfunksjonar for domene- og artefaktlabels
set -euo pipefail

domain_label() {
    case "$1" in
        felles)  t domene.felles; echo ;;
        referanse) t domene.referanse; echo ;;
        ap-no)   t domene.ap_no; echo ;;
        begrepskatalog) t domene.begrepskatalog; echo ;;
        modellkatalog)   t domene.modellkatalog; echo ;;
        ngr)     t domene.ngr; echo ;;
        fint)    t domene.fint; echo ;;
        samt)    t domene.samt; echo ;;
        fair)    t domene.fair; echo ;;
        oreg)    t domene.oreg; echo ;;
        *)     echo "$1" | awk '{print toupper($0)}' ;;
    esac
}

artifact_label() {
    case "$1" in
        shapes.ttl)     t artefakt.shapes_ttl; echo ;;
        ontology.ttl)   t artefakt.ontology_ttl; echo ;;
        schema.ttl)     t artefakt.schema_ttl; echo ;;
        context.jsonld) t artefakt.context_jsonld; echo ;;
        schema.json)    t artefakt.schema_json; echo ;;
        schema.xsd)     t artefakt.schema_xsd; echo ;;
        openapi.yaml)   t artefakt.openapi_yaml; echo ;;
        asyncapi.yaml)  t artefakt.asyncapi_yaml; echo ;;
        model.py)       t artefakt.model_py; echo ;;
        schema.proto)   t artefakt.schema_proto; echo ;;
        schema.graphql) t artefakt.schema_graphql; echo ;;
        erdiagram.md)   t artefakt.erdiagram_md; echo ;;
        eksempel.ttl)   t artefakt.eksempel_ttl; echo ;;
        *)              echo "$1" ;;
    esac
}
