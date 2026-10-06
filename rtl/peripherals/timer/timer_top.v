module timer_top (
    input  wire        clk,
    input  wire        rst_n,

    // Bus interface
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,
    input  wire        bus_wen,
    input  wire        bus_valid,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready,

    // Interrupt
    output wire        timer_irq
);

    // Registers
    reg [31:0] count;
    reg [31:0] cmp;
    reg        enable;
    reg        reload_en;
    reg        irq_en;
    reg        match;

    assign timer_irq = irq_en && match;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            cmp <= 32'hFFFF_FFFF;
            enable <= 1'b0;
            reload_en <= 1'b0;
            irq_en <= 1'b0;
            match <= 1'b0;
            bus_ready <= 1'b0;
            bus_rdata <= 32'd0;
        end else begin
            // Default: no bus response
            bus_ready <= 1'b0;
            
            // Bus interface
            if (bus_valid && !bus_ready) begin
                bus_ready <= 1'b1;
                if (bus_wen) begin
                    case (bus_addr[3:0])
                        4'h0: begin // TIMER_CTRL
                            enable <= bus_wdata[0];
                            reload_en <= bus_wdata[1];
                            irq_en <= bus_wdata[2];
                        end
                        4'h4: begin // TIMER_COUNT
                            count <= bus_wdata;
                        end
                        4'h8: begin // TIMER_CMP
                            cmp <= bus_wdata;
                        end
                        4'hC: begin // TIMER_STATUS
                            if (bus_wdata[0]) match <= 1'b0; // W1C
                        end
                    endcase
                end else begin // Read
                    case (bus_addr[3:0])
                        4'h0: bus_rdata <= {29'd0, irq_en, reload_en, enable};
                        4'h4: bus_rdata <= count;
                        4'h8: bus_rdata <= cmp;
                        4'hC: bus_rdata <= {31'd0, match};
                        default: bus_rdata <= 32'd0;
                    endcase
                end
            end

            // Timer logic
            if (enable) begin
                if (count == cmp) begin
                    match <= 1'b1;
                    if (reload_en) begin
                        count <= 32'd0;
                    end
                end else begin
                    // Only increment if we didn't just write to count this cycle
                    if (!(bus_valid && !bus_ready && bus_wen && bus_addr[3:0] == 4'h4)) begin
                        count <= count + 32'd1;
                    end
                end
            end
        end
    end

endmodule
