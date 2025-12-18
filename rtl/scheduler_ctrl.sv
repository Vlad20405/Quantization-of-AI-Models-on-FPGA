module scheduler_ctrl(
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  output logic load_prec,
  output logic run_dense,
  input  logic dense_done,
  output logic done
);
  typedef enum logic [2:0] {S_IDLE, S_LOAD, S_START, S_WAIT, S_DONE} st_t;
  st_t st;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      st <= S_IDLE;
      load_prec <= 1'b0;
      run_dense <= 1'b0;
      done      <= 1'b0;
    end else begin
      // default: pulse-urile sunt 0
      load_prec <= 1'b0;
      run_dense <= 1'b0;
      done      <= 1'b0;

      case (st)
        S_IDLE: begin
          if (start) st <= S_LOAD;
        end

        S_LOAD: begin
          load_prec <= 1'b1;   // 1 ciclu
          st <= S_START;
        end

        S_START: begin
          run_dense <= 1'b1;   // 1 ciclu start pentru dense_engine
          st <= S_WAIT;
        end

        S_WAIT: begin
          if (dense_done) st <= S_DONE;
        end

        S_DONE: begin
          done <= 1'b1;        // 1 ciclu “done” catre top
          st <= S_IDLE;
        end

        default: st <= S_IDLE;
      endcase
    end
  end
endmodule
