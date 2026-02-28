##############################################################################
# Makefile – Multi-target RTL Synthesis
# Project : counter
# Author  : (your name)
#
# Supported flows:
#   sky130  – Yosys + SkyWater sky130 HD open-source ASIC library (default)
#   xilinx  – Vivado synthesis targeting Xilinx/AMD FPGAs
#   altera  – Quartus Prime synthesis targeting Intel/Altera FPGAs
#
# Usage:
#   make                        – sky130 synthesis (default)
#   make FLOW=sky130            – sky130 synthesis (explicit)
#   make FLOW=xilinx            – Vivado synthesis
#   make FLOW=altera            – Quartus synthesis
#   make synth_all              – run all three flows
#   make clean                  – remove outputs for current FLOW
#   make clean_all              – remove ALL flow outputs
#   make lint                   – Verilator lint check
#   make show                   – graphviz view (sky130 only)
#   make help                   – print this summary
##############################################################################

# ── Tool paths ────────────────────────────────────────────────────────────────
YOSYS       ?= yosys
VERILATOR   ?= verilator

# ── Synthesis flow selector ───────────────────────────────────────────────────
# Values: sky130 | xilinx | altera
FLOW        ?= sky130

# ── Xilinx / AMD Vivado settings ─────────────────────────────────────────────
# Override: make FLOW=xilinx XILINX_PART=xc7a100tcsg324-1
VIVADO          ?= vivado
XILINX_PART     ?= xc7a35tcpg236-1          # Artix-7 35T (common dev board)
XILINX_BOARD    ?= digilentinc.com:arty-a7-35:part0:1.1   # optional board preset

# ── Intel / Altera Quartus settings ──────────────────────────────────────────
# Override: make FLOW=altera ALTERA_DEVICE=5CSEMA5F31C6
QUARTUS         ?= quartus_sh
QUARTUS_MAP     ?= quartus_map
QUARTUS_FIT     ?= quartus_fit
QUARTUS_ASM     ?= quartus_asm
QUARTUS_STA     ?= quartus_sta
ALTERA_DEVICE   ?= EP4CE22F17C6              # Cyclone IV E (DE0-Nano)
ALTERA_FAMILY   ?= "Cyclone IV E"

# ── sky130 library paths ──────────────────────────────────────────────────────
# Override on command line:  make SKY130_ROOT=/path/to/open_pdks/sky130A
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

# Per-flow output directories (keeps flows isolated)
REPORTS_DIR := $(SYNTH_DIR)/$(FLOW)/reports
NETLIST_DIR := $(SYNTH_DIR)/$(FLOW)/netlist
IMPL_DIR    := $(SYNTH_DIR)/$(FLOW)/impl       # Xilinx / Altera implementation

# ── Input files ───────────────────────────────────────────────────────────────
FILELIST    := $(FL_DIR)/rtl.f
SDC         := $(CONSTR_DIR)/$(DESIGN).sdc

# ── Output files ──────────────────────────────────────────────────────────────
READ_RTL_YS := $(SCRIPTS_DIR)/read_rtl.ys          # auto-generated (sky130)
NETLIST     := $(NETLIST_DIR)/$(DESIGN)_netlist.v
STAT_RPT    := $(REPORTS_DIR)/synth_stat.rpt
CHECK_RPT   := $(REPORTS_DIR)/synth_check.rpt

# Xilinx outputs
VIVADO_TCL  := $(SCRIPTS_DIR)/vivado_synth.tcl     # auto-generated
VIVADO_RPT  := $(REPORTS_DIR)/vivado_utilization.rpt

# Altera outputs
QUARTUS_QSF := $(IMPL_DIR)/$(DESIGN).qsf           # auto-generated
QUARTUS_QPF := $(IMPL_DIR)/$(DESIGN).qpf           # auto-generated

# ── Collect RTL sources from filelist (strips comments & blank lines) ─────────
RTL_SOURCES := $(shell grep -v '^\s*#' $(FILELIST) | grep -v '^\s*$$' | \
                       sed 's|^|$(PROJ_ROOT)/|')

##############################################################################
# Default target — dispatches to the selected flow
##############################################################################
.PHONY: all
all: synth

.PHONY: synth
synth:
	@$(MAKE) --no-print-directory _synth_$(FLOW)

