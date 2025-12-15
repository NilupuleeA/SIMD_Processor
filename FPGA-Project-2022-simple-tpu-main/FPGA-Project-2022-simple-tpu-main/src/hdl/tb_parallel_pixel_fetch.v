//
// tb_parallel_pixel_fetch.v
//
// Testbench for parallel_pixel_fetch module
// Simulates memory with 8-bit consecutive pixels and verifies
// parallel fetching to PE array interface
//
`timescale 1ns/1ps

`include "def.v"

module tb_parallel_pixel_fetch;

    // Parameters
    parameter PIXEL_WIDTH  = 8;
    parameter NUM_PIXELS   = 8;
    parameter ADDR_WIDTH   = 12;
    parameter MEM_WIDTH    = 64;
    parameter CLK_PERIOD   = 10;  // 100MHz clock

    // DUT signals
    reg                         clk;
    reg                         rstn;
    reg                         fetch_en;
    reg                         fetch_start;
    reg  [ADDR_WIDTH-1:0]       base_addr;
    reg  [ADDR_WIDTH-1:0]       row_offset;
    reg  [ADDR_WIDTH-1:0]       col_offset;

    wire                        mem_rd_en;
    wire [ADDR_WIDTH-1:0]       mem_rd_addr;
    reg  [MEM_WIDTH-1:0]        mem_rd_data;

    wire [`WORD_WIDTH-1:0]      pixel_word_out;
    wire [NUM_PIXELS*PIXEL_WIDTH-1:0] pixel_out_flat;  // 64-bit flat pixel output
    wire                        pixel_valid;
    wire                        fetch_done;

    // Memory model (simulates source buffer with test image data)
    reg [MEM_WIDTH-1:0] test_memory [0:255]; // no. of locations - 256, memory width 64

    // Individual pixel extraction for monitoring (from flat output)
    wire [PIXEL_WIDTH-1:0] pixel_0 = pixel_out_flat[7:0];
    wire [PIXEL_WIDTH-1:0] pixel_1 = pixel_out_flat[15:8];
    wire [PIXEL_WIDTH-1:0] pixel_2 = pixel_out_flat[23:16];
    wire [PIXEL_WIDTH-1:0] pixel_3 = pixel_out_flat[31:24];
    wire [PIXEL_WIDTH-1:0] pixel_4 = pixel_out_flat[39:32];
    wire [PIXEL_WIDTH-1:0] pixel_5 = pixel_out_flat[47:40];
    wire [PIXEL_WIDTH-1:0] pixel_6 = pixel_out_flat[55:48];
    wire [PIXEL_WIDTH-1:0] pixel_7 = pixel_out_flat[63:56];

    // PE array word extraction for monitoring
    wire [`DATA_WIDTH-1:0] pe_data_0 = pixel_word_out[`DATA0];
    wire [`DATA_WIDTH-1:0] pe_data_1 = pixel_word_out[`DATA1];
    wire [`DATA_WIDTH-1:0] pe_data_2 = pixel_word_out[`DATA2];
    wire [`DATA_WIDTH-1:0] pe_data_3 = pixel_word_out[`DATA3];
    wire [`DATA_WIDTH-1:0] pe_data_4 = pixel_word_out[`DATA4];
    wire [`DATA_WIDTH-1:0] pe_data_5 = pixel_word_out[`DATA5];
    wire [`DATA_WIDTH-1:0] pe_data_6 = pixel_word_out[`DATA6];
    wire [`DATA_WIDTH-1:0] pe_data_7 = pixel_word_out[`DATA7];

    // Test counters
    integer fetch_count;
    integer error_count;
    integer i;

    // DUT instantiation
    parallel_pixel_fetch #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .NUM_PIXELS(NUM_PIXELS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_WIDTH(MEM_WIDTH)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .fetch_en(fetch_en),
        .fetch_start(fetch_start),
        .base_addr(base_addr),
        .row_offset(row_offset),
        .col_offset(col_offset),
        .mem_rd_en(mem_rd_en),
        .mem_rd_addr(mem_rd_addr),
        .mem_rd_data(mem_rd_data),
        .pixel_word_out(pixel_word_out),
        .pixel_out_flat(pixel_out_flat),
        .pixel_valid(pixel_valid),
        .fetch_done(fetch_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Memory read model (1 cycle latency)
    always @(posedge clk) begin
        if (mem_rd_en) begin
            mem_rd_data <= test_memory[mem_rd_addr[7:0]];
        end
    end

    // Initialize test memory with known pattern
    // Each 64-bit word contains 8 consecutive 8-bit pixels
    // Pattern: Address 0 -> pixels 1-8, Address 1 -> pixels 9-16, etc.
    initial begin
        // Sequential pixel values: 1,2,3,4,5,6,7,8 at address 0
        // Format: {pixel7, pixel6, pixel5, pixel4, pixel3, pixel2, pixel1, pixel0}
        test_memory[0]  = 64'h_08_07_06_05_04_03_02_01;  // pixels 1-8
        test_memory[1]  = 64'h_10_0F_0E_0D_0C_0B_0A_09;  // pixels 9-16
        test_memory[2]  = 64'h_18_17_16_15_14_13_12_11;  // pixels 17-24
        test_memory[3]  = 64'h_20_1F_1E_1D_1C_1B_1A_19;  // pixels 25-32
        test_memory[4]  = 64'h_28_27_26_25_24_23_22_21;  // pixels 33-40
        test_memory[5]  = 64'h_30_2F_2E_2D_2C_2B_2A_29;  // pixels 41-48
        test_memory[6]  = 64'h_38_37_36_35_34_33_32_31;  // pixels 49-56
        test_memory[7]  = 64'h_40_3F_3E_3D_3C_3B_3A_39;  // pixels 57-64
        test_memory[8]  = 64'h_48_47_46_45_44_43_42_41;  // pixels 65-72
        test_memory[9]  = 64'h_50_4F_4E_4D_4C_4B_4A_49;  // pixels 73-80
        test_memory[10] = 64'h_58_57_56_55_54_53_52_51;  // pixels 81-88
        test_memory[11] = 64'h_60_5F_5E_5D_5C_5B_5A_59;  // pixels 89-96
        test_memory[12] = 64'h_68_67_66_65_64_63_62_61;  // pixels 97-104
    end

    // Main test sequence
    initial begin
        // Initialize signals
        rstn        = 0;
        fetch_en    = 0;
        fetch_start = 0;
        base_addr   = 0;
        row_offset  = 0;
        col_offset  = 0;
        fetch_count = 0;
        error_count = 0;
        mem_rd_data = 0;

        $display("========================================");
        $display("  Parallel Pixel Fetch Testbench");
        $display("========================================");
        $display("Time: %0t - Starting simulation", $time);

        // Reset sequence
        repeat(5) @(posedge clk);
        rstn = 1;
        repeat(2) @(posedge clk);

        $display("Time: %0t - Reset complete", $time);

        // ============================================
        // Test 1: Basic fetch from address 0
        // ============================================
        $display("\n--- Test 1: Basic fetch from address 0 ---");
        fetch_en   = 1;
        base_addr  = 12'd0;
        row_offset = 12'd0;
        col_offset = 12'd0;
        
        @(posedge clk);
        fetch_start = 1;
        @(posedge clk);
        fetch_start = 0;

        // Wait for fetch complete
        wait(fetch_done);
        @(posedge clk);
        
        $display("Time: %0t - Fetch 1 complete", $time);
        $display("  Memory address: %0d", mem_rd_addr);
        $display("  Expected pixels: 1 2 3 4 5 6 7 8");
        $display("  Actual pixels:   %0d %0d %0d %0d %0d %0d %0d %0d",
                 pixel_0, pixel_1, pixel_2, pixel_3,
                 pixel_4, pixel_5, pixel_6, pixel_7);
        $display("  PE Word (128-bit): %032h", pixel_word_out);
        
        // Verify
        if (pixel_0 == 8'd1 && pixel_1 == 8'd2 && pixel_7 == 8'd8)
            $display("  PASS: Pixel values match expected");
        else begin
            $display("  FAIL: Pixel values mismatch!");
            error_count = error_count + 1;
        end
        fetch_count = fetch_count + 1;

        repeat(3) @(posedge clk);

        // ============================================
        // Test 2: Fetch from address 1 (pixels 9-16)
        // ============================================
        $display("\n--- Test 2: Fetch from address 1 (pixels 9-16) ---");
        base_addr  = 12'd1;
        row_offset = 12'd0;
        col_offset = 12'd0;
        
        @(posedge clk);
        fetch_start = 1;
        @(posedge clk);
        fetch_start = 0;

        wait(fetch_done);
        @(posedge clk);
        
        $display("Time: %0t - Fetch 2 complete", $time);
        $display("  Expected pixels: 9 10 11 12 13 14 15 16");
        $display("  Actual pixels:   %0d %0d %0d %0d %0d %0d %0d %0d",
                 pixel_0, pixel_1, pixel_2, pixel_3,
                 pixel_4, pixel_5, pixel_6, pixel_7);
        
        // Verify
        if (pixel_0 == 8'd9 && pixel_7 == 8'd16)
            $display("  PASS: Pixel values match expected");
        else begin
            $display("  FAIL: Pixel values mismatch!");
            error_count = error_count + 1;
        end
        fetch_count = fetch_count + 1;

        repeat(3) @(posedge clk);

        // ============================================
        // Test 3: Fetch with row/col offset
        // ============================================
        $display("\n--- Test 3: Fetch with row and column offset ---");
        base_addr  = 12'd0;
        row_offset = 12'd2;  // Row offset (e.g., row * img_width)
        col_offset = 12'd0;  // Column offset
        
        @(posedge clk);
        fetch_start = 1;
        @(posedge clk);
        fetch_start = 0;

        wait(fetch_done);
        @(posedge clk);
        
        $display("Time: %0t - Fetch 3 complete", $time);
        $display("  Base: 0, Row offset: 2, Col offset: 0");
        $display("  Effective address: %0d (pixels 17-24)", 0 + 2 + 0);
        $display("  Expected pixels: 17 18 19 20 21 22 23 24");
        $display("  Actual pixels:   %0d %0d %0d %0d %0d %0d %0d %0d",
                 pixel_0, pixel_1, pixel_2, pixel_3,
                 pixel_4, pixel_5, pixel_6, pixel_7);
        fetch_count = fetch_count + 1;

        repeat(3) @(posedge clk);

        // ============================================
        // Test 4: Multiple consecutive fetches (sliding window)
        // ============================================
        $display("\n--- Test 4: Multiple consecutive fetches (sliding window simulation) ---");
        
        for (i = 0; i < 4; i = i + 1) begin
            base_addr  = 12'd0;
            row_offset = 12'd0;
            col_offset = i[11:0];
            
            @(posedge clk);
            fetch_start = 1;
            @(posedge clk);
            fetch_start = 0;

            wait(fetch_done);
            @(posedge clk);
            
            $display("Time: %0t - Window %0d: addr=%0d, pixels=%0d %0d %0d %0d %0d %0d %0d %0d",
                     $time, i, i,
                     pixel_0, pixel_1, pixel_2, pixel_3,
                     pixel_4, pixel_5, pixel_6, pixel_7);
            fetch_count = fetch_count + 1;
            
            repeat(2) @(posedge clk);
        end

        // ============================================
        // Test 5: Fetch disabled test
        // ============================================
        $display("\n--- Test 5: Fetch with enable=0 (should not fetch) ---");
        fetch_en   = 0;
        base_addr  = 12'd0;
        
        @(posedge clk);
        fetch_start = 1;
        @(posedge clk);
        fetch_start = 0;
        
        repeat(5) @(posedge clk);
        
        if (!fetch_done)
            $display("  PASS: Fetch correctly blocked when disabled");
        else begin
            $display("  FAIL: Fetch occurred when disabled!");
            error_count = error_count + 1;
        end

        fetch_en = 1;  // Re-enable for any further tests

        // ============================================
        // End of tests
        // ============================================
        repeat(10) @(posedge clk);
        
        $display("\n========================================");
        $display("  Simulation Complete");
        $display("========================================");
        $display("  Total fetches: %0d", fetch_count);
        $display("  Errors: %0d", error_count);
        if (error_count == 0)
            $display("  STATUS: ALL TESTS PASSED");
        else
            $display("  STATUS: TESTS FAILED");
        $display("========================================\n");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #10000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Optional: Dump waveforms for VCD viewer
    initial begin
        $dumpfile("tb_parallel_pixel_fetch.vcd");
        $dumpvars(0, tb_parallel_pixel_fetch);
    end

endmodule
