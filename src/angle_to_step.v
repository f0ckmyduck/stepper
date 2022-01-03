// All floating point parameters are Q64.64
// notation (GEARUP, STEPANGLE)
module angle_to_step #(
    parameter MICROSTEPS = 256,
    parameter STEPANGLE = 1.80,
    parameter GEARUP = 26.85,

    parameter SYSCLK = 25000000,
    parameter SIZE = 32,
    parameter [SIZE - 1:0] VRISE = 20000,
    parameter [SIZE - 1:0] TRISE = 10000,
    parameter [SIZE - 1:0] VOFFSET = 6000
) (
    input clk_i,

    input enable_i,
    input [SIZE - 1:0] relative_angle_i,
    output step_o
);
  // Shifted algorithm parameters
  parameter SF = SIZE >> 1;
  parameter SF_VRISE = (VRISE << SF);
  parameter SF_TRISE = (TRISE << SF);
  parameter SF_VOFFSET = (VOFFSET << SF);

  parameter JERCK = ((4 * SF_VRISE) / (SF_TRISE ** 2));
  parameter TIME_INC = {1'b1, {(SIZE >> 1) {1'b0}}};

  wire int_clk;
  wire output_clk;

  assign step_o = enable_i ? output_clk : 1'b0;

  // Used as the actual frequency divider (inverse)
  reg [SIZE - 1:0] r_div = {SIZE{1'b0}};

  reg [SIZE - 1:0] r_stage1 = {SIZE{1'b0}};
  reg [SIZE - 1:0] r_stage2 = {SIZE{1'b0}};

  reg [SIZE - 1:0] r_t = TIME_INC;

  reg count_back = 1'b0;

  reg [SIZE - 1:0] steps_done = 0;
  reg [SIZE - 1:0] steps_needed = 0;

  // Indicates the current state of the machine (debugging)
  reg [1:0] state = 1'b0;

  // Internal clk (used for timekeeping)
  clk_divider #(
      .SIZE(32)
  ) internal (
      .clk_in (clk_i),
      // Every 1 us
      .max_in ((SYSCLK / 1000000) / 2),
      .clk_out(int_clk)
  );

  // Step pulse generator clk divider
  clk_divider #(
      .SIZE(SIZE)
  ) div (
      .clk_in (clk_i),
      .max_in (((SF_VRISE - r_div + SF_VOFFSET) >> SF) / 2),
      .clk_out(output_clk)
  );

  // Update the clkdivider output every int_clk
  always @(posedge clk_i) begin
    if (r_t > 0 && r_t < (SF_TRISE >> 1)) begin
      //First rise
      // If(x < t_{rise} / 2 ∧ x > 0, 1 / 2 J x²)
      r_div <= r_stage1;
      state <= 1;

    end else if (r_t >= (SF_TRISE >> 1) && r_t < SF_TRISE) begin
      // Second rise
      // If(t_{rise} / 2 ≤ x ∧ x < t_{rise}, 1 / 4 J (4x t_{rise} - 2x² - t_{rise}²))
      r_div <= r_stage2;
      state <= 2;

    end else begin
      // Error
      r_div = SF_VRISE;
      state <= 3;
    end
  end

  // Counter to keep track of how far the algorithm has already stepped.
  // It is used to find out when the algorithm needs to be reversed for the falloff.
  always @(posedge output_clk) begin
    if (steps_needed == steps_done) begin
      steps_done <= 0;
    end else begin
      steps_done <= steps_done + 1;
    end
  end

  always @(posedge int_clk) begin
    if (r_t >= SF_TRISE && (steps_needed / 2) <= steps_done) begin
      count_back <= 1'b1;
    end else if (r_t == 0) begin
      count_back <= 1'b0;
    end

    if (enable_i) begin
      if (count_back) begin
        r_t <= r_t - TIME_INC;
      end else begin
        r_t <= r_t + TIME_INC;
      end
    end else begin
      r_t <= TIME_INC;
    end

    steps_needed <= (relative_angle_i * GEARUP) / STEPANGLE * MICROSTEPS;
  end
endmodule
