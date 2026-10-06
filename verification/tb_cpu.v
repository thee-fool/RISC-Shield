`timescale 1ns/1ps

module tb_cpu;

    reg clk;
    reg rst_n;

    // Bus signals
    wire [31:0] bus_addr;
    wire [31:0] bus_wdata;
    reg  [31:0] bus_rdata;
    wire        bus_wen;
    wire        bus_valid;
    reg         bus_ready;

    // Instantiate datapath (CPU top)
    datapath cpu (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_rdata(bus_rdata),
        .bus_wen(bus_wen),
        .bus_valid(bus_valid),
        .bus_ready(bus_ready)
    );

    // Dummy data memory (acting as slave)
    reg [31:0] dmem [0:1023];

    always #5 clk = ~clk;

    // Bus slave responder (Single-cycle)
    always @(posedge clk) begin
        if (bus_valid && bus_wen) begin
            dmem[bus_addr[11:2]] <= bus_wdata;
            $display("[%0t] MEM WRITE: Addr=%08x, Data=%08x", $time, bus_addr, bus_wdata);
        end
    end

    always @(*) begin
        bus_rdata = dmem[bus_addr[11:2]];
        bus_ready = 1'b1;
    end

    initial begin
        $dumpfile("waveforms/tb_cpu.vcd");
        $dumpvars(0, tb_cpu);

        // Load instructions into IMEM
        $readmemh("../verification/test_prog.hex", cpu.instr_mem.mem);

        // Initialize dummy data memory
        dmem[0] = 32'h0000_0000;

        clk = 0;
        rst_n = 0;
        
        #10 rst_n = 1;

        // Run for a sufficient number of cycles
        #250;

        // Check internal registers to verify execution
        if (cpu.reg_file.registers[1] !== 32'd5)  $display("FAIL: x1 != 5");
        else $display("PASS: x1 == 5");
        
        if (cpu.reg_file.registers[2] !== 32'd10) $display("FAIL: x2 != 10");
        else $display("PASS: x2 == 10");
        
        if (cpu.reg_file.registers[3] !== 32'd15) $display("FAIL: x3 != 15");
        else $display("PASS: x3 == 15");
        
        if (cpu.reg_file.registers[4] !== 32'd15) $display("FAIL: x4 != 15 (LW failed)");
        else $display("PASS: x4 == 15");
        
        if (cpu.reg_file.registers[5] !== 32'd1)  $display("FAIL: x5 != 1 (SLT failed)");
        else $display("PASS: x5 == 1");
        
        if (cpu.reg_file.registers[6] !== 32'd1)  $display("FAIL: x6 != 1 (Branch skipped or JAL failed)");
        else $display("PASS: x6 == 1");

        $display("CPU tests completed.");
        $finish;
    end

endmodule
