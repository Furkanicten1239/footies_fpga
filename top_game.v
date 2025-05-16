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

    assign sdl_sx = 10'd100;
    assign sdl_sy = 10'd100;
    assign sdl_de = 1'b1;
    assign sdl_r  = 8'hFF;
    assign sdl_g  = 8'h00;
    assign sdl_b  = 8'h00;

endmodule
