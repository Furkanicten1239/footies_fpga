module hitlogic (
    input [9:0] char1_x,
    input [9:0] char1_y,
    input [2:0] char1_state,

    input [9:0] char2_x,
    input [9:0] char2_y,
    input [2:0] char2_state,

    output hit1_lands, // P1, P2'ye vurdu
    output hit2_lands  // P2, P1'e vurdu
);

    //==================== PARAMETRELER ====================
    parameter CHAR_WIDTH = 64;
    parameter CHAR_HEIGHT = 240;

    parameter HITBOX_WIDTH = 20;
    parameter HITBOX_HEIGHT = 60;

    // FSM durumları (aynı FSM.v ile eşleşmeli)
    localparam ATTACK = 3'b010;

    //==================== HITBOX KOORDİNATLARI ====================
    // P1 saldırırsa, hitbox sağ tarafında oluşur
    wire [9:0] char1_hitbox_x = char1_x + CHAR_WIDTH;
    wire [9:0] char1_hitbox_y = char1_y + (CHAR_HEIGHT - HITBOX_HEIGHT)/2;

    // P2 saldırırsa, hitbox sol tarafında oluşur
    wire [9:0] char2_hitbox_x = (char2_x >= HITBOX_WIDTH) ? char2_x - HITBOX_WIDTH : 0;
    wire [9:0] char2_hitbox_y = char2_y + (CHAR_HEIGHT - HITBOX_HEIGHT)/2;

    //==================== HITBOX ÇAKIŞMA KONTROLÜ ====================
    // Basit dikdörtgen çarpışma kontrolü fonksiyonu
    function hit_detect;
        input [9:0] x1, y1, w1, h1;
        input [9:0] x2, y2, w2, h2;
    begin
        hit_detect = !(x1 + w1 <= x2 || x2 + w2 <= x1 || y1 + h1 <= y2 || y2 + h2 <= y1);
    end
    endfunction

    //==================== VURUŞ TESPİTİ ====================
    assign hit1_lands = (char1_state == ATTACK) &&
                        hit_detect(char1_hitbox_x, char1_hitbox_y, HITBOX_WIDTH, HITBOX_HEIGHT,
                                   char2_x, char2_y, CHAR_WIDTH, CHAR_HEIGHT);

    assign hit2_lands = (char2_state == ATTACK) &&
                        hit_detect(char2_hitbox_x, char2_hitbox_y, HITBOX_WIDTH, HITBOX_HEIGHT,
                                   char1_x, char1_y, CHAR_WIDTH, CHAR_HEIGHT);

endmodule
