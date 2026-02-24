##############################################################################
# Makefile – RTL Synthesis with Yosys + sky130 HD library
# Project : counter
# Author  : (your name)
#
# Usage:
#   make           – run synthesis (default target)
#   make clean     – remove all generated outputs
#   make lint      – lint RTL with Verilator
#   make show      – open gate-level netlist in graphviz (requires xdot)
##############################################################################

# ── Tool paths ────────────────────────────────────────────────────────────────
YOSYS       ?= yosys
VERILATOR   ?= verilator

# ── sky130 library paths ──────────────────────────────────────────────────────
SKY130_ROOT ?= $(PDK_ROOT)/sky130A
SKY130_LIB  := $(SKY130_ROOT)/libs.ref/sky130_fd_sc_hd/lib
SKY130_LEF  := $(SKY130_ROOT)/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef

# Liberty corner to use for synthesis (TT / 25 °C / 1.8 V)
LIBERTY     := $(SKY130_LIB)/sky130_fd_sc_hd__tt_025C_1v80.lib

# ── Design parameters ─────────────────────────────────────────────────────────
DESIGN      := counter
TOP_MODULE  := counter

# ── Directory layout ──────────────────────────────────────────────────────────
PROJ_ROOT   := $(CURDIR)
RTL_DIR     := $(PROJ_ROOT)/rtl
FL_DIR      := $(PROJ_ROOT)/filelist
CONSTR_DIR  := $(PROJ_ROOT)/constraints
SYNTH_DIR   := $(PROJ_ROOT)/synth
SCRIPTS_DIR := $(SYNTH_DIR)/scripts
REPORTS_DIR := $(SYNTH_DIR)/reports
NETLIST_DIR := $(SYNTH_DIR)/netlist

# ── Input files ───────────────────────────────────────────────────────────────
FILELIST    := $(FL_DIR)/rtl.f
SDC         := $(CONSTR_DIR)/$(DESIGN).sdc

# ── Output files ──────────────────────────────────────────────────────────────
READ_RTL_YS := $(SCRIPTS_DIR)/read_rtl.ys          # auto-generated
SYNTH_YS    := $(SCRIPTS_DIR)/synth.ys
NETLIST     := $(NETLIST_DIR)/$(DESIGN)_netlist.v
STAT_RPT    := $(REPORTS_DIR)/synth_stat.rpt
CHECK_RPT   := $(REPORTS_DIR)/synth_check.rpt

# ── Collect RTL sources from filelist (strips comments & blank lines) ─────────
RTL_SOURCES := $(shell grep -v '^\s*#' $(FILELIST) | grep -v '^\s*$$' | \
                       sed 's|^|$(PROJ_ROOT)/|')

##############################################################################
# Default target
##############################################################################
.PHONY: all
all: synth

##############################################################################
# Synthesis
##############################################################################
.PHONY: synth
synth: $(NETLIST)

$(NETLIST): $(RTL_SOURCES) $(SDC) $(SYNTH_YS) $(LIBERTY) | dirs
	@echo "============================================================"
	@echo "  Synthesising $(DESIGN) → sky130 HD  (100 MHz)"
	@echo "============================================================"

	# --- Generate read_rtl.ys from filelist ---
	@echo "# Auto-generated – do not edit" > $(READ_RTL_YS)
	@grep -v '^\s*#' $(FILELIST) | grep -v '^\s*$$' | \
	    sed 's|^|read_verilog $(PROJ_ROOT)/|' >> $(READ_RTL_YS)

	# --- Run Yosys ---
	$(YOSYS) -l $(REPORTS_DIR)/yosys.log \
	         -p "script $(SYNTH_YS)" \
	         -D SKY130_LIB=$(SKY130_LIB) \
	         -D SDC=$(SDC) \
	         -D REPORTS=$(REPORTS_DIR) \
	         -D NETLIST=$(NETLIST)

	@echo ""
	@echo "  ✔ Netlist written : $(NETLIST)"
	@echo "  ✔ Area report     : $(STAT_RPT)"
	@echo "  ✔ Yosys log       : $(REPORTS_DIR)/yosys.log"

##############################################################################
# Directory creation
##############################################################################
.PHONY: dirs
dirs:
	@mkdir -p $(REPORTS_DIR) $(NETLIST_DIR) $(SCRIPTS_DIR)

##############################################################################
# Lint (Verilator – syntax & style check, no simulation)
##############################################################################
.PHONY: lint
lint:
	@echo "--- Linting RTL with Verilator ---"
	$(VERILATOR) --lint-only -Wall --top-module $(TOP_MODULE) \
	             $(RTL_SOURCES)
	@echo "  ✔ Lint passed"

##############################################################################
# View synthesised netlist as a graph (requires xdot + graphviz)
##############################################################################
.PHONY: show
show: $(NETLIST)
	$(YOSYS) -p "read_verilog $(NETLIST); \
	              read_liberty -lib $(LIBERTY); \
	              show -colors 2 -prefix $(SYNTH_DIR)/$(DESIGN)_netlist"

##############################################################################
# STA stub – reminder to run OpenSTA after synthesis
##############################################################################
.PHONY: sta
sta: $(NETLIST)
	@echo "Run OpenSTA manually:"
	@echo "  sta -exit synth/scripts/sta.tcl"

##############################################################################
# Clean
##############################################################################
.PHONY: clean
clean:
	@rm -rf $(REPORTS_DIR) $(NETLIST_DIR) $(READ_RTL_YS)
	@echo "  ✔ Clean done"

##############################################################################
# Help
##############################################################################
.PHONY: help
help:
	@echo ""
	@echo "  Targets:"
	@echo "    make  /  make synth   – synthesise with Yosys + sky130"
	@echo "    make lint             – Verilator lint check"
	@echo "    make show             – view gate netlist graph"
	@echo "    make clean            – remove outputs"
	@echo ""
	@echo "  Key variables (override on command line):"
	@echo "    SKY130_ROOT  = $(SKY130_ROOT)"
	@echo "    LIBERTY      = (TT 25C 1v80)"
	@echo "    DESIGN       = $(DESIGN)"
	@echo "    TOP_MODULE   = $(TOP_MODULE)"
	@echo ""
