`timescale 1ns / 1ps

module tb_image_fetch;

    // ============================================================
    // 1. PARAMETERS
    // ============================================================
    parameter DATA_WIDTH      = 32;
    parameter ADDR_WIDTH      = 12;
    // Small image width for easier visual debugging (e.g., 8x8 image)
    parameter MAX_IMG_WIDTH   = 8;   
    parameter MAX_KERNEL_SIZE = 5;

    // ============================================================
    // 2. SIGNALS
    // ============================================================
    reg                         clk;
    reg                         rstn;
    
    // Controls
    reg                         start;
    reg  [ADDR_WIDTH-1:0]       base_addr;
    reg  [2:0]                  ker_size;

    // BRAM Interface
    wire                        bram_en;
    wire [ADDR_WIDTH-1:0]       bram_addr;
    wire [DATA_WIDTH-1:0]       bram_din;

    // Outputs
    wire [DATA_WIDTH-1:0]       pe_windows [0:MAX_KERNEL_SIZE-1][0:MAX_KERNEL_SIZE-1];
    wire                        window_valid;
    wire                        frame_done;

    // Internal Simulation Memory
    reg [DATA_WIDTH-1:0]        mock_ram [0:1023];
    reg [DATA_WIDTH-1:0]        bram_rdata;

    // Loop variables
    integer i, j;

    // ============================================================
    // 3. DUT INSTANTIATION
    // ============================================================
    image_fetch_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MAX_IMG_WIDTH(MAX_IMG_WIDTH), // Overriding default 28 for test
        .MAX_KERNEL_SIZE(MAX_KERNEL_SIZE)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .base_addr(base_addr),
        .ker_size(ker_size),
        .bram_en(bram_en),
        .bram_addr(bram_addr),
        .bram_din(bram_din),
        .pe_windows(pe_windows),
        .window_valid(window_valid),
        .frame_done(frame_done)
    );

    // ============================================================
    // 4. CLOCK & BRAM BEHAVIOR
    // ============================================================
    // Clock Gen (100MHz)
    always #5 clk = ~clk;

    // BRAM Read Logic (1 Cycle Latency)
    always @(posedge clk) begin
        if (bram_en) begin
            bram_rdata <= mock_ram[bram_addr];
        end
    end
    assign bram_din = bram_rdata;

    // ============================================================
    // 5. STIMULUS
    // ============================================================
    initial begin
        // Init
        clk = 0;
        rstn = 0;
        start = 0;
        base_addr = 0;
        ker_size = 5;

        // Fill Mock RAM with linear pattern (0, 1, 2, 3...)
        // This makes it easy to verify the sliding window visually.
        for (i = 0; i < 1024; i = i + 1) begin
            mock_ram[i] = i;
        end

        $display("-------------------------------------------");
        $display("Simulation Start");
        $display("-------------------------------------------");

        // --- RESET ---
        #20 rstn = 1;
        #20;

        // --- TEST 1: 5x5 Kernel ---
        $display("\n[TEST] Starting 5x5 Kernel Processing...");
        ker_size = 5;
        start = 1;
        #10 start = 0;

        // Wait for frame to finish
        wait(frame_done);
        $display("[INFO] Frame Done (5x5)");
        #50;

        // --- TEST 2: 3x3 Kernel ---
        $display("\n[TEST] Starting 3x3 Kernel Processing...");
        
        // Reset Logic for clean state
        rstn = 0; #10 rstn = 1; 

        ker_size = 2;
        start = 1;
        #10 start = 0;

        wait(frame_done);
        $display("[INFO] Frame Done (3x3)");
        #50;

        $display("-------------------------------------------");
        $display("Simulation Finished");
        $display("-------------------------------------------");
        $finish;
    end

    // ============================================================
    // 6. VISUAL MONITOR
    // ============================================================
    // This block prints the matrices to the console whenever valid
    always @(posedge clk) begin
        if (window_valid) begin
            $display("Time: %0t | Valid Window Output:", $time);

            if (ker_size == 5) begin
                // Print 5x5 Grid
                for (i = 0; i < 5; i = i + 1) begin
                    $write("  [ ");
                    for (j = 0; j < 5; j = j + 1) begin
                        // 1D Array Mapping: Row*5 + Col
                        $write("%3d ", pe_windows[i][j]);
                    end
                    $write("]\n");
                end
            end 
            else if (ker_size == 3) begin
                // Print 3x3 Grid (Stored in the first 9 elements)
                for (i = 0; i < 3; i = i + 1) begin
                    $write("  [ ");
                    for (j = 0; j < 3; j = j + 1) begin
                        // 1D Array Mapping: Row*3 + Col
                        $write("%3d ", pe_windows[i][j]);
                    end
                    $write("]\n");
                end
            end
            else if (ker_size == 2) begin
                // Print 3x3 Grid (Stored in the first 9 elements)
                for (i = 0; i < 2; i = i + 1) begin
                    $write("  [ ");
                    for (j = 0; j < 2; j = j + 1) begin
                        // 1D Array Mapping: Row*3 + Col
                        $write("%3d ", pe_windows[i][j]);
                    end
                    $write("]\n");
                end
            end
            $display(""); // Newline
        end
    end

endmodule