# Convenience: build all three flows in sequence
.PHONY: synth_all
synth_all:
	@$(MAKE) --no-print-directory FLOW=sky130  _synth_sky130
	@$(MAKE) --no-print-directory FLOW=xilinx  _synth_xilinx
	@$(MAKE) --no-print-directory FLOW=altera  _synth_altera

##############################################################################
# sky130 – Yosys + SkyWater open-source ASIC flow
##############################################################################
.PHONY: _synth_sky130
_synth_sky130: $(NETLIST)

$(NETLIST): $(RTL_SOURCES) $(SDC) $(LIBERTY) | dirs
	@echo "============================================================"
	@echo "  Synthesising $(DESIGN) → sky130 HD  (100 MHz)"
	@echo "============================================================"

	# --- Generate read_rtl.ys from filelist ---
	@echo "# Auto-generated – do not edit" > $(READ_RTL_YS)
	@grep -v '^\s*#' $(FILELIST) | grep -v '^\s*$$' | \
	    sed 's|^|read_verilog -sv $(PROJ_ROOT)/|' >> $(READ_RTL_YS)

	# --- Run Yosys (all variables expanded by Make before Yosys sees them) ---
	$(YOSYS) -l $(REPORTS_DIR)/yosys.log \
	    -p "script $(READ_RTL_YS); \
	        hierarchy -check -top $(TOP_MODULE); \
	        proc; flatten; opt_expr; opt_clean; check; opt_dff; \
	        fsm; opt; wreduce; peepopt; opt_clean; share; opt; booth; \
	        techmap -map +/techmap.v; opt_clean; \
	        dfflibmap -liberty $(LIBERTY); \
	        abc -liberty $(LIBERTY) -constr $(SDC) -D 10000; \
	        opt_clean -purge; setundef -zero; \
	        tee -o $(STAT_RPT) stat -liberty $(LIBERTY); \
	        tee -o $(CHECK_RPT) check; \
	        write_verilog -noattr -noexpr -nohex -nodec $(NETLIST)"

	@echo ""
	@echo "  ✔ Netlist written : $(NETLIST)"
	@echo "  ✔ Area report     : $(STAT_RPT)"
	@echo "  ✔ Check report    : $(CHECK_RPT)"
	@echo "  ✔ Yosys log       : $(REPORTS_DIR)/yosys.log"

##############################################################################
# Xilinx / AMD – Vivado non-project batch synthesis
##############################################################################
.PHONY: _synth_xilinx
_synth_xilinx: | dirs
	@echo "============================================================"
	@echo "  Synthesising $(DESIGN) → Xilinx $(XILINX_PART)  (100 MHz)"
	@echo "============================================================"

	# --- Generate Vivado TCL script from filelist ---
	@echo "# Auto-generated by Makefile – do not edit"           > $(VIVADO_TCL)
	@echo "create_project -in_memory -part $(XILINX_PART)"      >> $(VIVADO_TCL)
	@echo ""                                                      >> $(VIVADO_TCL)
	@echo "# Read RTL sources"                                   >> $(VIVADO_TCL)
	@grep -v '^\s*#' $(FILELIST) | grep -v '^\s*$$' | \
	    sed 's|^|read_verilog -sv $(PROJ_ROOT)/|'               >> $(VIVADO_TCL)
	@echo ""                                                      >> $(VIVADO_TCL)
	@echo "# Read constraints"                                   >> $(VIVADO_TCL)
	@echo "read_xdc $(CONSTR_DIR)/$(DESIGN).xdc"                >> $(VIVADO_TCL)
	@echo ""                                                      >> $(VIVADO_TCL)
	@echo "# Synthesise"                                         >> $(VIVADO_TCL)
	@echo "synth_design -top $(TOP_MODULE) -part $(XILINX_PART) -flatten_hierarchy rebuilt" >> $(VIVADO_TCL)
	@echo ""                                                      >> $(VIVADO_TCL)
	@echo "# Optimise"                                           >> $(VIVADO_TCL)
	@echo "opt_design"                                           >> $(VIVADO_TCL)
	@echo ""                                                      >> $(VIVADO_TCL)
	@echo "# Reports"                                            >> $(VIVADO_TCL)
	@echo "report_utilization  -file $(REPORTS_DIR)/vivado_utilization.rpt"  >> $(VIVADO_TCL)
	@echo "report_timing_summary -file $(REPORTS_DIR)/vivado_timing.rpt"     >> $(VIVADO_TCL)
	@echo "report_power        -file $(REPORTS_DIR)/vivado_power.rpt"        >> $(VIVADO_TCL)
	@echo ""                                                      >> $(VIVADO_TCL)
	@echo "# Write netlist"                                      >> $(VIVADO_TCL)
	@echo "write_verilog -force -mode funcsim $(NETLIST)"        >> $(VIVADO_TCL)
	@echo "write_checkpoint  -force $(IMPL_DIR)/$(DESIGN)_synth.dcp" >> $(VIVADO_TCL)
	@echo ""                                                      >> $(VIVADO_TCL)
	@echo "exit"                                                  >> $(VIVADO_TCL)

	# --- Run Vivado in batch mode ---
	$(VIVADO) -mode batch \
	          -log  $(REPORTS_DIR)/vivado.log \
	          -journal $(REPORTS_DIR)/vivado.jou \
	          -source $(VIVADO_TCL)

	@echo ""
	@echo "  ✔ Netlist written    : $(NETLIST)"
	@echo "  ✔ Checkpoint         : $(IMPL_DIR)/$(DESIGN)_synth.dcp"
	@echo "  ✔ Utilisation report : $(REPORTS_DIR)/vivado_utilization.rpt"
	@echo "  ✔ Timing report      : $(REPORTS_DIR)/vivado_timing.rpt"
	@echo "  ✔ Vivado log         : $(REPORTS_DIR)/vivado.log"

