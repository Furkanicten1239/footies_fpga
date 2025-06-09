module game_design (
    input wire clk_game,          //game clock, 60Hz or manual
    input wire reset,
    input wire [9:0] pixel_x,     //current y pixel
    input wire [9:0] pixel_y,     //current x pixel
    input wire left_button,       //KEY3
    input wire right_button,      //KEY2
    output reg [7:0] color_out,  //RRRGGGBB
    input wire attack_button
);

localparam
    IDLE       = 4'b0000,
    LEFT       = 4'b0001,
    RIGHT      = 4'b0010,
	 ATTACK_1_STARTUP  = 4'b0011,//ATTACK WHEN CHARACTER IS STANDING
    ATTACK_1_ACTIVE   = 4'b0100,
    ATTACK_1_RECOVERY = 4'b0101,
    ATTACK_2_STARTUP  = 4'b0110,//ATTACK WHEN CHARACTER IS MOVING FORWARD
    ATTACK_2_ACTIVE   = 4'b0111,
    ATTACK_2_RECOVERY = 4'b1000, 
    DAMAGE     = 4'b1001,
    BLOCK      = 4'b1010;  //WHEN CHARACTER IS BEING HIT BUT MOVING FORWARD AT THAT TIME
	 
	 
	 
reg [3:0] next_state, current_state;
reg [4:0] frame_counter;  //  count frames for state changes.

// Character parameters
localparam CHAR_WIDTH = 128;
localparam CHAR_HEIGHT = 128;
localparam SCREEN_WIDTH = 640;
localparam GROUND_Y = 440; //upper limit for ground. Actually there is 480 pixel but we put character into the grass.

localparam HURTBOX_X1 = 44;
localparam HURTBOX_X2 = 84;
localparam HURTBOX_Y1 = 14;
localparam HURTBOX_Y2 = 114;

localparam HITBOX_X1 = 5;
localparam HITBOX_X2 = 43;
localparam HITBOX_Y1 = 40;
localparam HITBOX_Y2 = 88;



reg [9:0] char_x = 300;  //x's initial position
reg [9:0] char_y = GROUND_Y - CHAR_HEIGHT; //It is the top left corner of my character

// STICKMAN CONFIGURES
wire [127:0] attack_row;
wire [127:0] idle_row;
wire [127:0] left_row;
wire [127:0] right_row;
reg  [127:0] sprite_row;

//These 2 lines are used to decide whether each pixel is visible or not.
wire [6:0] sprite_x =  char_x - pixel_x;
wire [6:0] sprite_y = pixel_y - char_y;

// Instantiating the statements
stickman stickman(
    .y(sprite_y), .row(idle_row)
);

copadam_dovus pehlivan(
    .y(sprite_y), .row(attack_row)
);

left_state left(
    .y(sprite_y), .row(left_row)
);

right_state right(
    .y(sprite_y), .row(right_row)
);

// WRITING OTHER STATES (combinational FSM logic)
always @(*) begin
    case (current_state)
        IDLE: begin
            if (attack_button)
                next_state = ATTACK_1_STARTUP;
            else if (left_button)
                next_state = LEFT;
            else if (right_button)
                next_state = RIGHT;
					 
        end
        LEFT: begin
            if (!left_button)
				if(right_button)
				next_state = RIGHT;
				else
                next_state = IDLE; // If we don't press the button, move back to idle state.
				else if (attack_button)
                next_state = ATTACK_2_STARTUP;
            else
                next_state = LEFT;
        end
        RIGHT: begin
            if (!right_button)
				if (left_button)
				next_state = LEFT;
				else
                next_state = IDLE;
            else if (attack_button)
                next_state = ATTACK_2_STARTUP;
            else
                next_state = RIGHT;
        end
        ATTACK_1_STARTUP: begin
            if (frame_counter == 5)
                next_state = ATTACK_1_ACTIVE;
            else
                next_state = ATTACK_1_STARTUP;
        end
        ATTACK_1_ACTIVE: begin
            if (frame_counter == 7)
                next_state = ATTACK_1_RECOVERY;
            else
                next_state = ATTACK_1_ACTIVE;
        end
        ATTACK_1_RECOVERY: begin
            if (frame_counter == 23)
                next_state = IDLE;
            else
                next_state = ATTACK_1_RECOVERY;
        end
        ATTACK_2_STARTUP: begin
            if (frame_counter == 4)
                next_state = ATTACK_2_ACTIVE;
            else
                next_state = ATTACK_2_STARTUP;
        end
        ATTACK_2_ACTIVE: begin
            if (frame_counter == 7)
                next_state = ATTACK_2_RECOVERY;
            else
                next_state = ATTACK_2_ACTIVE;
        end
        ATTACK_2_RECOVERY: begin
            if (frame_counter == 22)
                next_state = IDLE;
            else
                next_state = ATTACK_2_RECOVERY;
        end
        default: next_state = IDLE;
    endcase

end

