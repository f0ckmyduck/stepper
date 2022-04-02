// Multiplexes the current input signal onto one of the selected outputs.
module mux #(
    parameter SIZE = 4,
    parameter INITIAL = 0
) (
    input [$clog2(SIZE) - 1:0] select_in,
    input sig_in,
    input clk_in,
    output reg [SIZE - 1:0] r_sig_out
);

  initial r_sig_out = INITIAL;

  always @(posedge clk_in) begin
    r_sig_out <= (sig_in << select_in) | (INITIAL & ~(1'h1 << select_in));
  end

endmodule
