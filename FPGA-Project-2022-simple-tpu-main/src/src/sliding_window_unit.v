module sliding_window_unit #(
    parameter DATA_WIDTH        = 8,
    parameter MAX_IMG_WIDTH     = 28, 
    parameter MAX_KERNEL_SIZE   = 7,
    parameter IMG_SIZE_WIDTH    = 5,
    parameter KERNEL_SIZE_WIDTH = 3     
)(
    input  wire                         clk,
    input  wire                         rst_n,

    input  wire [KERNEL_SIZE_WIDTH-1:0] fu_kernel_size_in, 
    input  wire [IMG_SIZE_WIDTH-1:0]    fu_img_size_in,   
    input  wire [DATA_WIDTH-1:0]        fu_pixel_in,
    input  wire                         fu_pixel_valid_in, 
    output reg  [DATA_WIDTH-1:0]        fu_window_out [0:(MAX_KERNEL_SIZE*MAX_KERNEL_SIZE)-1],
    output reg                          fu_window_valid_out
);

    reg [DATA_WIDTH-1:0] line_buff [0:MAX_KERNEL_SIZE-2][0:MAX_IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] taps [0:MAX_KERNEL_SIZE-1][0:MAX_KERNEL_SIZE-1];

    reg [11:0] col_cnt;
    reg [11:0] row_cnt;

    integer i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt     <= 0;
            row_cnt     <= 0;
            fu_window_valid_out   <= 0;

            for(i=0; i<MAX_KERNEL_SIZE-1; i=i+1)
                for(j=0; j<MAX_IMG_WIDTH; j=j+1)
                    line_buff[i][j] <= 0;

            for(i=0; i<MAX_KERNEL_SIZE; i=i+1)
                for(j=0; j<MAX_KERNEL_SIZE; j=j+1)
                    taps[i][j] <= 0;

        end else if (fu_pixel_valid_in) begin
            for(i=0; i<MAX_KERNEL_SIZE-1; i=i+1) begin
                for(j=MAX_IMG_WIDTH-1; j>0; j=j-1) begin
                    line_buff[i][j] <= line_buff[i][j-1];
                end
            end

            line_buff[0][0] <= fu_pixel_in;
            for(i=1; i<MAX_KERNEL_SIZE-1; i=i+1) begin
                line_buff[i][0] <= line_buff[i-1][fu_img_size_in-1];
            end

            for(i=0; i<MAX_KERNEL_SIZE; i=i+1) begin
                for(j=0; j<MAX_KERNEL_SIZE-1; j=j+1) begin
                    taps[i][j] <= taps[i][j+1];
                end
            end
            
            taps[MAX_KERNEL_SIZE-1][MAX_KERNEL_SIZE-1] <= fu_pixel_in;
            
            for(i=0; i<MAX_KERNEL_SIZE-1; i=i+1) begin
                taps[(MAX_KERNEL_SIZE-2) - i][MAX_KERNEL_SIZE-1] <= line_buff[i][fu_img_size_in-1];
            end

            if (col_cnt == fu_img_size_in - 1) begin
                col_cnt <= 0;
                if (row_cnt == fu_img_size_in - 1)
                    row_cnt <= 0;
                else
                    row_cnt <= row_cnt + 1;
            end else begin
                col_cnt <= col_cnt + 1;
            end

            if (row_cnt >= (fu_kernel_size_in - 1) && col_cnt >= (fu_kernel_size_in - 1))
                fu_window_valid_out <= 1;
            else
                fu_window_valid_out <= 0;
        end else begin
            fu_window_valid_out <= 0;
        end
    end

    always @(*) begin
        for(int k=0; k<MAX_KERNEL_SIZE*MAX_KERNEL_SIZE; k++) fu_window_out[k] = 0;

        for(int r=0; r<fu_kernel_size_in; r++) begin
            for(int c=0; c<fu_kernel_size_in; c++) begin
                fu_window_out[r*fu_kernel_size_in + c] = taps[r+MAX_KERNEL_SIZE-fu_kernel_size_in][c+MAX_KERNEL_SIZE-fu_kernel_size_in];
            end
        end
    end

endmodule
