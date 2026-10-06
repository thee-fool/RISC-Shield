`timescale 1ns/1ps

module tb_register_file;

    reg         clk;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  rd_addr;
    reg  [31:0] rd_data;
    reg         reg_write;
    
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    register_file uut (
        .clk(clk),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .reg_write(reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/tb_register_file.vcd");
        $dumpvars(0, tb_register_file);

        clk = 0;
        reg_write = 0;
        rd_addr = 0;
        rd_data = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        #10;

        // Write to x1
        reg_write = 1;
        rd_addr = 5'd1;
        rd_data = 32'hDEAD_BEEF;
        #10;
        
        // Write to x2
        rd_addr = 5'd2;
        rd_data = 32'hCAFE_F00D;
        #10;
        
        // Write to x0 (should be ignored)
        rd_addr = 5'd0;
        rd_data = 32'hFFFF_FFFF;
        #10;

        reg_write = 0;

        // Read back
        rs1_addr = 5'd1;
        rs2_addr = 5'd2;
        #10;
        if (rs1_data !== 32'hDEAD_BEEF) $display("FAIL READ x1");
        if (rs2_data !== 32'hCAFE_F00D) $display("FAIL READ x2");

        // Read x0
        rs1_addr = 5'd0;
        #10;
        if (rs1_data !== 32'h0000_0000) $display("FAIL READ x0");

        $display("Register file tests completed.");
        $finish;
    end

endmodule
