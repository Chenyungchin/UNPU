module LBPE(

);

// ============= parameters =======================
genvar i;

// ============= module instantiation =============
// LUT Bundle x 4
generate
    for (i=0; i<4; i=i+1) begin
        LUT #(
            .WEIGHT_WIDTH(WEIGHT_WIDTH)
        ) lut0(
            .clk(clk),
            .rst_n(rst_n), 
            .mode(), 
            .new_activation(),
            .weights(),
            .weights_1b(), 
            .activations(), 
            .partial_sums()
        );
    end
endgenerate
endmodule