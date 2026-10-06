module uart_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        uart_rxd,
    input  wire        baud_tick_16x,
    output reg  [7:0]  rx_data,
    output reg         rx_valid,
    output reg         rx_error
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] sample_count;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    // Synchronize RXD to avoid metastability
    reg rxd_sync1, rxd_sync2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_sync1 <= 1'b1;
            rxd_sync2 <= 1'b1;
        end else begin
            rxd_sync1 <= uart_rxd;
            rxd_sync2 <= rxd_sync1;
        end
    end

    wire rxd = rxd_sync2;
    wire falling_edge = (rxd_sync1 == 1'b0 && rxd_sync2 == 1'b1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sample_count <= 4'd0;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
            rx_data <= 8'd0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            rx_valid <= 1'b0; // Pulse
            
            case (state)
                IDLE: begin
                    if (falling_edge) begin
                        state <= START;
                        sample_count <= 4'd0;
                    end
                end
                START: begin
                    if (baud_tick_16x) begin
                        if (sample_count == 4'd7) begin
                            if (rxd == 1'b0) begin // Confirm start bit
                                state <= DATA;
                                sample_count <= 4'd0;
                                bit_count <= 3'd0;
                            end else begin
                                state <= IDLE; // False start
                            end
                        end else begin
                            sample_count <= sample_count + 4'd1;
                        end
                    end
                end
                DATA: begin
                    if (baud_tick_16x) begin
                        if (sample_count == 4'd15) begin
                            sample_count <= 4'd0;
                            shift_reg <= {rxd, shift_reg[7:1]};
                            if (bit_count == 3'd7) begin
                                state <= STOP;
                            end else begin
                                bit_count <= bit_count + 3'd1;
                            end
                        end else begin
                            sample_count <= sample_count + 4'd1;
                        end
                    end
                end
                STOP: begin
                    if (baud_tick_16x) begin
                        if (sample_count == 4'd15) begin
                            state <= IDLE;
                            rx_data <= shift_reg;
                            rx_valid <= 1'b1;
                            rx_error <= (rxd == 1'b0); // Error if stop bit is not high
                        end else begin
                            sample_count <= sample_count + 4'd1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
