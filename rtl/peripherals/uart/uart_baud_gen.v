module uart_baud_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] divisor,
    output reg         baud_tick,
    output reg         baud_tick_16x
);

    reg [19:0] acc;
    reg [3:0]  oversample_count;

    wire [19:0] div_plus_1 = {4'd0, divisor} + 20'd1;
    wire [19:0] acc_next = acc + 20'd16;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 20'd0;
            oversample_count <= 4'd0;
            baud_tick <= 1'b0;
            baud_tick_16x <= 1'b0;
        end else begin
            baud_tick <= 1'b0;
            baud_tick_16x <= 1'b0;

            if (acc_next >= div_plus_1) begin
                acc <= acc_next - div_plus_1;
                baud_tick_16x <= 1'b1;
                
                if (oversample_count == 4'd15) begin
                    oversample_count <= 4'd0;
                    baud_tick <= 1'b1;
                end else begin
                    oversample_count <= oversample_count + 4'd1;
                end
            end else begin
                acc <= acc_next;
            end
        end
    end

endmodule
