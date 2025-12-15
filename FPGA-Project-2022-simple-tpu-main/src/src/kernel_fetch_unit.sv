module kernel_fetch_unit #(
    parameter ADDR_WIDTH       = 10,
    parameter DATA_WIDTH       = 32,
    parameter MAX_KERNEL_SIZE  = 5       // Supports up to 5x5 kernel
)(
    input  wire                       clk,
    input  wire                       rstn,

    input  wire                       start,      // start fetch
    input  wire                       first_time,
    // input  wire                       fetch_en,   // enable
    input  wire [ADDR_WIDTH-1:0]      base_addr,  // starting BRAM address
    input  wire [2:0]                 ker_size,   // actual kernel size (<= MAX_KERNEL_SIZE)

    output reg                        bram_en,
    output reg  [ADDR_WIDTH-1:0]      bram_addr,
    input  wire [DATA_WIDTH-1:0]      bram_din,

    output reg [DATA_WIDTH-1:0]       data_out [0:MAX_KERNEL_SIZE-1][0:MAX_KERNEL_SIZE-1],
    output reg                        data_out_valid
);

    // Internal counters
    reg [2:0] row;
    reg [2:0] col;

    always @(posedge clk) begin
        if (!rstn) begin
            bram_addr       <= 0;
            bram_en         <= 0;
            data_out_valid  <= 0;
            row             <= 0;
            col             <= 0;

        end else begin
            
            data_out_valid <= 0;  // default

            if (start) begin
                bram_en   <= 1;
                if (first_time) begin
                    bram_addr <= base_addr;                    
                end else begin
                    bram_addr <= bram_addr + 1; 
                end

                data_out[row][col] <= bram_din;

                if (col == ker_size - 1) begin
                    col <= 0;
                    if (row == ker_size - 1) begin
                        busy           <= 0;
                        bram_en        <= 0;
                        data_out_valid <= 1;
                    end else begin
                        row <= row + 1;
                    end
                end else begin
                    col <= col + 1;
                end
            end 
        end
    end

endmodule
