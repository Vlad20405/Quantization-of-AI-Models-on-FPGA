module mac_unit(
  input  logic [1:0] prec, // 0=INT8, 1=INT4, 2=BIN
  input  logic signed [7:0] a8,
  input  logic signed [7:0] b8,
  input  logic signed [3:0] a4,
  input  logic signed [3:0] b4,
  input  logic        ab,
  input  logic        bb,
  output logic signed [31:0] prod
);
  always_comb begin
    unique case (prec)
      2'd0: prod = $signed(a8) * $signed(b8);
      2'd1: prod = $signed(a4) * $signed(b4);
      default: prod = (ab == bb) ? 32'sd1 : -32'sd1;
    endcase
  end
endmodule
