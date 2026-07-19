# Portable Neovim environment

This repository is a self-contained Neovim 0.12.x and terminal setup for macOS,
Linux, and machines where you do not have root access (for example HPC
clusters). The installer is safe to run repeatedly and does not use `sudo`.

## Install on a new machine

```sh
git clone https://github.com/kerryandjry/vimrc.git ~/.config/nvim
~/.config/nvim/install.sh
```

Restart the shell and run `nvim`. The first installation can take several
minutes because it downloads command-line tools, language servers, Treesitter
parsers, and plugins.

The bootstrap keeps an existing Neovim configuration by renaming it with a
timestamp. It adds small, clearly marked blocks to `~/.zshrc`, `~/.bashrc`, and
`~/.tmux.conf`; the original file is also copied once to `*.pre-nvim-dotfiles`.
Fish loads a file from `~/.config/fish/conf.d/`. Machine-specific settings and
secrets should stay outside the managed blocks and must not be committed.

### Useful variants

```sh
./install.sh --minimal       # editor plus core search tools only
./install.sh --update        # update tools, plugins, and Treesitter parsers
./install.sh --no-shell      # leave zsh/bash/fish/tmux untouched
./install.sh --no-packages   # use tools already installed by the system
./install.sh --no-plugins    # skip the initial lazy.nvim sync
./install.sh --with-ai-tools # also install the optional Codex and Claude Code CLIs
./bin/nvim-doctor            # show missing and active tools
```

`--with-ai-tools` uses the official native installers and only installs a CLI
when its command is missing. Codex and Claude Code manage their own updates
outside the micromamba environment. Authentication and API keys remain
machine-specific: run `codex` and `claude` after installation to complete their
separate sign-in flows. The option is not enabled by default, including with
`--minimal`.

Missing dependencies are installed from conda-forge into
`~/.local/share/nvim-portable/env`. The bootstrap reuses an available
`micromamba`, `mamba`, or `conda`; otherwise it downloads micromamba, with the
official GitHub releases as a fallback when `micro.mamba.pm` is unavailable.
This avoids depending on Homebrew, apt, dnf, pacman, or administrator access.
Set `NVIM_ENV_PREFIX` if home-directory quotas require another location, such
as a cluster scratch disk.

## What is portable and what is machine-specific

The repository owns Neovim, common shell environment variables and aliases,
portable zsh with autosuggestions/syntax highlighting, Starship, bash
completion, fzf/zoxide, and tmux's true-colour/vi-mode defaults. On a normal
installation, a new interactive Bash session automatically enters the managed
zsh, without requiring `sudo`, `chsh`, or an `/etc/shells` change. Set
`PORTABLE_NVIM_KEEP_BASH=1` before starting Bash to opt out. The system account's
login-shell record is left unchanged. Terminal
emulator themes, fonts, SSH keys, tokens, proxy settings, and cluster `module`
commands remain machine-specific. Install a Nerd Font in a graphical terminal
to display all icons; remote clusters use the font configured on the local
terminal, so no font is needed on the server.

## Update

```sh
cd ~/.config/nvim
git pull --ff-only
./install.sh --update
```

`lazy-lock.json` pins plugin revisions, making installations reproducible.

## Uninstall

Remove the environment and managed shell configuration with one confirmation:

```sh
./uninstall.sh
```

Use `./uninstall.sh --yes` for non-interactive cleanup. Authentication files,
pre-install backups, and the Git checkout are preserved by default. Pass
`--remove-repo` to remove a clean checkout as well. Use the same XDG and
`NVIM_ENV_PREFIX` environment overrides that were used for installation.

## Language support and smoke test

Python uses Pyright for type-aware completion/navigation and Ruff for linting,
diagnostics, import actions, and formatting. C and C++ use clangd with clang-tidy
and clang-format. Lua and CMake use lua-language-server and
cmake-language-server. Project-local Python environments named `.venv` or
`venv`, and an active `VIRTUAL_ENV`, are detected automatically.

After installation, verify real Python execution, C++ compilation, LSP
attachment, completion, diagnostics, and formatting support with:

```sh
./tests/smoke.sh
```
