`timescale 1ns/1ps

module tb_soc_peripherals;

    reg clk;
    reg rst_n;

    // GPIO pins
    reg  [7:0] gpio_in;
    wire [7:0] gpio_out;
    wire [7:0] gpio_oe;

    // UART pins
    wire uart_txd;
    wire uart_rxd;
    
    // Connect UART TX to RX for loopback
    assign uart_rxd = uart_txd;

    // Interrupts
    wire uart_irq, gpio_irq, timer_irq;

    // Instantiate SoC Top
    soc_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .uart_irq(uart_irq),
        .gpio_irq(gpio_irq),
        .timer_irq(timer_irq)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/tb_soc_peripherals.vcd");
        $dumpvars(0, tb_soc_peripherals);

        // Load instructions into IMEM
        $readmemh("../verification/test_peripherals.hex", uut.instr_mem.mem);

        clk = 0;
        rst_n = 0;
        gpio_in = 8'h00;
        
        #15 rst_n = 1;

        // Run until UART TX is done and RX receives it
        // The program writes to UART and loops. We need to wait for UART to send 10 bits.
        // Baud divisor is 2. 16x oversampling tick happens every 3 clks.
        // 1 bit takes 16 * 3 = 48 clks. 10 bits takes 480 clks.
        // 480 clks * 10ns = 4800ns.
        #10000;

        $display("Checking GPIO State:");
        if (gpio_oe !== 8'h0F) $display("FAIL: gpio_oe != 0x0F");
        else $display("PASS: gpio_oe == 0x0F");
        
        if (gpio_out !== 8'h0A) $display("FAIL: gpio_out != 0x0A");
        else $display("PASS: gpio_out == 0x0A");

        $display("Checking UART State (Loopback):");
        // Verify UART received the data
        if (uut.uart.rx_data !== 8'hA5) $display("FAIL: uart.rx_data != 0xA5");
        else $display("PASS: uart.rx_data == 0xA5");
        
        if (uut.uart.rx_valid_flag !== 1'b1) $display("FAIL: uart.rx_valid_flag not set");
        else $display("PASS: uart.rx_valid_flag is set");

        $display("Peripheral tests completed.");
        $finish;
    end

endmodule
