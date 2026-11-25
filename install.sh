#!/usr/bin/env bash
# Install the voxtype + Groq dictation workflow (macOS or Linux).
#
#   ./install.sh          install or update everything with Groq; asks for the key if missing
#   ./install.sh --local  no Groq account: transcribe on this machine, no LLM cleanup
#   ./install.sh --key    only ask for (or replace) the Groq API key
#
# Safe to re-run: it backs up config.toml, keeps your vocabulary.txt and only
# touches the voxtype settings this workflow needs.
# Compatible with the bash 3.2 that ships with macOS.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/voxtype"
CONFIG="$CONFIG_DIR/config.toml"
SKILL_DEST="${SKILL_DEST:-$HOME/.agents/skills/dictation-vocabulary}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
OS="$(uname -s)"

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mAviso:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }

has_key() {
  grep -Eq '^[[:space:]]*remote_api_key[[:space:]]*=[[:space:]]*"[^"]+"' "$CONFIG" 2>/dev/null
}

# First python3 that is 3.11+ (voxtype-vocab needs tomllib)
find_python() {
  local candidate
  for candidate in python3.14 python3.13 python3.12 python3.11 python3 \
                   /opt/homebrew/bin/python3 /usr/local/bin/python3; do
    if command -v "$candidate" >/dev/null 2>&1 &&
       "$candidate" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null; then
      command -v "$candidate"
      return 0
    fi
  done
  return 1
}

ask_key() {
  if [[ ! -t 0 ]]; then
    warn "Falta la API key de Groq y esta terminal no es interactiva."
    warn "Pídele a la persona que ejecute en su propia terminal:  $REPO_DIR/install.sh --key"
    return 0
  fi
  local key=""
  printf 'Pega tu API key de Groq (empieza por gsk_; no se verá al escribir): '
  read -rs key
  printf '\n'
  [[ -n "$key" ]] || { warn "Key vacía: no se ha guardado nada."; return 0; }
  voxtype config set whisper.remote_api_key "$key" >/dev/null
  chmod 600 "$CONFIG"
  say "Key guardada en $CONFIG (permisos 600)."
}

restart_voxtype() {
  "$BIN_DIR/voxtype-vocab" restart || true
}

install_deps() {
  if [[ "$OS" == "Darwin" ]]; then
    command -v brew >/dev/null 2>&1 || die "Necesitas Homebrew: https://brew.sh"
    if ! command -v voxtype >/dev/null 2>&1; then
      say "Instalando voxtype con Homebrew…"
      brew install --cask peteonrails/voxtype/voxtype
    fi
    command -v jq >/dev/null 2>&1 || { say "Instalando jq…"; brew install jq; }
    if ! find_python >/dev/null; then
      say "Instalando Python 3 reciente (el de macOS es demasiado antiguo)…"
      brew install python
    fi
  else
    command -v voxtype >/dev/null 2>&1 ||
      die "Instala voxtype primero siguiendo https://voxtype.io y vuelve a ejecutar este script."
    local missing=""
    command -v jq   >/dev/null 2>&1 || missing="$missing jq"
    command -v curl >/dev/null 2>&1 || missing="$missing curl"
    [[ -z "$missing" ]] || die "Instala con tu gestor de paquetes:$missing"
  fi
  find_python >/dev/null || die "Necesitas Python 3.11 o superior."
}

ensure_config() {
  if [[ "$OS" == "Darwin" && -d "$HOME/Library/Application Support/voxtype" && ! -f "$CONFIG" ]]; then
    warn "Hay una config antigua en ~/Library/Application Support/voxtype; voxtype ahora usa $CONFIG."
  fi
  if [[ ! -f "$CONFIG" ]]; then
    if [[ "$OS" == "Darwin" ]]; then
      die "No existe $CONFIG. Abre voxtype una vez (o ejecuta \`voxtype configure\`), completa el asistente de permisos y tecla, y vuelve a ejecutar este script."
    fi
    die "No existe $CONFIG. Ejecuta \`voxtype setup\` (ver https://voxtype.io) y vuelve a ejecutar este script."
  fi
  local backup
  backup="$CONFIG.bak-$(date +%Y%m%d-%H%M%S)"
  cp -p "$CONFIG" "$backup"
  chmod 600 "$backup"
  say "Copia de seguridad: $backup"
}

