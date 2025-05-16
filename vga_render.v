module vga_render (
    input [9:0] next_x,
    input [9:0] next_y,
    input [9:0] char_x,
    input [9:0] char_y,
    input [2:0] state,
    output reg [7:0] color_out
);

    //================ FSM Durum Kodları ================
    localparam IDLE      = 3'b000;
    localparam MOVING    = 3'b001;
    localparam ATTACK    = 3'b010;
    localparam HITSTUN   = 3'b011;
    localparam BLOCKSTUN = 3'b100;  // şimdilik yok ama rezerve

    //================ Karakterin Boyutu ================
    parameter CHAR_WIDTH  = 64;
    parameter CHAR_HEIGHT = 240;

    //================ RENDER MANTIĞI ====================
    always @(*) begin
        // Karakterin içindeysek
        if ((next_x >= char_x) && (next_x < char_x + CHAR_WIDTH) &&
            (next_y >= char_y) && (next_y < char_y + CHAR_HEIGHT)) begin

            case (state)
                IDLE:       color_out = 8'b000_000_11; // mavi
                MOVING:     color_out = 8'b000_111_00; // yeşil
                ATTACK:     color_out = 8'b111_000_00; // kırmızı
                HITSTUN:    color_out = 8'b111_111_00; // sarı (vurulma)
                BLOCKSTUN:  color_out = 8'b000_111_11; // camgöbeği (gelecek)
                default:    color_out = 8'b111_111_11; // beyaz (hata durumu)
            endcase

        end else begin
            // Karakter dışında kalan alan → arka plan
            color_out = 8'b010_010_10; // gri
        end
    end

endmodule
