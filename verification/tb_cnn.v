`timescale 1ns/1ps
module tb_cnn;
    reg clk;
    reg rst_n;
    
    reg [31:0] bus_addr;
    reg [31:0] bus_wdata;
    reg        bus_wen;
    reg        bus_valid;
    wire [31:0] bus_rdata;
    wire       bus_ready;

    cnn_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_wen(bus_wen),
        .bus_valid(bus_valid),
        .bus_rdata(bus_rdata),
        .bus_ready(bus_ready)
    );

    always #5 clk = ~clk;

    task write_reg(input [7:0] addr, input [31:0] data);
        begin
            bus_addr = {24'h500000, addr};
            bus_wdata = data;
            bus_wen = 1;
            bus_valid = 1;
            wait(bus_ready);
            @(posedge clk);
            bus_valid = 0;
            bus_wen = 0;
            @(posedge clk);
        end
    endtask

    task read_reg(input [7:0] addr, output [31:0] data);
        begin
            bus_addr = {24'h500000, addr};
            bus_wen = 0;
            bus_valid = 1;
            wait(bus_ready);
            data = bus_rdata;
            @(posedge clk);
            bus_valid = 0;
            @(posedge clk);
        end
    endtask

    integer i;
    reg [31:0] read_val;

    initial begin
        $dumpfile("waveforms/tb_cnn.vcd");
        $dumpvars(0, tb_cnn);

        clk = 0;
        rst_n = 0;
        bus_valid = 0;
        bus_wen = 0;
        
        #15 rst_n = 1;
        
        // Write 9 weights (1.0 in Q16.16)
        for (i = 0; i < 9; i = i + 1) begin
            write_reg(8'h14 + i*4, 32'h0001_0000);
        end
        
        // Write 16 inputs (1.0 in Q16.16)
        for (i = 0; i < 16; i = i + 1) begin
            write_reg(8'h40 + i*4, 32'h0001_0000);
        end
        
        // Start CNN
        write_reg(8'h00, 32'h1);
        
        // Poll for done
        read_val = 0;
        while ((read_val & 32'h2) == 0) begin
            read_reg(8'h04, read_val);
        end
        
        // Read result (CNN_OUTPUT[0] at offset 0x80)
        read_reg(8'h80, read_val);
        if (read_val !== 32'h0009_0000) begin
            $display("FAIL: Expected 0x00090000, got %h", read_val);
        end else begin
            $display("PASS: CNN Output is correct (%h)", read_val);
        end
        
        $finish;
    end
endmodule
