`timescale 1ns/1ps

module tb_fetch_unit;

    // ---------------------------------------------------------
    // PARAMETERS
    // ---------------------------------------------------------
    localparam ADDR_WIDTH        = 10;
    localparam DATA_WIDTH        = 32;
    localparam MAX_KERNEL_SIZE   = 5;
    localparam PE_COUNT          = 1;
    localparam KERNEL_SIZE_WIDTH = 3;

    // ---------------------------------------------------------
    // DUT SIGNALS
    // ---------------------------------------------------------
    reg                                 clk;
    reg                                 rstn;
    reg  [2:0]                           du_ker_size_in;
    reg  [11:0]                          du_img_size_in;
    reg  [ADDR_WIDTH-1:0]                du_img_base_addr_in;
    reg  [ADDR_WIDTH-1:0]                du_ker_base_addr_in;
    reg                                  cu_img_fetch_en_in;
    reg                                  cu_ker_fetch_en_in;

    wire                                 ibram_en_out;
    wire [ADDR_WIDTH-1:0]                ibram_addr_out;
    wire [PE_COUNT-1:0][DATA_WIDTH-1:0]  ibram_data_in;

    wire                                 kbram_en_out;
    wire [ADDR_WIDTH-1:0]                kbram_addr_out;
    wire [PE_COUNT-1:0][DATA_WIDTH-1:0]  kbram_data_in;

    wire                                 pea_kernel_valid_out;
    wire                                 pea_window_valid_out;

    wire [DATA_WIDTH-1:0]                pea_kernel_out [0:MAX_KERNEL_SIZE*MAX_KERNEL_SIZE-1];
    wire [DATA_WIDTH-1:0]                pea_window_out [0:MAX_KERNEL_SIZE*MAX_KERNEL_SIZE-1];

    wire [KERNEL_SIZE_WIDTH-1:0]         swu_kernel_size_out;
    wire [11:0]                          swu_img_size_out;

    wire [DATA_WIDTH-1:0]                swu_pixel_out;
    wire                                  swu_pixel_valid_out;

    reg  [DATA_WIDTH-1:0]                 swu_window_in [0:MAX_KERNEL_SIZE*MAX_KERNEL_SIZE-1];
    reg                                  swu_window_valid_in;

    // ---------------------------------------------------------
    // SIMPLE BRAM MODELS
    // ---------------------------------------------------------
    reg [DATA_WIDTH-1:0] kernel_bram [0:1023];
    reg [DATA_WIDTH-1:0] image_bram  [0:1023];

    assign kbram_data_in[0] = kernel_bram[kbram_addr_out];
    assign ibram_data_in[0] = image_bram[ibram_addr_out];

    // ---------------------------------------------------------
    // DUT INSTANTIATION
    // ---------------------------------------------------------
    fetch_unit #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_KERNEL_SIZE(MAX_KERNEL_SIZE),
        .PE_COUNT(PE_COUNT),
        .KERNEL_SIZE_WIDTH(KERNEL_SIZE_WIDTH)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .du_ker_size_in(du_ker_size_in),
        .du_img_size_in(du_img_size_in),
        .du_img_base_addr_in(du_img_base_addr_in),
        .du_ker_base_addr_in(du_ker_base_addr_in),
        .cu_img_fetch_en_in(cu_img_fetch_en_in),
        .cu_ker_fetch_en_in(cu_ker_fetch_en_in),
        .ibram_en_out(ibram_en_out),
        .ibram_addr_out(ibram_addr_out),
        .ibram_data_in(ibram_data_in),
        .kbram_en_out(kbram_en_out),
        .kbram_addr_out(kbram_addr_out),
        .kbram_data_in(kbram_data_in),
        .pea_kernel_valid_out(pea_kernel_valid_out),
        .pea_window_valid_out(pea_window_valid_out),
        .pea_kernel_out(pea_kernel_out),
        .pea_window_out(pea_window_out),
        .swu_kernel_size_out(swu_kernel_size_out),
        .swu_img_size_out(swu_img_size_out),
        .swu_pixel_out(swu_pixel_out),
        .swu_pixel_valid_out(swu_pixel_valid_out),
        .swu_window_in(swu_window_in),
        .swu_window_valid_in(swu_window_valid_in)
    );

    // ---------------------------------------------------------
    // CLOCK GENERATION
    // ---------------------------------------------------------
    always #5 clk = ~clk;   // 100 MHz clock

    // ---------------------------------------------------------
    // TESTCASE
    // ---------------------------------------------------------
    integer i;
    initial begin
        clk = 0;
        rstn = 0;
        cu_img_fetch_en_in = 0;
        cu_ker_fetch_en_in = 0;
        swu_window_valid_in = 0;

        du_ker_size_in = 3;      // 3x3 kernel
        du_img_size_in = 4;      // 4x4 image
        du_ker_base_addr_in = 0;
        du_img_base_addr_in = 0;

        // Load kernel values
        for (i = 0; i < 9; i++)
            kernel_bram[i] = i + 1;   // kernel = 1..9

        // Load image values
        for (i = 0; i < 16; i++)
            image_bram[i] = 100 + i;  // image = 100..115

        // Deassert reset after few cycles
        #20 rstn = 1;

        // ---------------------------------------------------------
        // START FETCHING KERNEL
        // ---------------------------------------------------------
        #10 cu_ker_fetch_en_in = 1;
        cu_img_fetch_en_in = 1;
        // #10 cu_ker_fetch_en_in = 0;

        wait(pea_kernel_valid_out);
        $display("Kernel load completed");

        // ---------------------------------------------------------
        // START FETCHING IMAGE
        // ---------------------------------------------------------
        // #20 cu_img_fetch_en_in = 1;
        // #10 cu_img_fetch_en_in = 0;

        // Wait until all pixels sent
        wait(!cu_img_fetch_en_in && !swu_pixel_valid_out);

        #10;
        $finish;
    end

    // ---------------------------------------------------------
    // MONITOR OUTPUTS
    // ---------------------------------------------------------
    always @(posedge clk) begin
        if (swu_pixel_valid_out) begin
            $display("Pixel OUT = %0d at time %0t", swu_pixel_out, $time);
        end

        if (pea_kernel_valid_out) begin
            $display("Kernel Loaded:");
            for (int k=0; k<9; k++)
                $display("  K[%0d] = %0d", k, pea_kernel_out[k]);
        end
    end

endmodule
