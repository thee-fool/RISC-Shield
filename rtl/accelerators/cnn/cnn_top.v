module cnn_top (
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

    // Register File
    reg [31:0] cnn_cfg0;
    reg [31:0] cnn_cfg1;
    reg [31:0] cnn_bias;
    reg [31:0] cnn_weights [0:8];
    reg [31:0] cnn_input   [0:15];
    reg [31:0] cnn_output  [0:15];

    // Control signals
    reg  start_req;
    reg  clear_req;
    wire fsm_done;
    wire fsm_busy;
    wire fsm_error;
    wire [2:0] fsm_state;

    wire conv_done;
    wire conv_busy;
    wire pool_done;

    wire conv_start;
    wire pool_enable;

    // Packed arrays for wiring
    wire [16*32-1:0] input_packed;
    wire [9*32-1:0]  weights_packed;
    wire [16*32-1:0] conv_out_packed;
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pack_in
            assign input_packed[i*32 +: 32] = cnn_input[i];
        end
        for (i = 0; i < 9; i = i + 1) begin : pack_w
            assign weights_packed[i*32 +: 32] = cnn_weights[i];
        end
    endgenerate

    // Sub-modules
    cnn_control_fsm fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_req),
        .clear(clear_req),
        .conv_done(conv_done),
        .pool_done(pool_done),
        .conv_start(conv_start),
        .pool_enable(pool_enable),
        .state(fsm_state),
        .done(fsm_done),
        .busy(fsm_busy),
        .error(fsm_error)
    );

    conv_3x3 #(.DATA_WIDTH(32)) conv (
        .clk(clk),
        .rst_n(rst_n),
        .start(conv_start),
        .input_data(input_packed),
        .weights(weights_packed),
        .bias(cnn_bias),
        .input_rows(cnn_cfg0[31:16]),
        .input_cols(cnn_cfg0[15:0]),
        .output_data(conv_out_packed),
        .output_valid(conv_done),
        .busy(conv_busy)
    );

    wire signed [31:0] r0, r1, r2, r3;
    relu #(.DATA_WIDTH(32)) u_relu0 (.data_in(conv_out_packed[0*32+:32]), .data_out(r0));
    relu #(.DATA_WIDTH(32)) u_relu1 (.data_in(conv_out_packed[1*32+:32]), .data_out(r1));
    relu #(.DATA_WIDTH(32)) u_relu2 (.data_in(conv_out_packed[2*32+:32]), .data_out(r2));
    relu #(.DATA_WIDTH(32)) u_relu3 (.data_in(conv_out_packed[3*32+:32]), .data_out(r3));

    wire signed [31:0] pool_out;
    maxpool_2x2 #(.DATA_WIDTH(32)) u_pool (
        .clk(clk),
        .rst_n(rst_n),
        .enable(pool_enable),
        .in0(r0),
        .in1(r1),
        .in2(r2),
        .in3(r3),
        .data_out(pool_out),
        .valid(pool_done)
    );

    // Save pooling output to output register
    always @(posedge clk) begin
        if (pool_done) begin
            cnn_output[0] <= pool_out;
        end
    end

    // Bus interface handling
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_ready <= 1'b0;
            bus_rdata <= 32'h0;
            cnn_cfg0 <= 32'h0004_0004; // default 4x4
            cnn_cfg1 <= 32'h0;
            cnn_bias <= 32'h0;
            start_req <= 1'b0;
            clear_req <= 1'b0;
            for (j = 0; j < 9; j = j + 1) cnn_weights[j] <= 32'h0;
            for (j = 0; j < 16; j = j + 1) cnn_input[j] <= 32'h0;
            for (j = 0; j < 16; j = j + 1) cnn_output[j] <= 32'h0;
        end else begin
            start_req <= 1'b0;
            clear_req <= 1'b0;
            
            if (bus_valid && !bus_ready) begin
                bus_ready <= 1'b1;
                
                if (bus_wen) begin
                    if (bus_addr[7:0] == 8'h00) begin
                        start_req <= bus_wdata[0];
                        clear_req <= bus_wdata[1];
                    end else if (bus_addr[7:0] == 8'h08) begin
                        cnn_cfg0 <= bus_wdata;
                    end else if (bus_addr[7:0] == 8'h0C) begin
                        cnn_cfg1 <= bus_wdata;
                    end else if (bus_addr[7:0] >= 8'h10 && bus_addr[7:0] <= 8'h30) begin
                        cnn_weights[(bus_addr[7:0] - 8'h10) >> 2] <= bus_wdata;
                    end else if (bus_addr[7:0] == 8'h38) begin
                        cnn_bias <= bus_wdata;
                    end else if (bus_addr[7:0] >= 8'h40 && bus_addr[7:0] <= 8'h7C) begin
                        cnn_input[(bus_addr[7:0] - 8'h40) >> 2] <= bus_wdata;
                    end
                end else begin
                    // Read
                    if (bus_addr[7:0] == 8'h00) begin
                        bus_rdata <= 32'h0;
                    end else if (bus_addr[7:0] == 8'h04) begin
                        bus_rdata <= {26'd0, fsm_state, fsm_error, fsm_done, fsm_busy};
                    end else if (bus_addr[7:0] == 8'h08) begin
                        bus_rdata <= cnn_cfg0;
                    end else if (bus_addr[7:0] == 8'h0C) begin
                        bus_rdata <= cnn_cfg1;
                    end else if (bus_addr[7:0] >= 8'h10 && bus_addr[7:0] <= 8'h30) begin
                        bus_rdata <= cnn_weights[(bus_addr[7:0] - 8'h10) >> 2];
                    end else if (bus_addr[7:0] == 8'h38) begin
                        bus_rdata <= cnn_bias;
                    end else if (bus_addr[7:0] >= 8'h40 && bus_addr[7:0] <= 8'h7C) begin
                        bus_rdata <= cnn_input[(bus_addr[7:0] - 8'h40) >> 2];
                    end else if (bus_addr[7:0] >= 8'h80 && bus_addr[7:0] <= 8'hBC) begin
                        bus_rdata <= cnn_output[(bus_addr[7:0] - 8'h80) >> 2];
                    end else begin
                        bus_rdata <= 32'h0;
                    end
                end
            end else begin
                bus_ready <= 1'b0;
            end
        end
    end

endmodule
