module random_button_generator (
    input wire clk,
    input wire rst,
    input wire enable,
    output wire [3:0] bits// We will use 3 bits from 4, and assign them to attack, left and right buttons.
);

    reg [3:0] lfsr_reg;
    wire feedback;

    assign feedback = lfsr_reg[3] ^ lfsr_reg[2];
    assign bits = lfsr_reg[3:0];  // MSBs for external use

    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr_reg <= 4'b0001;  // We add that statement to avoid 0000 case.
        else if (enable)
            lfsr_reg <= {lfsr_reg[2:0], feedback}; //After the feedback, we added that bit as MSB. Then to conserve the size we shift the array.
    end

endmodule
