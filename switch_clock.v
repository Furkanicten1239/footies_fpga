module switch_clock (
    input wire clk_25MHz,
    input wire manual_step,   // KEY[2]
    input wire mode_select,   // SW[1]
    output reg clk_game
);
    reg [19:0] counter = 0;
    reg tick_60Hz = 0;

    always @(posedge clk_25MHz) begin
        // Generate 60Hz from 25MHz
        if (counter >= 416666) begin  // 25MHz / 60Hz = ~416666
            counter <= 0;
            tick_60Hz <= 1;
        end else begin
            counter <= counter + 1;
            tick_60Hz <= 0;
        end

        // Clock mux
        if (mode_select)
            clk_game <= manual_step;   // Manual mode
        else
            clk_game <= tick_60Hz;     // Auto 60Hz mode
    end
endmodule
