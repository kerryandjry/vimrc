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
The full installation also links the repository's Yazi configuration to
`~/.config/yazi/yazi.toml`, preserving an existing file once as
`yazi.toml.pre-nvim-dotfiles`.

### Installation behavior

```sh
./install.sh          # install everything, or update an existing installation
./bin/nvim-doctor     # show missing and active tools
```

The installer intentionally has no command-line options. Its first run installs
the complete portable environment, shell configuration, plugins, Treesitter
parsers, and the Codex, Claude Code, and Pi agent CLIs. Later runs update all
managed packages, shell plugins, editor plugins, parsers, and AI CLIs.

The AI CLIs use their official installers. The repository restores Pi's global
settings, shared agent memory, PDF skill, and pinned extension packages from
`pi/agent/`. Authentication, API keys, trust decisions, and session history
remain machine-specific and are deliberately not committed: run `codex`,
`claude`, and `pi` after installation to complete their separate sign-in flows.

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
./install.sh
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
