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

    // Fixed 40x40 square centered at (320, 240)
    localparam logic [9:0] square_x = 300;
    localparam logic [9:0] square_y = 220;

    // Pixel scan counters
    logic [9:0] pix_x = 0;
    logic [9:0] pix_y = 0;

    // Raster scan logic
    always_ff @(posedge clk_pix) begin
        if (pix_x < 639) begin
            pix_x <= pix_x + 1;
        end else begin
            pix_x <= 0;
            if (pix_y < 479)
                pix_y <= pix_y + 1;
            else
                pix_y <= 0;
        end
    end

    // Output pixel position
    assign sdl_sx = pix_x;
    assign sdl_sy = pix_y;

    // Draw when inside 40x40 square
    assign sdl_de = (pix_x >= square_x && pix_x < square_x + 40 &&
                     pix_y >= square_y && pix_y < square_y + 40);

    // Output red color if inside square
    assign sdl_r = sdl_de ? 8'hFF : 8'h00;
    assign sdl_g = 8'h00;
    assign sdl_b = 8'h00;

endmodule
