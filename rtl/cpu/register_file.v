module register_file (
    input  wire        clk,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    input  wire        reg_write,
    
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    // 32 registers of 32 bits each
    reg [31:0] registers [0:31];

    // Initialize registers to 0 for simulation predictability
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'h0000_0000;
        end
    end

    // Asynchronous read
    // x0 is hardwired to 0
    assign rs1_data = (rs1_addr == 5'b0) ? 32'h0000_0000 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'h0000_0000 : registers[rs2_addr];

    // Synchronous write
    always @(posedge clk) begin
        if (reg_write && (rd_addr != 5'b0)) begin
            registers[rd_addr] <= rd_data;
        end
    end

endmodule
