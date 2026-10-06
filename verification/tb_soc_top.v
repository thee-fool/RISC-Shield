`timescale 1ns/1ps

module tb_soc_top;

    reg clk;
    reg rst_n;

    // Instantiate SoC Top
    soc_top uut (
        .clk(clk),
        .rst_n(rst_n)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/tb_soc_top.vcd");
        $dumpvars(0, tb_soc_top);

        // Load instructions into IMEM
        $readmemh("../verification/test_soc.hex", uut.instr_mem.mem);

        clk = 0;
        rst_n = 0;
        
        #15 rst_n = 1; // De-assert reset

        // Run for a sufficient number of cycles
        #250;

        // Check internal registers to verify execution
        $display("Checking CPU Registers:");
        if (uut.cpu.reg_file.registers[10] !== 32'h1000_0000) $display("FAIL: x10 != 0x1000_0000 (Data from IMEM load failed)");
        else $display("PASS: x10 == 0x1000_0000");

        if (uut.cpu.reg_file.registers[1] !== 32'd5)  $display("FAIL: x1 != 5");
        else $display("PASS: x1 == 5");
        
        if (uut.cpu.reg_file.registers[2] !== 32'd10) $display("FAIL: x2 != 10");
        else $display("PASS: x2 == 10");
        
        if (uut.cpu.reg_file.registers[3] !== 32'd15) $display("FAIL: x3 != 15");
        else $display("PASS: x3 == 15");
        
        if (uut.cpu.reg_file.registers[4] !== 32'd15) $display("FAIL: x4 != 15 (DMEM load failed)");
        else $display("PASS: x4 == 15 (DMEM read back correctly)");
        
        // Verify DMEM contents directly
        if (uut.data_mem.mem[0] !== 32'd15) $display("FAIL: dmem[0] != 15");
        else $display("PASS: dmem[0] == 15");

        $display("SoC interconnect and memory tests completed.");
        $finish;
    end

endmodule
