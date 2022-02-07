module angle_to_step #(
    parameter SIZE = 64,
    // MICROSTEPS / (STEPANGLE / GEARING)
    // (in Q(SIZE >> 1).(SIZE>>1))
    parameter [SIZE - 1 : 0] SCALE = {32'd4000, {(SIZE >> 1) {1'b0}}},

    parameter SYSCLK = 25000000,
    parameter [SIZE - 1 : 0] VRISE = 20000,
    parameter [SIZE - 1 : 0] TRISE = 10000,
    parameter [SIZE - 1 : 0] OUTPUT_DIV_MIN = 50
) (
    input clk_i,

    input enable_i,
    output reg done_o = 1'b1,

    input [SIZE - 1:0] relative_angle_i,
    output step_o
);
  parameter SF = SIZE >> 1;
  parameter INC = {1'b1, {SF{1'b0}}};

  wire int_clk;
  wire output_clk;

  // Used as the actual frequency divider (inverse)

  reg [SIZE - 1:0] r_t = INC;
  wire [SIZE - 1:0] speedup;
  wire [SIZE - 1:0] div;
  wire [SIZE - 1:0] negated_div;
  wire [SIZE - 1:0] invers_div;
  wire [SIZE - 1:0] switched_invers_div;

  reg r_output_clk_prev = 1'b0;
  reg r_enable_prev = 1'b0;
  reg r_run = 1'b0;

  reg [SIZE - 1:0] steps_done = 0;
  wire [SIZE - 1:0] steps_needed;

  assign step_o = (r_t > INC) ? output_clk : 1'b0;

  always @(posedge clk_i) begin
    // Reset on negative edge
    if (!enable_i && r_enable_prev) begin
      r_run  <= 1'b0;
      done_o <= 1'b0;
      $display("%m>\tDisabled");
    end

    if ((steps_done >> SF) >= (steps_needed >> SF)) begin
      r_run  <= 1'b0;
      done_o <= 1'b1;
    end

    // Enable output
    if (enable_i && !r_enable_prev) begin
      r_run  <= 1'b1;
      done_o <= 1'b0;
      $display("%m>\tEnabled");
    end

    r_enable_prev <= enable_i;
  end

  // Counter to keep track of how far the algorithm has already stepped.
  // It is used to find out when the algorithm needs to be reversed for the falloff.
  always @(posedge clk_i) begin
    // Count the steps done up until it reaches steps_done
    if (r_run) begin
      if (output_clk && !r_output_clk_prev) begin
        steps_done <= steps_done + INC;
      end
    end else begin
      steps_done <= 0;
    end

    r_output_clk_prev <= output_clk;
  end

  // Increment time if the output is enabled
  always @(posedge int_clk) begin
    if (r_run) begin
      if ((steps_needed >> 1) <= steps_done) begin
        r_t <= r_t - INC;
      end else begin
        r_t <= r_t + INC;
      end
    end else begin
      r_t <= INC;
    end
  end

  /* speedup = VRISE / TRISE */
  fx_div #(
      .Q(SF),
      .N(SIZE)
  ) calc_speedup (
      .dividend_i(VRISE << SF),
      .divisor_i (TRISE << SF),
      .quotient_o(speedup),

      .start_i(1'b1),
      .clk_i  (clk_i),

      .complete_o(),
      .overflow_o()
  );

  /* div = r_t * speedup */
  fx_mult #(
      .Q(SF),
      .N(SIZE)
  ) calc_clk_divider (
      .multiplicand_i(speedup),
      .multiplier_i(r_t),
      .r_result_o(div),
      .overflow_r_o()
  );

  /* negated_div = -div */
  assign negated_div[SIZE-2:0] = div[SIZE-2:0];
  assign negated_div[SIZE-1]   = ~div[SIZE-1];

  /* invers_div = VRISE + negated_div  */
  fx_add #(
      .Q(SF),
      .N(SIZE)
  ) calc_invert_div (
      .summand_a_i((VRISE + OUTPUT_DIV_MIN) << SF),
      .summand_b_i(negated_div),
      .sum_i(invers_div)
  );

  assign switched_invers_div = (r_t > 0 && r_t < (TRISE << SF)) ? invers_div : OUTPUT_DIV_MIN << SF;

  /* steps_needed = relative_angle_i * SCALE; */
  fx_mult #(
      .Q(SF),
      .N(SIZE)
  ) steps_needed_mult (
      .multiplicand_i(relative_angle_i),
      .multiplier_i(SCALE),
      .r_result_o(steps_needed),
      .overflow_r_o()
  );

  // Internal clk (used for timekeeping)
  clk_divider #(
      .SIZE(32)
  ) internal_clk_gen (
      .clk_in (clk_i),
      // Every 1 us
      .max_in ((SYSCLK / 1000000) >> 1),
      .clk_out(int_clk)
  );

  // Step pulse generator clk divider
  clk_divider #(
      .SIZE(SIZE)
  ) step_pulse_gen (
      .clk_in (clk_i),
      .max_in ((switched_invers_div >> SF) >> 1),
      .clk_out(output_clk)
  );
endmodule
