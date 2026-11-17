#!/usr/bin/env bash
# Sjekkar at alle føresetnader for lokal utvikling er oppfylte.
# Designa for å køyrast standalone (bash check-prereqs.bash), utan at
# make/podman er installerte frå før — ikkje legg til ei reell
# make-avhengigheit (t.d. $(MAKE)-kall) i dette scriptet.
#
# Støtta miljø: Linux/WSL2 (apt) og macOS (Homebrew). Scriptet må vere
# kompatibelt med bash 3.2 (macOS sin /bin/bash), sidan det vert køyrt
# før Homebrew-bash er installert — ikkje bruk mapfile, declare -A o.l.
#
# PREREQS_OS (valfri): overstyrer `uname -s` (Linux|Darwin). Brukt av
# tests/test_check_prereqs.sh for å dekkje begge grenane.
# Sjå specs/done/check-prereqs-macos.md.
set -euo pipefail

OK=0
WARN=0
FAIL=0

ok()   { echo "  ✓ $1"; ((OK++))   || true; }
warn() { echo "  ⚠ $1"; ((WARN++)) || true; }
fail() { echo "  ✗ $1"; ((FAIL++)) || true; }

OS="${PREREQS_OS:-$(uname -s)}"
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

# install_hint <pakke> — OS-spesifikt installasjonsråd.
install_hint() {
  local pkg="$1"
  if [ "$OS" = "Darwin" ]; then
    case "$pkg" in
      git)    echo "brew install git (eller: xcode-select --install)" ;;
      # Homebrew har ingen pyyaml-formel, og Homebrew-Python er «externally
      # managed» (PEP 668) — pip må til brukarmappa med --break-system-packages.
      pyyaml) echo "python3 -m pip install --user --break-system-packages pyyaml" ;;
      *)      echo "brew install ${pkg}" ;;
    esac
  else
    case "$pkg" in
      pyyaml) pkg="python3-yaml" ;;
    esac
    echo "sudo apt-get update && sudo apt-get -y install ${pkg}"
  fi
}

echo ""
echo "=== make check-prereqs ==="
echo ""

# Homebrew (berre macOS)
HAVE_BREW=false
if [ "$OS" = "Darwin" ]; then
  if command -v brew &>/dev/null; then
    HAVE_BREW=true
    ok "Homebrew tilgjengeleg ($(brew --version 2>/dev/null | head -1 || echo ukjend versjon))"
  else
    fail "Homebrew ikkje funne. Følg installasjonsinstruksjonen på https://brew.sh og køyr scriptet på nytt"
  fi
fi

# GNU make (macOS leverer Apple sin GNU Make 3.81 — krev >= 4.0)
if make --version 2>/dev/null | grep -q "GNU Make"; then
  MAKE_VERSION_LINE=$(make --version 2>/dev/null | head -1 || true)
  MAKE_MAJOR=$(echo "$MAKE_VERSION_LINE" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.[0-9]+/) {split($i,v,"."); print v[1]; exit}}')
  if [ "$OS" = "Darwin" ] && [ "${MAKE_MAJOR:-0}" -lt 4 ]; then
    fail "GNU make er for gamal (${MAKE_VERSION_LINE}) — treng >= 4.0 (Apple leverer 3.81). Installer: brew install make, og legg til i ~/.zshrc: export PATH=\"\$(brew --prefix make)/libexec/gnubin:\$PATH\" (eller bruk 'gmake')"
  else
    ok "GNU make tilgjengeleg (${MAKE_VERSION_LINE})"
  fi
else
  fail "GNU make ikkje funne. Installer: $(install_hint make)"
fi

# bash >= 4 (scripta brukar mapfile og assosiative arrays; macOS leverer 3.2).
# Sjekkar bash-en som står først i PATH — same som Makefile brukar.
BASH_MAJOR=$(bash -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null || echo 0)
if [ "${BASH_MAJOR:-0}" -ge 4 ]; then
  ok "bash >= 4 tilgjengeleg ($(bash -c 'echo "$BASH_VERSION"' 2>/dev/null))"
