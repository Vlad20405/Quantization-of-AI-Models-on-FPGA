module qnn_accel_top #(
  parameter int IN_DIM  = 64,
  parameter int OUT_DIM = 16,
  parameter int NUM_PE  = 1
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic [1:0] layer_prec,

  input  logic signed [7:0] in8 [IN_DIM],
  input  logic signed [7:0] w8  [OUT_DIM][IN_DIM],
  input  logic signed [3:0] in4 [IN_DIM],
  input  logic signed [3:0] w4  [OUT_DIM][IN_DIM],
  input  logic        inb [IN_DIM],
  input  logic        wb  [OUT_DIM][IN_DIM],
  input  logic signed [31:0] bias [OUT_DIM],

  output logic signed [31:0] out [OUT_DIM],
  output logic done
);

  logic [1:0] active_prec;
  logic load_prec;
  logic run_dense;
  logic dense_done;

  mixed_precision_ctrl u_prec(
    .clk(clk), .rst_n(rst_n),
    .load(load_prec),
    .layer_prec(layer_prec),
    .active_prec(active_prec)
  );

  dense_engine #(.IN_DIM(IN_DIM), .OUT_DIM(OUT_DIM), .NUM_PE(NUM_PE)) u_dense(
    .clk(clk), .rst_n(rst_n),
    .start(run_dense),
    .prec(active_prec),
    .in8(in8), .w8(w8),
    .in4(in4), .w4(w4),
    .inb(inb), .wb(wb),
    .bias(bias),
    .out(out),
    .done(dense_done)
  );

  scheduler_ctrl u_sched(
    .clk(clk), .rst_n(rst_n),
    .start(start),
    .load_prec(load_prec),
    .run_dense(run_dense),
    .dense_done(dense_done),
    .done(done)
  );

endmodule
