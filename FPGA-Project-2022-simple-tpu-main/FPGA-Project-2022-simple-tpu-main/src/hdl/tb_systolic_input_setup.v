//
// tb_systolic_input_setup.v
//
// Testbench for systolic_input_setup module with Xilinx BRAM
// BRAM configuration: 64-bit data width, single address fetch
//

`timescale 1ns/1ps

`include "def.v"

module tb_systolic_input_setup();

  // Clock and reset
  reg clk;
  reg rst_n;
  
  // Control signals
  reg en;
  reg bram_read_en;
  
  // BRAM interface (address width for 32x32 im2col data: ~1013 entries need 10 bits)
  reg  [9:0] bram_addr;
  wire [63:0] bram_dout;
  
  // DUT interface
  wire [`WORD_WIDTH-1:0] skew_out;
  
  // Test control
  integer i;
  reg [63:0] test_data;
  
  //==========================================================================
  // Xilinx BRAM Instantiation (64-bit width)
  // Using behavioral model for simulation
  //==========================================================================
  reg [63:0] bram_memory [0:1023];  // 1024 x 64-bit for 32x32 image im2col data
  reg [63:0] bram_dout_reg;
  
  // BRAM read logic (synchronous read)
  always @(posedge clk) begin
    if (bram_read_en) begin
      bram_dout_reg <= bram_memory[bram_addr];
    end
  end
  
  assign bram_dout = bram_dout_reg;
  
  //==========================================================================
  // DUT: systolic_input_setup
  //==========================================================================
  systolic_input_setup dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .en_i(en),
    .word_i(bram_dout),
    .skew_o(skew_out)
  );
  
  //==========================================================================
  // Clock generation: 100MHz (10ns period)
  //==========================================================================
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  //==========================================================================
  // Initialize BRAM with im2col image data from .mem file
  //==========================================================================
  initial begin
    // Initialize all memory locations to 0
    for (i = 0; i < 1024; i = i + 1) begin
      bram_memory[i] = 64'h0;
    end
    
    // Load im2col image data from .mem file
    // Each 64-bit word contains 8 x 8-bit pixels
    // Format: kernel windows stored consecutively for systolic array
    $readmemh("../../../../input/image.mem", bram_memory);
    
    $display("Loaded image.mem into BRAM (im2col format)");
    $display("  - Each 64-bit word = 8 pixels");
    $display("  - Kernel windows stored consecutively");
  end
  
  //==========================================================================
  // Test stimulus
  //==========================================================================
  initial begin
    // Initialize signals
    rst_n = 0;
    en = 0;
    bram_read_en = 0;
    bram_addr = 12'h0;
    
    // Generate VCD file for waveform viewing
    $dumpfile("tb_systolic_input_setup.vcd");
    $dumpvars(0, tb_systolic_input_setup);
    
    // Display header
    $display("========================================");
    $display("Systolic Input Setup Testbench");
    $display("BRAM: 64-bit width, 4096 depth");
    $display("========================================");
    
    // Reset sequence
    #20;
    rst_n = 1;
    #10;
    
    $display("\n[%0t] Reset released", $time);
    
    //----------------------------------------------------------------------
    // Test 1: Sequential data feed from BRAM
    //----------------------------------------------------------------------
    $display("\n--- Test 1: Sequential Data Feed ---");
    #10;
    en = 1;
    bram_read_en = 1;
    
    // Read first 8 words from BRAM
    for (i = 0; i < 8; i = i + 1) begin
      bram_addr = i;
      #10;
      $display("[%0t] BRAM[%0d] = 0x%h, skew_out = 0x%h", 
               $time, i, bram_dout, skew_out);
    end
    
    // Wait for pipeline to fill
    $display("\n--- Waiting for pipeline delay ---");
    #80;
    $display("[%0t] Pipeline filled, skew_out = 0x%h", $time, skew_out);
    
    //----------------------------------------------------------------------
    // Test 2: Enable/Disable control
    //----------------------------------------------------------------------
    $display("\n--- Test 2: Enable/Disable Control ---");
    bram_addr = 8;
    #10;
    $display("[%0t] EN=1, BRAM[8] = 0x%h", $time, bram_dout);
    
    #30;
    en = 0;
    $display("[%0t] EN=0 (disabled)", $time);
    
    bram_addr = 9;
    #30;
    $display("[%0t] EN=0, skew_out should not change", $time);
    
    en = 1;
    #10;
    $display("[%0t] EN=1 (re-enabled)", $time);
    
    //----------------------------------------------------------------------
    // Test 3: Burst read from BRAM
    //----------------------------------------------------------------------
    $display("\n--- Test 3: Burst Read ---");
    for (i = 16; i < 24; i = i + 1) begin
      bram_addr = i;
      #10;
      $display("[%0t] BRAM[%0d] = 0x%h", $time, i, bram_dout);
    end
    
    #100;
    
    //----------------------------------------------------------------------
    // Test 4: Reset during operation
    //----------------------------------------------------------------------
    $display("\n--- Test 4: Reset During Operation ---");
    rst_n = 0;
    #20;
    $display("[%0t] Reset asserted, skew_out = 0x%h", $time, skew_out);
    
    rst_n = 1;
    #10;
    $display("[%0t] Reset released", $time);
    
    // Continue operation
    bram_addr = 0;
    #100;
    
    //----------------------------------------------------------------------
    // Test 5: Random access pattern
    //----------------------------------------------------------------------
    $display("\n--- Test 5: Random Access ---");
    bram_addr = 5;  #10;
    bram_addr = 2;  #10;
    bram_addr = 7;  #10;
    bram_addr = 1;  #10;
    bram_addr = 9;  #10;
    
    #100;
    
    // End simulation
    $display("\n========================================");
    $display("Simulation completed successfully!");
    $display("========================================");
    #20;
    $finish;
  end
  
  //==========================================================================
  // Monitor: Continuous display of key signals
  //==========================================================================
  initial begin
    $monitor("[%0t] clk=%b rst_n=%b en=%b bram_addr=0x%h bram_dout=0x%h skew_out=0x%h", 
             $time, clk, rst_n, en, bram_addr, bram_dout, skew_out);
  end
  
  //==========================================================================
  // Timeout watchdog
  //==========================================================================
  initial begin
    #10000;
    $display("\nERROR: Simulation timeout!");
    $finish;
  end

endmodule
