module mac_unit #(
    parameter DATA_WIDTH = 32
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    clear,
    input  wire                    enable,
    input  wire signed [DATA_WIDTH-1:0] a,
    input  wire signed [DATA_WIDTH-1:0] b,
    output reg  signed [2*DATA_WIDTH-1:0] accumulator
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= 0;
        end else if (clear) begin
            accumulator <= 0;
        end else if (enable) begin
            accumulator <= accumulator + (a * b);
        end
    end
endmodule
