`timescale 1ns/1ps

module tb_soc_aes ();

    reg clk;
    reg rst_n;
    
    // UART pins
    wire uart_txd;
    reg  uart_rxd;
    
    // GPIO pins
    wire [7:0] gpio_in = 8'h00;
    wire [7:0] gpio_out;
    wire [7:0] gpio_oe;
    
    // Interrupts
    wire uart_irq, gpio_irq, timer_irq;
    
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

    // Clock generation
    always #5 clk = ~clk;
    
    // Load instruction memory
    initial begin
        $readmemh("aes_program.hex", uut.instr_mem.mem);
    end

    integer i;
    reg [31:0] w0, w1, w2, w3;
    reg [127:0] cipher_result;

    always @(posedge clk) begin
        if (rst_n) begin
            if (uut.cpu.bus_valid && uut.cpu.bus_wen && uut.cpu.bus_ready)
                $display("Time %0t: CPU WRITE Addr=%h Data=%h", $time, uut.cpu.bus_addr, uut.cpu.bus_wdata);
            if (uut.cpu.bus_valid && !uut.cpu.bus_wen && uut.cpu.bus_ready)
                $display("Time %0t: CPU READ Addr=%h Data=%h", $time, uut.cpu.bus_addr, uut.cpu.bus_rdata);
        end
    end

    always @(posedge clk) begin
        if (uut.cpu.pc_out == 32'h00000094) begin
            $display("Hit infinite loop at PC=0x94");
        end
    end

    initial begin
        $dumpfile("waveforms/tb_soc_aes.vcd");
        $dumpvars(0, tb_soc_aes);

        // Initialize
        clk = 0;
        rst_n = 0;
        uart_rxd = 1;

        #20;
        rst_n = 1;

        while (uut.cpu.pc_out != 32'h00000094) begin
            @(posedge clk);
            if ($time > 200000) begin
                $display("FAIL: Timeout");
                $finish;
            end
        end
        
        // Wait a few cycles to ensure writes to SRAM are complete
        #100;

        // Read result from DMEM
        w0 = uut.data_mem.mem[0];
        w1 = uut.data_mem.mem[1];
        w2 = uut.data_mem.mem[2];
        w3 = uut.data_mem.mem[3];
        
        cipher_result = {w0, w1, w2, w3};
        
        $display("Expected: 3925841d02dc09fbdc118597196a0b32");
        $display("Actual:   %h", cipher_result);
        
        if (cipher_result == 128'h3925841d02dc09fbdc118597196a0b32) begin
            $display("PASS: SoC integration of AES Engine successful!");
        end else begin
            $display("FAIL: Expected 3925841d02dc09fbdc118597196a0b32, got %h", cipher_result);
        end

        $finish;
    end

endmodule
