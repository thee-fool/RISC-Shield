module dmem #(
    parameter DEPTH = 4096 // 16KB data memory
) (
    input  wire        clk,
    input  wire        rst_n,
    
    // Bus interface
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,
    input  wire        bus_wen,
    input  wire        bus_valid,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready
);

    // Memory array
    reg [31:0] mem [0:DEPTH-1];

    // Initialize to 0
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'h0000_0000;
        end
    end

    // Word address (ignore lower 2 bits of byte address)
    // Extract the local offset. For DMEM, region is 0x1, so use addr[13:2]
    wire [11:0] word_addr = bus_addr[13:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_ready <= 1'b0;
            bus_rdata <= 32'h0000_0000;
        end else begin
            if (bus_valid && !bus_ready) begin
                if (bus_wen) begin
                    mem[word_addr] <= bus_wdata;
                end else begin
                    bus_rdata <= mem[word_addr];
                end
                // Complete transaction next cycle
                bus_ready <= 1'b1;
            end else begin
                // De-assert ready if valid goes low, or finish handshake
                bus_ready <= 1'b0;
            end
        end
    end

endmodule
