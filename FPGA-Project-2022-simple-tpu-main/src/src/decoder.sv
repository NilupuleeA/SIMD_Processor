`include "params.svh"

module decoder #(
    parameter INS_ADDR_WIDTH = 10,
    parameter ADDR_WIDTH = 10,
    parameter IMG_SIZE_WIDTH = 5,
    parameter KERNEL_SIZE_WIDTH = 3
) (
    input logic clk,     
    input logic rstn,
    input logic half_clk,
    input logic ins_valid,
    
    //Instruction memory interface
    output logic [INS_ADDR_WIDTH-1:0] bram_ins_addr, //next instruction address
    input  logic [(OPCODE_WIDTH+ADDR_WIDTH*3+IMG_SIZE_WIDTH)-1:0] bram_ins_din, //From ins mem

    //Image fetch Unit interface
    output logic img_fetch_en,
    output logic [IMG_SIZE_WIDTH-1:0] img_size,
    output logic [ADDR_WIDTH-1:0] img_addr, 
    
    //Kernel fetch Unit interface
    output logic ker_fetch_en,
    output logic [KERNEL_SIZE_WIDTH-1:0] ker_size, 
    output logic [ADDR_WIDTH-1:0] ker_addr, 

    output logic write_en,
    output logic [ADDR_WIDTH-1:0] out_addr,

    output logic [OP_SEL_WIDTH-1:0] pe_op,     
    output logic ins_done
);

    logic [OPCODE_WIDTH-1:0] opcode;

    assign opcode = bram_ins_din[OPCODE_WIDTH-1 : 0];
    assign out_addr = bram_ins_din[OPCODE_WIDTH+ADDR_WIDTH-1 : OPCODE_WIDTH];
    assign ker_addr = bram_ins_din[(OPCODE_WIDTH+ADDR_WIDTH*2)-1 : OPCODE_WIDTH+ADDR_WIDTH];
    assign img_addr = bram_ins_din[(OPCODE_WIDTH+ADDR_WIDTH*3)-1 : OPCODE_WIDTH+ADDR_WIDTH*2];
    assign img_size = bram_ins_din[(OPCODE_WIDTH+ADDR_WIDTH*3+IMG_SIZE_WIDTH)-1 : (OPCODE_WIDTH+ADDR_WIDTH*3)];

    assign ins_done = ((opcode==3'b000) || (bram_ins_addr=={INS_ADDR_WIDTH{1'b1}}));

    always @(posedge clk) begin
        if (!rstn)
            bram_ins_addr <= {INS_ADDR_WIDTH{1'b0}};
        else if (half_clk) begin
            bram_ins_addr <= bram_ins_addr + 1; 
            if (bram_ins_addr=={INS_ADDR_WIDTH{1'b1}}) begin
                if (ins_valid) begin
                    bram_ins_addr <= {INS_ADDR_WIDTH{1'b0}};
                end else begin
                    bram_ins_addr <= bram_ins_addr;
                end
            end

        end
	end


    always_comb begin
        case (opcode)
            //Nop 
            3'b000 : begin
                pe_op = 2'b00;
                write_en = 0;
                img_fetch_en = 0;
                ker_fetch_en = 0;
                ker_size = 3'b00;
            end
            //CONV_2
            3'b001 : begin
                pe_op = 2'b01;
                write_en = 1;
                img_fetch_en = 1;
                ker_fetch_en = 1;
                ker_size = 3'b010;
            end
            //CONV_3
            3'b010 : begin
                pe_op = 2'b01;
                write_en = 1;
                img_fetch_en = 1;
                ker_fetch_en = 1;
                ker_size = 3'b011;
            end
            //CONV_5
            3'b011 : begin
                pe_op = 2'b01;
                write_en = 1;
                img_fetch_en = 1;
                ker_fetch_en = 1;
                ker_size = 3'b101;
            end
            //Maxpool
            3'b100 : begin
                pe_op = 2'b10;
                write_en = 1;
                img_fetch_en = 1;
                ker_fetch_en = 0;
                ker_size = 3'b010;
            end  
            //ReLu
            3'b101 : begin
                pe_op = 2'b11;
                write_en = 1;
                img_fetch_en = 1;
                ker_fetch_en = 0;
                ker_size = 3'b000;
            end 
            //HALT
            3'b110 : begin
                pe_op = 2'b00;
                write_en = 0;
                img_fetch_en = 0;
                ker_fetch_en = 0;
                ker_size =3'b000;
            end        
            default : begin
                pe_op = 2'b00;
                write_en = 0;
                img_fetch_en = 0;
                ker_fetch_en = 0;
                ker_size = 3'b000;
            end
        endcase
    end

endmodule