module control_unit (
    input  wire [31:0] instruction,
    input  wire        zero_flag,
    
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         alu_src,
    output reg         branch,
    output reg         jump,
    output reg  [3:0]  alu_op
);

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    always @(*) begin
        // Default control signal values
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 4'b0000;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_src   = 1'b0; // Use rs2
                
                // ALU operation decode
                if (funct3 == 3'b000) begin
                    if (funct7 == 7'b0000000) alu_op = 4'b0000; // ADD
                    else                      alu_op = 4'b0001; // SUB
                end else if (funct3 == 3'b111) begin
                    alu_op = 4'b0010; // AND
                end else if (funct3 == 3'b110) begin
                    alu_op = 4'b0011; // OR
                end else if (funct3 == 3'b100) begin
                    alu_op = 4'b0100; // XOR
                end else if (funct3 == 3'b010) begin
                    alu_op = 4'b0101; // SLT
                end
            end

            7'b0010011: begin // I-type
                reg_write = 1'b1;
                alu_src   = 1'b1; // Use immediate
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI -> ADD
                    3'b111: alu_op = 4'b0010; // ANDI -> AND
                    3'b110: alu_op = 4'b0011; // ORI -> OR
                    3'b100: alu_op = 4'b0100; // XORI -> XOR
                    3'b010: alu_op = 4'b0101; // SLTI -> SLT
                    default: alu_op = 4'b0000;
                endcase
            end

            7'b0110111: begin // U-type (LUI)
                reg_write = 1'b1;
                alu_src   = 1'b1; // Use immediate
                alu_op    = 4'b0110; // PASS_B
            end

            7'b0000011: begin // I-type Load (LW)
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1; // Use immediate for address calculation
                alu_op     = 4'b0000; // ADD
            end

            7'b0100011: begin // S-type Store (SW)
                mem_write = 1'b1;
                alu_src   = 1'b1; // Use immediate for address calculation
                alu_op    = 4'b0000; // ADD
            end

            7'b1100011: begin // B-type Branch (BEQ)
                branch    = 1'b1;
                alu_src   = 1'b0; // Use rs2 for comparison
                alu_op    = 4'b0001; // SUB (used for equality check with zero_flag)
            end

            7'b1101111: begin // J-type Jump (JAL)
                reg_write = 1'b1;
                jump      = 1'b1;
                // alu_src, alu_op don't matter as write_back selects pc+4 directly when jump=1
            end

            default: ; // Default values apply
        endcase
    end

endmodule
