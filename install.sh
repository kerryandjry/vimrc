#!/usr/bin/env bash
set -euo pipefail

# Portable bootstrap for macOS, Linux workstations, and unprivileged clusters.
# It never needs sudo: missing tools are installed in a Conda-compatible environment.

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly LOCAL_BIN="$HOME/.local/bin"
readonly ENV_PREFIX="${NVIM_ENV_PREFIX:-$DATA_HOME/nvim-portable/env}"
readonly MANAGED_MAMBA_BIN="$LOCAL_BIN/micromamba"

PACKAGE_MANAGER_BIN=''

INSTALL_PACKAGES=1
INSTALL_SHELL=1
SYNC_PLUGINS=1
INSTALL_AI_TOOLS=0
MINIMAL=0
UPDATE=0

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --minimal       Install only Neovim and command-line essentials
  --update        Update the managed tools, plugins, and Treesitter parsers
  --no-packages   Do not install missing command-line tools
  --no-shell      Do not add managed blocks to shell/tmux configuration
  --no-plugins    Do not run lazy.nvim sync
  --with-ai-tools Install the optional Codex and Claude Code CLIs
  -h, --help      Show this help

Environment:
  NVIM_ENV_PREFIX   Override the user-local tool environment directory
  XDG_CONFIG_HOME   Override ~/.config
  XDG_DATA_HOME     Override ~/.local/share
EOF
}

while (($#)); do
  case "$1" in
    --minimal) MINIMAL=1 ;;
    --update) UPDATE=1 ;;
    --no-packages) INSTALL_PACKAGES=0 ;;
    --no-shell) INSTALL_SHELL=0 ;;
    --no-plugins) SYNC_PLUGINS=0 ;;
    --with-ai-tools) INSTALL_AI_TOOLS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

download() {
  local url=$1 destination=$2
  if command -v curl >/dev/null 2>&1; then
    curl -fL --retry 3 --connect-timeout 15 "$url" -o "$destination"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$destination" "$url"
  else
    die "curl or wget is required for the initial bootstrap"
  fi
}

have_modern_nvim() {
  command -v nvim >/dev/null 2>&1 || return 1
  nvim --clean --headless "+lua if vim.fn.has('nvim-0.12') ~= 1 then vim.cmd('cquit') end" +qa \
    >/dev/null 2>&1
}

need_portable_env() {
  have_modern_nvim || return 0
  local command_name
  for command_name in git rg fd cc zsh; do
    command -v "$command_name" >/dev/null 2>&1 || return 0
  done
  if ((MINIMAL == 0)); then
    for command_name in lazygit yazi clangd lua-language-server pyright-langserver cmake-language-server ruff tree-sitter starship; do
      command -v "$command_name" >/dev/null 2>&1 || return 0
    done
    command -v clang++ >/dev/null 2>&1 || command -v g++ >/dev/null 2>&1 || return 0
  fi
  return 1
}

install_micromamba() {
  local platform arch archive_url release_url temporary downloaded_bin
  case "$(uname -s)" in
    Darwin) platform=osx ;;
    Linux) platform=linux ;;
    *) die "Unsupported operating system: $(uname -s)" ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64) arch=64 ;;
    arm64) [[ "$platform" == osx ]] && arch=arm64 || arch=aarch64 ;;
    aarch64) arch=aarch64 ;;
    ppc64le) arch=ppc64le ;;
    *) die "Unsupported CPU architecture: $(uname -m)" ;;
  esac

  mkdir -p "$LOCAL_BIN"
  temporary="$(mktemp -d "${TMPDIR:-/tmp}/nvim-bootstrap.XXXXXX")"
  trap 'rm -rf "$temporary"' RETURN
  archive_url="https://micro.mamba.pm/api/micromamba/${platform}-${arch}/latest"
  release_url="https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-${platform}-${arch}"
  log "Downloading micromamba (${platform}-${arch})"
  if download "$archive_url" "$temporary/micromamba.tar.bz2" \
      && tar -xjf "$temporary/micromamba.tar.bz2" -C "$temporary" bin/micromamba; then
    downloaded_bin="$temporary/bin/micromamba"
  else
    warn "micro.mamba.pm is unavailable; trying the official GitHub release"
    download "$release_url" "$temporary/micromamba" || die \
      "Could not download micromamba. Configure HTTPS_PROXY, provide micromamba/mamba/conda on PATH, or install $MANAGED_MAMBA_BIN manually"
    downloaded_bin="$temporary/micromamba"
  fi

  chmod 0755 "$downloaded_bin"
  "$downloaded_bin" --version >/dev/null 2>&1 || die "Downloaded micromamba binary could not run on this system"
  install -m 0755 "$downloaded_bin" "$MANAGED_MAMBA_BIN"
  PACKAGE_MANAGER_BIN="$MANAGED_MAMBA_BIN"
  mkdir -p "$DATA_HOME/nvim-portable"
  [[ -d "$DATA_HOME/mamba" ]] || touch "$DATA_HOME/nvim-portable/mamba-root-created-by-nvim"
  touch "$DATA_HOME/nvim-portable/micromamba-installed-by-nvim"
  rm -rf "$temporary"
  trap - RETURN
}

