#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/nvim-smoke.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT
export RUFF_CACHE_DIR="$build_dir/ruff-cache"
export NVIM_LOG_FILE="$build_dir/nvim.log"

python3 "$repo_dir/tests/fixtures/python_ok.py"

portable_env="${NVIM_ENV_PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/nvim-portable/env}"
cc="${CC:-$portable_env/bin/cc}"
[[ -x "$cc" ]] || cc="$(command -v cc || true)"
[[ -n "$cc" && -x "$cc" ]] || {
  printf 'No working C compiler was found\n' >&2
  exit 1
}
printf 'C compiler: %s\n' "$cc"
printf 'int main(void) { return 0; }\n' | "$cc" -x c - -o "$build_dir/c-smoke"
"$build_dir/c-smoke"

compiler_supports_stdlib() {
  local compiler=$1
  printf '#include <iostream>\nint main() {}\n' |
    "$compiler" -x c++ -std=c++20 -fsyntax-only - >/dev/null 2>&1
}

cxx="${CXX:-}"
if [[ -n "$cxx" ]]; then
  compiler_supports_stdlib "$cxx" || {
    printf 'CXX=%s cannot compile a program using <iostream>\n' "$cxx" >&2
    exit 1
  }
else
  candidates=(
    "$portable_env/bin/c++"
    "$portable_env/bin/g++"
    "$portable_env/bin/clang++"
    "$(command -v g++ || true)"
    "$(command -v c++ || true)"
  )
  for candidate in "${candidates[@]}" "$portable_env"/bin/*-g++ "$portable_env"/bin/clang++-*; do
    if [[ -n "$candidate" && -x "$candidate" ]] && compiler_supports_stdlib "$candidate"; then
      cxx=$candidate
      break
    fi
  done
fi
[[ -n "$cxx" ]] || {
  printf 'No C++ compiler with working standard-library headers was found\n' >&2
  exit 1
}
printf 'C++ compiler: %s\n' "$cxx"
"$cxx" -std=c++20 -Wall -Wextra -Werror "$repo_dir/tests/fixtures/cpp_ok.cpp" -o "$build_dir/cpp-smoke"
"$build_dir/cpp-smoke"

nvim --headless "+lua dofile('$repo_dir/tests/lsp_smoke.lua')"
