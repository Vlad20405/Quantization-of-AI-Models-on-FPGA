module conv2d_stub(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic [1:0] prec,
  output logic done
);
  always_ff @(posedge clk) begin
    if (!rst_n) done <= 1'b0;
    else done <= start;
  end
endmodule
