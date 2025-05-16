module fighting_game_vga(

    //////////// CLOCK //////////
    input               CLOCK_50,
    input               CLOCK2_50,
    input               CLOCK3_50,
    input               CLOCK4_50,

    //////////// SEG7 //////////
    output     [6:0]    HEX0,
    output     [6:0]    HEX1,
    output     [6:0]    HEX2,
    output     [6:0]    HEX3,
    output     [6:0]    HEX4,
    output     [6:0]    HEX5,

    //////////// KEY //////////
    input      [3:0]    KEY,

    //////////// LED //////////
    output     [9:0]    LEDR,

    //////////// SW //////////
    input      [9:0]    SW,

    //////////// VGA //////////
    output              VGA_BLANK_N,
    output     [7:0]    VGA_B,
    output              VGA_CLK,
    output     [7:0]    VGA_G,
    output              VGA_HS,
    output     [7:0]    VGA_R,
    output              VGA_SYNC_N,
    output              VGA_VS
);

    //================ CLOCK DIVIDERS ================

    reg clk_div = 0;
    always @(posedge CLOCK_50)
        clk_div <= ~clk_div;
    wire clk_25MHz = clk_div;

    reg [19:0] clk_count = 0;
    reg game_clk_reg = 0;
    always @(posedge CLOCK_50) begin
        if (clk_count == 833_333) begin
            clk_count <= 0;
            game_clk_reg <= ~game_clk_reg;
        end else begin
            clk_count <= clk_count + 1;
        end
    end
    wire game_clk = game_clk_reg;

    //================ MANUAL STEP CLOCK =============

    reg [1:0] key_reg;
    wire step_pulse;
    always @(posedge CLOCK_50) begin
        key_reg[0] <= ~KEY[3];
        key_reg[1] <= key_reg[0];
    end
    assign step_pulse = (key_reg[0] & ~key_reg[1]);

    //================ CLOCK SELECTION ===============
    wire selected_clk;
    assign selected_clk = (SW[1] == 1'b0) ? game_clk : step_pulse;

    wire reset = ~SW[0];

    //================ FSM ÇIKIŞLARI ==================
    wire [9:0] char1_x;
    wire [2:0] char1_state;

    //================ VGA sinyalleri =================
    wire [9:0] next_x, next_y;
    wire [7:0] color;

    //================ FSM ============================
    fsm fsm_inst (
        .clk(selected_clk),
        .reset(reset),
        .move_left(~KEY[2]),
        .move_right(~KEY[1]),
        .attack(~KEY[0]),
        .got_hit(hit2_lands),
        .char_x(char1_x),
        .state(char1_state)
    );

    //================ RENDER =========================
    vga_render render_inst (
        .next_x(next_x),
        .next_y(next_y),
        .char_x(char1_x),
        .char_y(10'd200),
        .state(char1_state),
        .color_out(color)
    );

    //================ VGA DRIVER =====================
    vga_driver vga_inst (
        .clock(clk_25MHz),
        .reset(reset),
        .color_in(color),
        .next_x(next_x),
        .next_y(next_y),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .red(VGA_R),
        .green(VGA_G),
        .blue(VGA_B),
        .sync(VGA_SYNC_N),
        .clk(VGA_CLK),
        .blank(VGA_BLANK_N)
    );

    //================ HITLOGIC ========================
    wire hit1_lands, hit2_lands;
    hitlogic hit_sys (
        .char1_x(char1_x),
        .char1_y(10'd200),
        .char1_state(char1_state),
        .char2_x(10'd300),            // sabit karakter 2 (örnek)
        .char2_y(10'd200),
        .char2_state(3'b000),         // IDLE
        .hit1_lands(hit1_lands),
        .hit2_lands(hit2_lands)
    );

    //================ HEALTH LOGIC ====================
    wire [1:0] health1, health2;
    wire game_over1, game_over2;

    health_logic health_sys (
        .clk(selected_clk),
        .reset(reset),
        .hit1_lands(hit1_lands),
        .hit2_lands(hit2_lands),
        .health1(health1),
        .health2(health2),
        .game_over1(game_over1),
        .game_over2(game_over2)
    );

    //================ 7-SEGMENT DISPLAY ===============
    hex_decoder state_disp   (.in({1'b0, char1_state}), .out(HEX0));
    hex_decoder health1_disp (.in({2'b00, health1}), .out(HEX1));
    hex_decoder health2_disp (.in({2'b00, health2}), .out(HEX2));

    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;

    assign LEDR = {8'b0, game_over2, game_over1};

endmodule
