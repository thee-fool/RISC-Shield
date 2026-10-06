module uart_top (
    input  wire        clk,
    input  wire        rst_n,

    // Bus interface
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,
    input  wire        bus_wen,
    input  wire        bus_valid,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready,

    // UART pins
    output wire        uart_txd,
    input  wire        uart_rxd,

    // Interrupt
    output wire        uart_irq
);

    // Registers
    reg [15:0] divisor;
    reg        tx_irq_en;
    reg        rx_irq_en;
    
    // Status flags
    wire tx_busy;
    wire rx_valid;
    wire rx_error;
    wire tx_done;

    // Sub-module connections
    reg  [7:0] tx_data;
    reg        tx_start;
    wire [7:0] rx_data;
    wire       baud_tick;
    wire       baud_tick_16x;

    // Internal states
    reg rx_valid_flag;
    reg rx_error_flag;
    
    assign uart_irq = (tx_irq_en && tx_done) || (rx_irq_en && rx_valid_flag);

    // Instantiate Baud Rate Generator
    uart_baud_gen baud_gen (
        .clk(clk),
        .rst_n(rst_n),
        .divisor(divisor),
        .baud_tick(baud_tick),
        .baud_tick_16x(baud_tick_16x)
    );

    // Instantiate Transmitter
    uart_tx tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .baud_tick(baud_tick),
        .uart_txd(uart_txd),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // Instantiate Receiver
    uart_rx rx (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rxd(uart_rxd),
        .baud_tick_16x(baud_tick_16x),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    // Latch RX flags
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid_flag <= 1'b0;
            rx_error_flag <= 1'b0;
        end else begin
            if (rx_valid) begin
                rx_valid_flag <= 1'b1;
                rx_error_flag <= rx_error;
            end else if (bus_valid && bus_ready && !bus_wen && (bus_addr[3:0] == 4'h4)) begin
                // Clear rx_valid_flag on reading UART_RX_DATA
                rx_valid_flag <= 1'b0;
            end
        end
    end

    // Bus interface logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_ready <= 1'b0;
            bus_rdata <= 32'h0;
            divisor   <= 16'h0;
            tx_irq_en <= 1'b0;
            rx_irq_en <= 1'b0;
            tx_start  <= 1'b0;
            tx_data   <= 8'h0;
        end else begin
            tx_start <= 1'b0; // Auto clear
            
            if (bus_valid && !bus_ready) begin
                bus_ready <= 1'b1;
                
                if (bus_wen) begin
                    case (bus_addr[3:0])
                        4'h0: begin // UART_TX_DATA
                            tx_data <= bus_wdata[7:0];
                            tx_start <= 1'b1;
                        end
                        4'hC: begin // UART_CTRL
                            divisor   <= bus_wdata[15:2]; // Divisor in [15:2]
                            tx_irq_en <= bus_wdata[0]; // Just mapping tx_en to tx_irq_en for now
                            rx_irq_en <= bus_wdata[1]; // Mapping rx_en to rx_irq_en
                        end
                        default: ;
                    endcase
                end else begin // Read
                    case (bus_addr[3:0])
                        4'h4: bus_rdata <= {24'h0, rx_data}; // UART_RX_DATA
                        4'h8: bus_rdata <= {28'h0, tx_done, rx_error_flag, rx_valid_flag, tx_busy}; // UART_STATUS
                        4'hC: bus_rdata <= {16'h0, divisor, rx_irq_en, tx_irq_en}; // UART_CTRL
                        default: bus_rdata <= 32'h0;
                    endcase
                end
            end else begin
                bus_ready <= 1'b0;
            end
        end
    end

endmodule
