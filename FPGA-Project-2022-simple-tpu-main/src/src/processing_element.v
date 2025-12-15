module simd_pe (
    input wire clk,
    input wire rst_n,
    input wire en_mac,              // Enable Multiply-Accumulate
    input wire clr_acc,             // Clear Accumulator (Start new convolution window)
    input wire signed [15:0] pixel_in,  // Shared Input Pixel (Broadcasted)
    input wire signed [15:0] weight_in, // Unique Weight for this Lane
    output reg signed [15:0] result_out // Result after ReLU
);

    // Q8.8 Fixed Point Logic
    // 1 sign bit, 7 integer bits, 8 fractional bits
    
    reg signed [31:0] product;
    reg signed [31:0] accumulator;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= 0;
            result_out <= 0;
        end else begin
            if (clr_acc) begin
                accumulator <= 0;
            end 
            else if (en_mac) begin
                // 1. Multiply: Result is 32-bit (Q16.16)
                product = pixel_in * weight_in;
                
                // 2. Accumulate: Add to running total
                // We perform the shift >>> 8 here to realign Q16.16 to Q8.8
                // Note: In real silicon, you might keep precision high and only shift at the end.
                // For simplicity/speed here, we shift the product.
                accumulator <= accumulator + (product >>> 8);
            end
        end
    end

    // Combinational Logic for ReLU (Activation)
    // Runs constantly on the accumulator value
    always @(*) begin
        if (accumulator > 32767) result_out = 32767;      // Clamp Max
        else if (accumulator < 0) result_out = 0;         // ReLU (Clip Negatives)
        else result_out = accumulator[15:0];              // Pass through
    end

endmodule