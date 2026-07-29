#!/usr/bin/env bash
set -euo pipefail

# Portable bootstrap for macOS, Linux workstations, and unprivileged clusters.
# It never needs sudo: missing tools are installed in a Conda-compatible environment.

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly CONFIG_DIR="$CONFIG_HOME/nvim"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly LOCAL_BIN="$HOME/.local/bin"
readonly ENV_PREFIX="${NVIM_ENV_PREFIX:-$DATA_HOME/nvim-portable/env}"
readonly MANAGED_MAMBA_BIN="$LOCAL_BIN/micromamba"

PACKAGE_MANAGER_BIN=''
EXISTING_INSTALL=0

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() {
	printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
	exit 1
}

(($# == 0)) || die "install.sh does not accept options; run it without arguments"

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

install_micromamba() {
	local platform arch archive_url release_url temporary downloaded_bin
	case "$(uname -s)" in
	Darwin) platform=osx ;;
	Linux) platform=linux ;;
	*) die "Unsupported operating system: $(uname -s)" ;;
	esac
	case "$(uname -m)" in
	x86_64 | amd64) arch=64 ;;
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
	if download "$archive_url" "$temporary/micromamba.tar.bz2" &&
		tar -xjf "$temporary/micromamba.tar.bz2" -C "$temporary" bin/micromamba; then
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
		if resolved="$(command -v "$manager" 2>/dev/null)" &&
			"$manager" --version >/dev/null 2>&1; then
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
		"tmux>=3.3" lazygit yazi fzf bat zoxide starship trash-cli bash-completion cmake ninja nodejs python
		lua-language-server pyright cmake-language-server ruff pynvim
	)

	log "Installing portable tools into $ENV_PREFIX"
	if ((EXISTING_INSTALL)); then
		"$PACKAGE_MANAGER_BIN" install -y -p "$ENV_PREFIX" -c conda-forge "${packages[@]}"
		log "Updating all portable packages"
		"$PACKAGE_MANAGER_BIN" update -y -p "$ENV_PREFIX" -c conda-forge --all
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

	installer="$temporary/codex-install.sh"
	log "Installing or updating Codex CLI"
	download "https://chatgpt.com/codex/install.sh" "$installer"
	sh "$installer"
	hash -r 2>/dev/null || true
	command -v codex >/dev/null 2>&1 || die "Codex installer completed but codex is not on PATH"
	mkdir -p "$DATA_HOME/nvim-portable"
	touch "$DATA_HOME/nvim-portable/codex-installed-by-nvim"

	installer="$temporary/claude-install.sh"
	log "Installing or updating Claude Code CLI"
	download "https://claude.ai/install.sh" "$installer"
	bash "$installer"
	hash -r 2>/dev/null || true
	command -v claude >/dev/null 2>&1 || die "Claude installer completed but claude is not on PATH"
	touch "$DATA_HOME/nvim-portable/claude-installed-by-nvim"

	installer="$temporary/pi-install.sh"
	log "Installing or updating Pi agent CLI"
	download "https://pi.dev/install.sh" "$installer"
	sh "$installer"
	hash -r 2>/dev/null || true
	command -v pi >/dev/null 2>&1 || die "Pi installer completed but pi is not on PATH"
	command -v pi >"$DATA_HOME/nvim-portable/pi-installed-by-nvim"

	rm -rf "$temporary"
	trap - RETURN
}

install_agent_global_memory() {
	local claude_dir="$HOME/.claude"
	local codex_dir="$HOME/.codex"
	local pi_dir="$HOME/.pi/agent"
	local claude_memory="$claude_dir/CLAUDE.md"
	local codex_memory="$codex_dir/AGENTS.md"
	local pi_memory="$pi_dir/AGENTS.md"
	local temporary

	temporary="$(mktemp "${TMPDIR:-/tmp}/agent-global-memory.XXXXXX")"
	cat >"$temporary" <<'EOF'
# CLAUDE.md

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

EOF

	mkdir -p "$claude_dir" "$codex_dir" "$pi_dir"
	if [[ -e "$claude_memory" ]] && ! cmp -s "$temporary" "$claude_memory"; then
		backup_once "$claude_memory"
	fi
	install -m 0644 "$temporary" "$claude_memory"
	rm -f "$temporary"

	if [[ ! -L "$codex_memory" || "$(readlink "$codex_memory" 2>/dev/null || true)" != "$claude_memory" ]]; then
		if [[ -d "$codex_memory" ]]; then
			die "Cannot replace directory with agent global memory link: $codex_memory"
		fi
		if [[ -e "$codex_memory" || -L "$codex_memory" ]]; then
			backup_once "$codex_memory"
			rm -f "$codex_memory"
		fi
		ln -s "$claude_memory" "$codex_memory"
	fi

	if [[ ! -L "$pi_memory" || "$(readlink "$pi_memory" 2>/dev/null || true)" != "$claude_memory" ]]; then
		if [[ -d "$pi_memory" ]]; then
			die "Cannot replace directory with agent global memory link: $pi_memory"
		fi
		if [[ -e "$pi_memory" || -L "$pi_memory" ]]; then
			backup_once "$pi_memory"
			rm -f "$pi_memory"
		fi
		ln -s "$claude_memory" "$pi_memory"
	fi
	log "Installed shared agent global memory for Claude, Codex, and Pi"
}