##############################################################################
# Intel / Altera – Quartus Prime Pro/Standard CLI synthesis
##############################################################################
.PHONY: _synth_altera
_synth_altera: | dirs
	@echo "============================================================"
	@echo "  Synthesising $(DESIGN) → Altera $(ALTERA_DEVICE)  (100 MHz)"
	@echo "============================================================"

	@mkdir -p $(IMPL_DIR)

	# --- Generate Quartus project file (.qpf) ---
	@echo "# Auto-generated by Makefile – do not edit"   > $(QUARTUS_QPF)
	@echo "PROJECT_REVISION = $(DESIGN)"                >> $(QUARTUS_QPF)

	# --- Generate Quartus settings file (.qsf) ---
	@echo "# Auto-generated by Makefile – do not edit"              > $(QUARTUS_QSF)
	@echo "set_global_assignment -name FAMILY $(ALTERA_FAMILY)"    >> $(QUARTUS_QSF)
	@echo "set_global_assignment -name DEVICE $(ALTERA_DEVICE)"    >> $(QUARTUS_QSF)
	@echo "set_global_assignment -name TOP_LEVEL_ENTITY $(TOP_MODULE)" >> $(QUARTUS_QSF)
	@echo "set_global_assignment -name PROJECT_OUTPUT_FILES $(IMPL_DIR)" >> $(QUARTUS_QSF)
	@echo "set_global_assignment -name SDC_FILE $(CONSTR_DIR)/$(DESIGN).sdc" >> $(QUARTUS_QSF)
	@echo "set_global_assignment -name VERILOG_INPUT_VERSION SYSTEMVERILOG_2005" >> $(QUARTUS_QSF)
	@echo ""                                                         >> $(QUARTUS_QSF)
	@echo "# RTL source files"                                       >> $(QUARTUS_QSF)
	@grep -v '^\s*#' $(FILELIST) | grep -v '^\s*$$' | \
	    sed 's|^|set_global_assignment -name SYSTEMVERILOG_FILE $(PROJ_ROOT)/|' >> $(QUARTUS_QSF)
	@echo ""                                                         >> $(QUARTUS_QSF)
	@echo "# Timing / effort"                                        >> $(QUARTUS_QSF)
	@echo "set_global_assignment -name SYNTHESIS_EFFORT AUTO"       >> $(QUARTUS_QSF)
	@echo "set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON" >> $(QUARTUS_QSF)

	# --- Run Quartus synthesis (map → fit → asm → sta) ---
	cd $(IMPL_DIR) && $(QUARTUS_MAP) --read_settings_files=on \
	    --write_settings_files=off $(DESIGN) -c $(DESIGN)
	cd $(IMPL_DIR) && $(QUARTUS_FIT) --read_settings_files=on \
	    --write_settings_files=off $(DESIGN) -c $(DESIGN)
	cd $(IMPL_DIR) && $(QUARTUS_ASM) --read_settings_files=on \
	    --write_settings_files=off $(DESIGN) -c $(DESIGN)
	cd $(IMPL_DIR) && $(QUARTUS_STA) $(DESIGN) -c $(DESIGN) \
	    --report_script=$(SCRIPTS_DIR)/quartus_sta.tcl 2>/dev/null || true

	# --- Copy key reports to reports dir ---
	@cp -f $(IMPL_DIR)/$(DESIGN).map.rpt   $(REPORTS_DIR)/quartus_map.rpt    2>/dev/null || true
	@cp -f $(IMPL_DIR)/$(DESIGN).fit.rpt   $(REPORTS_DIR)/quartus_fit.rpt    2>/dev/null || true
	@cp -f $(IMPL_DIR)/$(DESIGN).sta.rpt   $(REPORTS_DIR)/quartus_sta.rpt    2>/dev/null || true

	@echo ""
	@echo "  ✔ Impl directory  : $(IMPL_DIR)"
	@echo "  ✔ Map report      : $(REPORTS_DIR)/quartus_map.rpt"
	@echo "  ✔ Fit report      : $(REPORTS_DIR)/quartus_fit.rpt"
	@echo "  ✔ STA report      : $(REPORTS_DIR)/quartus_sta.rpt"

