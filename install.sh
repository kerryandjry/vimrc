#!/usr/bin/env bash
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { echo "$*" >&2; exit 1; }

install_apt() {
  log "Installing packages via apt"
  sudo apt update
  sudo apt install -y \
    neovim git curl wget ripgrep fd-find lazygit \
    build-essential cmake clang clangd python3 python3-pip python3-venv \
    lua-language-server fonts-firacode fonts-jetbrains-mono
  if ! command -v fd >/dev/null; then
    sudo ln -sfn "$(command -v fdfind)" /usr/local/bin/fd || true
  fi
}

install_dnf() {
  log "Installing packages via dnf"
  sudo dnf install -y \
    neovim git curl wget ripgrep fd lazygit \
    gcc gcc-c++ make cmake clang clang-tools-extra \
    python3 python3-pip python3-virtualenv lua-language-server \
    nerd-fonts-jetbrains-mono
}

install_pacman() {
  log "Installing packages via pacman"
  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm \
    neovim git curl wget ripgrep fd lazygit \
    base-devel cmake clang python python-pip lua-language-server \
    nerd-fonts-jetbrains-mono
}

install_brew() {
  log "Installing packages via Homebrew"
  brew update
  brew install neovim git curl wget ripgrep fd lazygit llvm cmake python@3.11 node
  brew tap homebrew/cask-fonts
  brew install --cask font-jetbrains-mono-nerd-font
  if [[ -d /opt/homebrew/opt/llvm/bin ]]; then
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
  fi
}

ensure_python_tools() {
  log "Installing Python language tools"
  python3 -m pip install --user --upgrade pip
  python3 -m pip install --user "python-lsp-server[all]" cmake-language-server
}

ensure_lazy_sync() {
  log "Refreshing lazy.nvim plugins"
  env PATH="$HOME/.local/bin:$PATH" nvim --headless +'Lazy! sync' +qa
}

main() {
  if [[ "$(uname)" == "Darwin" ]]; then
    command -v brew >/dev/null || die "Homebrew is required on macOS - install it first."
    install_brew
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    case "$ID" in
      ubuntu|debian)
        install_apt
        ;;
      fedora)
        install_dnf
        ;;
      arch)
        install_pacman
        ;;
      *)
        log "Detected $ID, unsure of the package manager fallback to apt style"
        install_apt
        ;;
    esac
  else
    die "Unsupported OS; please install dependencies manually."
  fi

  ensure_python_tools
  ensure_lazy_sync

  log "Done. Reminder: install a Nerd Font (JetBrains, FiraCode, Hack) and add it to your terminal."
  log "Sync ~/.config/nvim via rsync or git clone, then reopen nvim."
}

main
