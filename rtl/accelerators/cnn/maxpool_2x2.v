module maxpool_2x2 #(
    parameter DATA_WIDTH = 32
) (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire signed [DATA_WIDTH-1:0] in0,
    input  wire signed [DATA_WIDTH-1:0] in1,
    input  wire signed [DATA_WIDTH-1:0] in2,
    input  wire signed [DATA_WIDTH-1:0] in3,
    output reg  signed [DATA_WIDTH-1:0] data_out,
    output reg  valid
);
    wire signed [DATA_WIDTH-1:0] max_01 = ($signed(in0) > $signed(in1)) ? in0 : in1;
    wire signed [DATA_WIDTH-1:0] max_23 = ($signed(in2) > $signed(in3)) ? in2 : in3;
    wire signed [DATA_WIDTH-1:0] max_final = ($signed(max_01) > $signed(max_23)) ? max_01 : max_23;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            valid <= 1'b0;
        end else if (enable) begin
            data_out <= max_final;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule
