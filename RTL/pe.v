//
// pe.v
//
// The process element doing mac operations and propagating the input a and b to
// its adjacent pe's. The mac operation assumes 16 fixed-point data input with
// 8 fraction bits. The computation is done in 16-32-16 manner to ensure better
// precision. The propagation delay from src to psum is 2 cc's.
//
`ifndef _PE_V
`define _PE_V

`include "def.v"

// Mode definitions
`define MODE_CONV    2'b00
`define MODE_MAXPOOL 2'b01

module pe (
  input  clk_i,
  input  rst_ni,
  input  clr_i,  // Clear signal for accumulated value
  output clr_o,  // Propagation of the clear signal

  input  [1:0] mode_i, // Mode select: 00 = convolution, 01 = maxpool

  input  signed [`DATA_WIDTH-1:0] srca_i,
  input  signed [`DATA_WIDTH-1:0] srcb_i,

  output signed [`DATA_WIDTH-1:0] srca_o,
  output signed [`DATA_WIDTH-1:0] srcb_o,
  output signed [`DATA_WIDTH-1:0] psum_o
);

  // State definitions
  localparam STATE_IDLE    = 2'b00;
  localparam STATE_COMPUTE = 2'b01;
  localparam STATE_ACCUM   = 2'b10;

  // State register
  reg [1:0] state_q, state_d;

  // Pipeline registers
  reg                     clr_q;
  reg [`DATA_WIDTH-1:0]   srca_q, srcb_q;
  reg [`DATA_WIDTH*2-1:0] ab_q;
  reg [`DATA_WIDTH*2-1:0] psum_q;

  // Input of pipeline registers
  wire                     clr_d  = clr_i;
  wire [`DATA_WIDTH-1:0]   srca_d = srca_i;
  wire [`DATA_WIDTH-1:0]   srcb_d = srcb_i;

  // Intermediate computations
  wire [`DATA_WIDTH*2-1:0] mult_result = srca_i * srcb_i;
  wire [`DATA_WIDTH*2-1:0] srca_ext    = {{`DATA_WIDTH{srca_i[`DATA_WIDTH-1]}}, srca_i}; // Sign-extend srca_i
  wire [`DATA_WIDTH*2-1:0] max_result  = ($signed(psum_q) > $signed(srca_ext)) ? psum_q : srca_ext;

  // Compute and accumulate logic based on mode (state machine)
  reg [`DATA_WIDTH*2-1:0] ab_d;
  reg [`DATA_WIDTH*2-1:0] psum_d;

  // State machine - next state logic
  always @(*) begin
    state_d = state_q;
    case (state_q)
      STATE_IDLE: begin
        state_d = STATE_COMPUTE;
      end
      STATE_COMPUTE: begin
        state_d = STATE_ACCUM;
      end
      STATE_ACCUM: begin
        state_d = STATE_COMPUTE;
      end
      default: state_d = STATE_IDLE;
    endcase
  end

  // State machine - output logic (Moore-style with mode selection)
  always @(*) begin
    ab_d   = 'd0;
    psum_d = psum_q;

    case (state_q)
      STATE_IDLE: begin
        ab_d   = 'd0;
        psum_d = 'd0;
      end

      STATE_COMPUTE: begin
        case (mode_i)
          `MODE_CONV: begin
            // Convolution: multiply srca * srcb
            ab_d = mult_result;
          end
          `MODE_MAXPOOL: begin
            // Maxpool: compare current input with accumulated max
            ab_d = max_result;
          end
          default: begin
            ab_d = mult_result;
          end
        endcase
        psum_d = clr_q ? 'd0 : psum_q;
      end

      STATE_ACCUM: begin
        case (mode_i)
          `MODE_CONV: begin
            // Convolution: accumulate product
            ab_d   = ab_q;
            psum_d = ab_q + (clr_q ? 'd0 : psum_q);
          end
          `MODE_MAXPOOL: begin
            // Maxpool: store maximum value directly
            ab_d   = ab_q;
            psum_d = ab_q; // In maxpool, ab_q already holds the max
          end
          default: begin
            ab_d   = ab_q;
            psum_d = ab_q + (clr_q ? 'd0 : psum_q);
          end
        endcase
      end

      default: begin
        ab_d   = 'd0;
        psum_d = 'd0;
      end
    endcase
  end

  // Assign output signals
  assign clr_o  = clr_q;
  assign srca_o = srca_q;
  assign srcb_o = srcb_q;
  assign psum_o = psum_q[8+`DATA_WIDTH-1:8];  // Fraction bits are psum_q[15:0]

  // State register update
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= STATE_IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  // Pipeline propagation of srca and srcb
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      srca_q <= 'd0;
      srcb_q <= 'd0;
    end else begin
      srca_q <= srca_d;
      srcb_q <= srcb_d;
    end
  end

  // Pipeline propagation of clear signal
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      clr_q <= 1'b0;
    end else begin
      clr_q <= clr_d;
    end
  end

  // Pipeline propagation of ab and psum
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ab_q   <= 'd0;
      psum_q <= 'd0;
    end else begin
      ab_q   <= ab_d;
      psum_q <= psum_d;
    end
  end

endmodule

`endif