select_package_manager() {
  local manager resolved
  if [[ -x "$MANAGED_MAMBA_BIN" ]]; then
    if "$MANAGED_MAMBA_BIN" --version >/dev/null 2>&1; then
      PACKAGE_MANAGER_BIN="$MANAGED_MAMBA_BIN"
      return
    fi
    warn "Ignoring an unusable micromamba binary at $MANAGED_MAMBA_BIN"
  fi

  for manager in micromamba mamba conda; do
    if resolved="$(command -v "$manager" 2>/dev/null)" \
        && "$manager" --version >/dev/null 2>&1; then
      PACKAGE_MANAGER_BIN="$manager"
      log "Using existing package manager: $resolved"
      return
    fi
  done

  install_micromamba
}

install_portable_tools() {
  select_package_manager

  local packages=(
    "nvim>=0.12,<0.13" git curl ripgrep fd-find "tree-sitter-cli>=0.26.1" clang-tools zsh
  )
  if ((MINIMAL == 0)); then
    packages+=(
      tmux lazygit yazi fzf bat zoxide starship trash-cli bash-completion cmake ninja nodejs python
      lua-language-server pyright cmake-language-server ruff pynvim
    )
  fi

  log "Installing portable tools into $ENV_PREFIX"
  if [[ -d "$ENV_PREFIX/conda-meta" ]]; then
    "$PACKAGE_MANAGER_BIN" install -y -p "$ENV_PREFIX" -c conda-forge "${packages[@]}"
  else
    "$PACKAGE_MANAGER_BIN" create -y -p "$ENV_PREFIX" -c conda-forge "${packages[@]}"
  fi

  # conda-forge versions clang++ (for example clang++-22) but does not always
  # provide the unversioned compiler names unless the environment is activated.
  # This setup intentionally works with PATH only, so create local aliases.
  local candidate cxx=''
  if [[ ! -x "$ENV_PREFIX/bin/clang++" ]]; then
    for candidate in "$ENV_PREFIX"/bin/clang++-*; do
      [[ -x "$candidate" ]] && cxx=$candidate
    done
    [[ -n "$cxx" ]] && ln -sfn "${cxx##*/}" "$ENV_PREFIX/bin/clang++"
  fi
  [[ -x "$ENV_PREFIX/bin/clang" && ! -e "$ENV_PREFIX/bin/cc" ]] && ln -s clang "$ENV_PREFIX/bin/cc"
  [[ -x "$ENV_PREFIX/bin/clang++" && ! -e "$ENV_PREFIX/bin/c++" ]] && ln -s clang++ "$ENV_PREFIX/bin/c++"

  export PATH="$ENV_PREFIX/bin:$LOCAL_BIN:$PATH"
}

install_ai_tools() {
  local temporary installer

  temporary="$(mktemp -d "${TMPDIR:-/tmp}/nvim-ai-tools.XXXXXX")"
  trap 'rm -rf "$temporary"' RETURN

  if command -v codex >/dev/null 2>&1; then
    log "Codex CLI is already installed; its updater will manage upgrades"
  else
    installer="$temporary/codex-install.sh"
    log "Installing optional Codex CLI"
    download "https://chatgpt.com/codex/install.sh" "$installer"
    sh "$installer"
    hash -r 2>/dev/null || true
    command -v codex >/dev/null 2>&1 || die "Codex installer completed but codex is not on PATH"
    mkdir -p "$DATA_HOME/nvim-portable"
    touch "$DATA_HOME/nvim-portable/codex-installed-by-nvim"
  fi

  # Refresh command lookup after an installer adds a new executable to PATH.
  hash -r 2>/dev/null || true
  if command -v claude >/dev/null 2>&1; then
    log "Claude Code is already installed; its updater will manage upgrades"
  else
    installer="$temporary/claude-install.sh"
    log "Installing optional Claude Code CLI"
    download "https://claude.ai/install.sh" "$installer"
    bash "$installer"
    hash -r 2>/dev/null || true
    command -v claude >/dev/null 2>&1 || die "Claude installer completed but claude is not on PATH"
    mkdir -p "$DATA_HOME/nvim-portable"
    touch "$DATA_HOME/nvim-portable/claude-installed-by-nvim"
  fi

  rm -rf "$temporary"
  trap - RETURN
}

sync_shell_plugins() {
  ((MINIMAL == 0)) || return 0
  local plugin_root="$DATA_HOME/nvim-portable/zsh" name url destination
  mkdir -p "$plugin_root"
  while read -r name url; do
    destination="$plugin_root/$name"
    if [[ ! -d "$destination/.git" ]]; then
      log "Installing zsh plugin: $name"
      git clone --depth 1 "$url" "$destination"
    elif ((UPDATE)); then
      if [[ -n "$(git -C "$destination" status --porcelain)" ]]; then
        warn "Skipping modified zsh plugin checkout: $destination"
      else
        log "Updating zsh plugin: $name"
        git -C "$destination" pull --ff-only
      fi
    fi
  done <<'EOF'
zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
fast-syntax-highlighting https://github.com/zdharma-continuum/fast-syntax-highlighting.git
EOF
}

