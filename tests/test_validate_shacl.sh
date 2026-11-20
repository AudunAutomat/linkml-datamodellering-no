#!/usr/bin/env bash
# Testar `make validate-shacl`: gyldig data gir exit 0 og «Conforms: True»,
# ugyldig data (manglar påkravd ex:navn) gir exit != 0 og «Conforms: False»,
# og manglande argument/filer gir exit != 0 med ei feilmelding. Krev podman og
# python-pytest-imaget (make build-docker-python).
#
#   bash tests/test_validate_shacl.sh
#
# Køyrer ikkje i `make test` (som er per skjema); køyr manuelt etter endring i
# validate-shacl eller pyshacl-versjonen.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2
FX=tests/fixtures
SCHEMA=src/linkml/referanse/referansemodell-bronze/referansemodell-bronze-schema.yaml

PASS=0
FAILED=0
check() { # check <namn> <0|1>
  if [ "$2" = "0" ]; then echo "  ✓ $1"; PASS=$((PASS+1)); else echo "  ✗ $1"; FAILED=$((FAILED+1)); fi
}
run() { OUT=$(make --no-print-directory validate-shacl "$@" 2>&1); RC=$?; }
has() { printf '%s' "$OUT" | grep -qF -- "$1"; echo $?; }

echo "gyldig data"
run SCHEMA="$SCHEMA" SHAPES=$FX/validate-shacl-shapes.ttl DATA=$FX/validate-shacl-gyldig.ttl
check "exit 0" "$([ "$RC" = 0 ]; echo $?)"
check "Conforms: True" "$(has 'Conforms: True')"

echo "ugyldig data"
run SCHEMA="$SCHEMA" SHAPES=$FX/validate-shacl-shapes.ttl DATA=$FX/validate-shacl-ugyldig.ttl
check "exit != 0" "$([ "$RC" != 0 ]; echo $?)"
check "Conforms: False" "$(has 'Conforms: False')"
check "peikar på ex:navn" "$(has 'navn')"

echo "feilhandtering"
run
check "manglar SCHEMA gir exit != 0" "$([ "$RC" != 0 ]; echo $?)"
check "manglar SCHEMA gir bruksmelding" "$(has 'Bruk: make validate-shacl')"
run SCHEMA="$SCHEMA" SHAPES=$FX/validate-shacl-shapes.ttl
check "standard DATA som manglar gir melding" "$(has 'Fann ikkje datafila')"
run SCHEMA="$SCHEMA" SHAPES=$FX/finst-ikkje.ttl DATA=$FX/validate-shacl-gyldig.ttl
check "manglande shapes gir exit != 0" "$([ "$RC" != 0 ]; echo $?)"
check "manglande shapes gir melding" "$(has 'Fann ikkje shapes-fila')"
run SCHEMA="$SCHEMA" SHAPES=$FX/validate-shacl-shapes.ttl DATA=$FX/finst-ikkje.ttl
check "manglande data gir exit != 0" "$([ "$RC" != 0 ]; echo $?)"
check "manglande data gir melding" "$(has 'Fann ikkje datafila')"

echo
echo "Bestått: $PASS, feila: $FAILED"
[ "$FAILED" = 0 ]
