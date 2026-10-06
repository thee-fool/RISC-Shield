`timescale 1ns/1ps

module aes_key_expansion (
    input  wire [127:0] key_in,
    input  wire [7:0]   rcon,
    output wire [127:0] key_out
);

    wire [31:0] w0 = key_in[127:96];
    wire [31:0] w1 = key_in[95:64];
    wire [31:0] w2 = key_in[63:32];
    wire [31:0] w3 = key_in[31:0];

    // RotWord(w3)
    wire [31:0] rot_w3 = {w3[23:0], w3[31:24]};

    // SubWord(RotWord(w3))
    wire [31:0] sub_w3;
    aes_sbox sbox0 (.in(rot_w3[31:24]), .out(sub_w3[31:24]));
    aes_sbox sbox1 (.in(rot_w3[23:16]), .out(sub_w3[23:16]));
    aes_sbox sbox2 (.in(rot_w3[15:8]),  .out(sub_w3[15:8]));
    aes_sbox sbox3 (.in(rot_w3[7:0]),   .out(sub_w3[7:0]));

    // XOR with Rcon
    wire [31:0] g_w3 = sub_w3 ^ {rcon, 24'h00_00_00};

    // Generate next 4 words
    wire [31:0] w4 = w0 ^ g_w3;
    wire [31:0] w5 = w1 ^ w4;
    wire [31:0] w6 = w2 ^ w5;
    wire [31:0] w7 = w3 ^ w6;

    assign key_out = {w4, w5, w6, w7};

endmodule