backup_once() {
  local path=$1
  [[ ! -e "$path" || -e "$path.pre-nvim-dotfiles" ]] || cp -p "$path" "$path.pre-nvim-dotfiles"
}

install_managed_block() {
  local destination=$1 block=$2 start='# >>> portable-nvim >>>' end='# <<< portable-nvim <<<' temporary
  mkdir -p "$(dirname "$destination")"
  touch "$destination"
  if grep -Fq "$start" "$destination"; then
    temporary="$(mktemp "${TMPDIR:-/tmp}/nvim-shell.XXXXXX")"
    awk -v start="$start" -v end="$end" '
      $0 == start { skipping=1; next }
      $0 == end { skipping=0; next }
      !skipping { print }
    ' "$destination" > "$temporary"
    mv "$temporary" "$destination"
  else
    backup_once "$destination"
  fi
  printf '\n%s\n%s\n%s\n' "$start" "$block" "$end" >> "$destination"
}

link_config() {
  mkdir -p "$(dirname "$CONFIG_DIR")"
  if [[ "$SCRIPT_DIR" == "$CONFIG_DIR" ]]; then
    return
  fi
  if [[ -L "$CONFIG_DIR" && "$(cd -- "$CONFIG_DIR" && pwd -P)" == "$SCRIPT_DIR" ]]; then
    return
  fi
  if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
    local backup="${CONFIG_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
    warn "Moving existing Neovim config to $backup"
    mv "$CONFIG_DIR" "$backup"
  fi
  ln -s "$SCRIPT_DIR" "$CONFIG_DIR"
}

install_shell_config() {
  local source_line='[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/shell/common.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/shell/common.sh"'
  install_managed_block "$HOME/.zshrc" "$source_line
[ -r \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/zshrc\" ] && . \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/zshrc\""
  install_managed_block "$HOME/.bashrc" "$source_line
[ -r \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/bashrc\" ] && . \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/bashrc\""
  install_managed_block "$HOME/.tmux.conf" "source-file \"$CONFIG_DIR/tmux.conf\""

  local fish_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d"
  local fish_file="$fish_dir/portable-nvim.fish"
  mkdir -p "$fish_dir"
  backup_once "$fish_file"
  ln -sfn "$CONFIG_DIR/shell/config.fish" "$fish_file"
}

sync_plugins() {
  have_modern_nvim || die "Neovim 0.12.x is required by this configuration"
  local active_config
  active_config="$(nvim --clean --headless -i NONE \
    "+lua io.stdout:write(vim.fn.stdpath('config'))" +qa 2>/dev/null)"
  [[ "$active_config" == "$CONFIG_DIR" ]] || die \
    "Neovim is using $active_config instead of $CONFIG_DIR (check NVIM_APPNAME and XDG_CONFIG_HOME)"
  nvim --headless -i NONE \
    "+lua if vim.g.portable_nvim_loaded ~= 1 then vim.cmd('cquit') end" +qa \
    >/dev/null 2>&1 || die "Neovim could not fully load $CONFIG_DIR/init.lua"

  if ((UPDATE)); then
    log "Updating lazy.nvim plugins"
    nvim --headless "+Lazy! update" +qa
    log "Updating Treesitter parsers"
    nvim --headless -i NONE "+PortableTSUpdate" +qa
  else
    log "Synchronizing lazy.nvim plugins"
    nvim --headless "+Lazy! sync" +qa
    log "Installing pinned Treesitter parsers"
    nvim --headless -i NONE "+PortableTSInstall" +qa
  fi
}

main() {
  if ((EUID == 0)) && [[ -n ${SUDO_USER:-} ]]; then
    die "Do not run this installer with sudo; run it as your normal user ($SUDO_USER)"
  fi
  link_config
  export PATH="$LOCAL_BIN:$PATH"
  [[ -d "$ENV_PREFIX/bin" ]] && export PATH="$ENV_PREFIX/bin:$PATH"
  if ((INSTALL_PACKAGES)) && { ((UPDATE)) && [[ -d "$ENV_PREFIX/conda-meta" ]] || need_portable_env; }; then
    install_portable_tools
  elif ((INSTALL_PACKAGES)); then
    log "Required tools are already available; skipping portable environment"
  fi
  ((INSTALL_SHELL)) && sync_shell_plugins
  ((INSTALL_SHELL)) && install_shell_config
  ((INSTALL_AI_TOOLS)) && install_ai_tools
  ((SYNC_PLUGINS)) && sync_plugins

  log "Installation complete"
  printf '    Restart your shell, then run: nvim\n'
  if ((INSTALL_AI_TOOLS)); then
    printf '    Run codex and claude once to complete their individual sign-in flows.\n'
  fi
  printf '    Check the environment with: %s/bin/nvim-doctor\n' "$CONFIG_DIR"
}

main
