module soc_top (
    input  wire        clk,
    input  wire        rst_n,

    // UART pins
    output wire        uart_txd,
    input  wire        uart_rxd,

    // GPIO pins
    input  wire [7:0]  gpio_in,
    output wire [7:0]  gpio_out,
    output wire [7:0]  gpio_oe,

    // Interrupts (for testing)
    output wire        uart_irq,
    output wire        gpio_irq,
    output wire        timer_irq
);

    // CPU Instruction Fetch Interface
    wire [31:0] cpu_instr_addr;
    wire [31:0] cpu_instr_rdata;

    // CPU Data Bus Master Interface
    wire [31:0] cpu_bus_addr;
    wire [31:0] cpu_bus_wdata;
    wire [31:0] cpu_bus_rdata;
    wire        cpu_bus_wen;
    wire        cpu_bus_valid;
    wire        cpu_bus_ready;

    // IMEM Slave Interface
    wire        imem_valid;
    wire [31:0] imem_rdata;
    wire        imem_ready;

    // DMEM Slave Interface
    wire        dmem_valid;
    wire [31:0] dmem_rdata;
    wire        dmem_ready;

    // Peripheral Slave Interfaces
    wire        uart_valid;
    wire [31:0] uart_rdata;
    wire        uart_ready;

    wire        gpio_valid;
    wire [31:0] gpio_rdata;
    wire        gpio_ready;

    wire        timer_valid;
    wire [31:0] timer_rdata;
    wire        timer_ready;

    // Accelerator Interfaces
    wire        cnn_valid;
    wire [31:0] cnn_rdata;
    wire        cnn_ready;

    wire        aes_valid;
    wire [31:0] aes_rdata;
    wire        aes_ready;

    // Instantiate the CPU (Datapath)
    datapath cpu (
        .clk(clk),
        .rst_n(rst_n),
        .instr_addr(cpu_instr_addr),
        .instr_rdata(cpu_instr_rdata),
        .bus_addr(cpu_bus_addr),
        .bus_wdata(cpu_bus_wdata),
        .bus_rdata(cpu_bus_rdata),
        .bus_wen(cpu_bus_wen),
        .bus_valid(cpu_bus_valid),
        .bus_ready(cpu_bus_ready)
    );

    // Instantiate Instruction Memory (IMEM)
    imem #(
        .DEPTH(1024)
    ) instr_mem (
        .clk(clk),
        .instr_addr(cpu_instr_addr),
        .instr_rdata(cpu_instr_rdata),
        .bus_addr(cpu_bus_addr),
        .bus_valid(imem_valid),
        .bus_rdata(imem_rdata),
        .bus_ready(imem_ready)
    );

    // Instantiate Data Memory (DMEM)
    dmem #(
        .DEPTH(4096)
    ) data_mem (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(cpu_bus_addr),
        .bus_wdata(cpu_bus_wdata),
        .bus_wen(cpu_bus_wen),
        .bus_valid(dmem_valid),
        .bus_rdata(dmem_rdata),
        .bus_ready(dmem_ready)
    );

    // Instantiate Bus Decoder
    bus_decoder bus (
        .bus_addr(cpu_bus_addr),
        .bus_valid(cpu_bus_valid),
        .bus_wen(cpu_bus_wen),
        .bus_wdata(cpu_bus_wdata),
        .bus_rdata(cpu_bus_rdata),
        .bus_ready(cpu_bus_ready),

        .imem_valid(imem_valid),
        .imem_rdata(imem_rdata),
        .imem_ready(imem_ready),

        .dmem_valid(dmem_valid),
        .dmem_rdata(dmem_rdata),
        .dmem_ready(dmem_ready),

        .uart_valid(uart_valid),
        .uart_rdata(uart_rdata),
        .uart_ready(uart_ready),
        
        .gpio_valid(gpio_valid),
        .gpio_rdata(gpio_rdata),
        .gpio_ready(gpio_ready),
        
        .timer_valid(timer_valid),
        .timer_rdata(timer_rdata),
        .timer_ready(timer_ready),
        
        // Accelerators
        .cnn_valid(cnn_valid),
        .cnn_rdata(cnn_rdata),
        .cnn_ready(cnn_ready),
        
        .aes_valid(aes_valid),
        .aes_rdata(aes_rdata),
        .aes_ready(aes_ready)
    );

    // Instantiate AES-128 Engine
    aes_top aes_engine (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(cpu_bus_addr),
        .bus_wdata(cpu_bus_wdata),
        .bus_wen(cpu_bus_wen),
        .bus_valid(aes_valid),
        .bus_rdata(aes_rdata),
        .bus_ready(aes_ready)
    );

    // Instantiate UART
    uart_top uart (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(cpu_bus_addr),
        .bus_wdata(cpu_bus_wdata),
        .bus_wen(cpu_bus_wen),
        .bus_valid(uart_valid),
        .bus_rdata(uart_rdata),
        .bus_ready(uart_ready),
        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd),
        .uart_irq(uart_irq)
    );

    // Instantiate GPIO
    gpio_top gpio (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(cpu_bus_addr),
        .bus_wdata(cpu_bus_wdata),
        .bus_wen(cpu_bus_wen),
        .bus_valid(gpio_valid),
        .bus_rdata(gpio_rdata),
        .bus_ready(gpio_ready),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .gpio_irq(gpio_irq)
    );

    // Instantiate Timer
    timer_top timer (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(cpu_bus_addr),
        .bus_wdata(cpu_bus_wdata),
        .bus_wen(cpu_bus_wen),
        .bus_valid(timer_valid),
        .bus_rdata(timer_rdata),
        .bus_ready(timer_ready),
        .timer_irq(timer_irq)
    );

    // Instantiate CNN Accelerator
    cnn_top cnn_accel (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(cpu_bus_addr),
        .bus_wdata(cpu_bus_wdata),
        .bus_wen(cpu_bus_wen),
        .bus_valid(cnn_valid),
        .bus_rdata(cnn_rdata),
        .bus_ready(cnn_ready)
    );

endmodule
