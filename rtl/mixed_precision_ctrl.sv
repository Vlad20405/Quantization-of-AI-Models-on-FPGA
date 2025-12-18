module mixed_precision_ctrl(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       load,
  input  logic [1:0] layer_prec,
  output logic [1:0] active_prec
);
  always_ff @(posedge clk) begin
    if (!rst_n) active_prec <= 2'd0;
    else if (load) active_prec <= layer_prec;
  end
endmodule
