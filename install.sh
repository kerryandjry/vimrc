#!/usr/bin/env bash
set -euo pipefail

# Portable bootstrap for macOS, Linux workstations, and unprivileged clusters.
# It never needs sudo: missing tools are installed in a Conda-compatible environment.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly CONFIG_DIR="$CONFIG_HOME/nvim"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly LOCAL_BIN="$HOME/.local/bin"
readonly ENV_PREFIX="${NVIM_ENV_PREFIX:-$DATA_HOME/nvim-portable/env}"
readonly MANAGED_MAMBA_BIN="$LOCAL_BIN/micromamba"

PACKAGE_MANAGER_BIN=''
MODE=install

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() {
	printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage: ./install.sh [--update | --verify]

  no option   Install or restore the versions committed to this repository
  --update    Pull the repository, advance all managed dependencies, then verify
  --verify    Run diagnostics and the full smoke test without changing anything
  -h, --help  Show this help
EOF
}

case ${1:-} in
'') ;;
--update) MODE=update ;;
--verify) MODE=verify ;;
-h | --help)
	usage
	exit 0
	;;
*) die "Unknown option: $1 (try --help)" ;;
esac
(($# <= 1)) || die "Only one mode option may be supplied (try --help)"

download() {
	local url=$1 destination=$2
	[[ "$url" == https://* ]] || die "Refusing non-HTTPS download: $url"
	if command -v curl >/dev/null 2>&1; then
		curl --proto '=https' --proto-redir '=https' -fL --retry 3 --connect-timeout 15 \
			"$url" -o "$destination"
	elif command -v wget >/dev/null 2>&1; then
		wget --https-only -O "$destination" "$url"
	else
		die "curl or wget is required for the initial bootstrap"
	fi
}

file_sha256() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$1" | awk '{print $1}'
	else
		printf 'unavailable'
	fi
}

announce_vendor_installer() {
	local label=$1 installer=$2
	warn "$label is supplied by a mutable vendor URL and cannot be authenticated by this repository"
	log "$label installer SHA-256: $(file_sha256 "$installer")"
}

update_repository() {
	[[ -d "$SCRIPT_DIR/.git" ]] || die "--update requires a Git checkout: $SCRIPT_DIR"
	[[ -z "$(git -C "$SCRIPT_DIR" status --porcelain)" ]] || die \
		"--update requires a clean checkout; commit or stash local changes first"
	git -C "$SCRIPT_DIR" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1 || die \
		"The current branch has no upstream; configure one before --update"

	local old_head new_head
	old_head="$(git -C "$SCRIPT_DIR" rev-parse HEAD)"
	log "Pulling configuration repository"
	git -C "$SCRIPT_DIR" pull --ff-only
	new_head="$(git -C "$SCRIPT_DIR" rev-parse HEAD)"
	if [[ "$old_head" != "$new_head" && ${PORTABLE_NVIM_UPDATE_REEXEC:-0} != 1 ]]; then
		log "Repository changed; restarting the updated installer"
		exec env PORTABLE_NVIM_UPDATE_REEXEC=1 "$SCRIPT_DIR/install.sh" --update
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
	local mode=$1
	select_package_manager

	if [[ "$mode" == update && "$PACKAGE_MANAGER_BIN" == "$MANAGED_MAMBA_BIN" ]]; then
		log "Updating managed micromamba"
		"$MANAGED_MAMBA_BIN" self-update -y
		select_package_manager
	fi

	local packages=(
		"nvim>=0.12,<0.13" git curl ripgrep fd-find "tree-sitter-cli>=0.26.1" clang-tools c-compiler cxx-compiler zsh
		"tmux>=3.3" lazygit yazi fzf bat zoxide starship trash-cli bash-completion cmake ninja nodejs python
		lua-language-server pyright cmake-language-server ruff pynvim
	)
	local channel_args=(-c conda-forge --override-channels --strict-channel-priority)

	log "Installing portable tools into $ENV_PREFIX"
	if [[ -d "$ENV_PREFIX/conda-meta" ]]; then
		"$PACKAGE_MANAGER_BIN" install -y -p "$ENV_PREFIX" "${channel_args[@]}" "${packages[@]}"
	else
		"$PACKAGE_MANAGER_BIN" create -y -p "$ENV_PREFIX" "${channel_args[@]}" "${packages[@]}"
	fi
	if [[ "$mode" == update ]]; then
		log "Updating all portable packages"
		"$PACKAGE_MANAGER_BIN" update -y -p "$ENV_PREFIX" "${channel_args[@]}" --all
	fi

	# Compiler metapackages include the platform runtime/sysroot needed for
	# parser linking. Prefer their GCC wrappers on Linux and Clang on macOS,
	# then expose stable names because this environment is used through PATH
	# without requiring `conda activate`.
	local candidate cc='' cxx=''
	for candidate in \
		"$ENV_PREFIX/bin/gcc" "$ENV_PREFIX"/bin/*-gcc \
		"$ENV_PREFIX/bin/clang" "$ENV_PREFIX"/bin/*-clang "$ENV_PREFIX"/bin/clang-[0-9]*; do
		if [[ -x "$candidate" && "$candidate" != "$ENV_PREFIX/bin/cc" ]]; then
			cc=$candidate
			break
		fi
	done
	for candidate in \
		"$ENV_PREFIX/bin/g++" "$ENV_PREFIX"/bin/*-g++ \
		"$ENV_PREFIX/bin/clang++" "$ENV_PREFIX"/bin/*-clang++ "$ENV_PREFIX"/bin/clang++-[0-9]*; do
		if [[ -x "$candidate" && "$candidate" != "$ENV_PREFIX/bin/c++" ]]; then
			cxx=$candidate
			break
		fi
	done
	[[ -n "$cc" ]] || die "The portable C compiler is missing after package installation"
	[[ -n "$cxx" ]] || die "The portable C++ compiler is missing after package installation"
	ln -sfn "${cc##*/}" "$ENV_PREFIX/bin/cc"
	ln -sfn "${cxx##*/}" "$ENV_PREFIX/bin/c++"

	export PATH="$ENV_PREFIX/bin:$LOCAL_BIN:$PATH"
	export CC="$ENV_PREFIX/bin/cc"
	export CXX="$ENV_PREFIX/bin/c++"
}

install_ai_tools() {
	local mode=$1 temporary installer

	temporary="$(mktemp -d "${TMPDIR:-/tmp}/nvim-ai-tools.XXXXXX")"
	trap 'rm -rf "$temporary"' RETURN
	mkdir -p "$DATA_HOME/nvim-portable"

	if [[ "$mode" == update ]] || ! command -v codex >/dev/null 2>&1; then
		installer="$temporary/codex-install.sh"
		log "Installing or updating Codex CLI"
		download "https://chatgpt.com/codex/install.sh" "$installer"
		announce_vendor_installer "Codex CLI" "$installer"
		sh "$installer"
		hash -r 2>/dev/null || true
		command -v codex >/dev/null 2>&1 || die "Codex installer completed but codex is not on PATH"
		touch "$DATA_HOME/nvim-portable/codex-installed-by-nvim"
	else
		log "Codex CLI is already installed; keeping its current version"
	fi

	if [[ "$mode" == update ]] || ! command -v claude >/dev/null 2>&1; then
		installer="$temporary/claude-install.sh"
		log "Installing or updating Claude Code CLI"
		download "https://claude.ai/install.sh" "$installer"
		announce_vendor_installer "Claude Code CLI" "$installer"
		bash "$installer"
		hash -r 2>/dev/null || true
		command -v claude >/dev/null 2>&1 || die "Claude installer completed but claude is not on PATH"
		touch "$DATA_HOME/nvim-portable/claude-installed-by-nvim"
	else
		log "Claude Code CLI is already installed; keeping its current version"
	fi

	if [[ "$mode" == update ]] || ! command -v pi >/dev/null 2>&1; then
		installer="$temporary/pi-install.sh"
		log "Installing or updating Pi agent CLI"
		download "https://pi.dev/install.sh" "$installer"
		announce_vendor_installer "Pi agent CLI" "$installer"
		sh "$installer"
		hash -r 2>/dev/null || true
		command -v pi >/dev/null 2>&1 || die "Pi installer completed but pi is not on PATH"
		command -v pi >"$DATA_HOME/nvim-portable/pi-installed-by-nvim"
	else
		log "Pi agent CLI is already installed; keeping its current version"
	fi

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
	done < <(cd "$source_dir" && find . -type f ! -path './package.json' ! -path './package-lock.json' -print | sed 's#^./##' | sort)
	log "Installed Pi settings, local extensions, and local skills"
}

update_pi_package_locks() {
	local source_dir="$SCRIPT_DIR/pi/agent" package
	local packages=()

	command -v npm >/dev/null 2>&1 || die "npm is required to update Pi extension packages"
	while IFS= read -r package; do
		packages+=("$package@latest")
	done < <(node -e '
const manifest = require(process.argv[1]);
for (const name of Object.keys(manifest.dependencies || {}).sort()) console.log(name);
' "$source_dir/package.json")
	((${#packages[@]})) || die "No Pi extension dependencies are declared"

	log "Advancing Pi extension manifest and lock to reviewed upstream releases"
	(
		cd "$source_dir"
		npm install --package-lock-only --ignore-scripts --legacy-peer-deps --save-exact "${packages[@]}"
	)
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
	# pi-vim imports the host API at runtime. Keep a local, locked copy because
	# Node cannot resolve the separately installed global/managed Pi package on
	# every platform (notably Pi's releases-v1 layout on Linux).
	(
		cd "$npm_dir"
		npm ci --omit=dev --legacy-peer-deps
	)
	node - "$npm_dir" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const root = process.argv[2];
const piVim = require.resolve("pi-vim/package.json", { paths: [root] });
const peer = path.join(path.dirname(path.dirname(piVim)), "@earendil-works", "pi-coding-agent", "package.json");
fs.accessSync(peer, fs.constants.R_OK);
NODE
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
	local mode=$1 plugin_root="$DATA_HOME/nvim-portable/zsh" name url destination
	mkdir -p "$plugin_root"
	while read -r name url; do
		destination="$plugin_root/$name"
		if [[ ! -d "$destination/.git" ]]; then
			log "Installing zsh plugin: $name"
			git clone --depth 1 "$url" "$destination"
		elif [[ -n "$(git -C "$destination" status --porcelain)" ]]; then
			warn "Skipping modified zsh plugin checkout: $destination"
		elif [[ "$mode" == update ]]; then
			log "Updating zsh plugin: $name"
			git -C "$destination" pull --ff-only
		else
			log "Zsh plugin is already installed; keeping its current revision: $name"
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
		local backup
		backup="${CONFIG_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
		warn "Moving existing Neovim config to $backup"
		mv "$CONFIG_DIR" "$backup"
	fi
	ln -s "$SCRIPT_DIR" "$CONFIG_DIR"
}

install_shell_config() {
	# This line is installed literally so the destination shell expands its variables.
	# shellcheck disable=SC2016
	local source_line='[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/shell/common.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/shell/common.sh"'
	install_managed_block "$HOME/.zshrc" "$source_line
[ -r \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/zshrc\" ] && . \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/zshrc\""
	install_managed_block "$HOME/.bashrc" "$source_line
[ -r \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/bashrc\" ] && . \"\${XDG_CONFIG_HOME:-\$HOME/.config}/nvim/shell/bashrc\""
	install_managed_block "$HOME/.tmux.conf" "source-file \"$CONFIG_DIR/tmux.conf\""
	if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
		tmux source-file "$HOME/.tmux.conf" || warn "Could not reload the running tmux server"
	fi

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

assert_config_loads() {
	have_modern_nvim || die "Neovim 0.12.x is required by this configuration"
	local active_config
	active_config="$(nvim --clean --headless -i NONE \
		"+lua io.stdout:write(vim.fn.stdpath('config'))" +qa 2>/dev/null)"
	[[ "$active_config" == "$CONFIG_DIR" ]] || die \
		"Neovim is using $active_config instead of $CONFIG_DIR (check NVIM_APPNAME and XDG_CONFIG_HOME)"
	nvim --headless -i NONE \
		"+lua if vim.g.portable_nvim_loaded ~= 1 then vim.cmd('cquit') end" +qa \
		>/dev/null 2>&1 || die "Neovim could not fully load $CONFIG_DIR/init.lua"
}

sync_plugins() {
	local mode=$1
	assert_config_loads
	if [[ "$mode" == update ]]; then
		log "Updating lazy.nvim plugins and lock file"
		nvim --headless "+Lazy! update" +qa
		log "Updating Treesitter parsers"
		nvim --headless -i NONE "+PortableTSUpdate" +qa
	else
		log "Synchronizing lazy.nvim plugins to the committed lock file"
		nvim --headless "+Lazy! sync" +qa
		log "Installing pinned Treesitter parsers"
		nvim --headless -i NONE "+PortableTSInstall" +qa
	fi
}

verify_installation() (
	export PORTABLE_NVIM_VERIFY=1
	log "Verifying the installed configuration in fresh Neovim processes"
	assert_config_loads
	"$SCRIPT_DIR/bin/nvim-doctor"
	"$SCRIPT_DIR/tests/smoke.sh"
	log "Verification complete"
)

main() {
	if ((EUID == 0)) && [[ -n ${SUDO_USER:-} ]]; then
		die "Do not run this installer with sudo; run it as your normal user ($SUDO_USER)"
	fi

	export PATH="$LOCAL_BIN:$PATH"
	[[ -d "$ENV_PREFIX/bin" ]] && export PATH="$ENV_PREFIX/bin:$PATH"
	if [[ "$MODE" == verify ]]; then
		verify_installation
		return
	fi
	[[ "$MODE" == update ]] && update_repository

	link_config
	install_agent_global_memory
	install_claude_settings
	install_pi_settings
	install_portable_tools "$MODE"
	sync_shell_plugins "$MODE"
	install_shell_config
	install_yazi_config
	install_lazygit_config
	install_ai_tools "$MODE"
	[[ "$MODE" == update ]] && update_pi_package_locks
	sync_pi_packages
	sync_plugins "$MODE"
	verify_installation

	log "$MODE complete"
	printf '    Restart your shell, then run: nvim\n'
	printf '    Run codex, claude, and pi once to complete their individual sign-in flows.\n'
	if [[ "$MODE" == update ]]; then
		printf '    Review and commit updated lock files with: git status --short\n'
	fi
}

main
