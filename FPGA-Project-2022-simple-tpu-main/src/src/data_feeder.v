module data_feeder #(parameter IMG_W = 64) (
    input wire clk,
    input wire rst,
    input wire [7:0] serial_pixel_in,
    
    // These outputs go to the Systolic Array rows
    output reg [7:0] row0_skewed,
    output reg [7:0] row1_skewed,
    output reg [7:0] row2_skewed
);

    // --- 1. Line Buffers (FIFOs) ---
    // We need to store previous rows to access 3 vertical pixels at once.
    // In real hardware, use BRAM or proper FIFO IPs. Here is a behavioral model.
    reg [7:0] lb0 [0:IMG_W-1];
    reg [7:0] lb1 [0:IMG_W-1];
    integer i;

    reg [7:0] p0, p1, p2; // The 3 vertical pixels

    always @(posedge clk) begin
        // Shift Line Buffers
        // p2 is current input, p1 is from 1 row back, p0 is from 2 rows back
        p2 <= serial_pixel_in;
        p1 <= lb1[IMG_W-1];
        p0 <= lb0[IMG_W-1];

        // Shift register logic (inefficient for large img, good for demo)
        for (i = IMG_W-1; i > 0; i = i - 1) begin
            lb1[i] <= lb1[i-1];
            lb0[i] <= lb0[i-1];
        end
        lb1[0] <= p2;
        lb0[0] <= p1;
    end

    // --- 2. Data Skewing (The Systolic Feed) ---
    // Row 0 enters immediately.
    // Row 1 is delayed by 1 cycle.
    // Row 2 is delayed by 2 cycles.
    
    reg [7:0] r1_d1;        // Row 1 delay register
    reg [7:0] r2_d1, r2_d2; // Row 2 delay registers

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            row0_skewed <= 0;
            row1_skewed <= 0;
            row2_skewed <= 0;
            r1_d1 <= 0;
            r2_d1 <= 0; r2_d2 <= 0;
        end else begin
            // No delay for Row 0
            row0_skewed <= p0; 

            // 1 cycle delay for Row 1
            r1_d1 <= p1;
            row1_skewed <= r1_d1;

            // 2 cycle delay for Row 2
            r2_d1 <= p2;
            r2_d2 <= r2_d1;
            row2_skewed <= r2_d2;
        end
    end

endmodule