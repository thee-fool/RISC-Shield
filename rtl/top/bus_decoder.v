module bus_decoder (
    // Master interface (from CPU)
    input  wire [31:0] bus_addr,
    input  wire        bus_valid,
    input  wire        bus_wen,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready,

    // Slave 0: IMEM (0x0...)
    output wire        imem_valid,
    input  wire [31:0] imem_rdata,
    input  wire        imem_ready,

    // Slave 1: DMEM (0x1...)
    output wire        dmem_valid,
    input  wire [31:0] dmem_rdata,
    input  wire        dmem_ready,

    // Slave 2: UART (0x2...)
    output wire        uart_valid,
    input  wire [31:0] uart_rdata,
    input  wire        uart_ready,

    // Slave 3: GPIO (0x3...)
    output wire        gpio_valid,
    input  wire [31:0] gpio_rdata,
    input  wire        gpio_ready,

    // Slave 4: Timer (0x4...)
    output wire        timer_valid,
    input  wire [31:0] timer_rdata,
    input  wire        timer_ready,

    // Slave 5: CNN Accelerator (0x5...)
    output wire        cnn_valid,
    input  wire [31:0] cnn_rdata,
    input  wire        cnn_ready,

    // Slave 6: AES-128 Engine (0x6...)
    output wire        aes_valid,
    input  wire [31:0] aes_rdata,
    input  wire        aes_ready
);

    // Decode logic based on addr[31:28]
    wire [3:0] region = bus_addr[31:28];

    assign imem_valid  = bus_valid && (region == 4'h0);
    assign dmem_valid  = bus_valid && (region == 4'h1);
    assign uart_valid  = bus_valid && (region == 4'h2);
    assign gpio_valid  = bus_valid && (region == 4'h3);
    assign timer_valid = bus_valid && (region == 4'h4);
    assign cnn_valid   = bus_valid && (region == 4'h5);
    assign aes_valid   = bus_valid && (region == 4'h6);

    always @(*) begin
        case (region)
            4'h0: begin
                bus_rdata = imem_rdata;
                bus_ready = imem_ready;
            end
            4'h1: begin
                bus_rdata = dmem_rdata;
                bus_ready = dmem_ready;
            end
            4'h2: begin
                bus_rdata = uart_rdata;
                bus_ready = uart_ready;
            end
            4'h3: begin
                bus_rdata = gpio_rdata;
                bus_ready = gpio_ready;
            end
            4'h4: begin
                bus_rdata = timer_rdata;
                bus_ready = timer_ready;
            end
            4'h5: begin
                bus_rdata = cnn_rdata;
                bus_ready = cnn_ready;
            end
            4'h6: begin
                bus_rdata = aes_rdata;
                bus_ready = aes_ready;
            end
            default: begin
                // Unmapped region -> fault/stall (no ready)
                bus_rdata = 32'h0000_0000;
                bus_ready = 1'b0;
            end
        endcase
    end

endmodule
