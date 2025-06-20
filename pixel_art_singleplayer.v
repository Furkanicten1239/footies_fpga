//hurtbox hitbox çarpışma mantığı eksik, health bar block bar eksik, block logic eksik.

module pixel_art_singleplayer (
    input wire clk_game,
    input wire reset,
    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    output reg [7:0] color_out,
	 input wire left1,
    input wire right1,
    input wire attack1
);

    // Parameters for players
    localparam CHAR_WIDTH = 128;
    localparam CHAR_HEIGHT = 128;
    localparam GROUND_Y = 440;
	 
	 //Coordinates of hurtbox and hitbox
	 localparam HURTBOX_X1 = 44;
	 localparam HURTBOX_X2 = 84;
	 localparam HURTBOX_Y1 = 14;
	 localparam HURTBOX_Y2 = 114;
	 
	 localparam HITBOX_X1 = 5;
	 localparam HITBOX_X2 = 43;
	 localparam HITBOX_Y1 = 40;
	 localparam HITBOX_Y2 = 88;
	 
	 

    // Player positions
    wire [9:0] player1_x;
    reg [9:0] player1_y = GROUND_Y - CHAR_HEIGHT;
    wire [9:0] player2_x;
    reg [9:0] player2_y = GROUND_Y - CHAR_HEIGHT;
	 

    // Sprite ROMs (declared elsewhere)
    wire [127:0] p1_idle_row, p1_attack_row, p1_left_row, p1_right_row;
    wire [127:0] p2_idle_row, p2_attack_row;
    wire [6:0] sprite_x1 = player1_x - pixel_x;
    wire [6:0] sprite_y1 = pixel_y - player1_y;
    wire [6:0] sprite_x2 = pixel_x - player2_x;
    wire [6:0] sprite_y2 = pixel_y - player2_y;

    reg [127:0] sprite_row_p1;
    reg [127:0] sprite_row_p2;
	 
	     // Outputs from FSM
    wire [3:0] state_p1, state_p2;
    wire [9:0] char1_x, char2_x;

// FSM MODULE INSTANTIATON
fsm_logic_singleplayer logic_inst (
    .clk_game(clk_game),
    .reset(reset),
    .left_button1(left1),
    .right_button1(right1),
    .attack_button1(attack1),
    .state_p1(state_p1),
    .state_p2(state_p2),
    .char1_x(player1_x),
    .char2_x(player2_x)
);


    // CHARACTER DRAWINGS
    stickman stickman_idle(.y(sprite_y1), .row(p1_idle_row));
    copadam_dovus stickman_attack(.y(sprite_y1), .row(p1_attack_row));
    left_state stickman_left(.y(sprite_y1), .row(p1_left_row));
    right_state stickman_right(.y(sprite_y1), .row(p1_right_row));

    stickman panda_idle(.y(sprite_y2), .row(p2_idle_row));
    copadam_dovus panda_attack(.y(sprite_y2), .row(p2_attack_row));

    // Player 1 sprite selection
    always @(*) begin
        case (state_p1)
            4'b0000: sprite_row_p1 = p1_idle_row;     // IDLE
            4'b0001: sprite_row_p1 = p1_left_row;     // LEFT
            4'b0010: sprite_row_p1 = p1_right_row;    // RIGHT
            4'b0011,
            4'b0100,
            4'b0101: sprite_row_p1 = p1_attack_row;   // ATTACK_1 states
            4'b0110,
            4'b0111,
            4'b1000: sprite_row_p1 = p1_attack_row;   // ATTACK_2 states
            default: sprite_row_p1 = p1_idle_row;
        endcase
    end
	 
	 		  
		  		  //Definition of hurtbox borders
		   wire is_hurtbox_p1 = (state_p1 == 4'b0100 || state_p1 == 4'b0111);  // ATTACK_1_ACTIVE or ATTACK_2_ACTIVE

			wire is_on_hurtbox_border_p1 =
				((sprite_x1 == HURTBOX_X1 || sprite_x1 == HURTBOX_X2 - 1) && (sprite_y1 >= HURTBOX_Y1 && sprite_y1 < HURTBOX_Y2)) ||
				((sprite_y1 == HURTBOX_Y1 || sprite_y1 == HURTBOX_Y2 - 1) && (sprite_x1 >= HURTBOX_X1 && sprite_x1 < HURTBOX_X2));
			
			wire is_on_hitbox_border_p1 =
				((sprite_x1 == HITBOX_X1 || sprite_x1 == HITBOX_X2 - 1) && (sprite_y1 >= HITBOX_Y1 && sprite_y1 < HITBOX_Y2)) ||
				((sprite_y1 == HITBOX_Y1 || sprite_y1 == HITBOX_Y2 - 1) && (sprite_x1 >= HITBOX_X1 && sprite_x1 < HITBOX_X2));
				
			

    // Player 2 sprite selection (simplified)
    always @(*) begin
        case (state_p2)
            4'b0000: sprite_row_p2 = p2_idle_row;     // IDLE
            4'b0001: sprite_row_p2 = p1_left_row;     // LEFT
            4'b0010: sprite_row_p2 = p1_right_row;    // RIGHT
            4'b0011,
            4'b0100,
            4'b0101: sprite_row_p2 = p2_attack_row;   // ATTACK_1 states
            4'b0110,
            4'b0111,
            4'b1000: sprite_row_p2 = p2_attack_row;   // ATTACK_2 states
            default: sprite_row_p2 = p2_idle_row;
        endcase
    end

	 
	 
	 
    // Display logic
// Replace your display logic with this version that handles overlapping characters
    // Check if pixel is within Player 1's area
    wire p1_in_area = (pixel_x >= player1_x && pixel_x < player1_x + CHAR_WIDTH &&
                       pixel_y >= player1_y && pixel_y < player1_y + CHAR_HEIGHT);
    
    // Check if pixel is within Player 2's area  
    wire p2_in_area = (pixel_x >= player2_x && pixel_x < player2_x + CHAR_WIDTH &&
                       pixel_y >= player2_y && pixel_y < player2_y + CHAR_HEIGHT);
    
    // Check if pixels are active for each character
    wire p1_pixel_active = p1_in_area && sprite_row_p1[sprite_x1];
    wire p2_pixel_active = p2_in_area && sprite_row_p2[sprite_x2];
    
    // Check for hitbox/hurtbox borders for Player 1
    wire p1_hurtbox_border = p1_in_area && is_on_hurtbox_border_p1;
    wire p1_hitbox_border = p1_in_area && is_hurtbox_p1 && is_on_hitbox_border_p1;
    
always @(*) begin

    // Determine final color based on priority
    if (p1_hurtbox_border) begin
        color_out = 8'b111_111_00;  // Yellow hurtbox (highest priority)
    end else if (p1_hitbox_border) begin
        color_out = 8'b111_000_00;  // Red hitbox
    end else if (p1_pixel_active) begin
        color_out = 8'b000_000_00;  // Player 1 color (black)
    end else if (p2_pixel_active) begin
        color_out = 8'b111_000_00;  // Player 2 color (red)
    end else if (pixel_y >= GROUND_Y) begin
        color_out = (pixel_x[5]) ? 8'b000_111_00 : 8'b000_011_00;  // Ground
    end else begin
        color_out = 8'b111_111_11;  // Background (white)
    end
end

endmodule