install_pi_settings() {
	local source_dir="$SCRIPT_DIR/pi/agent"
	local pi_dir="$HOME/.pi/agent"
	local relative source destination

	[[ -d "$source_dir" ]] || die "Missing managed Pi configuration: $source_dir"
	mkdir -p "$pi_dir"
	while IFS= read -r relative; do
		source="$source_dir/$relative"
		destination="$pi_dir/$relative"
		mkdir -p "$(dirname "$destination")"
		if [[ -e "$destination" ]] && ! cmp -s "$source" "$destination"; then
			backup_once "$destination"
		fi
		install -m 0644 "$source" "$destination"
	done < <(cd "$source_dir" && find . -type f ! -name package.json ! -name package-lock.json -print | sed 's#^./##' | sort)
	log "Installed Pi settings and local skills"
}

sync_pi_packages() {
	local source_dir="$SCRIPT_DIR/pi/agent"
	local npm_dir="$HOME/.pi/agent/npm"

	command -v pi >/dev/null 2>&1 || return 0
	if ! command -v npm >/dev/null 2>&1; then
		warn "npm is unavailable; Pi settings were installed but its packages could not be restored"
		return 0
	fi
	mkdir -p "$npm_dir"
	install -m 0644 "$source_dir/package.json" "$npm_dir/package.json"
	install -m 0644 "$source_dir/package-lock.json" "$npm_dir/package-lock.json"
	log "Restoring pinned Pi packages"
	# Pi is supplied globally; do not install package peer declarations locally.
	npm ci --omit=dev --legacy-peer-deps --prefix "$npm_dir"
}

install_claude_settings() {
	local claude_dir="$HOME/.claude"
	local settings="$claude_dir/settings.json"
	local temporary

	mkdir -p "$claude_dir"
	temporary="$(mktemp "${TMPDIR:-/tmp}/claude-settings.XXXXXX")"

	if [[ ! -s "$settings" ]]; then
		printf '{\n  "editorMode": "vim"\n}\n' >"$temporary"
	elif command -v python3 >/dev/null 2>&1; then
		python3 - "$settings" "$temporary" <<'PY'
import json
import sys

source, destination = sys.argv[1:]
with open(source, encoding="utf-8") as handle:
    settings = json.load(handle)
if not isinstance(settings, dict):
    raise SystemExit(f"Claude settings must contain a JSON object: {source}")
settings["editorMode"] = "vim"
with open(destination, "w", encoding="utf-8") as handle:
    json.dump(settings, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
PY
	else
		rm -f "$temporary"
		die "python3 is required to preserve and update existing Claude settings: $settings"
	fi

	if [[ -e "$settings" ]] && cmp -s "$temporary" "$settings"; then
		rm -f "$temporary"
		log "Claude Code Vim mode is already configured"
		return
	fi
	[[ -e "$settings" ]] && backup_once "$settings"
	install -m 0600 "$temporary" "$settings"
	rm -f "$temporary"
	log "Configured Claude Code to use Vim mode"
}

sync_shell_plugins() {
	local plugin_root="$DATA_HOME/nvim-portable/zsh" name url destination
	mkdir -p "$plugin_root"
	while read -r name url; do
		destination="$plugin_root/$name"
		if [[ ! -d "$destination/.git" ]]; then
			log "Installing zsh plugin: $name"
			git clone --depth 1 "$url" "$destination"
		elif [[ -n "$(git -C "$destination" status --porcelain)" ]]; then
			warn "Skipping modified zsh plugin checkout: $destination"
		else
			log "Updating zsh plugin: $name"
			git -C "$destination" pull --ff-only
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
    ' "$destination" >"$temporary"
		mv "$temporary" "$destination"
	else
		backup_once "$destination"
	fi
	printf '\n%s\n%s\n%s\n' "$start" "$block" "$end" >>"$destination"
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

install_yazi_config() {
	local yazi_dir="$CONFIG_HOME/yazi"
	local yazi_file="$yazi_dir/yazi.toml"
	local yazi_source="$CONFIG_DIR/yazi/yazi.toml"
	mkdir -p "$yazi_dir"
	if [[ -L "$yazi_file" && "$(readlink "$yazi_file")" == "$yazi_source" ]]; then
		return
	fi
	backup_once "$yazi_file"
	ln -sfn "$yazi_source" "$yazi_file"
	log "Installed Yazi configuration"
}

install_lazygit_config() {
	local lazygit_dir lazygit_file
	local lazygit_source="$CONFIG_DIR/lazygit/config.yml"

	if command -v lazygit >/dev/null 2>&1; then
		lazygit_dir="$(lazygit --print-config-dir)"
	elif [[ "$(uname -s)" == Darwin ]]; then
		lazygit_dir="$HOME/Library/Application Support/lazygit"
	else
		lazygit_dir="$CONFIG_HOME/lazygit"
	fi
	lazygit_file="$lazygit_dir/config.yml"
	mkdir -p "$lazygit_dir"
	if [[ -L "$lazygit_file" && "$(readlink "$lazygit_file")" == "$lazygit_source" ]]; then
		return
	fi
	backup_once "$lazygit_file"
	ln -sfn "$lazygit_source" "$lazygit_file"
	log "Installed LazyGit configuration"
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

	if ((EXISTING_INSTALL)); then
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
	[[ -d "$ENV_PREFIX/conda-meta" ]] && EXISTING_INSTALL=1
	link_config
	install_agent_global_memory
	install_claude_settings
	install_pi_settings
	export PATH="$LOCAL_BIN:$PATH"
	[[ -d "$ENV_PREFIX/bin" ]] && export PATH="$ENV_PREFIX/bin:$PATH"
	install_portable_tools
	sync_shell_plugins
	install_shell_config
	install_yazi_config
	install_lazygit_config
	install_ai_tools
	sync_pi_packages
	sync_plugins

	log "Installation complete"
	printf '    Restart your shell, then run: nvim\n'
	printf '    Run codex, claude, and pi once to complete their individual sign-in flows.\n'
	printf '    Check the environment with: %s/bin/nvim-doctor\n' "$CONFIG_DIR"
}

main
