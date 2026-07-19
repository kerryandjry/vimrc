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
if [ -z "${STARSHIP_CONFIG:-}" ] && [ -r "$_nvim_config_dir/shell/starship.toml" ]; then
  export STARSHIP_CONFIG="$_nvim_config_dir/shell/starship.toml"
fi
unset _nvim_config_dir

alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'

# True colour inside tmux and over SSH-capable terminals.
case "${TERM:-}" in
  xterm*|screen*|tmux*) export COLORTERM="${COLORTERM:-truecolor}" ;;
esac
