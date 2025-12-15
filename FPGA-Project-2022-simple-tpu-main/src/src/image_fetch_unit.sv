module image_fetch_unit #(
    parameter DATA_WIDTH      = 32,
    parameter ADDR_WIDTH      = 12,
    parameter MAX_IMG_WIDTH   = 28,  
    parameter MAX_KERNEL_SIZE = 5
)(
    input wire clk,
    input wire rstn,

    // Controls
    input  wire                       start,      
    input  wire [ADDR_WIDTH-1:0]      base_addr, 
    input  wire [2:0]                 ker_size,  
    input  wire [4:0]                 img_size,  

    // BRAM Interface
    output reg                        bram_en,
    output reg  [ADDR_WIDTH-1:0]      bram_addr,
    input  wire [DATA_WIDTH-1:0]      bram_din,     

    output reg [DATA_WIDTH-1:0]       pe_windows [0:MAX_KERNEL_SIZE-1][0:MAX_KERNEL_SIZE-1],
    output reg                        window_valid,
    output reg                        frame_done
);

    localparam SHIFT_REG_WIDTH = MAX_KERNEL_SIZE;

    reg [DATA_WIDTH-1:0] line_buff_0 [0:MAX_IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_buff_1 [0:MAX_IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_buff_2 [0:MAX_IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_buff_3 [0:MAX_IMG_WIDTH-1];

    reg [DATA_WIDTH-1:0] wide_taps [0:MAX_KERNEL_SIZE-1][0:SHIFT_REG_WIDTH-1];

    reg fetching;
    reg [9:0] col_count;
    reg [9:0] row_count;
    reg pixel_valid_d; 

    integer i, j; 

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bram_addr <= 0;
            bram_en   <= 0;
            fetching  <= 0;
            col_count <= 0;
            row_count <= 0;
            window_valid <= 0;
            frame_done   <= 0;
            pixel_valid_d <= 0;

            for(i=0; i<MAX_KERNEL_SIZE; i=i+1)
                for(j=0; j<SHIFT_REG_WIDTH; j=j+1)
                    wide_taps[i][j] <= 0;
                    
        end else begin

            window_valid <= 0;
            frame_done   <= 0;

            if (start) begin
                fetching    <= 1;
                bram_en     <= 1;
                bram_addr   <= base_addr;
                col_count   <= 0;
                row_count   <= 0;
                pixel_valid_d <= 0;
            end 

            else if (fetching) begin
                bram_addr <= bram_addr + 1;
                pixel_valid_d <= 1; 

                if (row_count == MAX_IMG_WIDTH-1 && col_count == MAX_IMG_WIDTH-1) begin
                    fetching <= 0;
                    bram_en  <= 0;
                    pixel_valid_d <= 0; 
                    frame_done <= 1;
                end
            end

            if (pixel_valid_d) begin
                for (i = 0; i < MAX_IMG_WIDTH-1; i = i + 1) begin
                    line_buff_0[i] <= line_buff_0[i+1];
                    line_buff_1[i] <= line_buff_1[i+1];
                    line_buff_2[i] <= line_buff_2[i+1];
                    line_buff_3[i] <= line_buff_3[i+1];
                end
                
                line_buff_0[MAX_IMG_WIDTH-1] <= bram_din;      
                line_buff_1[MAX_IMG_WIDTH-1] <= line_buff_0[0];
                line_buff_2[MAX_IMG_WIDTH-1] <= line_buff_1[0];
                line_buff_3[MAX_IMG_WIDTH-1] <= line_buff_2[0];

                for (i = 0; i < MAX_KERNEL_SIZE; i = i + 1) begin
                    for (j = 0; j < SHIFT_REG_WIDTH-1; j = j + 1) begin
                        wide_taps[i][j] <= wide_taps[i][j+1];
                    end
                end

                wide_taps[0][SHIFT_REG_WIDTH-1] <= line_buff_3[0]; 
                wide_taps[1][SHIFT_REG_WIDTH-1] <= line_buff_2[0];
                wide_taps[2][SHIFT_REG_WIDTH-1] <= line_buff_1[0];
                wide_taps[3][SHIFT_REG_WIDTH-1] <= line_buff_0[0];
                wide_taps[4][SHIFT_REG_WIDTH-1] <= bram_din;     

                if (col_count == MAX_IMG_WIDTH - 1) begin
                    col_count <= 0;
                    row_count <= row_count + 1;
                end else begin
                    col_count <= col_count + 1;
                end

                if (row_count >= ker_size-1 && col_count >= (ker_size - 1)) begin
                    window_valid <= 1;
                end
            end
        end
    end

    always @(*) begin
        for (i = 0; i < MAX_KERNEL_SIZE; i = i + 1) begin
            for (j = 0; j < MAX_KERNEL_SIZE; j = j + 1) pe_windows[i][j] = 0;
        end

        case (ker_size)
            3'd5: begin
                for (i = 0; i < 5; i = i + 1) begin       
                    for (j = 0; j < 5; j = j + 1) begin   
                        pe_windows[i][j] = wide_taps[i][j];
                    end
                end
            end

            3'd3: begin
                for (i = 0; i < 3; i = i + 1) begin
                    for (j = 0; j < 3; j = j + 1) begin
                        pe_windows[i][j] = wide_taps[i+2][j + 2];
                    end
                end
            end
            
            3'd2: begin
                for (i = 0; i < 2; i = i + 1) begin
                    for (j = 0; j < 2; j = j + 1) begin
                        pe_windows[i][j] = wide_taps[i+3][j + 3];
                    end
                end
            end
        endcase
    end

endmodule