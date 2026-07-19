# Loaded from ~/.config/fish/conf.d/portable-nvim.fish.
fish_add_path --prepend "$HOME/.local/bin"
set -l portable_data_home "$HOME/.local/share"
set -q XDG_DATA_HOME; and set portable_data_home $XDG_DATA_HOME
set -l portable_env (set -q NVIM_ENV_PREFIX; and echo $NVIM_ENV_PREFIX; or echo "$portable_data_home/nvim-portable/env")
test -d "$portable_env/bin"; and fish_add_path --prepend "$portable_env/bin"

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx GIT_EDITOR nvim

alias v nvim
alias vi nvim
alias vim nvim
alias lg lazygit