install_files() {
  mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$SKILL_DEST/scripts"

  local normalizer="$CONFIG_DIR/normalize-es.sh"
  if [[ -f "$normalizer" ]] && ! cmp -s "$REPO_DIR/normalize-es.sh" "$normalizer"; then
    cp -p "$normalizer" "$normalizer.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  cp "$REPO_DIR/normalize-es.sh" "$normalizer"
  chmod 755 "$normalizer"

  if [[ -f "$CONFIG_DIR/vocabulary.txt" ]]; then
    say "Conservo tu vocabulary.txt actual."
  else
    cp "$REPO_DIR/vocabulary.txt" "$CONFIG_DIR/vocabulary.txt"
  fi

  cp "$REPO_DIR/skills/dictation-vocabulary/SKILL.md" "$SKILL_DEST/SKILL.md"
  cp "$REPO_DIR/skills/dictation-vocabulary/scripts/voxtype-vocab" "$SKILL_DEST/scripts/voxtype-vocab"
  chmod 755 "$SKILL_DEST/scripts/voxtype-vocab"

  # Wrapper pins a Python 3.11+, so the macOS system python3 (3.9) is never used
  local python
  python="$(find_python)"
  rm -f "$BIN_DIR/voxtype-vocab"
  cat > "$BIN_DIR/voxtype-vocab" <<EOF
#!/bin/sh
exec "$python" "$SKILL_DEST/scripts/voxtype-vocab" "\$@"
EOF
  chmod 755 "$BIN_DIR/voxtype-vocab"

  # Claude Code reads ~/.claude/skills; other agents: see README
  if [[ -d "$HOME/.claude" && "$SKILL_DEST" != "$HOME/.claude/skills/dictation-vocabulary" ]]; then
    mkdir -p "$HOME/.claude/skills"
    if [[ ! -e "$HOME/.claude/skills/dictation-vocabulary" ]]; then
      ln -s "$SKILL_DEST" "$HOME/.claude/skills/dictation-vocabulary"
      say "Skill enlazada en ~/.claude/skills/dictation-vocabulary"
    fi
  fi

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR no está en tu PATH. Añade a tu ~/.zshrc o ~/.bashrc:  export PATH=\"$BIN_DIR:\$PATH\"" ;;
  esac
}

configure_voxtype() {
  say "Configurando voxtype para Groq…"
  local pair key value
  for pair in \
    "engine=whisper" \
    "whisper.mode=remote" \
    "whisper.remote_endpoint=https://api.groq.com/openai" \
    "whisper.remote_model=whisper-large-v3" \
    "whisper.language=es" \
    "output.post_process.command=$CONFIG_DIR/normalize-es.sh" \
    "output.post_process.timeout_ms=8000"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    voxtype config set "$key" "$value" >/dev/null || die "voxtype no aceptó $key = $value (mira \`voxtype config schema\`)."
  done
  VOXTYPE_VOCAB_NO_RESTART=1 "$BIN_DIR/voxtype-vocab" sync
  chmod 600 "$CONFIG"
}

# No Groq: keep the model the voxtype wizard downloaded, drop our LLM cleanup.
# The dictionary still works through initial_prompt and replacements.
configure_voxtype_local() {
  say "Configurando voxtype en local (sin Groq)…"
  voxtype config set engine whisper >/dev/null
  voxtype config set whisper.mode local >/dev/null
  voxtype config set whisper.language es >/dev/null
  if [[ "$(voxtype config get output.post_process.command 2>/dev/null)" == "$CONFIG_DIR/normalize-es.sh" ]]; then
    voxtype config unset output.post_process.command >/dev/null
  fi
  VOXTYPE_VOCAB_NO_RESTART=1 "$BIN_DIR/voxtype-vocab" sync
  say "Modelo local actual: $(voxtype config get whisper.model 2>/dev/null || echo '?'). Comprueba que está descargado con \`voxtype info models\`."
}

smoke_test() {
  has_key || return 0
  say "Probando el normalizador con Groq…"
  local out
  if out=$(printf 'eh bueno pues esto es una prueba de git hub' | "$CONFIG_DIR/normalize-es.sh"); then
    say "Groq responde: $out"
  else
    warn "El normalizador falló. Revisa la key y tu conexión; voxtype usará el texto sin limpiar."
  fi
}

if [[ "${1:-}" == "--key" ]]; then
  [[ -f "$CONFIG" ]] || die "No existe $CONFIG; ejecuta antes ./install.sh"
  ask_key
  smoke_test
  restart_voxtype
  exit 0
fi

install_deps
ensure_config
install_files
if [[ "${1:-}" == "--local" ]]; then
  configure_voxtype_local
  restart_voxtype
  say "Hecho (modo local). Si más adelante creas la cuenta de Groq, ejecuta ./install.sh sin --local."
  exit 0
fi
configure_voxtype
has_key || ask_key
smoke_test
restart_voxtype

say "Hecho. Siguientes pasos en el README: permisos de macOS, tecla de dictado y la regla para tu agente (AGENTS-snippet.md)."
