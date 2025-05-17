module top_game (
    input  logic        clk_pix,   // Pixel clock, from SDL sim
    input  logic        sim_rst,   // Reset signal
    input  logic        btn_up,    // (unused for now)
    input  logic        btn_dn,    // Used for "move right"
    input  logic        btn_fire,  // (unused for now)
    output logic [9:0]  sdl_sx,    // Current X pixel coordinate (0-639)
    output logic [9:0]  sdl_sy,    // Current Y pixel coordinate (0-479)
    output logic        sdl_de,    // Draw enable signal (active pixel)
    output logic [7:0]  sdl_r,     // Red color component
    output logic [7:0]  sdl_g,     // Green color component
    output logic [7:0]  sdl_b      // Blue color component
);

    // =========================
    // Position of moving square
    // =========================
    logic [9:0] square_x = 0;         // Top-left X of the 40×40 square
    logic [9:0] square_y = 440;       // Fixed Y for bottom of screen

    // Move the square to the right on btn_dn press (mapped to Right Arrow in C++)
    always_ff @(posedge clk_pix or posedge sim_rst) begin
        if (sim_rst) begin
            square_x <= 0;            // Reset to leftmost position
        end else begin
            if (btn_dn && square_x < 639 - 40) begin
                square_x <= square_x + 1;
            end
        end
    end

    // =========================
    // Pixel position counters (frame scanner)
    // =========================
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
                pix_y <= 0;
        end
    end

    assign sdl_sx = pix_x;
    assign sdl_sy = pix_y;

    // =========================
    // Draw logic: display red if inside 40×40 square
    // =========================
    assign sdl_de = (pix_x >= square_x && pix_x < square_x + 40 &&
                     pix_y >= square_y && pix_y < square_y + 40);

    assign sdl_r = sdl_de ? 8'hFF : 8'h00;  // Full red inside square
    assign sdl_g = 8'h00;                   // No green
    assign sdl_b = 8'h00;                   // No blue

endmodule
