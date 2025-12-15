# cd <path_to_hdl_folder>
# do sim_parallel_pixel_fetch.do# =============================================================================
# sim_parallel_pixel_fetch.do
# ModelSim/QuestaSim simulation script for parallel_pixel_fetch module
# =============================================================================

# Quit any existing simulation
quit -sim

# Create work library
vlib work

# Compile source files
vlog -work work def.v
vlog -work work parallel_pixel_fetch.v
vlog -work work tb_parallel_pixel_fetch.v

# Load simulation
vsim -voptargs="+acc" work.tb_parallel_pixel_fetch

# =============================================================================
# WAVEFORM CONFIGURATION - Grouped signals for clear observation
# =============================================================================

# Open wave window first
view wave

# Delete all existing waves
delete wave *

# -----------------------------------------------------------------------------
# Group 1: Clock and Reset
# -----------------------------------------------------------------------------
add wave -divider "=== CLOCK & RESET ==="
add wave -color "Yellow"   -label "CLK"  /tb_parallel_pixel_fetch/clk
add wave -color "Red"      -label "RSTn" /tb_parallel_pixel_fetch/rstn

# -----------------------------------------------------------------------------
# Group 2: Control Signals
# -----------------------------------------------------------------------------
add wave -divider "=== CONTROL SIGNALS ==="
add wave -color "Cyan"     -label "Fetch Enable"  /tb_parallel_pixel_fetch/fetch_en
add wave -color "Green"    -label "Fetch Start"   /tb_parallel_pixel_fetch/fetch_start
add wave -color "Magenta"  -label "Fetch Done"    /tb_parallel_pixel_fetch/fetch_done
add wave -color "Orange"   -label "Pixel Valid"   /tb_parallel_pixel_fetch/pixel_valid

# -----------------------------------------------------------------------------
# Group 3: Address Configuration
# -----------------------------------------------------------------------------
add wave -divider "=== ADDRESS CONFIG ==="
add wave -radix unsigned -color "White" -label "Base Addr"   /tb_parallel_pixel_fetch/base_addr
add wave -radix unsigned -color "White" -label "Row Offset"  /tb_parallel_pixel_fetch/row_offset
add wave -radix unsigned -color "White" -label "Col Offset"  /tb_parallel_pixel_fetch/col_offset

# -----------------------------------------------------------------------------
# Group 4: Memory Interface
# -----------------------------------------------------------------------------
add wave -divider "=== MEMORY INTERFACE ==="
add wave -color "Yellow"   -label "Mem Read En"   /tb_parallel_pixel_fetch/mem_rd_en
add wave -radix unsigned -color "Cyan" -label "Mem Address"  /tb_parallel_pixel_fetch/mem_rd_addr
add wave -radix hex -color "Green" -label "Mem Data (64b)" /tb_parallel_pixel_fetch/mem_rd_data

# -----------------------------------------------------------------------------
# Group 5: DUT Internal State
# -----------------------------------------------------------------------------
add wave -divider "=== DUT INTERNAL STATE ==="
add wave -radix unsigned -color "Orange" -label "State"      /tb_parallel_pixel_fetch/dut/state
add wave -radix unsigned -color "Orange" -label "Wait Count" /tb_parallel_pixel_fetch/dut/wait_count

# -----------------------------------------------------------------------------
# Group 6: Individual Pixel Outputs (8-bit each)
# -----------------------------------------------------------------------------
add wave -divider "=== PIXEL OUTPUTS (8-bit) ==="
add wave -radix hex -color "Gold" -label "Pixel Flat (64b)" /tb_parallel_pixel_fetch/pixel_out_flat
add wave -radix hex -color "Coral"      -label "Pixel[0]" /tb_parallel_pixel_fetch/pixel_0
add wave -radix hex -color "Coral"      -label "Pixel[1]" /tb_parallel_pixel_fetch/pixel_1
add wave -radix hex -color "Coral"      -label "Pixel[2]" /tb_parallel_pixel_fetch/pixel_2
add wave -radix hex -color "Coral"      -label "Pixel[3]" /tb_parallel_pixel_fetch/pixel_3
add wave -radix hex -color "SkyBlue"    -label "Pixel[4]" /tb_parallel_pixel_fetch/pixel_4
add wave -radix hex -color "SkyBlue"    -label "Pixel[5]" /tb_parallel_pixel_fetch/pixel_5
add wave -radix hex -color "SkyBlue"    -label "Pixel[6]" /tb_parallel_pixel_fetch/pixel_6
add wave -radix hex -color "SkyBlue"    -label "Pixel[7]" /tb_parallel_pixel_fetch/pixel_7

# -----------------------------------------------------------------------------
# Group 7: PE Array Interface (16-bit data for each PE)
# -----------------------------------------------------------------------------
add wave -divider "=== PE ARRAY INTERFACE (16-bit) ==="
add wave -radix hex -color "Gold" -label "PE Word (128b)" /tb_parallel_pixel_fetch/pixel_word_out

add wave -divider "PE Data Breakdown"
add wave -radix hex -color "LimeGreen"  -label "PE0 Data" /tb_parallel_pixel_fetch/pe_data_0
add wave -radix hex -color "LimeGreen"  -label "PE1 Data" /tb_parallel_pixel_fetch/pe_data_1
add wave -radix hex -color "LimeGreen"  -label "PE2 Data" /tb_parallel_pixel_fetch/pe_data_2
add wave -radix hex -color "LimeGreen"  -label "PE3 Data" /tb_parallel_pixel_fetch/pe_data_3
add wave -radix hex -color "Violet"     -label "PE4 Data" /tb_parallel_pixel_fetch/pe_data_4
add wave -radix hex -color "Violet"     -label "PE5 Data" /tb_parallel_pixel_fetch/pe_data_5
add wave -radix hex -color "Violet"     -label "PE6 Data" /tb_parallel_pixel_fetch/pe_data_6
add wave -radix hex -color "Violet"     -label "PE7 Data" /tb_parallel_pixel_fetch/pe_data_7

# -----------------------------------------------------------------------------
# Group 8: Test Status
# -----------------------------------------------------------------------------
add wave -divider "=== TEST STATUS ==="
add wave -radix unsigned -color "White" -label "Fetch Count" /tb_parallel_pixel_fetch/fetch_count
add wave -radix unsigned -color "Red"   -label "Error Count" /tb_parallel_pixel_fetch/error_count

# =============================================================================
# WAVEFORM DISPLAY SETTINGS
# =============================================================================

# Configure wave window
configure wave -namecolwidth 180
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

# Set default radix
radix hex

# Zoom to fit
wave zoom full

# =============================================================================
# RUN SIMULATION
# =============================================================================

# Run simulation
run -all

# Zoom to see all waveforms
wave zoom full

# Print completion message
echo "============================================"
echo "  Simulation Complete!"
echo "  Check waveform window for signal groups:"
echo "    - Clock & Reset"
echo "    - Control Signals"  
echo "    - Address Config"
echo "    - Memory Interface"
echo "    - DUT Internal State"
echo "    - Pixel Outputs (8-bit)"
echo "    - PE Array Interface (16-bit)"
echo "    - Test Status"
echo "============================================"
