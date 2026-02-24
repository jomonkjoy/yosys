#!/usr/bin/env bash
# =============================================================================
# setup_project.sh
# Creates the counter_block RTL synthesis project directory structure.
# A .gitkeep file is placed in every leaf directory so empty folders are
# tracked by Git.
#
# Usage:
#   ./setup_project.sh [PROJECT_ROOT]
#
# Examples:
#   ./setup_project.sh                   # creates ./counter_block
#   ./setup_project.sh ~/projects        # creates ~/projects/counter_block
# =============================================================================

set -euo pipefail

# ── Resolve project root ──────────────────────────────────────────────────────
BASE_DIR="${1:-.}"
PROJECT_NAME="counter_block"
ROOT="${BASE_DIR}/${PROJECT_NAME}"

# ── Directory list ────────────────────────────────────────────────────────────
DIRS=(
    "rtl"
    "filelist"
    "constraints"
    "synth/scripts"
    "synth/reports"
    "synth/netlist"
)

# ── Colour helpers (graceful fallback if terminal has no colour support) ──────
if command -v tput &>/dev/null && tput setaf 1 &>/dev/null; then
    GREEN=$(tput setaf 2); CYAN=$(tput setaf 6)
    YELLOW=$(tput setaf 3); RESET=$(tput sgr0)
else
    GREEN=""; CYAN=""; YELLOW=""; RESET=""
fi

# ── Guard: don't overwrite an existing project ────────────────────────────────
if [[ -d "${ROOT}" ]]; then
    echo "${YELLOW}[WARN]${RESET} Directory '${ROOT}' already exists. Skipping creation."
    echo "       Remove it first or choose a different base directory."
    exit 1
fi

# ── Create directories & .gitkeep files ──────────────────────────────────────
echo ""
echo "${CYAN}Creating project: ${ROOT}${RESET}"
echo "────────────────────────────────────────"

for dir in "${DIRS[@]}"; do
    full_path="${ROOT}/${dir}"
    mkdir -p "${full_path}"
    touch "${full_path}/.gitkeep"
    echo "  ${GREEN}✔${RESET}  ${dir}/.gitkeep"
done

# ── Print final tree ──────────────────────────────────────────────────────────
echo ""
echo "${CYAN}Project layout:${RESET}"
echo ""

if command -v tree &>/dev/null; then
    tree -a "${ROOT}"
else
    # Fallback: manual tree using find
    find "${ROOT}" | sort | sed \
        -e "s|${ROOT}||" \
        -e 's|[^/]*/|  |g' \
        -e 's|  \([^  ]\)|── \1|'
fi

echo ""
echo "${GREEN}Done!${RESET}  Project scaffold ready at: ${ROOT}"
echo ""
echo "Next steps:"
echo "  1. Copy your RTL into        ${ROOT}/rtl/"
echo "  2. Edit the filelist at      ${ROOT}/filelist/rtl.f"
echo "  3. Adjust constraints at     ${ROOT}/constraints/counter.sdc"
echo "  4. Run synthesis with        cd ${ROOT} && make"
echo ""
