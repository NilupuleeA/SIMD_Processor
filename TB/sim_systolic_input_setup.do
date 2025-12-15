# ============================================================================
# sim_systolic_input_setup.do
# ModelSim/Questa simulation script for systolic_input_setup testbench
# ============================================================================

# Clean up previous simulation
quit -sim

# Create work library if it doesn't exist
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile design files
echo "=========================================="
echo "Compiling Design Files..."
echo "=========================================="

vlog -work work ../RTL/def.v
vlog -work work ../RTL/systolic_input_setup.v
vlog -work work ../TB/tb_systolic_input_setup.v

# Start simulation
echo "=========================================="
echo "Starting Simulation..."
echo "=========================================="

vsim -voptargs=+acc work.tb_systolic_input_setup

# ============================================================================
# WAVEFORM CONFIGURATION - ORGANIZED BY GROUPS
# ============================================================================

# Configure wave window
view wave
delete wave *

# Set radix and other display options
radix define hex

# ----------------------------------------------------------------------------
# GROUP 1: CLOCK & RESET
# ----------------------------------------------------------------------------
add wave -noupdate -divider {CLOCK & RESET}
add wave -noupdate -color Yellow -label "CLK" /tb_systolic_input_setup/clk
add wave -noupdate -color Orange -label "RST_N" /tb_systolic_input_setup/rst_n

# ----------------------------------------------------------------------------
# GROUP 2: CONTROL SIGNALS
# ----------------------------------------------------------------------------
add wave -noupdate -divider {CONTROL SIGNALS}
add wave -noupdate -color Cyan -label "EN" /tb_systolic_input_setup/en
add wave -noupdate -color Cyan -label "BRAM_READ_EN" /tb_systolic_input_setup/bram_read_en

# ----------------------------------------------------------------------------
# GROUP 3: BRAM INTERFACE
# ----------------------------------------------------------------------------
add wave -noupdate -divider {BRAM INTERFACE}
add wave -noupdate -radix hex -label "BRAM_ADDR" /tb_systolic_input_setup/bram_addr
add wave -noupdate -radix hex -label "BRAM_DOUT[63:0]" /tb_systolic_input_setup/bram_dout
add wave -noupdate -radix hex -label "BRAM_DOUT_REG" /tb_systolic_input_setup/bram_dout_reg

# ----------------------------------------------------------------------------
# GROUP 4: BRAM DATA BREAKDOWN (Individual Bytes)
# ----------------------------------------------------------------------------
add wave -noupdate -divider {BRAM DATA BYTES}
add wave -noupdate -radix hex -label "BRAM_DATA[7]" -color "Magenta" /tb_systolic_input_setup/bram_dout[63:56]
add wave -noupdate -radix hex -label "BRAM_DATA[6]" -color "Magenta" /tb_systolic_input_setup/bram_dout[55:48]
add wave -noupdate -radix hex -label "BRAM_DATA[5]" -color "Magenta" /tb_systolic_input_setup/bram_dout[47:40]
add wave -noupdate -radix hex -label "BRAM_DATA[4]" -color "Magenta" /tb_systolic_input_setup/bram_dout[39:32]
add wave -noupdate -radix hex -label "BRAM_DATA[3]" -color "Violet" /tb_systolic_input_setup/bram_dout[31:24]
add wave -noupdate -radix hex -label "BRAM_DATA[2]" -color "Violet" /tb_systolic_input_setup/bram_dout[23:16]
add wave -noupdate -radix hex -label "BRAM_DATA[1]" -color "Violet" /tb_systolic_input_setup/bram_dout[15:8]
add wave -noupdate -radix hex -label "BRAM_DATA[0]" -color "Violet" /tb_systolic_input_setup/bram_dout[7:0]

# ----------------------------------------------------------------------------
# GROUP 5: DUT INPUTS
# ----------------------------------------------------------------------------
add wave -noupdate -divider {DUT INPUTS}
add wave -noupdate -color Green -label "DUT_CLK" /tb_systolic_input_setup/dut/clk_i
add wave -noupdate -color Green -label "DUT_RST_N" /tb_systolic_input_setup/dut/rst_ni
add wave -noupdate -color Green -label "DUT_EN" /tb_systolic_input_setup/dut/en_i
add wave -noupdate -radix hex -color Green -label "DUT_WORD_IN[63:0]" /tb_systolic_input_setup/dut/word_i

