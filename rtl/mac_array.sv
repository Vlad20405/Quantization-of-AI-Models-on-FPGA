module mac_array #(
  parameter int NUM_PE = 1
)(
  input  logic [1:0] prec,
  input  logic signed [7:0] a8 [NUM_PE],
  input  logic signed [7:0] b8 [NUM_PE],
  input  logic signed [3:0] a4 [NUM_PE],
  input  logic signed [3:0] b4 [NUM_PE],
  input  logic        ab [NUM_PE],
  input  logic        bb [NUM_PE],
  output logic signed [31:0] sum_prod
);
  logic signed [31:0] prod [NUM_PE];

  genvar i;
  generate
    for (i=0; i<NUM_PE; i++) begin: PE
      mac_unit u_mac(
        .prec(prec),
        .a8(a8[i]), .b8(b8[i]),
        .a4(a4[i]), .b4(b4[i]),
        .ab(ab[i]), .bb(bb[i]),
        .prod(prod[i])
      );
    end
  endgenerate

  integer k;
  always_comb begin
    sum_prod = 32'sd0;
    for (k=0; k<NUM_PE; k++) sum_prod += prod[k];
  end
endmodule
