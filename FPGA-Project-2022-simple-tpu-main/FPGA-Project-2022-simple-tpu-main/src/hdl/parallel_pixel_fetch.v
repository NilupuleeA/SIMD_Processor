//
// parallel_pixel_fetch.v
//
// Simple memory fetching module that reads 8 consecutive 8-bit pixels
// from source memory and provides them in parallel to PE array inputs.
//
// Features:
//   - Reads 64 bits (8 x 8-bit pixels) in a single memory access
//   - Converts 8-bit pixels to 16-bit for PE array compatibility
//   - Provides sliding window pixel access for convolution
//   - Each PE receives one pixel for parallel MAC operations
//
`ifndef _PARALLEL_PIXEL_FETCH_V
`define _PARALLEL_PIXEL_FETCH_V

`include "def.v"

module parallel_pixel_fetch #(
    parameter PIXEL_WIDTH  = 8,              // 8-bit pixels
    parameter NUM_PIXELS   = 8,              // Fetch 8 pixels at once
    parameter ADDR_WIDTH   = 12,             // Memory address width
    parameter MEM_WIDTH    = 64              // Memory data width (8 x 8 = 64)
)(
    input  wire                         clk,
    input  wire                         rstn,

    // Control Interface
    input  wire                         fetch_en,           // Enable fetching
    input  wire                         fetch_start,        // Start new fetch sequence
    input  wire [ADDR_WIDTH-1:0]        base_addr,          // Base address for pixels
    input  wire [ADDR_WIDTH-1:0]        row_offset,         // Row offset (row * image_width)
    input  wire [ADDR_WIDTH-1:0]        col_offset,         // Column offset

    // Memory Read Interface (Single port, 64-bit wide)
    output reg                          mem_rd_en,
    output reg  [ADDR_WIDTH-1:0]        mem_rd_addr,
    input  wire [MEM_WIDTH-1:0]         mem_rd_data,        // 64 bits = 8 consecutive pixels

    // Parallel Pixel Output to PE Array (8 x 16-bit values packed in 128-bit word)
    output reg  [`WORD_WIDTH-1:0]       pixel_word_out,     // 128-bit output word
    output reg  [NUM_PIXELS*PIXEL_WIDTH-1:0] pixel_out_flat, // 64-bit flat pixel output (8 x 8-bit)
    output reg                          pixel_valid,        // Pixels are valid

    // Status
    output reg                          fetch_done
);

    // State definitions
    localparam S_IDLE    = 2'd0;
    localparam S_REQUEST = 2'd1;
    localparam S_WAIT    = 2'd2;
    localparam S_OUTPUT  = 2'd3;

    reg [1:0] state, next_state;
    reg [1:0] wait_count;

    // Pixel extraction from memory data
    wire [PIXEL_WIDTH-1:0] pixels_from_mem [0:NUM_PIXELS-1];
    
    genvar g;
    generate
        for (g = 0; g < NUM_PIXELS; g = g + 1) begin : PIXEL_EXTRACT
            assign pixels_from_mem[g] = mem_rd_data[g*PIXEL_WIDTH +: PIXEL_WIDTH];
        end
    endgenerate

    // Address calculation
    wire [ADDR_WIDTH-1:0] fetch_addr = base_addr + row_offset + col_offset;

    integer i;

    // State machine - sequential
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // State machine - combinational
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (fetch_start && fetch_en)
                    next_state = S_REQUEST;
            end
            S_REQUEST: begin
                next_state = S_WAIT;
            end
            S_WAIT: begin
                // Wait for memory read latency (typically 1-2 cycles)
                if (wait_count >= 2'd1)
                    next_state = S_OUTPUT;
            end
            S_OUTPUT: begin
                next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // Main sequential logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            mem_rd_en       <= 1'b0;
            mem_rd_addr     <= {ADDR_WIDTH{1'b0}};
            pixel_word_out  <= {`WORD_WIDTH{1'b0}};
            pixel_out_flat  <= {(NUM_PIXELS*PIXEL_WIDTH){1'b0}};
            pixel_valid     <= 1'b0;
            fetch_done      <= 1'b0;
            wait_count      <= 2'd0;

        end else begin
            // Default outputs
            pixel_valid <= 1'b0;
            fetch_done  <= 1'b0;

            case (state)
                S_IDLE: begin
                    mem_rd_en   <= 1'b0;
                    wait_count  <= 2'd0;
                end

                S_REQUEST: begin
                    // Issue memory read request
                    mem_rd_en   <= 1'b1;
                    mem_rd_addr <= fetch_addr;
                    wait_count  <= 2'd0;
                end

                S_WAIT: begin
                    mem_rd_en  <= 1'b0;
                    wait_count <= wait_count + 1'b1;
                end

                S_OUTPUT: begin
                    // Capture pixels from memory as flat output
                    pixel_out_flat <= mem_rd_data;

                    // Pack into 128-bit word (zero-extend 8-bit to 16-bit)
                    pixel_word_out[`DATA0] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[0]};
                    pixel_word_out[`DATA1] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[1]};
                    pixel_word_out[`DATA2] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[2]};
                    pixel_word_out[`DATA3] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[3]};
                    pixel_word_out[`DATA4] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[4]};
                    pixel_word_out[`DATA5] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[5]};
                    pixel_word_out[`DATA6] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[6]};
                    pixel_word_out[`DATA7] <= {{(16-PIXEL_WIDTH){1'b0}}, pixels_from_mem[7]};

                    pixel_valid <= 1'b1;
                    fetch_done  <= 1'b1;
                end

                default: begin
                    // Do nothing
                end
            endcase
        end
    end

endmodule

`endif
