module qnn_dense_top #(
  parameter int IN_DIM  = 64,
  parameter int OUT_DIM = 16
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic [1:0] prec,   // 0=INT8, 1=INT4, 2=BIN

  input  logic signed [7:0] in8 [IN_DIM],
  input  logic signed [7:0] w8  [OUT_DIM][IN_DIM],

  input  logic signed [3:0] in4 [IN_DIM],
  input  logic signed [3:0] w4  [OUT_DIM][IN_DIM],

  input  logic        inb [IN_DIM],           // 0 => -1, 1 => +1
  input  logic        wb  [OUT_DIM][IN_DIM],  // 0 => -1, 1 => +1

  input  logic signed [31:0] bias [OUT_DIM],

  output logic signed [31:0] out  [OUT_DIM],
  output logic done
);

  typedef enum logic [1:0] {IDLE, CALC, FINAL, DONE} state_t;
  state_t state;

  int unsigned o_idx, i_idx, f_idx;

  logic signed [31:0] acc [OUT_DIM];

  // product for current (o_idx, i_idx)
  logic signed [31:0] prod32;

  always_comb begin
    prod32 = 32'sd0;
    unique case (prec)
      2'd0: prod32 = $signed(in8[i_idx]) * $signed(w8[o_idx][i_idx]);
      2'd1: prod32 = $signed(in4[i_idx]) * $signed(w4[o_idx][i_idx]);
      default: begin
        // BIN: (+1 if same) else (-1)
        prod32 = (inb[i_idx] == wb[o_idx][i_idx]) ? 32'sd1 : -32'sd1;
      end
    endcase
  end

  integer k;
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      done  <= 1'b0;
      o_idx <= 0;
      i_idx <= 0;
      f_idx <= 0;
      for (k = 0; k < OUT_DIM; k++) begin
        acc[k] <= 32'sd0;
        out[k] <= 32'sd0;
      end
    end else begin
      done <= 1'b0;

      case (state)
        IDLE: begin
          if (start) begin
            for (k = 0; k < OUT_DIM; k++) begin
              acc[k] <= 32'sd0;
              out[k] <= 32'sd0;
            end
            o_idx <= 0;
            i_idx <= 0;
            f_idx <= 0;
            state <= CALC;
          end
        end

        CALC: begin
          acc[o_idx] <= acc[o_idx] + prod32;

          if (i_idx == IN_DIM-1) begin
            i_idx <= 0;
            if (o_idx == OUT_DIM-1) begin
              f_idx <= 0;
              state <= FINAL;
            end else begin
              o_idx <= o_idx + 1;
            end
          end else begin
            i_idx <= i_idx + 1;
          end
        end

        FINAL: begin
          logic signed [31:0] y;
          y = acc[f_idx] + bias[f_idx];
          if (y < 0) y = 0;
          out[f_idx] <= y;

          if (f_idx == OUT_DIM-1) begin
            state <= DONE;
          end else begin
            f_idx <= f_idx + 1;
          end
        end

        DONE: begin
          done  <= 1'b1;
          state <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