# ----------------------------------------------------------------------------
# GROUP 6: DUT INTERNAL BUFFERS (Shift Register Stages)
# ----------------------------------------------------------------------------
add wave -noupdate -divider {SHIFT REGISTER BUFFERS}
add wave -noupdate -radix hex -label "BUF_Q1[55:0] (1-cycle)" -color "Gold" /tb_systolic_input_setup/dut/buf_q1
add wave -noupdate -radix hex -label "BUF_Q2[47:0] (2-cycle)" -color "Gold" /tb_systolic_input_setup/dut/buf_q2
add wave -noupdate -radix hex -label "BUF_Q3[39:0] (3-cycle)" -color "Gold" /tb_systolic_input_setup/dut/buf_q3
add wave -noupdate -radix hex -label "BUF_Q4[31:0] (4-cycle)" -color "Gold" /tb_systolic_input_setup/dut/buf_q4
add wave -noupdate -radix hex -label "BUF_Q5[23:0] (5-cycle)" -color "Khaki" /tb_systolic_input_setup/dut/buf_q5
add wave -noupdate -radix hex -label "BUF_Q6[15:0] (6-cycle)" -color "Khaki" /tb_systolic_input_setup/dut/buf_q6
add wave -noupdate -radix hex -label "BUF_Q7[7:0]  (7-cycle)" -color "Khaki" /tb_systolic_input_setup/dut/buf_q7

# ----------------------------------------------------------------------------
# GROUP 7: DUT OUTPUT (Skewed Data)
# ----------------------------------------------------------------------------
add wave -noupdate -divider {OUTPUT - SKEWED DATA}
add wave -noupdate -radix hex -label "SKEW_OUT[63:0]" -color "SpringGreen" /tb_systolic_input_setup/skew_out

# ----------------------------------------------------------------------------
# GROUP 8: OUTPUT DATA BREAKDOWN (Individual Bytes)
# ----------------------------------------------------------------------------
add wave -noupdate -divider {OUTPUT BYTES}
add wave -noupdate -radix hex -label "SKEW_OUT[7]" -color "Lime" /tb_systolic_input_setup/skew_out[63:56]
add wave -noupdate -radix hex -label "SKEW_OUT[6]" -color "Lime" /tb_systolic_input_setup/skew_out[55:48]
add wave -noupdate -radix hex -label "SKEW_OUT[5]" -color "Lime" /tb_systolic_input_setup/skew_out[47:40]
add wave -noupdate -radix hex -label "SKEW_OUT[4]" -color "Lime" /tb_systolic_input_setup/skew_out[39:32]
add wave -noupdate -radix hex -label "SKEW_OUT[3]" -color "Aquamarine" /tb_systolic_input_setup/skew_out[31:24]
add wave -noupdate -radix hex -label "SKEW_OUT[2]" -color "Aquamarine" /tb_systolic_input_setup/skew_out[23:16]
add wave -noupdate -radix hex -label "SKEW_OUT[1]" -color "Aquamarine" /tb_systolic_input_setup/skew_out[15:8]
add wave -noupdate -radix hex -label "SKEW_OUT[0]" -color "Aquamarine" /tb_systolic_input_setup/skew_out[7:0]

# ----------------------------------------------------------------------------
# GROUP 9: TEST CONTROL
# ----------------------------------------------------------------------------
add wave -noupdate -divider {TEST CONTROL}
add wave -noupdate -radix unsigned -label "TEST_INDEX_i" /tb_systolic_input_setup/i
add wave -noupdate -radix hex -label "TEST_DATA" /tb_systolic_input_setup/test_data

# ============================================================================
# WAVEFORM DISPLAY CONFIGURATION
# ============================================================================

# Configure wave window appearance
configure wave -namecolwidth 250
configure wave -valuecolwidth 120
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

# ============================================================================
# RUN SIMULATION
# ============================================================================

echo "=========================================="
echo "Running Simulation..."
echo "=========================================="

# Run simulation for sufficient time
run 1000ns

# Zoom to show entire waveform
wave zoom full

echo "=========================================="
echo "Simulation Complete!"
echo "Check waveform for results"
echo "=========================================="

# Optional: Automatically zoom to specific time range
# wave zoom range 0ns 500ns
