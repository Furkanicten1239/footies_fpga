// Module: game_logic
// Responsibility: Handles FSM transitions and character positions for both players

module fsm_logic_singleplayer (
    input wire clk_game,
    input wire reset,
    input wire left_button1,
    input wire right_button1,
    input wire attack_button1,
	 
    // CREATING THE REGISTERS FOR STATES AND CHARACTER POSITIONS
    output reg [3:0] state_p1,
    output reg [3:0] state_p2,
    output reg [9:0] char1_x,
    output reg [9:0] char2_x
);

    // We use those wires for instantiating the lfsr random bit generator module
    wire [3:0] lfsr_bits;
    wire attack_button2, left_button2, right_button2;

    // Constants
    localparam CHAR_WIDTH = 128;
    localparam SCREEN_WIDTH = 640;
    localparam MOVE_SPEED_P1_LEFT = 2;
    localparam MOVE_SPEED_P1_RIGHT = 3;
    localparam MOVE_SPEED_P2_LEFT = 3;
    localparam MOVE_SPEED_P2_RIGHT = 2;
    localparam COLLISION_BUFFER = 4; // Small buffer to prevent overlapping

    // Improved collision detection
    wire basic_collision = (char1_x < char2_x + CHAR_WIDTH) && (char2_x < char1_x + CHAR_WIDTH);
    
    // Calculate next positions for collision prediction
    wire [9:0] char1_next_left = (char1_x >= MOVE_SPEED_P1_LEFT) ? char1_x - MOVE_SPEED_P1_LEFT : 10'd0;
    wire [9:0] char1_next_right = (char1_x + CHAR_WIDTH + MOVE_SPEED_P1_RIGHT <= SCREEN_WIDTH) ? 
                                  char1_x + MOVE_SPEED_P1_RIGHT : SCREEN_WIDTH - CHAR_WIDTH;
    wire [9:0] char2_next_left = (char2_x >= MOVE_SPEED_P2_LEFT) ? char2_x - MOVE_SPEED_P2_LEFT : 10'd0;
    wire [9:0] char2_next_right = (char2_x + CHAR_WIDTH + MOVE_SPEED_P2_RIGHT <= SCREEN_WIDTH) ? 
                                  char2_x + MOVE_SPEED_P2_RIGHT : SCREEN_WIDTH - CHAR_WIDTH;
    
    // Collision prediction for next moves
    wire char1_would_collide_left = (char1_next_left < char2_x + CHAR_WIDTH + COLLISION_BUFFER) && 
                                    (char2_x < char1_next_left + CHAR_WIDTH + COLLISION_BUFFER);
    wire char1_would_collide_right = (char1_next_right < char2_x + CHAR_WIDTH + COLLISION_BUFFER) && 
                                     (char2_x < char1_next_right + CHAR_WIDTH + COLLISION_BUFFER);
    wire char2_would_collide_left = (char2_next_left < char1_x + CHAR_WIDTH + COLLISION_BUFFER) && 
                                    (char1_x < char2_next_left + CHAR_WIDTH + COLLISION_BUFFER);
    wire char2_would_collide_right = (char2_next_right < char1_x + CHAR_WIDTH + COLLISION_BUFFER) && 
                                     (char1_x < char2_next_right + CHAR_WIDTH + COLLISION_BUFFER);
    
    // Determine which character is on which side
    wire char1_is_left_of_char2 = (char1_x + CHAR_WIDTH/2 < char2_x + CHAR_WIDTH/2);

    random_button_generator lfsr_inst (
        .clk(clk_game),
        .rst(reset),
        .enable(1'b1),
        .bits(lfsr_bits)
    );

    assign attack_button2 = lfsr_bits[2];
    assign right_button2  = lfsr_bits[3];
    assign left_button2   = lfsr_bits[1];

    // States
    localparam IDLE = 4'b0000,
               LEFT = 4'b0001,
               RIGHT = 4'b0010,
               ATTACK_1_STARTUP = 4'b0011,
               ATTACK_1_ACTIVE = 4'b0100,
               ATTACK_1_RECOVERY = 4'b0101,
               ATTACK_2_STARTUP = 4'b0110,
               ATTACK_2_ACTIVE = 4'b0111,
               ATTACK_2_RECOVERY = 4'b1000,
               DAMAGE = 4'b1001,
               BLOCK = 4'b1010;

    // Count frames for state changes
    reg [4:0] frame_counter_p1;
    reg [4:0] frame_counter_p2;

    initial begin
        state_p1 = IDLE;
        state_p2 = IDLE;
        char1_x = 300;
        char2_x = 500;
        frame_counter_p1 = 0;
        frame_counter_p2 = 0;
    end

    // FSM for Player 1
    always @(posedge clk_game or posedge reset) begin
        if (reset) begin
            state_p1 <= IDLE;
            char1_x <= 300;
            frame_counter_p1 <= 0;
        end else begin
            case (state_p1)
                IDLE: begin
                    if (attack_button1) state_p1 <= ATTACK_1_STARTUP;
                    else if (left_button1) state_p1 <= LEFT;
                    else if (right_button1) state_p1 <= RIGHT;
                end

                LEFT: begin
                    // Check if movement is allowed
                    if (char1_x >= MOVE_SPEED_P1_LEFT && 
                        (!char1_would_collide_left || char1_is_left_of_char2)) begin
                        char1_x <= char1_x - MOVE_SPEED_P1_LEFT;
                    end
                    
                    // State transitions
                    if (!left_button1) begin
                        state_p1 <= (right_button1 ? RIGHT : IDLE);
                    end else if (attack_button1) begin
                        state_p1 <= ATTACK_2_STARTUP;
                    end
                end

                RIGHT: begin
                    // Check if movement is allowed
                    if (char1_x + CHAR_WIDTH + MOVE_SPEED_P1_RIGHT <= SCREEN_WIDTH && 
                        (!char1_would_collide_right || !char1_is_left_of_char2)) begin
                        char1_x <= char1_x + MOVE_SPEED_P1_RIGHT;
                    end
                    
                    // State transitions
                    if (!right_button1) begin
                        state_p1 <= (left_button1 ? LEFT : IDLE);
                    end else if (attack_button1) begin
                        state_p1 <= ATTACK_2_STARTUP;
                    end
                end

                ATTACK_1_STARTUP: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 5) begin
                        state_p1 <= ATTACK_1_ACTIVE;
                    end
                end

                ATTACK_1_ACTIVE: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 7) begin
                        state_p1 <= ATTACK_1_RECOVERY;
                    end
                end

                ATTACK_1_RECOVERY: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 23) begin
                        frame_counter_p1 <= 0;
                        state_p1 <= IDLE;
                    end
                end

                ATTACK_2_STARTUP: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 4) begin
                        state_p1 <= ATTACK_2_ACTIVE;
                    end
                end

                ATTACK_2_ACTIVE: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 7) begin
                        state_p1 <= ATTACK_2_RECOVERY;
                    end
                end

                ATTACK_2_RECOVERY: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 22) begin
                        frame_counter_p1 <= 0;
                        state_p1 <= IDLE;
                    end
                end

                default: state_p1 <= IDLE;
            endcase
        end
    end

    // FSM for Player 2 (AI)
    always @(posedge clk_game or posedge reset) begin
        if (reset) begin
            state_p2 <= IDLE;
            char2_x <= 500;
            frame_counter_p2 <= 0;
        end else begin
            case (state_p2)
                IDLE: begin
                    if (attack_button2) state_p2 <= ATTACK_1_STARTUP;
                    else if (left_button2) state_p2 <= LEFT;
                    else if (right_button2) state_p2 <= RIGHT;
                end

                LEFT: begin
                    // Check if movement is allowed
                    if (char2_x >= MOVE_SPEED_P2_LEFT && 
                        (!char2_would_collide_left || !char1_is_left_of_char2)) begin
                        char2_x <= char2_x - MOVE_SPEED_P2_LEFT;
                    end
                    
                    // State transitions
                    if (!left_button2) begin
                        state_p2 <= (right_button2 ? RIGHT : IDLE);
                    end else if (attack_button2) begin
                        state_p2 <= ATTACK_2_STARTUP;
                    end
                end

                RIGHT: begin
                    // Check if movement is allowed
                    if (char2_x + CHAR_WIDTH + MOVE_SPEED_P2_RIGHT <= SCREEN_WIDTH && 
                        (!char2_would_collide_right || char1_is_left_of_char2)) begin
                        char2_x <= char2_x + MOVE_SPEED_P2_RIGHT;
                    end
                    
                    // State transitions
                    if (!right_button2) begin
                        state_p2 <= (left_button2 ? LEFT : IDLE);
                    end else if (attack_button2) begin
                        state_p2 <= ATTACK_2_STARTUP;
                    end
                end

                ATTACK_1_STARTUP: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 5) begin
                        state_p2 <= ATTACK_1_ACTIVE;
                    end
                end

                ATTACK_1_ACTIVE: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 7) begin
                        state_p2 <= ATTACK_1_RECOVERY;
                    end
                end

                ATTACK_1_RECOVERY: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 23) begin
                        frame_counter_p2 <= 0;
                        state_p2 <= IDLE;
                    end
                end

                ATTACK_2_STARTUP: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 4) begin
                        state_p2 <= ATTACK_2_ACTIVE;
                    end
                end

                ATTACK_2_ACTIVE: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 7) begin
                        state_p2 <= ATTACK_2_RECOVERY;
                    end
                end

                ATTACK_2_RECOVERY: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 22) begin
                        frame_counter_p2 <= 0;
                        state_p2 <= IDLE;
                    end
                end

                default: state_p2 <= IDLE;
            endcase
        end
    end

endmodule
