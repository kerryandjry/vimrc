# Portable aliases adapted from ~/.zsh/aliases.zsh. Machine-specific paths and
# commands are enabled only when their targets exist.

if (( $+commands[gls] )); then
  alias ls='gls --hyperlink=auto --color=auto'
elif command ls --hyperlink=auto -d . >/dev/null 2>&1; then
  # GNU ls on Linux supports OSC 8 file hyperlinks directly.
  alias ls='ls --hyperlink=auto --color=auto'
else
  alias ls='ls --color=auto'
fi
alias s='ls'
alias la='ls -a'
alias ll='ls -l'

alias vim='nvim -c "e ++enc=GBK"'
alias vi='nvim'
(( $+commands[claude] )) && alias cc='claude'
(( $+commands[bat] )) && alias cat='bat'
alias b='cd ..'
alias g++='g++ -std=c++17'
alias pip='pip3'
alias python='python3'
(( $+commands[trash] )) && alias rm='trash'
(( $+commands[otool] )) && alias ldd='otool'
(( $+commands[podman] )) && alias docker='podman'
(( $+commands[termpdf.py] )) && alias pdf='termpdf.py'

[[ -d "$HOME/work" ]] && alias work='cd "$HOME/work"'
[[ -d "$HOME/work/cpp" ]] && alias cpp='cd "$HOME/work/cpp"'
[[ -d "$HOME/work/python" ]] && alias py='cd "$HOME/work/python"'
[[ -d "$HOME/Downloads" ]] && alias dl='cd "$HOME/Downloads"'

if (( $+commands[kitten] )); then
  alias icat='kitten icat'
  alias ssh='kitten ssh'
fi

# Clear the legacy alias before defining the interactive host picker.  Without
# this, re-sourcing the file can make zsh expand `sshc` while parsing `sshc()`.
unalias sshc 2>/dev/null
function sshc {
  local host
  [[ -r "$HOME/.ssh/config" ]] || return 1
  host="$(awk '/^Host / {for (i=2; i<=NF; i++) print $i}' "$HOME/.ssh/config" | fzf)"
  [[ -n "$host" ]] && ssh "$host"
}
