module cnn_control_fsm (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire clear,
    
    input  wire conv_done,
    input  wire pool_done,
    
    output reg  conv_start,
    output reg  pool_enable,
    output reg  [2:0] state,
    output wire done,
    output wire busy,
    output reg  error
);
    localparam IDLE = 3'd0;
    localparam CONV = 3'd1;
    localparam RELU = 3'd2; // Will fall through to POOL
    localparam POOL = 3'd3;
    localparam DONE = 3'd4;
    
    assign busy = (state != IDLE && state != DONE);
    assign done = (state == DONE);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            conv_start <= 1'b0;
            pool_enable <= 1'b0;
            error <= 1'b0;
        end else begin
            conv_start <= 1'b0;
            pool_enable <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= CONV;
                        conv_start <= 1'b1;
                        error <= 1'b0;
                    end
                end
                CONV: begin
                    if (conv_done) begin
                        state <= RELU;
                    end
                end
                RELU: begin
                    state <= POOL;
                    pool_enable <= 1'b1;
                end
                POOL: begin
                    if (pool_done) begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    if (clear) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
