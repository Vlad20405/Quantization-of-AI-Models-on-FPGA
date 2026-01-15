module qnn_fpga_wrapper #(
  parameter int IN_DIM  = 64,
  parameter int OUT_DIM = 16,
  parameter int NUM_PE  = 1
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  output logic done
);

  // precision select
  logic [1:0] layer_prec;

  // inputs/weights/biases (arrays)
  logic signed [7:0]  in8  [IN_DIM];
  logic signed [7:0]  w8   [OUT_DIM][IN_DIM];

  logic signed [3:0]  in4  [IN_DIM];
  logic signed [3:0]  w4   [OUT_DIM][IN_DIM];

  logic        inb [IN_DIM];
  logic        wb  [OUT_DIM][IN_DIM];

  logic signed [31:0] bias [OUT_DIM];
  logic signed [31:0] out  [OUT_DIM];

  // init to zero for simulation (so design is fully driven)
  integer i, j;
  initial begin
    layer_prec = 2'b00; // choose INT8/INT4/BIN based on your design encoding

    for (i = 0; i < IN_DIM; i = i + 1) begin
      in8[i] = '0;
      in4[i] = '0;
      inb[i] = 1'b0;

      for (j = 0; j < OUT_DIM; j = j + 1) begin
        w8[j][i] = '0;
        w4[j][i] = '0;
        wb[j][i] = 1'b0;
      end
    end

    for (j = 0; j < OUT_DIM; j = j + 1) begin
      bias[j] = '0;
    end
  end

  // DUT
   qnn_accel_top #(
    .IN_DIM(IN_DIM),
    .OUT_DIM(OUT_DIM),
    .NUM_PE(NUM_PE)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .layer_prec(layer_prec),
    .in8(in8), .w8(w8),
    .in4(in4), .w4(w4),
    .inb(inb), .wb(wb),
    .bias(bias),
    .out(out),
    .done(done)
  );

  logic [31:0] _unused_ok;
  always_comb _unused_ok = out[0];

endmodule
