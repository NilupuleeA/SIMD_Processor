module fetch_unit #(
    parameter ADDR_WIDTH        = 10,
    parameter DATA_WIDTH        = 32,
    parameter MAX_KERNEL_SIZE   = 5,
    parameter PE_COUNT          = 1,
    parameter KERNEL_SIZE_WIDTH = 3
)(
    input  wire                                 clk,
    input  wire                                 rstn,
    input  wire [2:0]                           du_ker_size_in,  
    input  wire [11:0]                          du_img_size_in, 
    input  wire [ADDR_WIDTH-1:0]                du_img_base_addr_in, 
    input  wire [ADDR_WIDTH-1:0]                du_ker_base_addr_in, 
    input  wire                                 cu_img_fetch_en_in,
    input  wire                                 cu_ker_fetch_en_in,   
    output reg                                  ibram_en_out,
    output reg [ADDR_WIDTH-1:0]                 ibram_addr_out,
    input  wire [PE_COUNT-1:0][DATA_WIDTH-1:0]  ibram_data_in,
    output reg                                  kbram_en_out,
    output reg [ADDR_WIDTH-1:0]                 kbram_addr_out,
    input  wire [PE_COUNT-1:0][DATA_WIDTH-1:0]  kbram_data_in,
    output wire                                 pea_kernel_valid_out,
    output wire                                 pea_window_valid_out,
    output reg  [DATA_WIDTH-1:0]                pea_kernel_out [0:MAX_KERNEL_SIZE*MAX_KERNEL_SIZE-1],
    output reg  [DATA_WIDTH-1:0]                pea_window_out [0:MAX_KERNEL_SIZE*MAX_KERNEL_SIZE-1],
    output wire [KERNEL_SIZE_WIDTH-1:0]         swu_kernel_size_out, 
    output wire [11:0]                          swu_img_size_out,   
    output reg  [DATA_WIDTH-1:0]                swu_pixel_out,
    output reg                                  swu_pixel_valid_out, 
    input  wire [DATA_WIDTH-1:0]                swu_window_in [0:(MAX_KERNEL_SIZE*MAX_KERNEL_SIZE)-1],
    input  wire                                 swu_window_valid_in
);

    assign swu_kernel_size_out  = du_ker_size_in;
    assign swu_img_size_out     = du_img_size_in;
    
    assign pea_window_valid_out = swu_window_valid_in;

    reg weights_loaded;
    assign pea_kernel_valid_out = weights_loaded;

    always @(*) begin
        for(int i=0; i < MAX_KERNEL_SIZE*MAX_KERNEL_SIZE; i++) begin
            pea_window_out[i] = swu_window_in[i];
        end
    end

    reg [ADDR_WIDTH-1:0] k_cnt;
    reg [ADDR_WIDTH-1:0] i_cnt;
    reg [ADDR_WIDTH-1:0] k_limit;
    reg [ADDR_WIDTH-1:0] i_limit;
    reg k_valid_d;
    reg i_valid_d;
    reg ker_busy;
    reg img_busy;
    reg [ADDR_WIDTH-1:0] k_write_idx;

    always @(*) begin
        k_limit = du_ker_size_in * du_ker_size_in;
        i_limit = du_img_size_in * du_img_size_in;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            kbram_en_out    <= 0;
            kbram_addr_out  <= 0;
            k_cnt           <= 0;
            ker_busy        <= 0;
            k_valid_d       <= 0;
            k_write_idx     <= 0;
            weights_loaded  <= 0;

            for(int i=0; i<MAX_KERNEL_SIZE*MAX_KERNEL_SIZE; i++) pea_kernel_out[i] <= 0;
        end else begin

            if (cu_ker_fetch_en_in) begin
                ker_busy       <= 1;
                k_cnt          <= 0;
                kbram_en_out   <= 1;
                kbram_addr_out <= du_ker_base_addr_in;
                k_write_idx    <= 0; 
                weights_loaded <= 0;
            end

            if (ker_busy) begin
                if (k_cnt < k_limit - 1) begin
                    kbram_addr_out <= kbram_addr_out + 1;
                    k_cnt          <= k_cnt + 1;
                    kbram_en_out   <= 1;
                end else begin
                    kbram_en_out   <= 0;
                end

                if (!kbram_en_out && !k_valid_d) begin
                    ker_busy       <= 0;
                    weights_loaded <= 1;
                end
            end

            k_valid_d <= kbram_en_out; 
            
            if (k_valid_d) begin
                pea_kernel_out[k_write_idx] <= kbram_data_in[0];
                k_write_idx <= k_write_idx + 1;
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ibram_en_out        <= 0;
            ibram_addr_out      <= 0;
            i_cnt               <= 0;
            img_busy            <= 0;
            i_valid_d           <= 0;
            swu_pixel_valid_out <= 0;
            swu_pixel_out       <= 0;
        end else begin

            if (cu_img_fetch_en_in && !img_busy) begin
                img_busy       <= 1;
                i_cnt          <= 0;
                ibram_en_out   <= 1;
                ibram_addr_out <= du_img_base_addr_in;
            end

            if (img_busy) begin
                if (i_cnt < i_limit - 1) begin
                    ibram_addr_out <= ibram_addr_out + 1;
                    i_cnt          <= i_cnt + 1;
                    ibram_en_out   <= 1;
                end else begin
                    ibram_en_out   <= 0;
                end

                if (!ibram_en_out && !i_valid_d) begin
                    img_busy <= 0;
                end
            end

            i_valid_d <= ibram_en_out;
            
            if (i_valid_d) begin
                swu_pixel_out       <= ibram_data_in[0];
                swu_pixel_valid_out <= 1;
            end else begin
                swu_pixel_valid_out <= 0;
            end
        end
    end

endmodule