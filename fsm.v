module fsm (
    input clk,                // FSM clock (selected_clk)
    input reset,              // aktif yüksek reset
    input move_left,          // sola gitme tuşu
    input move_right,         // sağa gitme tuşu
    input attack,             // saldırı tuşu
    input got_hit,            // vurulma sinyali (hitlogic'ten gelir)

    output reg [9:0] char_x,  // karakterin X pozisyonu (render için)
    output reg [2:0] state    // karakterin mevcut durumu (render için)
);

    //========= DURUM TANIMLARI =========
    localparam IDLE     = 3'b000;
    localparam MOVING   = 3'b001;
    localparam ATTACK   = 3'b010;
    localparam HITSTUN  = 3'b011;

    //========= DAHİLİ SAYAÇLAR =========
    reg [3:0] attack_timer;
    reg [3:0] hitstun_timer;

    //========= RESET BLOĞU =========
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            char_x <= 10'd100;
            attack_timer <= 0;
            hitstun_timer <= 0;
        end
        else begin
            case (state)

                //========= DURUM: IDLE =========
                IDLE: begin
                    if (got_hit) begin
                        state <= HITSTUN;
                        hitstun_timer <= 5;
                    end
                    else if (attack) begin
                        state <= ATTACK;
                        attack_timer <= 5;
                    end
                    else if (move_left) begin
                        state <= MOVING;
                        char_x <= (char_x > 0) ? char_x - 3 : char_x;
                    end
                    else if (move_right) begin
                        state <= MOVING;
                        char_x <= (char_x < 576) ? char_x + 3 : char_x; // ekran sınırı (640 - 64)
                    end
                end

                //========= DURUM: MOVING =========
                MOVING: begin
                    if (got_hit) begin
                        state <= HITSTUN;
                        hitstun_timer <= 5;
                    end
                    else if (attack) begin
                        state <= ATTACK;
                        attack_timer <= 5;
                    end
                    else if (!move_left && !move_right)
                        state <= IDLE;
                    else begin
                        if (move_left)
                            char_x <= (char_x > 0) ? char_x - 3 : char_x;
                        else if (move_right)
                            char_x <= (char_x < 576) ? char_x + 3 : char_x;
                    end
                end

                //========= DURUM: ATTACK =========
                ATTACK: begin
                    if (got_hit) begin
                        state <= HITSTUN;
                        hitstun_timer <= 5;
                    end
                    else if (attack_timer == 0)
                        state <= IDLE;
                    else
                        attack_timer <= attack_timer - 1;
                end

                //========= DURUM: HITSTUN =========
                HITSTUN: begin
                    if (hitstun_timer == 0)
                        state <= IDLE;
                    else
                        hitstun_timer <= hitstun_timer - 1;
                end

                //========= EMNİYET =========
                default: state <= IDLE;
            endcase
        end
    end

endmodule
