`timescale 1ns/1ps

module aes_top (
    input  wire        clk,
    input  wire        rst_n,
    
    // Bus Interface
    input  wire [31:0] bus_addr,
    input  wire [31:0] bus_wdata,
    input  wire        bus_wen,
    input  wire        bus_valid,
    output reg  [31:0] bus_rdata,
    output reg         bus_ready
);

    // Register Map
    // 0x00: AES_CTRL   (Bit 0: Start, Bit 1: Soft Reset)
    // 0x04: AES_STATUS (Bit 0: Busy, Bit 1: Done)
    // 0x10-0x1C: AES_KEY[0..3]
    // 0x20-0x2C: AES_PLAIN[0..3]
    // 0x30-0x3C: AES_CIPHER[0..3]

    reg  [31:0] aes_ctrl;
    reg  [31:0] aes_key   [0:3];
    reg  [31:0] aes_plain [0:3];
    
    wire [1:0]  aes_status;
    wire [127:0] cipher_out;

    wire start = aes_ctrl[0];
    wire soft_reset = aes_ctrl[1];
    
    wire rst_n_int = rst_n & ~soft_reset;
    
    // Status signals
    wire busy, done;
    assign aes_status = {14'd0, done, busy};

    // Datapath registers
    reg  [127:0] state_reg;
    reg  [127:0] current_key;
    
    wire [127:0] key_in = {aes_key[0], aes_key[1], aes_key[2], aes_key[3]};
    wire [127:0] plain_in = {aes_plain[0], aes_plain[1], aes_plain[2], aes_plain[3]};
    
    wire [127:0] next_key;
    wire [127:0] round_out;
    
    wire [3:0] round_idx;
    wire       is_final_round;
    wire [7:0] rcon;
    wire       load_initial_key;
    wire       update_state;

    // FSM
    aes_control_fsm fsm (
        .clk(clk),
        .rst_n(rst_n_int),
        .start(start),
        .busy(busy),
        .done(done),
        .round_idx(round_idx),
        .is_final_round(is_final_round),
        .rcon(rcon),
        .load_initial_key(load_initial_key),
        .update_state(update_state)
    );

    // Key Expansion
    aes_key_expansion key_expand (
        .key_in(current_key),
        .rcon(rcon),
        .key_out(next_key)
    );

    // Round Logic
    // In round 0, the state is just XORed with the initial key (AddRoundKey)
    wire [127:0] round_in = (round_idx == 0) ? plain_in : state_reg;
    wire [127:0] round_key = next_key;

    wire [127:0] add_round_key_out;
    aes_add_round_key initial_add_key (
        .in(plain_in),
        .round_key(key_in),
        .out(add_round_key_out)
    );

    // The actual AES round module
    aes_round aes_rnd (
        .in(round_in),
        .round_key(round_key),
        .is_final_round(is_final_round),
        .out(round_out)
    );

    // State update logic
    always @(posedge clk or negedge rst_n_int) begin
        if (!rst_n_int) begin
            state_reg <= 128'd0;
            current_key <= 128'd0;
        end else if (load_initial_key) begin
            state_reg <= add_round_key_out; // Initial AddRoundKey
            current_key <= key_in;
        end else if (update_state && round_idx > 0) begin
            state_reg <= round_out;
            current_key <= next_key;
        end
    end

    assign cipher_out = state_reg;

    // Bus Write Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aes_ctrl <= 32'd0;
            aes_key[0] <= 32'd0; aes_key[1] <= 32'd0; aes_key[2] <= 32'd0; aes_key[3] <= 32'd0;
            aes_plain[0] <= 32'd0; aes_plain[1] <= 32'd0; aes_plain[2] <= 32'd0; aes_plain[3] <= 32'd0;
        end else begin
            if (bus_valid && bus_wen && bus_ready) begin
                case (bus_addr[7:0])
                    8'h00: aes_ctrl <= bus_wdata;
                    8'h10: aes_key[0] <= bus_wdata;
                    8'h14: aes_key[1] <= bus_wdata;
                    8'h18: aes_key[2] <= bus_wdata;
                    8'h1C: aes_key[3] <= bus_wdata;
                    8'h20: aes_plain[0] <= bus_wdata;
                    8'h24: aes_plain[1] <= bus_wdata;
                    8'h28: aes_plain[2] <= bus_wdata;
                    8'h2C: aes_plain[3] <= bus_wdata;
                endcase
            end
            
            // Auto-clear start bit
            if (aes_ctrl[0] && busy) begin
                aes_ctrl[0] <= 1'b0;
            end
            
            // Auto-clear soft reset
            if (aes_ctrl[1]) begin
                aes_ctrl[1] <= 1'b0;
            end
        end
    end

    // Bus Read Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_rdata <= 32'd0;
            bus_ready <= 1'b0;
        end else begin
            if (bus_valid && !bus_ready) begin
                bus_ready <= 1'b1;
                if (!bus_wen) begin
                    case (bus_addr[7:0])
                        8'h00: bus_rdata <= aes_ctrl;
                        8'h04: bus_rdata <= {30'd0, aes_status};
                        8'h10: bus_rdata <= aes_key[0];
                        8'h14: bus_rdata <= aes_key[1];
                        8'h18: bus_rdata <= aes_key[2];
                        8'h1C: bus_rdata <= aes_key[3];
                        8'h20: bus_rdata <= aes_plain[0];
                        8'h24: bus_rdata <= aes_plain[1];
                        8'h28: bus_rdata <= aes_plain[2];
                        8'h2C: bus_rdata <= aes_plain[3];
                        8'h30: bus_rdata <= cipher_out[127:96];
                        8'h34: bus_rdata <= cipher_out[95:64];
                        8'h38: bus_rdata <= cipher_out[63:32];
                        8'h3C: bus_rdata <= cipher_out[31:0];
                        default: bus_rdata <= 32'd0;
                    endcase
                end
            end else begin
                bus_ready <= 1'b0;
            end
        end
    end

endmodule
