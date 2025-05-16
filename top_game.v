module top_game (
    input  logic        clk_pix,     // pixel clock from SDL sim
    input  logic        sim_rst,     // reset signal
    input  logic        btn_up,      // key input
    input  logic        btn_dn,
    input  logic        btn_fire,
    output logic [9:0]  sdl_sx,      // pixel X for SDL
    output logic [9:0]  sdl_sy,      // pixel Y for SDL
    output logic        sdl_de,      // draw enable for SDL
    output logic [7:0]  sdl_r,       // red
    output logic [7:0]  sdl_g,       // green
    output logic [7:0]  sdl_b        // blue
);

    // Internal wires
    logic [9:0] next_x, next_y;
    logic [7:0] color;

    // Simulated switches & keys
    logic [9:0] SW;
    logic [3:0] KEY;

    // VGA outputs from original design
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic VGA_BLANK_N;

    assign KEY[3] = ~sim_rst;    // Reset from sim
    assign KEY[2] = ~btn_up;
    assign KEY[1] = ~btn_dn;
    assign KEY[0] = ~btn_fire;
    assign SW[1] = 1'b0;         // auto clock
    assign SW[0] = 1'b1;         // not reset

    // Instantiate your full game
    fighting_game_vga game (
        .CLOCK_50(clk_pix),
        .CLOCK2_50(1'b0),
        .CLOCK3_50(1'b0),
        .CLOCK4_50(1'b0),
        .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(),
        .KEY(KEY),
        .LEDR(),
        .SW(SW),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_B(VGA_B),
        .VGA_CLK(),  // unused
        .VGA_G(VGA_G),
        .VGA_HS(),   // unused
        .VGA_R(VGA_R),
        .VGA_SYNC_N(), // unused
        .VGA_VS()     // unused
    );

    // VGA driver values from your design (pass from vga_driver!)
    assign sdl_sx = next_x;
    assign sdl_sy = next_y;
    assign sdl_de = VGA_BLANK_N; // or just '1' if you want full frame
    assign sdl_r  = VGA_R;
    assign sdl_g  = VGA_G;
    assign sdl_b  = VGA_B;

    // Connect VGA driver's internal position to wrapper
    // IMPORTANT: you need to expose `next_x` and `next_y` as outputs from `vga_driver` module
    // OR: you can duplicate the sync logic in this wrapper.

endmodule
