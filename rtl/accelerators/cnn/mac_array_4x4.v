module mac_array_4x4 #(
    parameter DATA_WIDTH = 32
) (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,
    input  wire enable,
    
    // Inputs (packed for simplicity in passing to the array)
    // 16 elements * DATA_WIDTH
    input  wire [16*DATA_WIDTH-1:0] a_packed,
    input  wire [16*DATA_WIDTH-1:0] b_packed,
    
    // Outputs (packed)
    output wire [16*2*DATA_WIDTH-1:0] result_packed
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : mac_insts
            wire signed [DATA_WIDTH-1:0] a_in = a_packed[i*DATA_WIDTH +: DATA_WIDTH];
            wire signed [DATA_WIDTH-1:0] b_in = b_packed[i*DATA_WIDTH +: DATA_WIDTH];
            wire signed [2*DATA_WIDTH-1:0] acc_out;
            
            mac_unit #(
                .DATA_WIDTH(DATA_WIDTH)
            ) u_mac (
                .clk(clk),
                .rst_n(rst_n),
                .clear(clear),
                .enable(enable),
                .a(a_in),
                .b(b_in),
                .accumulator(acc_out)
            );
            
            assign result_packed[i*2*DATA_WIDTH +: 2*DATA_WIDTH] = acc_out;
        end
    endgenerate

endmodule
