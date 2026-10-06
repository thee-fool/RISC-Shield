module relu #(
    parameter DATA_WIDTH = 32
) (
    input  wire signed [DATA_WIDTH-1:0] data_in,
    output wire signed [DATA_WIDTH-1:0] data_out
);
    assign data_out = (data_in[DATA_WIDTH-1]) ? {DATA_WIDTH{1'b0}} : data_in;
endmodule
