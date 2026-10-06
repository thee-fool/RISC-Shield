module conv_3x3 #(
    parameter DATA_WIDTH = 32
) (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire [16*DATA_WIDTH-1:0] input_data,
    input  wire [9*DATA_WIDTH-1:0] weights,
    input  wire signed [DATA_WIDTH-1:0] bias,
    input  wire [3:0] input_rows,
    input  wire [3:0] input_cols,
    output reg  [16*DATA_WIDTH-1:0] output_data,
    output reg  output_valid,
    output wire busy
);

    localparam IDLE    = 4'd0;
    localparam CLEAR_0 = 4'd1;
    localparam CALC_0  = 4'd2;
    localparam WAIT_0  = 4'd3;
    localparam CLEAR_1 = 4'd4;
    localparam CALC_1  = 4'd5;
    localparam WAIT_1  = 4'd6;
    localparam CLEAR_2 = 4'd7;
    localparam CALC_2  = 4'd8;
    localparam WAIT_2  = 4'd9;
    localparam CLEAR_3 = 4'd10;
    localparam CALC_3  = 4'd11;
    localparam WAIT_3  = 4'd12;
    localparam SAVE_3  = 4'd13;
    localparam DONE    = 4'd14;

    reg [3:0] state;
    
    reg mac_clear;
    reg mac_enable;
    
    reg [16*DATA_WIDTH-1:0] mac_a;
    reg [16*DATA_WIDTH-1:0] mac_b;
    wire [16*2*DATA_WIDTH-1:0] mac_res;
    
    assign busy = (state != IDLE);

    mac_array_4x4 #(.DATA_WIDTH(DATA_WIDTH)) mac_arr (
        .clk(clk),
        .rst_n(rst_n),
        .clear(mac_clear),
        .enable(mac_enable),
        .a_packed(mac_a),
        .b_packed(mac_b),
        .result_packed(mac_res)
    );

    wire signed [63:0] p0 = mac_res[0*64 +: 64];
    wire signed [63:0] p1 = mac_res[1*64 +: 64];
    wire signed [63:0] p2 = mac_res[2*64 +: 64];
    wire signed [63:0] p3 = mac_res[3*64 +: 64];
    wire signed [63:0] p4 = mac_res[4*64 +: 64];
    wire signed [63:0] p5 = mac_res[5*64 +: 64];
    wire signed [63:0] p6 = mac_res[6*64 +: 64];
    wire signed [63:0] p7 = mac_res[7*64 +: 64];
    wire signed [63:0] p8 = mac_res[8*64 +: 64];
    
    wire signed [63:0] sum_all = p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8;
    wire signed [DATA_WIDTH-1:0] conv_result = (sum_all >>> 16) + bias;

    // Helper to get input data
    function [DATA_WIDTH-1:0] get_in;
        input [3:0] idx;
        begin
            get_in = input_data[idx*DATA_WIDTH +: DATA_WIDTH];
        end
    endfunction
    
    // Map weights (same for all)
    always @(*) begin
        mac_b = { {(7*DATA_WIDTH){1'b0}}, weights }; // Only 9 used
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            mac_clear <= 1'b0;
            mac_enable <= 1'b0;
            output_valid <= 1'b0;
            output_data <= 0;
            mac_a <= 0;
        end else begin
            mac_clear <= 1'b0;
            mac_enable <= 1'b0;
            output_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= CLEAR_0;
                    end
                end
                
                CLEAR_0: begin
                    mac_clear <= 1'b1;
                    state <= CALC_0;
                end
                CALC_0: begin
                    mac_a[0*DATA_WIDTH +: DATA_WIDTH] <= get_in(0);
                    mac_a[1*DATA_WIDTH +: DATA_WIDTH] <= get_in(1);
                    mac_a[2*DATA_WIDTH +: DATA_WIDTH] <= get_in(2);
                    mac_a[3*DATA_WIDTH +: DATA_WIDTH] <= get_in(4);
                    mac_a[4*DATA_WIDTH +: DATA_WIDTH] <= get_in(5);
                    mac_a[5*DATA_WIDTH +: DATA_WIDTH] <= get_in(6);
                    mac_a[6*DATA_WIDTH +: DATA_WIDTH] <= get_in(8);
                    mac_a[7*DATA_WIDTH +: DATA_WIDTH] <= get_in(9);
                    mac_a[8*DATA_WIDTH +: DATA_WIDTH] <= get_in(10);
                    mac_enable <= 1'b1;
                    state <= WAIT_0;
                end
                WAIT_0: begin
                    state <= CLEAR_1;
                end

                CLEAR_1: begin
                    output_data[0*DATA_WIDTH +: DATA_WIDTH] <= conv_result;
                    mac_clear <= 1'b1;
                    state <= CALC_1;
                end
                CALC_1: begin
                    mac_a[0*DATA_WIDTH +: DATA_WIDTH] <= get_in(1);
                    mac_a[1*DATA_WIDTH +: DATA_WIDTH] <= get_in(2);
                    mac_a[2*DATA_WIDTH +: DATA_WIDTH] <= get_in(3);
                    mac_a[3*DATA_WIDTH +: DATA_WIDTH] <= get_in(5);
                    mac_a[4*DATA_WIDTH +: DATA_WIDTH] <= get_in(6);
                    mac_a[5*DATA_WIDTH +: DATA_WIDTH] <= get_in(7);
                    mac_a[6*DATA_WIDTH +: DATA_WIDTH] <= get_in(9);
                    mac_a[7*DATA_WIDTH +: DATA_WIDTH] <= get_in(10);
                    mac_a[8*DATA_WIDTH +: DATA_WIDTH] <= get_in(11);
                    mac_enable <= 1'b1;
                    state <= WAIT_1;
                end
                WAIT_1: begin
                    state <= CLEAR_2;
                end

                CLEAR_2: begin
                    output_data[1*DATA_WIDTH +: DATA_WIDTH] <= conv_result;
                    mac_clear <= 1'b1;
                    state <= CALC_2;
                end
                CALC_2: begin
                    mac_a[0*DATA_WIDTH +: DATA_WIDTH] <= get_in(4);
                    mac_a[1*DATA_WIDTH +: DATA_WIDTH] <= get_in(5);
                    mac_a[2*DATA_WIDTH +: DATA_WIDTH] <= get_in(6);
                    mac_a[3*DATA_WIDTH +: DATA_WIDTH] <= get_in(8);
                    mac_a[4*DATA_WIDTH +: DATA_WIDTH] <= get_in(9);
                    mac_a[5*DATA_WIDTH +: DATA_WIDTH] <= get_in(10);
                    mac_a[6*DATA_WIDTH +: DATA_WIDTH] <= get_in(12);
                    mac_a[7*DATA_WIDTH +: DATA_WIDTH] <= get_in(13);
                    mac_a[8*DATA_WIDTH +: DATA_WIDTH] <= get_in(14);
                    mac_enable <= 1'b1;
                    state <= WAIT_2;
                end
                WAIT_2: begin
                    state <= CLEAR_3;
                end

                CLEAR_3: begin
                    output_data[2*DATA_WIDTH +: DATA_WIDTH] <= conv_result;
                    mac_clear <= 1'b1;
                    state <= CALC_3;
                end
                CALC_3: begin
                    mac_a[0*DATA_WIDTH +: DATA_WIDTH] <= get_in(5);
                    mac_a[1*DATA_WIDTH +: DATA_WIDTH] <= get_in(6);
                    mac_a[2*DATA_WIDTH +: DATA_WIDTH] <= get_in(7);
                    mac_a[3*DATA_WIDTH +: DATA_WIDTH] <= get_in(9);
                    mac_a[4*DATA_WIDTH +: DATA_WIDTH] <= get_in(10);
                    mac_a[5*DATA_WIDTH +: DATA_WIDTH] <= get_in(11);
                    mac_a[6*DATA_WIDTH +: DATA_WIDTH] <= get_in(13);
                    mac_a[7*DATA_WIDTH +: DATA_WIDTH] <= get_in(14);
                    mac_a[8*DATA_WIDTH +: DATA_WIDTH] <= get_in(15);
                    mac_enable <= 1'b1;
                    state <= WAIT_3;
                end
                WAIT_3: begin
                    state <= SAVE_3;
                end
                
                SAVE_3: begin
                    output_data[3*DATA_WIDTH +: DATA_WIDTH] <= conv_result;
                    state <= DONE;
                end

                DONE: begin
                    output_valid <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
