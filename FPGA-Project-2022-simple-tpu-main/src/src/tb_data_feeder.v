`timescale 1ns / 1ps

module tb_top;

    // --- 1. Configuration ---
    // We use a small width (4) to make the simulation easy to read.
    // In a 4-pixel wide image:
    // Row 0: Pixels 1-4
    // Row 1: Pixels 5-8
    // Row 2: Pixels 9-12
    localparam TEST_IMG_W = 4;

    // --- 2. Signals ---
    reg clk;
    reg rst;
    reg [7:0] serial_pixel_in;

    wire [7:0] row0_skewed;
    wire [7:0] row1_skewed;
    wire [7:0] row2_skewed;

    // --- 3. Instantiate the DUT (Device Under Test) ---
    data_feeder #(.IMG_W(TEST_IMG_W)) uut (
        .clk(clk),
        .rst(rst),
        .serial_pixel_in(serial_pixel_in),
        .row0_skewed(row0_skewed),
        .row1_skewed(row1_skewed),
        .row2_skewed(row2_skewed)
    );

    // --- 4. Clock Generation ---
    always #5 clk = ~clk; // 10ns period

    // --- 5. Test Stimulus ---
    integer i;
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        serial_pixel_in = 0;

        // Reset Pulse
        #20;
        rst = 0;
        
        // Wait a clearer start
        #10;

        $display("--- Starting Pixel Feed (Image Width = 4) ---");
        $display("Time | Input | R0_Out (Top) | R1_Out (Mid) | R2_Out (Bot)");

        // Feed pixels 1 to 20 (Enough for 5 rows)
        for (i = 1; i <= 20; i = i + 1) begin
            @(negedge clk); // Change input on negative edge to be safe
            serial_pixel_in = i;
        end

        // Feed zeros for a few cycles to flush
        for (i = 0; i < 5; i = i + 1) begin
             @(negedge clk);
             serial_pixel_in = 0;
        end

        $display("--- Simulation Done ---");
        $finish;
    end

    // --- 6. Monitor Output ---
    // This prints the status every time the clock rises
    always @(posedge clk) begin
        if (!rst) begin
            // We use #1 delay in display to show values AFTER the clock edge update
            #1 $display("%4t |   %2d  |      %2d      |      %2d      |      %2d", 
                        $time, serial_pixel_in, row0_skewed, row1_skewed, row2_skewed);
        end
    end

endmodule