`timescale 1ns / 1ps

module tb_sliding_window_unit;

    // ============================================================
    // 1. PARAMETERS
    // ============================================================
    parameter DATA_WIDTH      = 8;
    // We override the max width to something small for simulation to save memory
    // In real hardware, this would be 1920 or similar.
    parameter MAX_IMG_WIDTH   = 32; 
    parameter MAX_KERNEL_SIZE = 7;

    // ============================================================
    // 2. SIGNALS
    // ============================================================
    reg                         clk;
    reg                         rst_n;

    // Configuration Inputs
    reg  [2:0]                  fu_kernel_size_in;
    reg  [11:0]                 fu_img_size_in;

    // Data Stream
    reg  [DATA_WIDTH-1:0]       fu_pixel_in;
    reg                         fu_pixel_valid_in;

    // Outputs
    // Note: SystemVerilog unpacked array syntax
    wire [DATA_WIDTH-1:0]       fu_window_out [0:(MAX_KERNEL_SIZE*MAX_KERNEL_SIZE)-1];
    wire                        fu_window_valid_out;

    // Loop variables for monitor
    integer r, c;

    // ============================================================
    // 3. DUT INSTANTIATION
    // ============================================================
    sliding_window_unit #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_IMG_WIDTH(MAX_IMG_WIDTH),
        .MAX_KERNEL_SIZE(MAX_KERNEL_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .fu_kernel_size_in(fu_kernel_size_in),
        .fu_img_size_in(fu_img_size_in),
        .fu_pixel_in(fu_pixel_in),
        .fu_pixel_valid_in(fu_pixel_valid_in),
        .fu_window_out(fu_window_out),
        .fu_window_valid_out(fu_window_valid_out)
    );

    // ============================================================
    // 4. CLOCK GENERATION
    // ============================================================
    always #5 clk = ~clk; // 100MHz clock

    // ============================================================
    // 5. STIMULUS TASK
    // ============================================================
    // This task mimics a camera or DMA sending pixels row by row
    task send_frame(input int w, input int h, input int k_mode);
        integer x, y;
        reg [7:0] px_val;
        begin
            $display("\n--- Starting Frame: %0dx%0d | Kernel: %0dx%0d ---", w, h, k_mode, k_mode);
            
            // Setup Configuration
            fu_img_size_in      <= w;
            fu_img_size_in     <= h;
            fu_kernel_size_in    <= k_mode;
            fu_pixel_valid_in <= 0;
            px_val          = 1; // Start pixel value at 1
            
            @(posedge clk); 

            // Stream Loop
            for (y = 0; y < h; y = y + 1) begin
                for (x = 0; x < w; x = x + 1) begin
                    // Drive Data
                    fu_pixel_in       <= px_val;
                    fu_pixel_valid_in <= 1;
                    
                    // Increment pixel value for easy visual tracking
                    // (Wraps around at 255)
                    px_val = px_val + 1; 

                    @(posedge clk);
                end
            end

            // End of Frame
            fu_pixel_valid_in <= 0;
            fu_pixel_in       <= 0;
            repeat(10) @(posedge clk); // Gap between frames
        end
    endtask

    // ============================================================
    // 6. MAIN TEST SEQUENCE
    // ============================================================
    initial begin
        // Init Signals
        clk = 0;
        rst_n = 0;
        fu_pixel_in = 0;
        fu_pixel_valid_in = 0;
        fu_img_size_in = 10;
        fu_img_size_in = 10;
        fu_kernel_size_in = 3;

        // Reset
        #20 rst_n = 1;
        #20;

        // --- TEST CASE 1: 3x3 Kernel on 6x6 Image ---
        // Expect output valid after 2 rows + 2 pixels
        send_frame(6, 6, 3);

        // --- TEST CASE 2: 5x5 Kernel on 8x8 Image ---
        // Expect output valid after 4 rows + 4 pixels
        send_frame(8, 8, 5);

        // --- TEST CASE 3: 2x2 Kernel on 4x4 Image ---
        // Expect output valid after 1 row + 1 pixel
        send_frame(4, 4, 2);

        $display("Simulation Finished.");
        $finish;
    end

    // ============================================================
    // 7. VISUAL MONITOR
    // ============================================================
    // Prints the window matrix whenever fu_window_valid_out is high
    always @(posedge clk) begin
        if (fu_window_valid_out) begin
            $display("Time: %0t | Kernel: %0d | Window Output:", $time, fu_kernel_size_in);
            
            // Logic to print 2D matrix from flattened 1D array
            if (fu_kernel_size_in == 5) begin
                for (r=0; r<5; r=r+1) begin
                    $write("   [ ");
                    for (c=0; c<5; c=c+1) begin
                        $write("%3d ", fu_window_out[r*5 + c]);
                    end
                    $write("]\n");
                end
            end
            else if (fu_kernel_size_in == 3) begin
                for (r=0; r<3; r=r+1) begin
                    $write("   [ ");
                    for (c=0; c<3; c=c+1) begin
                        $write("%3d ", fu_window_out[r*3 + c]);
                    end
                    $write("]\n");
                end
            end
            else if (fu_kernel_size_in == 2) begin
                for (r=0; r<2; r=r+1) begin
                    $write("   [ ");
                    for (c=0; c<2; c=c+1) begin
                        $write("%3d ", fu_window_out[r*2 + c]);
                    end
                    $write("]\n");
                end
            end
            $display(""); // Empty line separator
        end
    end

endmodule