`timescale 1ns/1ps
module tb_soc_cnn;
    reg clk;
    reg rst_n;
    
    // UART pins
    wire uart_txd;
    reg uart_rxd;
    
    // GPIO pins
    reg [7:0] gpio_in;
    wire [7:0] gpio_out;
    wire [7:0] gpio_oe;

    // IRQs
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

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (uut.cpu.bus_valid && uut.cpu.bus_ready) begin
            if (uut.cpu.bus_wen) begin
                $display("Time %0t: CPU WRITE Addr=%h Data=%h", $time, uut.cpu.bus_addr, uut.cpu.bus_wdata);
            end else if (uut.cpu.bus_addr[31:28] != 4'h0 && uut.cpu.bus_addr[31:28] != 4'h1) begin
                $display("Time %0t: CPU READ Addr=%h Data=%h", $time, uut.cpu.bus_addr, uut.cpu.bus_rdata);
            end
        end
        if (!uut.cpu.stall && rst_n) begin
            $display("Time %0t: PC=%h Instr=%h rs1=%h rs2=%h ALU=%h", $time, uut.cpu.pc_out, uut.cpu.instruction, uut.cpu.rs1_data, uut.cpu.rs2_data, uut.cpu.alu_result);
        end
    end

    initial begin
        $dumpfile("waveforms/tb_soc_cnn.vcd");
        $dumpvars(0, tb_soc_cnn);

        // Load the CNN test program into the instruction memory
        $readmemh("test_cnn.hex", uut.instr_mem.mem);
        
        clk = 0;
        rst_n = 0;
        uart_rxd = 1;
        
        #20 rst_n = 1;
        
        // Wait enough time for CPU to write all weights/inputs, start CNN, and read back result
        #4000;
        
        // The result will be stored in register x5 (index 5)
        $display("x5 (result): %h", uut.cpu.reg_file.registers[5]);
        
        if (uut.cpu.reg_file.registers[5] === 32'h0009_0000) begin
            $display("PASS: SoC integration of CNN Accelerator successful! Output is %h", uut.cpu.reg_file.registers[5]);
        end else begin
            $display("FAIL: Expected 00090000, got %h", uut.cpu.reg_file.registers[5]);
        end
        
        $finish;
    end
endmodule
