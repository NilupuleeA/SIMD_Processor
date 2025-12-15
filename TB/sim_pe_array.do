# ==============================================
# sim_pe_array.do
# QuestaSim script to simulate PE Array module
# ==============================================

# Quit any existing simulation
quit -sim

# Create work library
vlib work

# Compile design files
vlog -work work ../RTL/def.v
vlog -work work ../RTL/pe.v
vlog -work work ../RTL/pe_array.v
vlog -work work ../TB/tb_pe_array.v

# Load simulation
vsim -voptargs="+acc" work.tb_pe_array

# ==============================================
# Add Waves - Grouped by Function
# ==============================================

# --- Clock and Reset ---
add wave -divider "======== CLOCK AND RESET ========"
add wave -radix binary   /tb_pe_array/clk_i
add wave -radix binary   /tb_pe_array/rst_ni

# --- Top Level Control ---
add wave -divider "======== TOP LEVEL CONTROL ========"
add wave -radix binary   /tb_pe_array/clr_i
add wave -radix binary   /tb_pe_array/clr_o
add wave -radix binary   /tb_pe_array/we_i
add wave -radix binary   /tb_pe_array/we_o
add wave -radix unsigned /tb_pe_array/mode_i

# --- Top Level Data Input ---
add wave -divider "======== TOP LEVEL INPUT ========"
add wave -radix hexadecimal /tb_pe_array/srca_word_i
add wave -radix decimal     /tb_pe_array/srcb_i

# --- Top Level Data Output ---
add wave -divider "======== TOP LEVEL OUTPUT ========"
add wave -radix hexadecimal /tb_pe_array/srca_word_o
add wave -radix hexadecimal /tb_pe_array/wordp_o

# --- Individual PE Outputs (Extracted) ---
add wave -divider "======== PE OUTPUT SUMMARY ========"
add wave -radix decimal /tb_pe_array/pe0_psum
add wave -radix decimal /tb_pe_array/pe1_psum
add wave -radix decimal /tb_pe_array/pe2_psum
add wave -radix decimal /tb_pe_array/pe3_psum
add wave -radix decimal /tb_pe_array/pe4_psum
add wave -radix decimal /tb_pe_array/pe5_psum
add wave -radix decimal /tb_pe_array/pe6_psum
add wave -radix decimal /tb_pe_array/pe7_psum

# ==============================================
# PE0 Signals
# ==============================================
add wave -divider "======== PE0 ========"
add wave -divider "PE0 - Control"
add wave -radix binary   /tb_pe_array/dut/pe0/clr_i
add wave -radix binary   /tb_pe_array/dut/pe0/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe0/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe0/state_q

add wave -divider "PE0 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe0/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe0/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe0/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe0/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe0/psum_o

add wave -divider "PE0 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe0/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe0/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe0/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe0/max_result

# ==============================================
# PE1 Signals
# ==============================================
add wave -divider "======== PE1 ========"
add wave -divider "PE1 - Control"
add wave -radix binary   /tb_pe_array/dut/pe1/clr_i
add wave -radix binary   /tb_pe_array/dut/pe1/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe1/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe1/state_q

add wave -divider "PE1 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe1/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe1/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe1/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe1/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe1/psum_o

add wave -divider "PE1 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe1/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe1/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe1/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe1/max_result

# ==============================================
# PE2 Signals
# ==============================================
add wave -divider "======== PE2 ========"
add wave -divider "PE2 - Control"
add wave -radix binary   /tb_pe_array/dut/pe2/clr_i
add wave -radix binary   /tb_pe_array/dut/pe2/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe2/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe2/state_q

add wave -divider "PE2 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe2/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe2/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe2/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe2/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe2/psum_o

add wave -divider "PE2 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe2/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe2/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe2/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe2/max_result

# ==============================================
# PE3 Signals
# ==============================================
add wave -divider "======== PE3 ========"
add wave -divider "PE3 - Control"
add wave -radix binary   /tb_pe_array/dut/pe3/clr_i
add wave -radix binary   /tb_pe_array/dut/pe3/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe3/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe3/state_q

add wave -divider "PE3 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe3/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe3/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe3/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe3/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe3/psum_o

add wave -divider "PE3 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe3/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe3/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe3/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe3/max_result

