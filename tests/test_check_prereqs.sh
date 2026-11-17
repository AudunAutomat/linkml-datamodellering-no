#!/usr/bin/env bash
# Testar src/assets/scripts/makefile/check-prereqs.bash utan å installere noko:
# stubba kommandoar i ein midlertidig PATH og PREREQS_OS-overstyring dekkjer
# både Darwin- og Linux-grenane. Køyrer på verten (scriptet krev ikkje podman).
#
#   bash tests/test_check_prereqs.sh
#
# Må vere kompatibel med bash 3.2 (macOS). Sjå specs/done/check-prereqs-macos.md.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/src/assets/scripts/makefile/check-prereqs.bash"
# Eksplisitt mal: BSD mktemp (macOS) les ikkje TMPDIR utan mal.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/check-prereqs-test.XXXXXX")" || { echo "mktemp feila" >&2; exit 2; }
[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "ugyldig TMP: '$TMP'" >&2; exit 2; }
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAILED=0
check() { # check <namn> <verdi:0|1>
  if [ "$2" = "0" ]; then echo "  ✓ $1"; PASS=$((PASS+1)); else echo "  ✗ $1"; FAILED=$((FAILED+1)); fi
}
contains() { printf '%s' "$1" | grep -qF -- "$2"; echo $?; }

# Lagar ein stub-bin med dei gitte kommandoane. Argument: katalog, namn=skript...
mkstub() {
  local dir="$1"; shift
  mkdir -p "$dir"
  local spec name body
  for spec in "$@"; do
    name="${spec%%=*}"; body="${spec#*=}"
    printf '#!/bin/sh\n%s\n' "$body" > "$dir/$name"
    chmod +x "$dir/$name"
  done
}

run_script() { # run_script <os> <stubdir>  → set OUT og RC
  OUT=$(PREREQS_OS="$1" PATH="$2:/usr/bin:/bin" bash "$SCRIPT" 2>&1); RC=$?
}

echo "== syntaks"
bash -n "$SCRIPT"; check "bash -n" "$?"

echo "== Darwin: ny make/bash, men utan podman og brew"
mkstub "$TMP/d1" 'make=echo "GNU Make 4.4.1"' 'git=echo "git version 2"' 'jq=echo "jq-1.7"' \
  'bash=exec /bin/bash "$@"'
run_script Darwin "$TMP/d1"
check "exit 1 (feil)"                         "$([ "$RC" = 1 ] && echo 0 || echo 1)"
check "ingen apt-råd på Darwin"               "$([ "$(contains "$OUT" 'apt-get')" = 1 ] && echo 0 || echo 1)"
check "Homebrew-råd for podman"               "$(contains "$OUT" 'brew install podman')"
check "Homebrew manglar"                      "$(contains "$OUT" 'https://brew.sh')"
check "subuid hoppa over på Darwin"           "$([ "$(contains "$OUT" 'usermod')" = 1 ] && echo 0 || echo 1)"
check "macOS-melding"                         "$(contains "$OUT" 'macOS oppdaga')"
check "oppsummering skriven"                  "$(contains "$OUT" 'Åtvaringar:')"

echo "== Darwin: gamal make (3.81)"
mkstub "$TMP/d2" 'make=echo "GNU Make 3.81"' 'git=echo "git version 2"' 'jq=echo "jq-1.7"'
run_script Darwin "$TMP/d2"
check "make < 4 gir feil med brew-råd"        "$(contains "$OUT" 'brew install make')"

echo "== Darwin: podman utan maskin"
mkstub "$TMP/d3" 'make=echo "GNU Make 4.4.1"' 'git=echo "git version 2"' 'jq=echo "jq-1.7"' \
  'podman=case "$1" in --version) echo "podman version 5";; machine) ;; *) exit 1;; esac' \
  'brew=echo "Homebrew 4"'
run_script Darwin "$TMP/d3"
check "machine init-råd"                      "$(contains "$OUT" 'podman machine init')"

echo "== Darwin: maskin stoppa"
mkstub "$TMP/d4" 'make=echo "GNU Make 4.4.1"' 'git=echo "git version 2"' 'jq=echo "jq-1.7"' \
  'podman=case "$1" in --version) echo "podman version 5";; machine) echo false;; *) exit 1;; esac' \
  'brew=echo "Homebrew 4"'
run_script Darwin "$TMP/d4"
check "machine start-råd"                     "$(contains "$OUT" 'podman machine start')"

echo "== Darwin: lite VM-minne gir åtvaring, nok minne gir OK"
PODMAN_STUB='podman=case "$1" in --version) echo "podman version 5";; machine) case "$2" in list) echo true;; inspect) echo MEM;; esac;; run) exit 0;; esac'
mkstub "$TMP/d5" 'make=echo "GNU Make 4.4.1"' 'git=echo "git version 2"' 'jq=echo "jq-1.7"' \
  'brew=echo "Homebrew 4"' "${PODMAN_STUB/MEM/2048}"
run_script Darwin "$TMP/d5"
check "åtvaring ved 2048 MiB"                 "$(contains "$OUT" 'podman machine set --memory 8192')"
mkstub "$TMP/d6" 'make=echo "GNU Make 4.4.1"' 'git=echo "git version 2"' 'jq=echo "jq-1.7"' \
  'brew=echo "Homebrew 4"' "${PODMAN_STUB/MEM/8192}"
run_script Darwin "$TMP/d6"
check "OK ved 8192 MiB"                       "$(contains "$OUT" 'tilstrekkeleg minne (8192 MiB)')"

echo "== python3 utan PyYAML / med PyYAML"
mkstub "$TMP/y1" 'make=echo "GNU Make 4.4.1"' 'python3=case "$1" in --version) echo "Python 3.12";; *) exit 1;; esac'
run_script Darwin "$TMP/y1"
check "Darwin: pip install --user pyyaml"     "$(contains "$OUT" 'pip install --user --break-system-packages pyyaml')"
run_script Linux "$TMP/y1"
check "Linux: apt python3-yaml"               "$(contains "$OUT" 'install python3-yaml')"
mkstub "$TMP/y2" 'make=echo "GNU Make 4.4.1"' 'python3=case "$1" in --version) echo "Python 3.12";; *) exit 0;; esac'
run_script Linux "$TMP/y2"
check "python3 med PyYAML gir OK"             "$(contains "$OUT" 'python3 med PyYAML tilgjengeleg')"

echo "== Linux: apt-råd og subuid-sjekk"
mkstub "$TMP/l1" 'make=echo "GNU Make 4.3"'
run_script Linux "$TMP/l1"
check "apt-råd for podman"                    "$(contains "$OUT" 'apt-get')"
check "podman system migrate-råd ikkje blanda inn utan podman" "$(contains "$OUT" 'kan ikkje testast')"
check "ingen brew-råd på Linux"               "$([ "$(contains "$OUT" 'brew install')" = 1 ] && echo 0 || echo 1)"

echo "== df-feil gir åtvaring, ikkje stille død"
mkstub "$TMP/df" 'make=echo "GNU Make 4.4.1"' 'df=exit 1'
run_script Linux "$TMP/df"
check "oppsummering skriven trass df-feil"    "$(contains "$OUT" 'Åtvaringar:')"
check "df-åtvaring"                           "$(contains "$OUT" 'Kunne ikkje lese ledig diskplass')"

echo
echo "Bestått: $PASS  Feila: $FAILED"
[ "$FAILED" -eq 0 ]