else
  fail "bash i PATH er for gamal (versjon $(bash -c 'echo "$BASH_VERSION"' 2>/dev/null || echo ukjend), treng >= 4). Installer: $(install_hint bash), og legg til i ~/.zshrc: export PATH=\"\$(brew --prefix)/bin:\$PATH\""
fi

# Git
if command -v git &>/dev/null; then
  ok "Git tilgjengeleg ($(git --version))"
else
  fail "Git ikkje funne. Installer: $(install_hint git)"
fi

# jq
if command -v jq &>/dev/null; then
  ok "jq tilgjengeleg ($(jq --version))"
else
  fail "jq ikkje funne. Installer: $(install_hint jq)"
fi

# python3 + PyYAML på verten (mkdocs/publish.sh og scripta det kallar, t.d.
# i18n_strings.py, køyrer python3 direkte på verten og importerer yaml).
# Ubuntu/WSL har python3-yaml som standard; macOS har det ikkje.
if command -v python3 &>/dev/null; then
  if python3 -c 'import yaml' &>/dev/null; then
    ok "python3 med PyYAML tilgjengeleg ($(python3 --version 2>&1))"
  else
    fail "python3 manglar PyYAML (treng for 'make docs-publish'). Installer: $(install_hint pyyaml)"
  fi
else
  fail "python3 ikkje funne. Installer: $(install_hint python3)"
fi

# Podman
PODMAN_OK=false
if command -v podman &>/dev/null; then
  ok "Podman tilgjengeleg ($(podman --version))"
  PODMAN_OK=true
else
  fail "Podman ikkje funne. Installer: $(install_hint podman)"
fi

# Podman-køyring
PODMAN_RUNS=false
if [ "$OS" = "Darwin" ]; then
  # På macOS køyrer Podman i ei Linux-VM (podman machine) — diagnose trinnvis.
  if $PODMAN_OK; then
    MACHINES=$(podman machine list --format '{{.Running}}' 2>/dev/null || true)
    if [ -z "$MACHINES" ]; then
      fail "Ingen Podman-maskin finst. Køyr: podman machine init && podman machine start"
    elif ! echo "$MACHINES" | grep -q "true"; then
      fail "Podman-maskina køyrer ikkje. Køyr: podman machine start"
    elif podman run --rm --quiet alpine echo ok &>/dev/null; then
      ok "Podman-maskina køyrer og kan starte containerar"
      PODMAN_RUNS=true
    else
      fail "Podman-maskina køyrer, men 'podman run alpine' feila. Sjekk 'podman info' og nettverkstilgang (ghcr.io/docker.io)"
    fi
  fi
else
  # Podman rootless (Linux/WSL2)
  if podman run --rm --quiet alpine echo ok &>/dev/null; then
    ok "Podman rootless fungerer"
    PODMAN_RUNS=true
  elif $PODMAN_OK; then
    fail "Podman rootless fungerer ikkje. Prøv: podman system migrate"
  else
    fail "Podman rootless kan ikkje testast (Podman manglar)"
  fi
fi

# /etc/subuid og /etc/subgid (Linux; på macOS ligg dette inni Podman-VM-en)
if [ "$OS" = "Darwin" ]; then
  ok "User namespace-mapping handtert av Podman-VM-en (ikkje relevant på macOS)"
else
  USER_NAME=$(id -un)
  if grep -q "^${USER_NAME}:" /etc/subuid 2>/dev/null && grep -q "^${USER_NAME}:" /etc/subgid 2>/dev/null; then
    ok "User namespace-mapping konfigurert (/etc/subuid + /etc/subgid)"
  else
    warn "User namespace-mapping manglar for '${USER_NAME}'. Prøv: sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 ${USER_NAME}"
  fi
fi

# Miljø
if $IS_WSL; then
  ok "WSL2-miljø oppdaga"
elif [ "$OS" = "Darwin" ]; then
  ok "macOS oppdaga (Podman køyrer i VM via 'podman machine')"
else
  warn "Ikkje WSL2 eller macOS — skript er primært testa i WSL2 og macOS, men kan fungere på vanleg Linux"
fi

