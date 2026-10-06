`timescale 1ns/1ps

module tb_soc_final ();

    reg clk;
    reg rst_n;
    
    // UART pins
    wire uart_txd;
    wire uart_rxd; // We loop TX back to RX internally in the testbench
    
    assign uart_rxd = uart_txd; // Loopback
    
    // GPIO pins
    wire [7:0] gpio_in;
    wire [7:0] gpio_out;
    wire [7:0] gpio_oe;
    
    // For GPIO, whatever is driven to output on lower 4 bits, we loop to input
    assign gpio_in = {4'b0000, gpio_out[3:0]};
    
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
        $readmemh("final_program.hex", uut.instr_mem.mem);
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (uut.cpu.bus_valid && uut.cpu.bus_wen && uut.cpu.bus_ready)
                $display("Time %0t: CPU WRITE Addr=%h Data=%h", $time, uut.cpu.bus_addr, uut.cpu.bus_wdata);
            if (uut.cpu.bus_valid && !uut.cpu.bus_wen && uut.cpu.bus_ready)
                $display("Time %0t: CPU READ Addr=%h Data=%h", $time, uut.cpu.bus_addr, uut.cpu.bus_rdata);
        end
    end

    reg [31:0] uart_val;
    reg [31:0] cnn_val;
    reg [127:0] aes_val;
    reg [31:0] magic_val;

    initial begin
        $dumpfile("waveforms/tb_soc_final.vcd");
        $dumpvars(0, tb_soc_final);

        // Initialize
        clk = 0;
        rst_n = 0;

        #20;
        rst_n = 1;

        // The program ends by writing 0xDEADBEEF to SRAM offset 0x18 (index 6)
        while (uut.data_mem.mem[6] !== 32'hDEADBEEF) begin
            @(posedge clk);
            if ($time > 1500000) begin
                $display("FAIL: Timeout reached!");
                $finish;
            end
        end
        
        #100;
        $display("========================================");
        $display("FINAL SoC INTEGRATION TEST RESULTS");
        $display("========================================");

        // 1. Verify GPIO
        if (gpio_oe == 8'h0F && gpio_out == 8'h0A) begin
            $display("PASS: GPIO Configuration (OE=0x0F, OUT=0x0A)");
        end else begin
            $display("FAIL: GPIO Output incorrect! OE=%h OUT=%h", gpio_oe, gpio_out);
        end
        
        // 2. Verify UART
        uart_val = uut.data_mem.mem[0];
        if (uart_val == 32'h000000A5) begin
            $display("PASS: UART Loopback (Data=0xA5)");
        end else begin
            $display("FAIL: UART Loopback failed! Got %h", uart_val);
        end
        
        // 3. Verify CNN
        cnn_val = uut.data_mem.mem[1];
        // 1x1 conv of 5.0 with weight 1.0 and bias 2.0 -> (5 * 1) + 2 = 7.0 (0x00070000). ReLU(7) = 7.
        if (cnn_val == 32'h00070000) begin
            $display("PASS: CNN Inference (Output=7.0)");
        end else begin
            $display("FAIL: CNN Inference failed! Got %h", cnn_val);
        end
        
        // 4. Verify AES
        aes_val = {uut.data_mem.mem[2], uut.data_mem.mem[3], uut.data_mem.mem[4], uut.data_mem.mem[5]};
        if (aes_val == 128'h3925841d02dc09fbdc118597196a0b32) begin
            $display("PASS: AES-128 Encryption (Output matches FIPS 197)");
        end else begin
            $display("FAIL: AES-128 Encryption failed! Got %h", aes_val);
        end

        $display("========================================");
        $display("TEST COMPLETED.");
        $finish;
    end

endmodule
