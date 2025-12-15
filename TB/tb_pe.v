//
// tb_pe.v
//
// Testbench for single PE module
// Tests both convolution and maxpool modes
//
`timescale 1ns/1ps

`include "def.v"

module tb_pe;

  //--------------------------------------------------
  // Clock and Reset
  //--------------------------------------------------
  reg clk_i;
  reg rst_ni;

  //--------------------------------------------------
  // Control Signals
  //--------------------------------------------------
  reg        clr_i;
  wire       clr_o;
  reg  [1:0] mode_i;

  //--------------------------------------------------
  // Data Signals
  //--------------------------------------------------
  reg  signed [`DATA_WIDTH-1:0] srca_i;
  reg  signed [`DATA_WIDTH-1:0] srcb_i;
  wire signed [`DATA_WIDTH-1:0] srca_o;
  wire signed [`DATA_WIDTH-1:0] srcb_o;
  wire signed [`DATA_WIDTH-1:0] psum_o;

  //--------------------------------------------------
  // DUT Instantiation
  //--------------------------------------------------
  pe dut (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .clr_i  (clr_i),
    .clr_o  (clr_o),
    .mode_i (mode_i),
    .srca_i (srca_i),
    .srcb_i (srcb_i),
    .srca_o (srca_o),
    .srcb_o (srcb_o),
    .psum_o (psum_o)
  );

  //--------------------------------------------------
  // Clock Generation (100 MHz)
  //--------------------------------------------------
  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  //--------------------------------------------------
  // Test Sequence
  //--------------------------------------------------
  integer i;
  
  initial begin
    $display("========================================");
    $display("       PE Testbench Started");
    $display("========================================");

    // Initialize
    rst_ni = 0;
    clr_i  = 0;
    mode_i = 2'b00;  // Convolution mode
    srca_i = 0;
    srcb_i = 0;

    // Reset sequence
    #20;
    rst_ni = 1;
    #10;

    //--------------------------------------------------
    // Test 1: Convolution Mode (MAC)
    //--------------------------------------------------
    $display("\n--- Test 1: Convolution Mode ---");
    mode_i = 2'b00;
    clr_i  = 1;  // Clear accumulator
    #10;
    clr_i  = 0;

    // Feed data: accumulate products
    for (i = 1; i <= 4; i = i + 1) begin
      srca_i = i * 256;      // Fixed-point with 8 fraction bits
      srcb_i = i * 256;
      #10;
      $display("  Cycle %0d: srca=%0d, srcb=%0d, psum=%0d", i, srca_i, srcb_i, psum_o);
    end

    // Wait for pipeline to flush
    srca_i = 0;
    srcb_i = 0;
    #50;
    $display("  Final psum (conv): %0d", psum_o);

    //--------------------------------------------------
    // Test 2: Maxpool Mode
    //--------------------------------------------------
    $display("\n--- Test 2: Maxpool Mode ---");
    mode_i = 2'b01;
    clr_i  = 1;  // Clear accumulator
    #10;
    clr_i  = 0;

    // Feed data: find maximum
    srca_i = 5 * 256;  #10;
    $display("  Input: %0d, psum=%0d", srca_i, psum_o);
    
    srca_i = 3 * 256;  #10;
    $display("  Input: %0d, psum=%0d", srca_i, psum_o);
    
    srca_i = 9 * 256;  #10;
    $display("  Input: %0d, psum=%0d", srca_i, psum_o);
    
    srca_i = 2 * 256;  #10;
    $display("  Input: %0d, psum=%0d", srca_i, psum_o);

    // Wait for pipeline to flush
    srca_i = 0;
    #50;
    $display("  Final psum (maxpool): %0d (expected max=9*256=2304)", psum_o);

    //--------------------------------------------------
    // Test 3: Negative Values in Maxpool
    //--------------------------------------------------
    $display("\n--- Test 3: Maxpool with Negative Values ---");
    mode_i = 2'b01;
    clr_i  = 1;
    #10;
    clr_i  = 0;

    srca_i = -5 * 256;  #10;
    $display("  Input: %0d, psum=%0d", srca_i, psum_o);
    
    srca_i = -2 * 256;  #10;
    $display("  Input: %0d, psum=%0d", srca_i, psum_o);
    
    srca_i = -8 * 256;  #10;
    $display("  Input: %0d, psum=%0d", srca_i, psum_o);

    // Wait for pipeline
    srca_i = 0;
    #50;
    $display("  Final psum (maxpool neg): %0d (expected max=-2*256=-512)", psum_o);

    //--------------------------------------------------
    // End of Test
    //--------------------------------------------------
    #100;
    $display("\n========================================");
    $display("       PE Testbench Completed");
    $display("========================================");
    $finish;
  end

endmodule
