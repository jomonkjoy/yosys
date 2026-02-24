#!/usr/bin/env bash
# =============================================================================
# setup_project.sh
# Creates the counter_synth RTL synthesis project directory structure.
# Mirrors the three-flow Makefile layout (sky130 / xilinx / altera):
#
#   synth/scripts/          – shared Yosys / Vivado / Quartus scripts
#   synth/sky130/{reports,netlist,impl}
#   synth/xilinx/{reports,netlist,impl}
#   synth/altera/{reports,netlist,impl}
#
# A .gitkeep file is placed in every leaf directory so empty folders are
# tracked by Git.
#
# Usage:
#   ./setup_project.sh [BASE_DIR]
#
# Examples:
#   ./setup_project.sh                   # creates ./counter_synth
#   ./setup_project.sh ~/projects        # creates ~/projects/counter_synth
# =============================================================================

set -euo pipefail

# ── Resolve project root ──────────────────────────────────────────────────────
BASE_DIR="${1:-.}"
PROJECT_NAME="counter_synth"
ROOT="${BASE_DIR}/${PROJECT_NAME}"

# ── Directory list ────────────────────────────────────────────────────────────
# Per-flow output dirs added for sky130 / xilinx / altera (Makefile FLOW=)
DIRS=(
    "rtl"
    "filelist"
    "constraints"
    "synth/scripts"
    "synth/sky130/reports"
    "synth/sky130/netlist"
    "synth/sky130/impl"
    "synth/xilinx/reports"
    "synth/xilinx/netlist"
    "synth/xilinx/impl"
    "synth/altera/reports"
    "synth/altera/netlist"
    "synth/altera/impl"
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
echo "  1. Copy your RTL into          ${ROOT}/rtl/"
echo "  2. Edit the filelist at        ${ROOT}/filelist/rtl.f"
echo ""
echo "  Constraints (one file per flow):"
echo "    sky130 / altera (SDC)  →   ${ROOT}/constraints/<design>.sdc"
echo "    xilinx  (XDC)          →   ${ROOT}/constraints/<design>.xdc"
echo ""
echo "  Synthesis commands:"
echo "    make FLOW=sky130             # Yosys + SkyWater sky130 HD"
echo "    make FLOW=xilinx             # Vivado  (set XILINX_PART=... )"
echo "    make FLOW=altera             # Quartus (set ALTERA_DEVICE=...)"
echo "    make synth_all               # run all three flows"
echo ""
echo "  Flow outputs land in:"
echo "    ${ROOT}/synth/<flow>/reports/"
echo "    ${ROOT}/synth/<flow>/netlist/"
echo "    ${ROOT}/synth/<flow>/impl/"
echo ""
