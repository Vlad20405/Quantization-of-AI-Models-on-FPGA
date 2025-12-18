module quantizer_unit #(
  parameter int IN_W = 16
)(
  input  logic signed [IN_W-1:0] in_fx,
  input  logic [4:0] shift,
  output logic signed [7:0] q8,
  output logic signed [3:0] q4,
  output logic        qb
);
  // lucrăm pe IN_W+1 biți ca să evităm overflow la rounding
  logic signed [IN_W:0] in_ext;
  logic signed [IN_W:0] rounded;
  logic signed [IN_W:0] shifted;
  logic signed [IN_W:0] half_lsb;

  always_comb begin
    in_ext = $signed({in_fx[IN_W-1], in_fx}); // sign-extend la IN_W+1

    qb = (in_fx >= 0) ? 1'b1 : 1'b0;

    if (shift == 0) begin
      rounded = in_ext;
    end else begin
      half_lsb = $signed( ({{IN_W{1'b0}},1'b1}) <<< (shift-1) ); // 1<<(shift-1) pe IN_W+1
      if (in_ext >= 0) rounded = in_ext + half_lsb;
      else             rounded = in_ext - half_lsb;
    end

    shifted = (shift == 0) ? rounded : (rounded >>> shift);

    // INT8 clip
    if (shifted > 127)        q8 = 8'sd127;
    else if (shifted < -128)  q8 = -8'sd128;
    else                      q8 = shifted[7:0];

    // INT4 clip (-8..7)
    if (shifted > 7)          q4 = 4'sd7;
    else if (shifted < -8)    q4 = -4'sd8;
    else                      q4 = shifted[3:0];
  end
endmodule