# ==============================================
# PE4 Signals
# ==============================================
add wave -divider "======== PE4 ========"
add wave -divider "PE4 - Control"
add wave -radix binary   /tb_pe_array/dut/pe4/clr_i
add wave -radix binary   /tb_pe_array/dut/pe4/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe4/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe4/state_q

add wave -divider "PE4 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe4/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe4/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe4/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe4/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe4/psum_o

add wave -divider "PE4 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe4/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe4/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe4/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe4/max_result

# ==============================================
# PE5 Signals
# ==============================================
add wave -divider "======== PE5 ========"
add wave -divider "PE5 - Control"
add wave -radix binary   /tb_pe_array/dut/pe5/clr_i
add wave -radix binary   /tb_pe_array/dut/pe5/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe5/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe5/state_q

add wave -divider "PE5 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe5/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe5/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe5/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe5/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe5/psum_o

add wave -divider "PE5 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe5/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe5/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe5/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe5/max_result

# ==============================================
# PE6 Signals
# ==============================================
add wave -divider "======== PE6 ========"
add wave -divider "PE6 - Control"
add wave -radix binary   /tb_pe_array/dut/pe6/clr_i
add wave -radix binary   /tb_pe_array/dut/pe6/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe6/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe6/state_q

add wave -divider "PE6 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe6/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe6/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe6/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe6/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe6/psum_o

add wave -divider "PE6 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe6/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe6/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe6/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe6/max_result

# ==============================================
# PE7 Signals
# ==============================================
add wave -divider "======== PE7 ========"
add wave -divider "PE7 - Control"
add wave -radix binary   /tb_pe_array/dut/pe7/clr_i
add wave -radix binary   /tb_pe_array/dut/pe7/clr_o
add wave -radix unsigned /tb_pe_array/dut/pe7/mode_i
add wave -radix unsigned /tb_pe_array/dut/pe7/state_q

add wave -divider "PE7 - Data"
add wave -radix decimal  /tb_pe_array/dut/pe7/srca_i
add wave -radix decimal  /tb_pe_array/dut/pe7/srcb_i
add wave -radix decimal  /tb_pe_array/dut/pe7/srca_o
add wave -radix decimal  /tb_pe_array/dut/pe7/srcb_o
add wave -radix decimal  /tb_pe_array/dut/pe7/psum_o

add wave -divider "PE7 - Internal"
add wave -radix decimal  /tb_pe_array/dut/pe7/ab_q
add wave -radix decimal  /tb_pe_array/dut/pe7/psum_q
add wave -radix decimal  /tb_pe_array/dut/pe7/mult_result
add wave -radix decimal  /tb_pe_array/dut/pe7/max_result

# ==============================================
# PE Array Internal Wires
# ==============================================
add wave -divider "======== PE ARRAY INTERNAL ========"
add wave -divider "Clear Chain"
add wave -radix binary /tb_pe_array/dut/clr_q1
add wave -radix binary /tb_pe_array/dut/clr_q2
add wave -radix binary /tb_pe_array/dut/clr_q3
add wave -radix binary /tb_pe_array/dut/clr_q4
add wave -radix binary /tb_pe_array/dut/clr_q5
add wave -radix binary /tb_pe_array/dut/clr_q6
add wave -radix binary /tb_pe_array/dut/clr_q7

add wave -divider "SrcB Chain"
add wave -radix decimal /tb_pe_array/dut/srcb_q1
add wave -radix decimal /tb_pe_array/dut/srcb_q2
add wave -radix decimal /tb_pe_array/dut/srcb_q3
add wave -radix decimal /tb_pe_array/dut/srcb_q4
add wave -radix decimal /tb_pe_array/dut/srcb_q5
add wave -radix decimal /tb_pe_array/dut/srcb_q6
add wave -radix decimal /tb_pe_array/dut/srcb_q7

add wave -divider "Write Enable"
add wave -radix binary /tb_pe_array/dut/we_shift_reg_q
add wave -radix binary /tb_pe_array/dut/we0
add wave -radix binary /tb_pe_array/dut/we1
add wave -radix binary /tb_pe_array/dut/we2
add wave -radix binary /tb_pe_array/dut/we3
add wave -radix binary /tb_pe_array/dut/we4
add wave -radix binary /tb_pe_array/dut/we5
add wave -radix binary /tb_pe_array/dut/we6
add wave -radix binary /tb_pe_array/dut/we7

# ==============================================
# Run Simulation
# ==============================================
run -all

# Zoom to fit all waves
wave zoom full
