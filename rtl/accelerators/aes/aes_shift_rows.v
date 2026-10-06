`timescale 1ns/1ps

module aes_shift_rows (
    input  wire [127:0] in,
    output wire [127:0] out
);

    // Byte mapping (Big Endian convention)
    // b0  = in[127:120], b4  = in[95:88], b8  = in[63:56], b12 = in[31:24]
    // b1  = in[119:112], b5  = in[87:80], b9  = in[55:48], b13 = in[23:16]
    // b2  = in[111:104], b6  = in[79:72], b10 = in[47:40], b14 = in[15:8]
    // b3  = in[103:96],  b7  = in[71:64], b11 = in[39:32], b15 = in[7:0]

    // Row 0: no shift (b0, b4, b8, b12)
    // Row 1: shift 1  (b5, b9, b13, b1)
    // Row 2: shift 2  (b10, b14, b2, b6)
    // Row 3: shift 3  (b15, b3, b7, b11)

    // Column 0
    assign out[127:120] = in[127:120]; // b0
    assign out[119:112] = in[87:80];   // b5
    assign out[111:104] = in[47:40];   // b10
    assign out[103:96]  = in[7:0];     // b15

    // Column 1
    assign out[95:88]   = in[95:88];   // b4
    assign out[87:80]   = in[55:48];   // b9
    assign out[79:72]   = in[15:8];    // b14
    assign out[71:64]   = in[103:96];  // b3

    // Column 2
    assign out[63:56]   = in[63:56];   // b8
    assign out[55:48]   = in[23:16];   // b13
    assign out[47:40]   = in[111:104]; // b2
    assign out[39:32]   = in[71:64];   // b7

    // Column 3
    assign out[31:24]   = in[31:24];   // b12
    assign out[23:16]   = in[119:112]; // b1
    assign out[15:8]    = in[79:72];   // b6
    assign out[7:0]     = in[39:32];   // b11

endmodule
