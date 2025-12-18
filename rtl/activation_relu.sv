module activation_relu(
  input  logic signed [31:0] x,
  output logic signed [31:0] y
);
  always_comb y = (x < 0) ? 32'sd0 : x;
endmodule