##############################################################################
# Directory creation (flow-aware)
##############################################################################
.PHONY: dirs
dirs:
	@mkdir -p $(REPORTS_DIR) $(NETLIST_DIR) $(SCRIPTS_DIR) $(IMPL_DIR)

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
	@echo "--- Cleaning FLOW=$(FLOW) outputs ---"
	@rm -rf $(SYNTH_DIR)/$(FLOW) \
	         $(REPORTS_DIR)/yosys.log $(SCRIPTS_DIR)/read_rtl.ys \
	         $(SCRIPTS_DIR)/vivado_synth.tcl vivado*.log vivado*.jou
	@echo "  ✔ Clean done ($(FLOW))"

.PHONY: clean_all
clean_all:
	@echo "--- Cleaning ALL flow outputs ---"
	@rm -rf $(SYNTH_DIR)/sky130 $(SYNTH_DIR)/xilinx $(SYNTH_DIR)/altera \
	         $(REPORTS_DIR)/yosys.log $(SCRIPTS_DIR)/read_rtl.ys \
	         $(SCRIPTS_DIR)/vivado_synth.tcl vivado*.log vivado*.jou
	@echo "  ✔ Clean done (all flows)"

##############################################################################
# Help
##############################################################################
.PHONY: help
help:
	@echo ""
	@echo "  ── Targets ─────────────────────────────────────────────────────"
	@echo "    make  /  make synth       – synthesise with current FLOW (default: sky130)"
	@echo "    make FLOW=sky130          – Yosys + sky130 HD ASIC"
	@echo "    make FLOW=xilinx          – Vivado → Xilinx/AMD FPGA"
	@echo "    make FLOW=altera          – Quartus → Intel/Altera FPGA"
	@echo "    make synth_all            – run all three flows"
	@echo "    make lint                 – Verilator lint check"
	@echo "    make show                 – graphviz netlist view (sky130)"
	@echo "    make clean                – remove outputs for current FLOW"
	@echo "    make clean_all            – remove ALL flow outputs"
	@echo ""
	@echo "  ── Common variables ─────────────────────────────────────────────"
	@echo "    FLOW         = $(FLOW)"
	@echo "    DESIGN       = $(DESIGN)"
	@echo "    TOP_MODULE   = $(TOP_MODULE)"
	@echo ""
	@echo "  ── sky130 variables ─────────────────────────────────────────────"
	@echo "    SKY130_ROOT  = $(SKY130_ROOT)"
	@echo "    LIBERTY      = TT 25C 1v80"
	@echo ""
	@echo "  ── Xilinx variables ─────────────────────────────────────────────"
	@echo "    XILINX_PART  = $(XILINX_PART)"
	@echo "    VIVADO       = $(VIVADO)"
	@echo ""
	@echo "  ── Altera variables ─────────────────────────────────────────────"
	@echo "    ALTERA_DEVICE = $(ALTERA_DEVICE)"
	@echo "    ALTERA_FAMILY = $(ALTERA_FAMILY)"
	@echo "    QUARTUS       = $(QUARTUS)"
	@echo ""
