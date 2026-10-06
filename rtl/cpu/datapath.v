module datapath (
    input  wire        clk,
    input  wire        rst_n,
    
    // Instruction Fetch Interface
    output wire [31:0] instr_addr,
    input  wire [31:0] instr_rdata,

    // Bus Interface
    output wire [31:0] bus_addr,
    output wire [31:0] bus_wdata,
    input  wire [31:0] bus_rdata,
    output wire        bus_wen,
    output wire        bus_valid,
    input  wire        bus_ready
);

    // Internal wires
    wire [31:0] pc_out;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_target;
    wire [31:0] pc_next;
    
    wire [31:0] instruction = instr_rdata;
    
    // Control signals
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        alu_src;
    wire        branch;
    wire        jump;
    wire [3:0]  alu_op;
    
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] rd_data_wb;
    wire [31:0] rd_data_final;
    
    wire [31:0] imm_out;
    
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        zero_flag;
    
    // Enable stall if waiting for bus (though memory accesses are supposed to be single-cycle, this makes it robust)
    // Wait, the specification says single cycle, so bus_ready should be ignored or used to stall PC.
    // Let's implement PC stall when bus_valid && !bus_ready.
    wire stall = (bus_valid && !bus_ready);
    
    wire [31:0] pc_next_stall = stall ? pc_out : pc_next;

    // --- Sub-module instantiations ---
    
    pc pc_reg (
        .clk(clk),
        .rst_n(rst_n),
        .pc_next(pc_next_stall),
        .pc_out(pc_out)
    );
    
    assign instr_addr = pc_out;
    
    control_unit ctrl (
        .instruction(instruction),
        .zero_flag(zero_flag),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op)
    );
    
    register_file reg_file (
        .clk(clk),
        .rs1_addr(instruction[19:15]),
        .rs2_addr(instruction[24:20]),
        .rd_addr(instruction[11:7]),
        .rd_data(rd_data_final),
        .reg_write(reg_write && !stall),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    
    imm_gen imm_generator (
        .instruction(instruction),
        .imm_out(imm_out)
    );
    
    alu alu_unit (
        .operand_a(rs1_data),
        .operand_b(alu_operand_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero_flag(zero_flag)
    );
    
    // --- Datapath Logic ---
    
    // PC calculation
    assign pc_plus_4 = pc_out + 32'd4;
    assign pc_target = pc_out + imm_out;
    assign pc_next   = (jump || (branch && zero_flag)) ? pc_target : pc_plus_4;
    
    // ALU operand B mux
    assign alu_operand_b = alu_src ? imm_out : rs2_data;
    
    // Write-back muxes
    assign rd_data_wb    = mem_to_reg ? bus_rdata : alu_result;
    assign rd_data_final = jump ? pc_plus_4 : rd_data_wb;
    
    // --- Bus Interface ---
    
    // Memory address comes from ALU result (calculated via base + offset)
    assign bus_addr  = alu_result;
    // Data to write comes from rs2
    assign bus_wdata = rs2_data;
    
    assign bus_wen   = mem_write;
    // Valid when either reading or writing memory
    assign bus_valid = mem_read || mem_write;

endmodule
