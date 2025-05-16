module health_logic (
    input clk,
    input reset,
    input hit1_lands,     // P1, P2'ye vurdu
    input hit2_lands,     // P2, P1'e vurdu

    output reg [1:0] health1, // P1'in canı (0–3)
    output reg [1:0] health2, // P2'nin canı
    output game_over1,        // P1 öldü mü?
    output game_over2         // P2 öldü mü?
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            health1 <= 2'd3;
            health2 <= 2'd3;
        end else begin
            if (hit2_lands && health1 > 0)
                health1 <= health1 - 1;

            if (hit1_lands && health2 > 0)
                health2 <= health2 - 1;
        end
    end

    assign game_over1 = (health1 == 0);
    assign game_over2 = (health2 == 0);

endmodule
