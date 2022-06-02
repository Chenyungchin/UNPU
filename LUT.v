module LUT #(
    parameter WEIGHT_WIDTH = 12
)(
    input                        clk,
    input                        rst_n,
    input                        mode, // If mode == 0: multi-bit mode. If mode == 1: 1-bit mode
    input                        table_update,
    input   [3*WEIGHT_WIDTH-1:0] weights, // 36b
    input       [WEIGHT_WIDTH:0] weights_1b,
    input                [127:0] LUT_update_values,
    output reg           [191:0] partial_sums // 12 x 16b
);

// ============= parameters =================
genvar i, j, ii;
integer k;
// ============= wire and reg ===============
// lookup table
reg   [127:0] LUT; // 16bit x 8
// LUT index
wire  [2:0] LUT_index     [0:WEIGHT_WIDTH-1];
wire  [2:0] LUT_index_inv [0:WEIGHT_WIDTH-1];
// output of mux
wire  [191:0] MUX_out;
// MUX out inverse
wire  [191:0] MUX_out_inv;

// ============= Assignments ================
// 12 LUT indices
generate
    for (i=0; i<WEIGHT_WIDTH; i=i+1) begin
        assign LUT_index[i]     = {weights[2*WEIGHT_WIDTH+i], weights[WEIGHT_WIDTH+i], weights[i]};
        assign LUT_index_inv[i] = ~LUT_index[i];
    end
endgenerate

// MUX out inverse
generate
    for (ii=0; ii<WEIGHT_WIDTH; ii=ii+1) begin
        assign MUX_out_inv[16*ii+15: 16*ii] = ~MUX_out[16*ii+15: 16*ii]+1;
    end
endgenerate
// ============= Combinational ==============
// LUT indices
always @(*) begin
    if (!mode) begin
        partial_sums = MUX_out;
    end
    else begin
        for (k=0; k<WEIGHT_WIDTH; k=k+1) begin
            if (weights_1b[k]) begin
                partial_sums[16*k-15: 16*k] = MUX_out[16*k-15: 16*k];
            end
            else begin
                partial_sums[16*k-15: 16*k] = MUX_out_inv[16*k-15: 16*k];
            end
        end
    end
end
// ============= Sequential ==================
// LUT update
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        LUT <= 128'b0;
    end
    else begin
        if (table_update) LUT <= LUT_update_values;
        else              LUT <= LUT;
    end
end

// ============= Module Instantiation ========
generate
    for (j=0; j<WEIGHT_WIDTH; j=j+1) begin
        MUX_8to1 mux0(
            .LUT(LUT),
            .ctrl((mode & ~weights_1b[j]) ? LUT_index_inv[j] : LUT_index[j]), // invert the index if mode is 1 (1-bit mode) and weights_1b is 0
            .MUX_out(MUX_out[16*j+15: 16*j])
        );
    end
endgenerate



endmodule