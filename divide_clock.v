module divide_clock (
    input wire clk_50mhz,
    output reg clk_25mhz = 0
);

    always @(posedge clk_50mhz) begin
        clk_25mhz <= ~clk_25mhz;  // Toggle every 20 ns → 40 ns period = 25 MHz
    end

endmodule
