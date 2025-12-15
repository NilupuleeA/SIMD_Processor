# ==============================================
# sim_pe.do
# QuestaSim script to simulate single PE module
# ==============================================

# Quit any existing simulation
quit -sim

# Create work library
vlib work

# Compile design files
vlog -work work ../RTL/def.v
vlog -work work ../RTL/pe.v
vlog -work work ../TB/tb_pe.v

# Load simulation
vsim -voptargs="+acc" work.tb_pe

# ==============================================
# Add Waves - Grouped by Function
# ==============================================

# --- Clock and Reset ---
add wave -divider "Clock and Reset"
add wave -radix binary   /tb_pe/clk_i
add wave -radix binary   /tb_pe/rst_ni

# --- Control Signals ---
add wave -divider "Control Signals"
add wave -radix binary   /tb_pe/clr_i
add wave -radix binary   /tb_pe/clr_o
add wave -radix unsigned /tb_pe/mode_i

# --- Input Data ---
add wave -divider "Input Data"
add wave -radix decimal  /tb_pe/srca_i
add wave -radix decimal  /tb_pe/srcb_i

# --- Output Data ---
add wave -divider "Output Data"
add wave -radix decimal  /tb_pe/srca_o
add wave -radix decimal  /tb_pe/srcb_o
add wave -radix decimal  /tb_pe/psum_o

# --- Internal PE State ---
add wave -divider "PE Internal - State Machine"
add wave -radix unsigned /tb_pe/dut/state_q
add wave -radix unsigned /tb_pe/dut/state_d

# --- Internal PE Registers ---
add wave -divider "PE Internal - Pipeline Regs"
add wave -radix decimal  /tb_pe/dut/srca_q
add wave -radix decimal  /tb_pe/dut/srcb_q
add wave -radix decimal  /tb_pe/dut/ab_q
add wave -radix decimal  /tb_pe/dut/psum_q
add wave -radix binary   /tb_pe/dut/clr_q

# --- Internal PE Combinational ---
add wave -divider "PE Internal - Combinational"
add wave -radix decimal  /tb_pe/dut/mult_result
add wave -radix decimal  /tb_pe/dut/srca_ext
add wave -radix decimal  /tb_pe/dut/max_result
add wave -radix decimal  /tb_pe/dut/ab_d
add wave -radix decimal  /tb_pe/dut/psum_d

# ==============================================
# Run Simulation
# ==============================================
run -all

# Zoom to fit all waves
wave zoom full