# macOS: heimekatalogen må vere delt med Podman-VM-en (alle make-targets
# monterer repoet med -v).
if [ "$OS" = "Darwin" ] && $PODMAN_RUNS; then
  if podman run --rm --quiet -v "$PWD:/w:ro" alpine ls /w &>/dev/null; then
    ok "Repoet kan monterast i Podman-VM-en"
  else
    warn "Kunne ikkje montere $PWD i Podman-VM-en. Hald repoet under heimekatalogen din (delt som standard), eller sjekk 'podman machine init --volume'"
  fi
fi

# macOS: Podman-VM-en sitt minne. Standard (2 GiB) er for lite for parallelle
# generatorar/testar — containerar vert OOM-drepne (exit 137) og `make test`
# gir mange falske feil. Åtvarar under 4 GiB; 8 GiB er tilrådd.
if [ "$OS" = "Darwin" ] && $PODMAN_RUNS; then
  VM_MEM_MB=$(podman machine inspect --format '{{.Resources.Memory}}' 2>/dev/null | head -1 || true)
  case "${VM_MEM_MB:-}" in
    ''|*[!0-9]*)
      warn "Kunne ikkje lese minnet til Podman-VM-en (podman machine inspect)"
      ;;
    *)
      if [ "$VM_MEM_MB" -ge 4096 ]; then
        ok "Podman-VM har tilstrekkeleg minne (${VM_MEM_MB} MiB)"
      else
        warn "Podman-VM har berre ${VM_MEM_MB} MiB minne — containerar kan bli OOM-drepne (exit 137) under parallelle køyringar som 'make test'. Auk til 8 GiB: podman machine stop && podman machine set --memory 8192 && podman machine start"
      fi
      ;;
  esac
fi

# WSL2 mirrored nettverksmodus (podman sin pasta-bakend + WSL2 sin NAT-baserte
# localhost-videresending har eit kjent samspelsproblem — sjå COMMANDS.md §
# docs-serve). Berre relevant i WSL2.
if $IS_WSL; then
  if command -v wslinfo &>/dev/null; then
    NET_MODE=$(wslinfo --networking-mode 2>/dev/null || echo "ukjend")
    if [ "$NET_MODE" = "mirrored" ]; then
      ok "WSL2 nettverksmodus er 'mirrored'"
    else
      warn "WSL2 nettverksmodus er '${NET_MODE}', ikkje 'mirrored'. http://localhost:<port> (t.d. 'make docs-serve') kan feile i nettlesaren på Windows-verten. Fiks: legg til 'networkingMode=mirrored' under [wsl2] i C:\\Users\\<brukar>\\.wslconfig, køyr 'wsl --shutdown' frå Windows PowerShell, og start WSL2 på nytt. Sjå COMMANDS.md § docs-serve."
    fi
  else
    warn "Kan ikkje avgjere WSL2 nettverksmodus ('wslinfo' ikkje funne — krev nyare WSL2-versjon). Om http://localhost:<port> (t.d. 'make docs-serve') ikkje fungerer i nettlesaren på Windows-verten, sjå COMMANDS.md § docs-serve for mirrored-modus-fiks."
  fi
fi

# Diskplass (>= 5 GB). Portabel (POSIX df -P, KiB) — GNU-spesifikke `df -BG`
# finst ikkje på macOS. Aldri stille død: feil gir ei synleg åtvaring.
AVAIL_KB=$(df -Pk . 2>/dev/null | awk 'NR==2 {print $4}' || true)
if [ -z "${AVAIL_KB:-}" ]; then
  warn "Kunne ikkje lese ledig diskplass (df -Pk feila)"
else
  AVAIL_GB=$((AVAIL_KB / 1048576))
  if [ "$AVAIL_GB" -ge 5 ]; then
    ok "Tilstrekkeleg diskplass (${AVAIL_GB} GB ledig)"
  else
    fail "For lite diskplass (${AVAIL_GB} GB ledig, treng minst 5 GB)"
  fi
  if [ "$OS" = "Darwin" ]; then
    warn "Diskplass-sjekken gjeld verts-disken. Podman-VM-en har eigen disk (podman machine init --disk-size <GB>)"
  fi
fi

echo ""
printf "  OK: %d  Åtvaringar: %d  Feil: %d\n" "$OK" "$WARN" "$FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "  → Rett feilane ovanfor før du går vidare."
  exit 1
fi
