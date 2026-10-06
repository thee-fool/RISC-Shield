`timescale 1ns/1ps

module aes_control_fsm (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    
    output reg         busy,
    output reg         done,
    output wire [3:0]  round_idx,
    output reg         is_final_round,
    output reg  [7:0]  rcon,
    
    // Datapath controls
    output reg         load_initial_key,
    output reg         update_state
);

    parameter IDLE    = 2'd0;
    parameter ROUND   = 2'd1;
    parameter FINISH  = 2'd2;
    
    reg [1:0] state, next_state;
    reg [3:0] round_cnt, next_round_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            round_cnt <= 4'd0;
        end else begin
            state <= next_state;
            round_cnt <= next_round_cnt;
        end
    end
    
    always @(*) begin
        next_state = state;
        next_round_cnt = round_cnt;
        
        busy = 1'b0;
        done = 1'b0;
        is_final_round = 1'b0;
        load_initial_key = 1'b0;
        update_state = 1'b0;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = ROUND;
                    next_round_cnt = 4'd1;
                    busy = 1'b1;
                    load_initial_key = 1'b1;
                    update_state = 1'b1;
                end
            end
            
            ROUND: begin
                busy = 1'b1;
                update_state = 1'b1;
                
                if (round_cnt == 4'd10) begin
                    is_final_round = 1'b1;
                    next_state = FINISH;
                end else begin
                    next_round_cnt = round_cnt + 4'd1;
                end
            end
            
            FINISH: begin
                done = 1'b1;
                // Wait in FINISH state until a new start command is issued
                if (start) begin
                    next_state = ROUND;
                    next_round_cnt = 4'd1;
                    busy = 1'b1;
                    load_initial_key = 1'b1;
                    update_state = 1'b1;
                    done = 1'b0;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    assign round_idx = round_cnt;

    // Rcon lookup for key expansion (rounds 1 to 10)
    always @(*) begin
        case (round_cnt)
            4'd1:  rcon = 8'h01;
            4'd2:  rcon = 8'h02;
            4'd3:  rcon = 8'h04;
            4'd4:  rcon = 8'h08;
            4'd5:  rcon = 8'h10;
            4'd6:  rcon = 8'h20;
            4'd7:  rcon = 8'h40;
            4'd8:  rcon = 8'h80;
            4'd9:  rcon = 8'h1b;
            4'd10: rcon = 8'h36;
            default: rcon = 8'h00;
        endcase
    end

endmodule
