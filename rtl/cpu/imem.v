module imem #(
    parameter DEPTH = 1024 // 4KB instruction memory
) (
    input  wire        clk,
    
    // Port 1: Instruction Fetch (Asynchronous read)
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_rdata,

    // Port 2: Data Bus Slave Interface (Synchronous read)
    input  wire [31:0] bus_addr,
    input  wire        bus_valid,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready
);

    reg [31:0] mem [0:DEPTH-1];
    
    // Port 1: Combinational read for CPU fetch
    assign instr_rdata = mem[instr_addr[11:2]];

    // Port 2: Synchronous read for Data Bus
    wire [9:0] bus_word_addr = bus_addr[11:2];

    always @(posedge clk) begin
        if (bus_valid && !bus_ready) begin
            bus_rdata <= mem[bus_word_addr];
            bus_ready <= 1'b1;
        end else begin
            bus_ready <= 1'b0;
        end
    end

endmodule
