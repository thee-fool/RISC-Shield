`timescale 1ns/1ps

module tb_alu;

    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [3:0]  alu_op;
    wire [31:0] result;
    wire        zero_flag;

    alu uut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_op(alu_op),
        .result(result),
        .zero_flag(zero_flag)
    );

    initial begin
        $dumpfile("waveforms/tb_alu.vcd");
        $dumpvars(0, tb_alu);

        // Test ADD
        operand_a = 32'd10; operand_b = 32'd20; alu_op = 4'b0000; #10;
        if (result !== 32'd30) $display("FAIL ADD");
        
        // Test SUB
        operand_a = 32'd50; operand_b = 32'd20; alu_op = 4'b0001; #10;
        if (result !== 32'd30) $display("FAIL SUB");

        // Test SUB (Negative result, wait, it's unsigned representation, but bits should match 2's complement)
        operand_a = 32'd10; operand_b = 32'd20; alu_op = 4'b0001; #10;
        if (result !== -32'd10) $display("FAIL SUB NEGATIVE");

        // Test AND
        operand_a = 32'h0F0F_0F0F; operand_b = 32'hFFFF_0000; alu_op = 4'b0010; #10;
        if (result !== 32'h0F0F_0000) $display("FAIL AND");

        // Test OR
        operand_a = 32'h0F0F_0F0F; operand_b = 32'hFFFF_0000; alu_op = 4'b0011; #10;
        if (result !== 32'hFFFF_0F0F) $display("FAIL OR");

        // Test XOR
        operand_a = 32'h0F0F_0F0F; operand_b = 32'hFFFF_0000; alu_op = 4'b0100; #10;
        if (result !== 32'hF0F0_0F0F) $display("FAIL XOR");

        // Test SLT (Positive < Positive)
        operand_a = 32'd10; operand_b = 32'd20; alu_op = 4'b0101; #10;
        if (result !== 32'd1) $display("FAIL SLT 1");

        // Test SLT (Positive > Positive)
        operand_a = 32'd20; operand_b = 32'd10; alu_op = 4'b0101; #10;
        if (result !== 32'd0) $display("FAIL SLT 2");

        // Test SLT (Negative < Positive)
        operand_a = -32'd10; operand_b = 32'd20; alu_op = 4'b0101; #10;
        if (result !== 32'd1) $display("FAIL SLT 3");

        // Test SLT (Positive > Negative)
        operand_a = 32'd10; operand_b = -32'd20; alu_op = 4'b0101; #10;
        if (result !== 32'd0) $display("FAIL SLT 4");

        // Test Zero Flag
        operand_a = 32'd10; operand_b = 32'd10; alu_op = 4'b0001; #10;
        if (result !== 32'd0 || zero_flag !== 1'b1) $display("FAIL ZERO FLAG");

        $display("ALU tests completed.");
        $finish;
    end

endmodule
