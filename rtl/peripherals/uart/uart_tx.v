module uart_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  tx_data,
    input  wire        tx_start,
    input  wire        baud_tick,
    output reg         uart_txd,
    output wire        tx_busy,
    output reg         tx_done
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state, next_state;
    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    assign tx_busy = (state != IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            uart_txd <= 1'b1;
            shift_reg <= 8'd0;
            bit_count <= 3'd0;
            tx_done <= 1'b0;
        end else begin
            tx_done <= 1'b0;
            case (state)
                IDLE: begin
                    uart_txd <= 1'b1;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        state <= START;
                    end
                end
                START: begin
                    uart_txd <= 1'b0; // Start bit
                    if (baud_tick) begin
                        state <= DATA;
                        bit_count <= 3'd0;
                    end
                end
                DATA: begin
                    uart_txd <= shift_reg[0];
                    if (baud_tick) begin
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        if (bit_count == 3'd7) begin
                            state <= STOP;
                        end else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end
                end
                STOP: begin
                    uart_txd <= 1'b1; // Stop bit
                    if (baud_tick) begin
                        state <= IDLE;
                        tx_done <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
