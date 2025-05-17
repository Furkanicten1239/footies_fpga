// Verilog module to display a 10x10 blue square in the center of a 640x480 screen
module top_game (
    input  logic        clk_pix,   // Pixel clock from SDL simulation
    input  logic        sim_rst,   // Reset signal
    input  logic        btn_up,    // Unused in this example
    input  logic        btn_dn,    // Unused in this example
    input  logic        btn_fire,  // Unused in this example
    output logic [9:0]  sdl_sx,    // Current X pixel coordinate
    output logic [9:0]  sdl_sy,    // Current Y pixel coordinate
    output logic        sdl_de,    // Draw enable: high when drawing active pixel
    output logic [7:0]  sdl_r,     // Red color output
    output logic [7:0]  sdl_g,     // Green color output
    output logic [7:0]  sdl_b      // Blue color output
);

    // =====================================================
    // Pixel scan position (raster scan from top-left corner)
    // =====================================================
    logic [9:0] pix_x = 0;
    logic [9:0] pix_y = 0;

    always_ff @(posedge clk_pix) begin
        if (pix_x < 639) begin
            pix_x <= pix_x + 1;
        end else begin
            pix_x <= 0;
            if (pix_y < 479)
                pix_y <= pix_y + 1;
            else
                pix_y <= 0; // restart scan at next frame
        end
    end

    assign sdl_sx = pix_x;
    assign sdl_sy = pix_y;

    // =====================================================
    // Drawing logic: activate for a 10x10 region in center
    // Center of screen = (320, 240)
    // Square bounds = (315, 235) to (324, 244)
    // =====================================================
    assign sdl_de = (pix_x >= 315 && pix_x < 325 &&
                     pix_y >= 235 && pix_y < 245);

    assign sdl_r = 8'h00;               // No red
    assign sdl_g = 8'h00;               // No green
    assign sdl_b = sdl_de ? 8'hFF : 8'h00; // Full blue inside square

endmodule
