module imm_gen (
    input  wire [31:0] instruction,
    output reg  [31:0] imm_out
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011, // I-type (ADDI)
            7'b0000011: // I-type (LW)
                imm_out = {{20{instruction[31]}}, instruction[31:20]};

            7'b0100011: // S-type (SW)
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            7'b1100011: // B-type (BEQ)
                imm_out = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            7'b1101111: // J-type (JAL)
                imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

            7'b0110111: // U-type (LUI)
                imm_out = {instruction[31:12], 12'b0};

            default:
                imm_out = 32'd0;
        endcase
    end

endmodule
