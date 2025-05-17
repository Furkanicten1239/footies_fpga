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

    logic [9:0] x_pos = 100;
    logic [9:0] y_pos = 100;

    // Only support right movement for now
    always_ff @(posedge clk_pix or posedge sim_rst) begin
        if (sim_rst) begin
            x_pos <= 100;
            y_pos <= 100;
        end else begin
            if (btn_dn) begin
                if (x_pos < 639)
                    x_pos <= x_pos + 1;
            end
        end
    end

    assign sdl_sx = x_pos;
    assign sdl_sy = y_pos;
    assign sdl_de = 1'b1;

    assign sdl_r = 8'hFF;
    assign sdl_g = 8'h00;
    assign sdl_b = 8'h00;

endmodule
