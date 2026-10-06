module pc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 32'h0000_0000;
        end else begin
            pc_out <= pc_next;
        end
    end

endmodule
