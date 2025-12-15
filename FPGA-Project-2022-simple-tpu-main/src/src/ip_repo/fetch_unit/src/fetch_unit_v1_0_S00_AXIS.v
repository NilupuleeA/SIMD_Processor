
`timescale 1 ns / 1 ps

	module fetch_unit_v1_0_S00_AXIS #
	(
		parameter BRAM_DEPTH = 10,
		parameter INSTR_BRAM_DEPTH = 11,
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		output [BRAM_DEPTH-1:0] input_addr,
		output [31:0] input_din,
		output input_en,
		output [BRAM_DEPTH-1:0] kernel_addr,
		output [31:0] kernel_din,
		output kernel_en,
		output [INSTR_BRAM_DEPTH-1:0] instr_addr,
		output [31:0] instr_din,
		output instr_en,
		input [1:0] bram_sel,
		input [31:0] row_width,
		output wire VALID_FU2PE,

		input wire  S_AXIS_ACLK,
		input wire  S_AXIS_ARESETN,
		output wire  S_AXIS_TREADY,
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		input wire  S_AXIS_TLAST,
		input wire  S_AXIS_TVALID
	);

	parameter [1:0] IDLE = 1'b0, WRITE_FIFO  = 1'b1;

	reg mst_exec_state;  
	reg [INSTR_BRAM_DEPTH-1:0] write_pointer;
	reg writes_done;
	reg [31:0] row_width_square;

	always@(posedge S_AXIS_ACLK) begin
		if(!S_AXIS_ARESETN) begin
			row_width_square <= 0;
		end  
		else begin
			row_width_square <= row_width * (row_width - 1);
		end
	end
	
	always @(posedge S_AXIS_ACLK) begin  
		if (!S_AXIS_ARESETN) begin
	    	mst_exec_state <= IDLE;
	    end  
	  	else
	    case (mst_exec_state)
	      IDLE: 
			if (S_AXIS_TVALID) mst_exec_state <= WRITE_FIFO;
			else mst_exec_state <= IDLE;
	      WRITE_FIFO: 
	        if (writes_done) mst_exec_state <= IDLE;
	        else mst_exec_state <= WRITE_FIFO;
	    endcase
	end

	always@(posedge S_AXIS_ACLK) begin
		if(!S_AXIS_ARESETN) begin
			write_pointer <= 0;
			writes_done <= 1'b0;
		end  
		else begin
	        if (S_AXIS_TVALID)begin
				if (bram_sel == 2'b01) begin
					if (write_pointer >= row_width_square) begin
						write_pointer <= (write_pointer - row_width_square) + 1;
					end
					else write_pointer <= write_pointer + row_width;
				end
				else 
	            	write_pointer <= write_pointer + 1;
		
	            writes_done <= 1'b0;
	        end

			if (S_AXIS_TLAST) begin
				writes_done <= 1'b1;
				write_pointer <= 0;
			end
			
			if (writes_done) begin
				writes_done <= 1'b0;
			end
	      end  
	end

	assign S_AXIS_TREADY = 1'b1;
	
	assign input_addr = write_pointer[BRAM_DEPTH-1:0];
	assign input_din = S_AXIS_TDATA;
	assign input_en = (bram_sel == 2'b00) & S_AXIS_TVALID;

	assign kernel_addr = write_pointer[BRAM_DEPTH-1:0];
	assign kernel_din = S_AXIS_TDATA;
	assign kernel_en = (bram_sel == 2'b01) & S_AXIS_TVALID;

	assign instr_addr = write_pointer;
	assign instr_din = S_AXIS_TDATA;
	assign instr_en = (bram_sel == 2'b10) & S_AXIS_TVALID;

	assign VALID_FU2PE = (bram_sel == 2'b10) & writes_done;

	endmodule
