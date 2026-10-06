module gpio_top (
    input  wire        clk,
    input  wire        rst_n,

    // Bus interface
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,
    input  wire        bus_wen,
    input  wire        bus_valid,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready,

    // GPIO pins
    input  wire [7:0]  gpio_in,
    output reg  [7:0]  gpio_out,
    output reg  [7:0]  gpio_oe,

    // Interrupt
    output wire        gpio_irq
);

    assign gpio_irq = 1'b0; // No interrupt support yet

    reg [7:0] gpio_in_sync1;
    reg [7:0] gpio_in_sync2;

    // Input Synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_in_sync1 <= 8'h00;
            gpio_in_sync2 <= 8'h00;
        end else begin
            gpio_in_sync1 <= gpio_in;
            gpio_in_sync2 <= gpio_in_sync1;
        end
    end

    // Bus Interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_ready <= 1'b0;
            bus_rdata <= 32'h0000_0000;
            gpio_oe   <= 8'h00;
            gpio_out  <= 8'h00;
        end else begin
            if (bus_valid && !bus_ready) begin
                bus_ready <= 1'b1;
                
                if (bus_wen) begin
                    case (bus_addr[3:0])
                        4'h0: gpio_out <= bus_wdata[7:0]; // GPIO_OUT
                        4'h8: gpio_oe  <= bus_wdata[7:0]; // GPIO_DIR
                        default: ;
                    endcase
                end else begin // Read
                    case (bus_addr[3:0])
                        4'h0: bus_rdata <= {24'h0, gpio_out};      // GPIO_OUT
                        4'h4: bus_rdata <= {24'h0, gpio_in_sync2}; // GPIO_IN
                        4'h8: bus_rdata <= {24'h0, gpio_oe};       // GPIO_DIR
                        default: bus_rdata <= 32'h0;
                    endcase
                end
            end else begin
                bus_ready <= 1'b0;
            end
        end
    end

endmodule
