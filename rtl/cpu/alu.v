module alu (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,
    
    output reg  [31:0] result,
    output wire        zero_flag
);

    always @(*) begin
        case (alu_op)
            4'b0000: result = operand_a + operand_b;                              // ADD
            4'b0001: result = operand_a - operand_b;                              // SUB
            4'b0010: result = operand_a & operand_b;                              // AND
            4'b0011: result = operand_a | operand_b;                              // OR
            4'b0100: result = operand_a ^ operand_b;                              // XOR
            4'b0101: result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0; // SLT
            4'b0110: result = operand_b; // PASS_B (used for LUI)
            default: result = 32'd0;
        endcase
    end

    // Zero flag used for branch evaluation (BEQ uses SUB)
    assign zero_flag = (result == 32'd0);

endmodule
