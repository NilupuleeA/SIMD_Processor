//
// tb_pe_array.v
//
// Testbench for PE Array module
// Tests both convolution and maxpool modes across all 8 PEs
//
`timescale 1ns/1ps

`include "def.v"

module tb_pe_array;

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
  reg        we_i;
  wire       we_o;
  reg  [1:0] mode_i;

  //--------------------------------------------------
  // Data Signals - Input
  //--------------------------------------------------
  reg  [`WORD_WIDTH-1:0] srca_word_i;
  reg  [`DATA_WIDTH-1:0] srcb_i;

  //--------------------------------------------------
  // Data Signals - Output
  //--------------------------------------------------
  wire [`WORD_WIDTH-1:0] srca_word_o;
  wire [`WORD_WIDTH-1:0] wordp_o;

  //--------------------------------------------------
  // Individual PE Output Extraction (for monitoring)
  //--------------------------------------------------
  wire signed [`DATA_WIDTH-1:0] pe0_psum = wordp_o[`DATA0];
  wire signed [`DATA_WIDTH-1:0] pe1_psum = wordp_o[`DATA1];
  wire signed [`DATA_WIDTH-1:0] pe2_psum = wordp_o[`DATA2];
  wire signed [`DATA_WIDTH-1:0] pe3_psum = wordp_o[`DATA3];
  wire signed [`DATA_WIDTH-1:0] pe4_psum = wordp_o[`DATA4];
  wire signed [`DATA_WIDTH-1:0] pe5_psum = wordp_o[`DATA5];
  wire signed [`DATA_WIDTH-1:0] pe6_psum = wordp_o[`DATA6];
  wire signed [`DATA_WIDTH-1:0] pe7_psum = wordp_o[`DATA7];

  //--------------------------------------------------
  // DUT Instantiation
  //--------------------------------------------------
  pe_array dut (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .clr_i       (clr_i),
    .clr_o       (clr_o),
    .we_i        (we_i),
    .we_o        (we_o),
    .mode_i      (mode_i),
    .srca_word_i (srca_word_i),
    .srca_word_o (srca_word_o),
    .srcb_i      (srcb_i),
    .wordp_o     (wordp_o)
  );

  //--------------------------------------------------
  // Clock Generation (100 MHz)
  //--------------------------------------------------
  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  //--------------------------------------------------
  // Helper Task: Set srca_word with 8 values
  //--------------------------------------------------
  task set_srca_word;
    input signed [`DATA_WIDTH-1:0] d0, d1, d2, d3, d4, d5, d6, d7;
    begin
      srca_word_i[`DATA0] = d0;
      srca_word_i[`DATA1] = d1;
      srca_word_i[`DATA2] = d2;
      srca_word_i[`DATA3] = d3;
      srca_word_i[`DATA4] = d4;
      srca_word_i[`DATA5] = d5;
      srca_word_i[`DATA6] = d6;
      srca_word_i[`DATA7] = d7;
    end
  endtask

  //--------------------------------------------------
  // Helper Task: Display all PE outputs
  //--------------------------------------------------
  task display_pe_outputs;
    begin
      $display("  PE0=%6d  PE1=%6d  PE2=%6d  PE3=%6d", pe0_psum, pe1_psum, pe2_psum, pe3_psum);
      $display("  PE4=%6d  PE5=%6d  PE6=%6d  PE7=%6d", pe4_psum, pe5_psum, pe6_psum, pe7_psum);
    end
  endtask

  //--------------------------------------------------
  // Test Sequence
  //--------------------------------------------------
  integer i;
  
  initial begin
    $display("========================================");
    $display("     PE Array Testbench Started");
    $display("========================================");

    // Initialize
    rst_ni      = 0;
    clr_i       = 0;
    we_i        = 0;
    mode_i      = 2'b00;
    srca_word_i = 0;
    srcb_i      = 0;

    // Reset sequence
    #20;
    rst_ni = 1;
    #10;

    //--------------------------------------------------
    // Test 1: Convolution Mode
    //--------------------------------------------------
    $display("\n--- Test 1: Convolution Mode ---");
    mode_i = 2'b00;
    
    // Clear all PEs
    clr_i = 1;
    we_i  = 1;
    #10;
    clr_i = 0;

    // Feed data for MAC operation
    // Each PE gets different srca, all share same srcb
    for (i = 1; i <= 4; i = i + 1) begin
      set_srca_word(
        1*256, 2*256, 3*256, 4*256,
        5*256, 6*256, 7*256, 8*256
      );
      srcb_i = i * 256;  // Kernel weight
      we_i   = 1;
      #10;
      $display("  Cycle %0d: srcb=%0d", i, srcb_i);
      display_pe_outputs();
    end

    // Flush pipeline
    set_srca_word(0, 0, 0, 0, 0, 0, 0, 0);
    srcb_i = 0;
    we_i   = 0;
    #100;
    
    $display("\n  Final Convolution Results:");
    display_pe_outputs();

    //--------------------------------------------------
    // Test 2: Maxpool Mode
    //--------------------------------------------------
    $display("\n--- Test 2: Maxpool Mode ---");
    mode_i = 2'b01;
    
    // Clear all PEs
    clr_i = 1;
    we_i  = 1;
    #10;
    clr_i = 0;

    // Feed varying data to find max per PE
    // Round 1
    set_srca_word(
      5*256, 3*256, 9*256, 2*256,
      7*256, 1*256, 4*256, 8*256
    );
    we_i = 1;
    #10;
    $display("  Round 1:");
    display_pe_outputs();

    // Round 2
    set_srca_word(
      2*256, 8*256, 1*256, 6*256,
      3*256, 9*256, 5*256, 4*256
    );
    #10;
    $display("  Round 2:");
    display_pe_outputs();

    // Round 3
    set_srca_word(
      7*256, 4*256, 6*256, 9*256,
      1*256, 5*256, 8*256, 2*256
    );
    #10;
    $display("  Round 3:");
    display_pe_outputs();

    // Flush pipeline
    set_srca_word(0, 0, 0, 0, 0, 0, 0, 0);
    we_i = 0;
    #100;

    $display("\n  Final Maxpool Results (expected max per PE):");
    $display("  Expected: PE0=7, PE1=8, PE2=9, PE3=9, PE4=7, PE5=9, PE6=8, PE7=8 (x256)");
    display_pe_outputs();

    //--------------------------------------------------
    // Test 3: Mode Switch During Operation
    //--------------------------------------------------
    $display("\n--- Test 3: Mode Switch ---");
    
    // Start in conv mode
    mode_i = 2'b00;
    clr_i  = 1;
    we_i   = 1;
    #10;
    clr_i  = 0;

    set_srca_word(
      2*256, 2*256, 2*256, 2*256,
      2*256, 2*256, 2*256, 2*256
    );
    srcb_i = 3*256;
    #20;

    // Switch to maxpool
    $display("  Switching to Maxpool mode...");
    mode_i = 2'b01;
    set_srca_word(
      10*256, 10*256, 10*256, 10*256,
      10*256, 10*256, 10*256, 10*256
    );
    #20;

    // Flush
    set_srca_word(0, 0, 0, 0, 0, 0, 0, 0);
    srcb_i = 0;
    we_i   = 0;
    #100;

    $display("  After mode switch:");
    display_pe_outputs();

    //--------------------------------------------------
    // End of Test
    //--------------------------------------------------
    #100;
    $display("\n========================================");
    $display("     PE Array Testbench Completed");
    $display("========================================");
    $finish;
  end

endmodule
