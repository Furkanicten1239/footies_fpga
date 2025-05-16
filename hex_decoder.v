module hex_decoder (
    input  [3:0] in,
    output reg [6:0] out
);

// 7-segment: 0 aktif, 1 pasif (common anode için terslenir)
always @(*) begin
    case (in)
        4'd0: out = 7'b100_0000; // 0
        4'd1: out = 7'b111_1001; // 1
        4'd2: out = 7'b010_0100; // 2
        4'd3: out = 7'b011_0000; // 3
        4'd4: out = 7'b001_1001; // 4
        4'd5: out = 7'b001_0010; // 5
        4'd6: out = 7'b000_0010; // 6
        4'd7: out = 7'b111_1000; // 7
        4'd8: out = 7'b000_0000; // 8
        4'd9: out = 7'b001_0000; // 9
        4'd10: out = 7'b000_1000; // A
        4'd11: out = 7'b000_0011; // b
        4'd12: out = 7'b100_0110; // C
        4'd13: out = 7'b010_0001; // d
        4'd14: out = 7'b000_0110; // E
        4'd15: out = 7'b000_1110; // F
        default: out = 7'b111_1111;
    endcase
end

endmodule
