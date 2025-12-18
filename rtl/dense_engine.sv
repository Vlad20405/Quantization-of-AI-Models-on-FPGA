module dense_engine #(
  parameter int IN_DIM  = 64,
  parameter int OUT_DIM = 16,
  parameter int NUM_PE  = 1
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic [1:0] prec,

  input  logic signed [7:0] in8 [IN_DIM],
  input  logic signed [7:0] w8  [OUT_DIM][IN_DIM],

  input  logic signed [3:0] in4 [IN_DIM],
  input  logic signed [3:0] w4  [OUT_DIM][IN_DIM],

  input  logic        inb [IN_DIM],
  input  logic        wb  [OUT_DIM][IN_DIM],

  input  logic signed [31:0] bias [OUT_DIM],

  output logic signed [31:0] out  [OUT_DIM],
  output logic done
);

  typedef enum logic [1:0] {IDLE, CALC, FINAL, DONE} state_t;
  state_t state;

  int unsigned o_idx, i_idx, f_idx;
  logic signed [31:0] acc [OUT_DIM];

  logic signed [7:0] a8_pe [NUM_PE];
  logic signed [7:0] b8_pe [NUM_PE];
  logic signed [3:0] a4_pe [NUM_PE];
  logic signed [3:0] b4_pe [NUM_PE];
  logic        ab_pe [NUM_PE];
  logic        bb_pe [NUM_PE];

  logic signed [31:0] sum_prod;

  mac_array #(.NUM_PE(NUM_PE)) u_arr(
    .prec(prec),
    .a8(a8_pe), .b8(b8_pe),
    .a4(a4_pe), .b4(b4_pe),
    .ab(ab_pe), .bb(bb_pe),
    .sum_prod(sum_prod)
  );

  integer p;
  always_comb begin
    for (p=0; p<NUM_PE; p++) begin
      int idx = i_idx + p;
      if (idx < IN_DIM) begin
        a8_pe[p] = in8[idx];
        b8_pe[p] = w8[o_idx][idx];
        a4_pe[p] = in4[idx];
        b4_pe[p] = w4[o_idx][idx];
        ab_pe[p] = inb[idx];
        bb_pe[p] = wb[o_idx][idx];
      end else begin
        a8_pe[p] = '0; b8_pe[p] = '0;
        a4_pe[p] = '0; b4_pe[p] = '0;
        ab_pe[p] = 1'b0; bb_pe[p] = 1'b0;
      end
    end
  end

  integer k;
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      done  <= 1'b0;
      o_idx <= 0; i_idx <= 0; f_idx <= 0;
      for (k=0; k<OUT_DIM; k++) begin
        acc[k] <= 32'sd0;
        out[k] <= 32'sd0;
      end
    end else begin
      done <= 1'b0;

      case (state)
        IDLE: begin
          if (start) begin
            for (k=0; k<OUT_DIM; k++) begin
              acc[k] <= 32'sd0;
              out[k] <= 32'sd0;
            end
            o_idx <= 0; i_idx <= 0; f_idx <= 0;
            state <= CALC;
          end
        end

        CALC: begin
          acc[o_idx] <= acc[o_idx] + sum_prod;

          if (i_idx + NUM_PE >= IN_DIM) begin
            i_idx <= 0;
            if (o_idx == OUT_DIM-1) begin
              f_idx <= 0;
              state <= FINAL;
            end else begin
              o_idx <= o_idx + 1;
            end
          end else begin
            i_idx <= i_idx + NUM_PE;
          end
        end

        FINAL: begin
          out[f_idx] <= (acc[f_idx] + bias[f_idx] < 0) ? 32'sd0 : (acc[f_idx] + bias[f_idx]);

          if (f_idx == OUT_DIM-1) state <= DONE;
          else f_idx <= f_idx + 1;
        end

        DONE: begin
          done  <= 1'b1;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
