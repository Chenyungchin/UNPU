module MUX_8to1 (
    input      [127:0] LUT,
    input        [2:0] ctrl,
    output reg  [15:0] MUX_out
);

always @(*) begin
    case(ctrl)
        3'b000 : MUX_out = LUT[15:0];
        3'b001 : MUX_out = LUT[31:16];
        3'b010 : MUX_out = LUT[47:32];
        3'b011 : MUX_out = LUT[63:48];
        3'b100 : MUX_out = LUT[79:64];
        3'b101 : MUX_out = LUT[95:80];
        3'b110 : MUX_out = LUT[111:96];
        3'b111 : MUX_out = LUT[127:112];
        default: MUX_out = 16'b0;
    endcase
end
    
endmodule