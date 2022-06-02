// functions: four LUT, calculate update value, 4-way add/sub tree

module LUT_BUNDLE #(
    parameter WEIGHT_WIDTH  = 12
)(
    input                        clk,
    input                        rst_n,
    input                        mode, 
    input                        new_activation, // new activations will arrive on the next cycle
    input  [12*WEIGHT_WIDTH-1:0] weights,
    input     [4*WEIGHT_WIDTH:0] weights_1b,
    input                 [63:0] activations, // 16b x 4, order: A->B->C->D
    output  reg          [215:0] partial_sums // 18b x 12     
);
// =============== parameters ==========================
genvar i;

// state 
localparam IDLE         = 2'b00;
localparam TABLE_CALC   = 2'b01;
localparam TABLE_UPDATE = 2'b10;
localparam COMP         = 2'b11;

// =============== wires and reg =======================
// state
reg  [1:0] state_r, state_w;
// activation
wire [15:0] A, B, C, D;
// signal for LUT module table update
wire        table_update;
// LUT update values
reg [127:0] LUT_update_values_r, LUT_update_values_w;
// LUT output
wire [191:0] LUT_OUT [0:3];

// =============== assignments =========================
// activations
assign {A, B, C, D} = activations;
// signal for LUT module table update
assign table_update = (state_r == TABLE_UPDATE);

// =============== Combinational =======================
// state
always @(*) begin
    state_w = state_r;
    case (state_r)
        IDLE: begin
            if (new_activation) state_w = TABLE_CALC;
        end
        TABLE_CALC: begin
            state_w = TABLE_UPDATE;
        end
        TABLE_UPDATE: begin
            state_w = COMP;
        end
        COMP: begin
            if (new_activation) state_w = TABLE_CALC;
        end
        default: begin
            
        end
    endcase
end

// LUT update values
always @(*) begin
    if (state_r == TABLE_CALC) begin
        if (!mode) begin // multi-bit
            LUT_update_values_w[15:0]    = 0;     // 000
            LUT_update_values_w[31:16]   = A;     // 001
            LUT_update_values_w[47:32]   = B;     // 010
            LUT_update_values_w[63:48]   = B+A;   // 011
            LUT_update_values_w[79:64]   = C;     // 100
            LUT_update_values_w[95:80]   = C+A;   // 101
            LUT_update_values_w[111:96]  = C+B;   // 110
            LUT_update_values_w[127:112] = C+B+A; // 111
        end
        else begin // 1-bit
            LUT_update_values_w[15:0]    = D-C-B-A;     // 000
            LUT_update_values_w[31:16]   = D-C-B+A;     // 001
            LUT_update_values_w[47:32]   = D-C+B-A;     // 010
            LUT_update_values_w[63:48]   = D-C+B+A;     // 011
            LUT_update_values_w[79:64]   = D+C-B-A;     // 100
            LUT_update_values_w[95:80]   = D+C-B+A;     // 101
            LUT_update_values_w[111:96]  = D+C+B-A;     // 110
            LUT_update_values_w[127:112] = D+C+B+A;     // 111
        end
    end
    else begin
        LUT_update_values_w = 128'b0;
    end
end

// partial sums
always @(*) begin
    partial_sums = LUT_OUT[0] + LUT_OUT[1] + LUT_OUT[2] + LUT_OUT[3];
end
// =============== Sequential ==========================
// state
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state_r <= 2'b0;
    else        state_r <= state_w;
end
// LUT update values
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) LUT_update_values_r <= 128'b0;
    else        LUT_update_values_r <= LUT_update_values_w;
end
// =============== module instantiation ================
// LUT x 4
generate
    for (i=0; i<4; i=i+1) begin
        LUT #(
            .WEIGHT_WIDTH(WEIGHT_WIDTH)
        ) lut0(
            .clk(clk),
            .rst_n(rst_n), 
            .mode(mode), 
            .table_update(table_update),
            .weights(weights[3*WEIGHT_WIDTH*(i+1)-1: 3*WEIGHT_WIDTH*i]),
            .weights_1b(weights_1b[WEIGHT_WIDTH*(i+1)-1: WEIGHT_WIDTH*i]), 
            .LUT_update_values(LUT_update_values_r), 
            .partial_sums(LUT_OUT[i])
        );
    end
endgenerate

endmodule
