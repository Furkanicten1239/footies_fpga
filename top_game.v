module top_game (
    input  logic        clk_pix,
    input  logic        sim_rst,
    input  logic        btn_up,
    input  logic        btn_dn,
    input  logic        btn_fire,
    output logic [9:0]  sdl_sx,
    output logic [9:0]  sdl_sy,
    output logic        sdl_de,
    output logic [7:0]  sdl_r,
    output logic [7:0]  sdl_g,
    output logic [7:0]  sdl_b
);

    reg [9:0] x = 0;
    reg [9:0] y = 0;

    always_ff @(posedge clk_pix) begin
        if (x < 639) x <= x + 1;
        else begin
            x <= 0;
            if (y < 479) y <= y + 1;
            else y <= 0;
        end
    end

    assign sdl_sx = x;
    assign sdl_sy = y;
    assign sdl_de = 1'b1;                // Always drawing
    assign sdl_r  = x[7:0];              // Color gradient
    assign sdl_g  = y[7:0];
    assign sdl_b  = 8'h00;

endmodule