// WRITING THE STATES (sequential logic)
always @(posedge clk_game or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        char_x <= 300;
		  frame_counter <= 0;
    end else begin
        case (next_state)
            LEFT: begin
                if (char_x > 1)
                    char_x <= char_x - 2;
            end
            RIGHT: begin
                if (char_x + CHAR_WIDTH < SCREEN_WIDTH)
                    char_x <= char_x + 3;
            end
        endcase
		  current_state <= next_state;
		  
        case (current_state)
            ATTACK_1_STARTUP,
            ATTACK_1_ACTIVE,
            ATTACK_1_RECOVERY,
            ATTACK_2_STARTUP,
            ATTACK_2_ACTIVE,
            ATTACK_2_RECOVERY: frame_counter <= frame_counter + 1;
            default: frame_counter <= 0;
        endcase
		  
    end
end

// SPRITE SELECTION LOGIC
always @(*) begin
    case (current_state)
        IDLE:      					sprite_row = idle_row;
        LEFT:      					sprite_row = left_row;
        RIGHT:     					sprite_row = right_row;
        ATTACK_1_ACTIVE:  			sprite_row = attack_row;
		  ATTACK_1_STARTUP:        sprite_row = attack_row;
		  ATTACK_1_RECOVERY:       sprite_row = attack_row;
        ATTACK_2_ACTIVE:  			sprite_row = attack_row;
		  ATTACK_2_STARTUP:        sprite_row = attack_row;
		  ATTACK_2_RECOVERY:       sprite_row = attack_row;
        default:   					sprite_row = attack_row;
    endcase
end

// DISPLAY
always @(*) begin
    if (pixel_x >= char_x && pixel_x < char_x + CHAR_WIDTH &&
        pixel_y >= char_y && pixel_y < char_y + CHAR_HEIGHT) begin
		
	

        // Default: background color
        color_out = 8'b000_000_00;

        // Prioritize overlay elements (hurtbox and hitbox)
        if (
            ((sprite_x == HURTBOX_X1 || sprite_x == HURTBOX_X2 - 1) && (sprite_y >= HURTBOX_Y1 && sprite_y < HURTBOX_Y2) ||
             (sprite_y == HURTBOX_Y1 || sprite_y == HURTBOX_Y2 - 1) && (sprite_x >= HURTBOX_X1 && sprite_x < HURTBOX_X2))) begin
            color_out = 8'b111_111_00; // Yellow hurtbox outline

        end else if (current_state == ATTACK_1_ACTIVE &&
                     ((sprite_x == HITBOX_X1 || sprite_x == HITBOX_X2 - 1) && (sprite_y >= HITBOX_Y1 && sprite_y < HITBOX_Y2) ||
                      (sprite_y == HITBOX_Y1 || sprite_y == HITBOX_Y2 - 1) && (sprite_x >= HITBOX_X1 && sprite_x < HITBOX_X2))) begin
            color_out = 8'b111_000_00; // Red hitbox outline
				
        end else if (current_state == ATTACK_2_ACTIVE &&
                     ((sprite_x == HITBOX_X1 || sprite_x == HITBOX_X2 - 1) && (sprite_y >= HITBOX_Y1 && sprite_y < HITBOX_Y2) ||
                      (sprite_y == HITBOX_Y1 || sprite_y == HITBOX_Y2 - 1) && (sprite_x >= HITBOX_X1 && sprite_x < HITBOX_X2))) begin
            color_out = 8'b111_000_00; // Red hitbox outline
				
				end else if ((current_state == ATTACK_1_STARTUP || current_state == ATTACK_1_RECOVERY) &&
                     ((sprite_x == HITBOX_X1 || sprite_x == HITBOX_X2 - 1) && (sprite_y >= HITBOX_Y1 && sprite_y < HITBOX_Y2) ||
                      (sprite_y == HITBOX_Y1 || sprite_y == HITBOX_Y2 - 1) && (sprite_x >= HITBOX_X1 && sprite_x < HITBOX_X2))) begin
            color_out = 8'b000_111_00; // GREEN hitbox outline
				
				
				end else if ((current_state == ATTACK_2_STARTUP || current_state == ATTACK_2_RECOVERY) &&
                     ((sprite_x == HITBOX_X1 || sprite_x == HITBOX_X2 - 1) && (sprite_y >= HITBOX_Y1 && sprite_y < HITBOX_Y2) ||
                      (sprite_y == HITBOX_Y1 || sprite_y == HITBOX_Y2 - 1) && (sprite_x >= HITBOX_X1 && sprite_x < HITBOX_X2))) begin
            color_out = 8'b111_111_11; // WHITE hitbox outline
				
				

		  
        end else if (sprite_row[sprite_x]) begin//  Changing the character's color.
            color_out = 8'b000_000_00;  // it is black
				
        end else begin
            ////////////////////////BACKGROUND PART//////////////////////
            if (pixel_y >= GROUND_Y) begin
                color_out = (pixel_x[5]) ? 8'b000_111_00 : 8'b000_011_00;  // Stripe pattern (green/light green)
            end else begin
                case (pixel_y[7:6]) // RRRGGGBB for colors
                    2'b00: color_out = 8'b000_000_11; // Dark blue
                    2'b01: color_out = 8'b000_000_10; // Medium blue
                    2'b10: color_out = 8'b000_001_01; // Cyan-ish
                    2'b11: color_out = 8'b000_001_11; // Lighter sky
                endcase
            end
        end
    end else begin
        // Outside the sprite region — always show background
        if (pixel_y >= GROUND_Y) begin
            color_out = (pixel_x[5]) ? 8'b000_111_00 : 8'b000_011_00;
        end else begin
            case (pixel_y[7:6])
                2'b00: color_out = 8'b000_000_11;
                2'b01: color_out = 8'b000_000_10;
                2'b10: color_out = 8'b000_001_01;
                2'b11: color_out = 8'b000_001_11;
            endcase
        end
    end
end

endmodule
