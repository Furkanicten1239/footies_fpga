// Module: game_logic
// Responsibility: Handles FSM transitions and character positions for both players

module fsm_logic_singleplayer (
    input wire clk_game,
    input wire reset,
    input wire left_button1,
    input wire right_button1,
    input wire attack_button1,
	 
	 //CREATING THE REGISTERS FOR STATES AND CHARACTER POSITIONS
    output reg [3:0] state_p1,
    output reg [3:0] state_p2,
    output reg [9:0] char1_x,
    output reg [9:0] char2_x
);
//We use those wires for instantiating the lfsr random bit generator module
wire [3:0] lfsr_bits;
wire attack_button2, left_button2, right_button2;

random_button_generator lfsr_inst (
    .clk(clk_game),
    .rst(reset),
    .enable(1'b1), //Since it is always enable, we have written 1 here.
    .bits(lfsr_bits)
);

assign attack_button2 = lfsr_bits[2];
assign right_button2  = lfsr_bits[3];
assign left_button2   = lfsr_bits[1];



    // States
    localparam IDLE = 4'b0000,
               LEFT = 4'b0001,
               RIGHT = 4'b0010,
               ATTACK_1_STARTUP = 4'b0011,//ATTACK WHEN CHARACTER IS STANDING
               ATTACK_1_ACTIVE = 4'b0100,
               ATTACK_1_RECOVERY = 4'b0101,
               ATTACK_2_STARTUP = 4'b0110,//ATTACK WHEN CHARACTER IS MOVING FORWARD
               ATTACK_2_ACTIVE = 4'b0111,
               ATTACK_2_RECOVERY = 4'b1000,
               DAMAGE = 4'b1001,
               BLOCK = 4'b1010;//WHEN CHARACTER IS BEING HIT BUT MOVING BACKWARD AT THAT TIME

					
					//  count frames for state changes.
    reg [4:0] frame_counter_p1;
    reg [4:0] frame_counter_p2;
	 
	 
	 

    localparam CHAR_WIDTH = 128;
    localparam SCREEN_WIDTH = 640;

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
                IDLE:
                    if (attack_button1) state_p1 <= ATTACK_1_STARTUP;
                    else if (left_button1) state_p1 <= LEFT;
                    else if (right_button1) state_p1 <= RIGHT;

                LEFT: begin
                    if (char1_x > 0) char1_x <= char1_x - 2;
                    if (!left_button1) state_p1 <= (right_button1 ? RIGHT : IDLE);
                    else if (attack_button1) state_p1 <= ATTACK_2_STARTUP;
                end

                RIGHT: begin
                    if (char1_x + CHAR_WIDTH < SCREEN_WIDTH) char1_x <= char1_x + 3;
                    if (!right_button1) state_p1 <= (left_button1 ? LEFT : IDLE);
                    else if (attack_button1) state_p1 <= ATTACK_2_STARTUP;
                end

                ATTACK_1_STARTUP: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 5) state_p1 <= ATTACK_1_ACTIVE;
                end

                ATTACK_1_ACTIVE: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 7) state_p1 <= ATTACK_1_RECOVERY;
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
                    if (frame_counter_p1 == 4) state_p1 <= ATTACK_2_ACTIVE;
                end

                ATTACK_2_ACTIVE: begin
                    frame_counter_p1 <= frame_counter_p1 + 1;
                    if (frame_counter_p1 == 7) state_p1 <= ATTACK_2_RECOVERY;
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

	 
	 
	 
	 
	 
    // RANDOMIZED FSM PLAYER
    always @(posedge clk_game or posedge reset) begin
        if (reset) begin
            state_p2 <= IDLE;
            char2_x <= 500;
            frame_counter_p2 <= 0;
        end else begin
            case (state_p2)
                IDLE:
                    if (attack_button2) state_p2 <= ATTACK_1_STARTUP;
                    else if (left_button2) state_p2 <= LEFT;
                    else if (right_button2) state_p2 <= RIGHT;

                LEFT: begin
                    if (char2_x > 0) char2_x <= char2_x - 3;
                    if (!left_button2) state_p2 <= (right_button2 ? RIGHT : IDLE);
                    else if (attack_button2) state_p2 <= ATTACK_2_STARTUP;
                end

                RIGHT: begin
                    if (char2_x + CHAR_WIDTH < SCREEN_WIDTH) char2_x <= char2_x + 2;
                    if (!right_button2) state_p2 <= (left_button2 ? LEFT : IDLE);
                    else if (attack_button2) state_p2 <= ATTACK_2_STARTUP;
                end

                ATTACK_1_STARTUP: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 5) state_p2 <= ATTACK_1_ACTIVE;
                end

                ATTACK_1_ACTIVE: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 7) state_p2 <= ATTACK_1_RECOVERY;
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
                    if (frame_counter_p2 == 4) state_p2 <= ATTACK_2_ACTIVE;
                end

                ATTACK_2_ACTIVE: begin
                    frame_counter_p2 <= frame_counter_p2 + 1;
                    if (frame_counter_p2 == 7) state_p2 <= ATTACK_2_RECOVERY;
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
