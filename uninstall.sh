#!/usr/bin/env bash
set -euo pipefail

# Remove artifacts managed by install.sh without deleting credentials,
# pre-install backups, or this Git checkout unless explicitly requested.

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
readonly CONFIG_DIR="$CONFIG_HOME/nvim"
readonly PORTABLE_ROOT="$DATA_HOME/nvim-portable"
readonly ENV_PREFIX="${NVIM_ENV_PREFIX:-$PORTABLE_ROOT/env}"
readonly LOCAL_BIN="$HOME/.local/bin"

ASSUME_YES=0
REMOVE_REPO=0

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

  -y, --yes       Do not ask for confirmation
  --remove-repo   Also delete this Git checkout when it is clean
  -h, --help      Show this help

The uninstaller removes the portable tool environment, Neovim data/cache/state,
managed shell blocks, shell plugins, and installer-owned CLI binaries. It keeps
Codex/Claude credentials, pre-install backups, and this repository by default.

Use the same XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_STATE_HOME, XDG_CACHE_HOME, and
NVIM_ENV_PREFIX values that were used during installation.
EOF
}

while (($#)); do
  case "$1" in
    -y|--yes) ASSUME_YES=1 ;;
    --remove-repo) REMOVE_REPO=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

validate_delete_target() {
  local path=$1
  [[ -n "$path" && "$path" != / && "$path" != "$HOME" ]] || \
    die "Refusing unsafe removal target: ${path:-<empty>}"
}

remove_tree() {
  local path=$1
  [[ -e "$path" || -L "$path" ]] || return 0
  validate_delete_target "$path"
  rm -rf -- "$path"
  log "Removed $path"
}

remove_file() {
  local path=$1
  [[ -e "$path" || -L "$path" ]] || return 0
  validate_delete_target "$path"
  rm -f -- "$path"
  log "Removed $path"
}

remove_managed_block() {
  local destination=$1 start='# >>> portable-nvim >>>' end='# <<< portable-nvim <<<' temporary
  [[ -f "$destination" ]] || return 0
  grep -Fq "$start" "$destination" || return 0
  temporary="$(mktemp "${TMPDIR:-/tmp}/nvim-uninstall.XXXXXX")"
  awk -v start="$start" -v end="$end" '
    $0 == start { skipping=1; next }
    $0 == end { skipping=0; next }
    !skipping { print }
  ' "$destination" > "$temporary"
  mv -- "$temporary" "$destination"
  log "Removed managed block from $destination"
}

show_plan() {
  printf 'This will remove:\n'
  printf '  %s\n' \
    "$ENV_PREFIX" \
    "$PORTABLE_ROOT" \
    "$DATA_HOME/nvim" \
    "$STATE_HOME/nvim" \
    "$CACHE_HOME/nvim"
  printf '  portable-nvim blocks in ~/.bashrc, ~/.zshrc, and ~/.tmux.conf\n'
  printf '  the managed Fish symlink, if present\n'
  printf '  the managed Yazi configuration symlink, if present\n'
  printf '  installer-owned micromamba/Codex/Claude binaries, when marked\n'
  if ((REMOVE_REPO)); then
    printf '  repository: %s\n' "$SCRIPT_DIR"
  else
    printf '\nRepository retained: %s\n' "$SCRIPT_DIR"
  fi
  printf 'Credentials and *.pre-nvim-dotfiles/config backups are retained.\n'
}

confirm() {
  ((ASSUME_YES)) && return
  [[ -t 0 ]] || die "Non-interactive shell; rerun with --yes"
  local answer
  read -r -p 'Continue? [y/N] ' answer
  [[ "$answer" == y || "$answer" == Y ]] || { log "Cancelled"; exit 0; }
}

remove_owned_ai_tools() {
  if [[ -f "$PORTABLE_ROOT/codex-installed-by-nvim" ]]; then
    remove_file "$LOCAL_BIN/codex"
    remove_tree "$HOME/.codex/packages/standalone"
  fi
  if [[ -f "$PORTABLE_ROOT/claude-installed-by-nvim" ]]; then
    remove_file "$LOCAL_BIN/claude"
    remove_tree "$HOME/.local/share/claude"
  fi
  return 0
}

remove_config_link() {
  [[ -L "$CONFIG_DIR" ]] || return 0
  local target
  if ! target="$(cd -- "$CONFIG_DIR" 2>/dev/null && pwd -P)"; then
    warn "Keeping unresolved config symlink: $CONFIG_DIR"
    return
  fi
  if [[ "$target" == "$SCRIPT_DIR" ]]; then
    remove_file "$CONFIG_DIR"
  else
    warn "Keeping unrelated config symlink: $CONFIG_DIR -> $target"
  fi
}

remove_repository() {
  ((REMOVE_REPO)) || return 0
  if [[ -d "$SCRIPT_DIR/.git" && -n "$(git -C "$SCRIPT_DIR" status --porcelain)" ]]; then
    die "Repository has uncommitted changes; refusing --remove-repo"
  fi
  cd -- "$HOME"
  remove_tree "$SCRIPT_DIR"
}

main() {
  show_plan
  confirm

  remove_managed_block "$HOME/.bashrc"
  remove_managed_block "$HOME/.zshrc"
  remove_managed_block "$HOME/.tmux.conf"

  local fish_file="$CONFIG_HOME/fish/conf.d/portable-nvim.fish"
  if [[ -L "$fish_file" ]]; then
    remove_file "$fish_file"
  elif [[ -e "$fish_file" ]]; then
    warn "Keeping non-symlink Fish config: $fish_file"
  fi

  local yazi_file="$CONFIG_HOME/yazi/yazi.toml"
  if [[ -L "$yazi_file" && "$(readlink "$yazi_file")" == "$CONFIG_DIR/yazi/yazi.toml" ]]; then
    remove_file "$yazi_file"
  elif [[ -e "$yazi_file" || -L "$yazi_file" ]]; then
    warn "Keeping unrelated Yazi config: $yazi_file"
  fi

  remove_owned_ai_tools
  if [[ -f "$PORTABLE_ROOT/micromamba-installed-by-nvim" ]]; then
    remove_file "$LOCAL_BIN/micromamba"
  fi
  if [[ -f "$PORTABLE_ROOT/mamba-root-created-by-nvim" ]]; then
    remove_tree "$DATA_HOME/mamba"
  fi

  if [[ "$ENV_PREFIX" != "$PORTABLE_ROOT" ]]; then
    remove_tree "$ENV_PREFIX"
  fi
  remove_tree "$DATA_HOME/nvim"
  remove_tree "$STATE_HOME/nvim"
  remove_tree "$CACHE_HOME/nvim"
  remove_tree "$PORTABLE_ROOT"
  remove_config_link

  log "Uninstallation complete"
  printf 'Pre-install backups and AI credentials were preserved.\n'
  printf 'Start a new shell before reinstalling.\n'

  remove_repository
}

main
