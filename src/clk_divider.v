// Dividies the clk_in with max_in * 2
// s = 25Mhz / (max * 2)
module clk_divider #(
    parameter SIZE = 8
) (
    input clk_in,
    input [SIZE - 1:0] max_in,
    output clk_out
);

  reg int_clk;
  reg [SIZE - 1:0] r_count = 0;

  always @(posedge clk_in) begin
    int_clk <= (r_count >= max_in - 1);

    if (r_count >= max_in - 1) begin
      r_count <= 0;
    end else begin
      r_count <= r_count + 1;
    end
  end

  toggle_ff out_div (
      .clk_in(int_clk),
      .toggle_in(1'b1),
      .r_q_out(clk_out)
  );

endmodule
