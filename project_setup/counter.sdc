# SDC Constraints – counter design
# Target clock: 100 MHz  →  period = 10 ns

# ── Primary clock ────────────────────────────────────────────────────────────
create_clock -name clk \
             -period 10.0 \
             -waveform {0 5} \
             [get_ports clk]

# ── Clock uncertainty & transition ───────────────────────────────────────────
set_clock_uncertainty 0.2 [get_clocks clk]
set_clock_transition  0.1 [get_clocks clk]

# ── Input / Output delays (assume 40 % of period for external logic) ─────────
set_input_delay  -max 4.0 -clock clk [get_ports {rst_n en}]
set_input_delay  -min 0.5 -clock clk [get_ports {rst_n en}]

set_output_delay -max 4.0 -clock clk [get_ports {count[*] overflow}]
set_output_delay -min 0.5 -clock clk [get_ports {count[*] overflow}]

# ── Driving cell / load (sky130 generic estimates) ───────────────────────────
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 \
                 -pin X \
                 [all_inputs]

set_load 0.05 [all_outputs]   ;# pF

# ── False paths ───────────────────────────────────────────────────────────────
# (none required for this simple design)
