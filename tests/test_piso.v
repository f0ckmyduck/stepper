`timescale 1ns / 100ps

`include "macros.v"
`include "../src/piso.v"

module test_piso ();

  reg r_clk;
  reg r_reset_n;
  parameter integer TP = 1;
  parameter integer CLK_HALF_PERIOD = 5;

  // separate initial process that generates the clk
  initial begin
    r_clk = 0;
    #5;
    forever r_clk = #(CLK_HALF_PERIOD) ~r_clk;
  end

  reg [31:0] i;
  reg [7:0] r_parallel_data = 8'b10101100;
  wire serial_output;

  piso #(
      .SIZE(8)
  ) piso1 (
      .data_in(r_parallel_data),
      .clk_in(r_clk),
      .reset_n_in(r_reset_n),
      .r_data_out(serial_output)
  );

  initial begin

    // dump waveform file
    $dumpfile("test_piso.vcd");
    $dumpvars(0, test_piso);

    $display("%0t:\tResetting system", $time);

    // create reset pulse
    r_reset_n = #TP 1'b1;
    repeat (30) @(posedge r_clk);

    r_reset_n = #TP 1'b0;
    repeat (30) @(posedge r_clk);

    r_reset_n = #TP 1'b1;
    repeat (30) @(posedge r_clk);

    $display("%0t:\tBeginning test of the piso module", $time);

    // test if the piso delivers the data in the right order
    // and doesn't miss a bit
    for (i = 0; i < 8; i++) begin
      repeat (1) @(posedge r_clk);
      `ASSERT(r_parallel_data[7-i], serial_output);
    end

    $display("%0t:\tNo errors", $time);
    $finish;
  end

endmodule
