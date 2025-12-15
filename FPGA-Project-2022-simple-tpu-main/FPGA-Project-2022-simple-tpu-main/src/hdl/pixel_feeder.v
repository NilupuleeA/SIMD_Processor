//
// pixel_feeder.v
//
// Memory fetching module for PE array convolution.
// Fetches 8 consecutive 8-bit pixels from source buffer and feeds them
// to the PE array in parallel. Each PE performs MAC operations cycle by cycle.
//
// Memory Interface:
//   - Reads 64-bit word (8 x 8-bit pixels) from source buffer per cycle
//   - Source buffer should have consecutive pixels stored
//
// PE Array Interface:
//   - Outputs 8 x 16-bit data words for srca (image pixels)
//   - Outputs single 16-bit data for srcb (kernel weight, flows through PEs)
//
`ifndef _PIXEL_FEEDER_V
`define _PIXEL_FEEDER_V

`include "def.v"

module pixel_feeder #(
    parameter PIXEL_WIDTH     = 8,           // Input pixel width (8-bit)
    parameter NUM_PE          = 8,           // Number of PEs in array
    parameter ADDR_WIDTH      = 12,          // Memory address width
    parameter IMG_WIDTH       = 28,          // Image width (default 28x28)
    parameter KERNEL_SIZE     = 3            // Kernel size (3x3, 5x5, etc.)
)(
    input  wire                         clk,
    input  wire                         rstn,

    // Control signals
    input  wire                         start,              // Start fetching
    input  wire                         enable,             // Enable operation
    input  wire [ADDR_WIDTH-1:0]        img_base_addr,      // Image base address in memory
    input  wire [ADDR_WIDTH-1:0]        kernel_base_addr,   // Kernel base address in memory
    input  wire [4:0]                   img_width,          // Actual image width
    input  wire [2:0]                   kernel_size,        // Actual kernel size

    // Source Buffer Interface (Image Memory) - 64-bit read port (8 pixels at once)
    output reg                          img_mem_en,
    output reg  [ADDR_WIDTH-1:0]        img_mem_addr,
    input  wire [NUM_PE*PIXEL_WIDTH-1:0] img_mem_data,      // 64 bits = 8 x 8-bit pixels

    // Kernel Buffer Interface - 16-bit read port
    output reg                          ker_mem_en,
    output reg  [ADDR_WIDTH-1:0]        ker_mem_addr,
    input  wire [`DATA_WIDTH-1:0]       ker_mem_data,       // 16-bit kernel weight

    // PE Array Interface
    output reg  [`WORD_WIDTH-1:0]       pe_srca_word,       // 128-bit: 8 x 16-bit pixel values
    output reg  [`DATA_WIDTH-1:0]       pe_srcb,            // 16-bit kernel weight
    output reg                          pe_clr,             // Clear accumulator signal
    output reg                          pe_we,              // Write enable for output

    // Status signals
    output reg                          busy,
    output reg                          conv_done,          // Convolution complete for current position
    output reg                          frame_done          // All positions processed
);

    // State machine states
    localparam IDLE           = 3'd0;
    localparam FETCH_PIXELS   = 3'd1;
    localparam FETCH_KERNEL   = 3'd2;
    localparam COMPUTE        = 3'd3;
    localparam NEXT_POSITION  = 3'd4;
    localparam DONE           = 3'd5;

    reg [2:0] state, next_state;

    // Position counters
    reg [9:0] out_row;              // Output feature map row position
    reg [9:0] out_col;              // Output feature map column position
    reg [9:0] max_out_row;          // Maximum output row
    reg [9:0] max_out_col;          // Maximum output column

    // Kernel iteration counters
    reg [2:0] ker_row;              // Current kernel row (0 to kernel_size-1)
    reg [2:0] ker_col;              // Current kernel column (0 to kernel_size-1)
    reg [5:0] kernel_count;         // Total kernel elements processed

    // Pixel buffer for current window (8 pixels per fetch)
    reg [PIXEL_WIDTH-1:0] pixel_buffer [0:NUM_PE-1];

    // Pipeline registers for timing
    reg [1:0] fetch_delay;
    reg       pixels_ready;
    reg       kernel_ready;

    // Helper wires for address calculation
    wire [9:0] img_row = out_row + ker_row;
    wire [9:0] img_col = out_col + ker_col;
    wire [ADDR_WIDTH-1:0] pixel_addr = img_base_addr + (img_row * img_width) + img_col;
    wire [ADDR_WIDTH-1:0] kernel_addr = kernel_base_addr + (ker_row * kernel_size) + ker_col;

    // Wire to check if we need more kernel iterations
    wire kernel_iteration_done = (ker_row == kernel_size - 1) && (ker_col == kernel_size - 1);
    wire position_done = kernel_iteration_done;

    integer i;

    // State machine - sequential
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // State machine - combinational
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start && enable)
                    next_state = FETCH_PIXELS;
            end

            FETCH_PIXELS: begin
                if (fetch_delay == 2'd2)
                    next_state = FETCH_KERNEL;
            end

            FETCH_KERNEL: begin
                if (kernel_ready)
                    next_state = COMPUTE;
            end

            COMPUTE: begin
                if (kernel_iteration_done)
                    next_state = NEXT_POSITION;
                else
                    next_state = FETCH_PIXELS;
            end

            NEXT_POSITION: begin
                if ((out_row >= max_out_row) && (out_col >= max_out_col))
                    next_state = DONE;
                else
                    next_state = FETCH_PIXELS;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Main sequential logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset all outputs
            img_mem_en      <= 1'b0;
            img_mem_addr    <= {ADDR_WIDTH{1'b0}};
            ker_mem_en      <= 1'b0;
            ker_mem_addr    <= {ADDR_WIDTH{1'b0}};
            pe_srca_word    <= {`WORD_WIDTH{1'b0}};
            pe_srcb         <= {`DATA_WIDTH{1'b0}};
            pe_clr          <= 1'b0;
            pe_we           <= 1'b0;
            busy            <= 1'b0;
            conv_done       <= 1'b0;
            frame_done      <= 1'b0;

            // Reset counters
            out_row         <= 10'd0;
            out_col         <= 10'd0;
            ker_row         <= 3'd0;
            ker_col         <= 3'd0;
            kernel_count    <= 6'd0;
            max_out_row     <= 10'd0;
            max_out_col     <= 10'd0;
            fetch_delay     <= 2'd0;
            pixels_ready    <= 1'b0;
            kernel_ready    <= 1'b0;

            // Reset pixel buffer
            for (i = 0; i < NUM_PE; i = i + 1) begin
                pixel_buffer[i] <= {PIXEL_WIDTH{1'b0}};
            end

        end else begin
            // Default outputs
            pe_clr      <= 1'b0;
            pe_we       <= 1'b0;
            conv_done   <= 1'b0;
            frame_done  <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (start && enable) begin
                        busy            <= 1'b1;
                        out_row         <= 10'd0;
                        out_col         <= 10'd0;
                        ker_row         <= 3'd0;
                        ker_col         <= 3'd0;
                        kernel_count    <= 6'd0;
                        fetch_delay     <= 2'd0;
                        pixels_ready    <= 1'b0;
                        kernel_ready    <= 1'b0;

                        // Calculate output dimensions (img_size - kernel_size + 1)
                        max_out_row     <= img_width - kernel_size;
                        max_out_col     <= img_width - kernel_size;

                        // Clear PE accumulators at start of new convolution
                        pe_clr          <= 1'b1;
                    end
                end

                FETCH_PIXELS: begin
                    // Enable image memory read
                    img_mem_en   <= 1'b1;
                    img_mem_addr <= pixel_addr;
                    fetch_delay  <= fetch_delay + 1'b1;

                    if (fetch_delay == 2'd2) begin
                        // Pixels available from memory (2 cycle latency)
                        // Unpack 64-bit data into 8 pixel buffer
                        for (i = 0; i < NUM_PE; i = i + 1) begin
                            pixel_buffer[i] <= img_mem_data[i*PIXEL_WIDTH +: PIXEL_WIDTH];
                        end
                        pixels_ready <= 1'b1;
                        img_mem_en   <= 1'b0;
                        fetch_delay  <= 2'd0;
                    end
                end

                FETCH_KERNEL: begin
                    // Enable kernel memory read
                    ker_mem_en   <= 1'b1;
                    ker_mem_addr <= kernel_addr;

                    // 1 cycle delay for kernel fetch
                    if (ker_mem_en) begin
                        pe_srcb      <= ker_mem_data;
                        kernel_ready <= 1'b1;
                        ker_mem_en   <= 1'b0;
                    end
                end

                COMPUTE: begin
                    pixels_ready <= 1'b0;
                    kernel_ready <= 1'b0;

                    // Convert 8-bit pixels to 16-bit and pack into word
                    // Zero-extend 8-bit to 16-bit for unsigned pixels
                    pe_srca_word[`DATA0] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[0]};
                    pe_srca_word[`DATA1] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[1]};
                    pe_srca_word[`DATA2] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[2]};
                    pe_srca_word[`DATA3] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[3]};
                    pe_srca_word[`DATA4] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[4]};
                    pe_srca_word[`DATA5] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[5]};
                    pe_srca_word[`DATA6] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[6]};
                    pe_srca_word[`DATA7] <= {{(16-PIXEL_WIDTH){1'b0}}, pixel_buffer[7]};

                    // Update kernel position counters
                    if (ker_col == kernel_size - 1) begin
                        ker_col <= 3'd0;
                        if (ker_row == kernel_size - 1) begin
                            ker_row <= 3'd0;
                            // Kernel iteration complete - write enable
                            pe_we <= 1'b1;
                        end else begin
                            ker_row <= ker_row + 1'b1;
                        end
                    end else begin
                        ker_col <= ker_col + 1'b1;
                    end

                    kernel_count <= kernel_count + 1'b1;
                end

                NEXT_POSITION: begin
                    kernel_count <= 6'd0;
                    conv_done    <= 1'b1;

                    // Clear accumulators for next convolution window
                    pe_clr <= 1'b1;

                    // Move to next output position
                    if (out_col >= max_out_col) begin
                        out_col <= 10'd0;
                        if (out_row >= max_out_row) begin
                            // All positions done
                        end else begin
                            out_row <= out_row + 1'b1;
                        end
                    end else begin
                        out_col <= out_col + 1'b1;
                    end
                end

                DONE: begin
                    busy       <= 1'b0;
                    frame_done <= 1'b1;
                end

                default: begin
                    // Do nothing
                end
            endcase
        end
    end

endmodule

`endif
