# Shared, intentionally dependency-free shell settings for bash and zsh.

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac

_nvim_portable_env="${NVIM_ENV_PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim-portable/env}"
if [ -d "$_nvim_portable_env/bin" ]; then
  case ":$PATH:" in
    *":$_nvim_portable_env/bin:"*) ;;
    *) PATH="$_nvim_portable_env/bin:$PATH" ;;
  esac
fi
export PATH
unset _nvim_portable_env

export EDITOR=nvim
export VISUAL=nvim
export GIT_EDITOR=nvim
export CLI_COLOR=1
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1

_nvim_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ -r "$_nvim_config_dir/shell/starship.toml" ]; then
  # Always select the managed config. A long-lived tmux server may otherwise
  # pass an old STARSHIP_CONFIG value to every newly created pane.
  export STARSHIP_CONFIG="$_nvim_config_dir/shell/starship.toml"
fi
unset _nvim_config_dir

alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'

# Target for Kitty file hyperlinks produced by `ls --hyperlink=auto`.
# Local macOS media/documents use their associated app; text files and all
# remote files open in Neovim in the current shell/tmux pane.
terminal_open() {
  [ "$#" -eq 1 ] || return 2
  local _terminal_open_target=$1 _terminal_open_path _terminal_open_ext

  case "$_terminal_open_target" in
    file://*)
      command -v python3 >/dev/null 2>&1 || {
        printf 'terminal_open: python3 is required to decode file URLs\n' >&2
        return 1
      }
      _terminal_open_path="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(urllib.parse.urlsplit(sys.argv[1]).path))' "$_terminal_open_target")" || return
      ;;
    *) _terminal_open_path=$_terminal_open_target ;;
  esac

  if [ -z "${SSH_CONNECTION:-}" ] && [ -z "${TMUX:-}" ] && [ "$(uname -s)" = Darwin ]; then
    _terminal_open_ext=$(printf '%s' "${_terminal_open_path##*.}" | tr '[:upper:]' '[:lower:]')
    case "$_terminal_open_ext" in
      pdf|png|jpg|jpeg|gif|webp|heic|svg|mp3|m4a|wav|flac|mp4|mov|mkv|avi|doc|docx|xls|xlsx|ppt|pptx)
        open -- "$_terminal_open_path"
        return
        ;;
    esac
  fi

  nvim -- "$_terminal_open_path"
}

# True colour inside tmux and over SSH-capable terminals.
case "${TERM:-}" in
  xterm*|screen*|tmux*) export COLORTERM="${COLORTERM:-truecolor}" ;;
esac
