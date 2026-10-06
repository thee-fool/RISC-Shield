`timescale 1ns/1ps

module aes_mix_columns (
    input  wire [127:0] in,
    output wire [127:0] out
);

    // Multiplication by 2 in GF(2^8)
    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = (x << 1) ^ (x[7] ? 8'h1b : 8'h00);
        end
    endfunction

    // Multiplication by 3 in GF(2^8)
    function [7:0] mul3;
        input [7:0] x;
        begin
            mul3 = xtime(x) ^ x;
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : col_gen
            wire [7:0] b0 = in[127 - (i*32) - 0*8 : 120 - (i*32)];
            wire [7:0] b1 = in[127 - (i*32) - 1*8 : 120 - (i*32) - 1*8];
            wire [7:0] b2 = in[127 - (i*32) - 2*8 : 120 - (i*32) - 2*8];
            wire [7:0] b3 = in[127 - (i*32) - 3*8 : 120 - (i*32) - 3*8];
            
            wire [7:0] out0 = xtime(b0) ^ mul3(b1) ^ b2 ^ b3;
            wire [7:0] out1 = b0 ^ xtime(b1) ^ mul3(b2) ^ b3;
            wire [7:0] out2 = b0 ^ b1 ^ xtime(b2) ^ mul3(b3);
            wire [7:0] out3 = mul3(b0) ^ b1 ^ b2 ^ xtime(b3);
            
            assign out[127 - (i*32) - 0*8 : 120 - (i*32)] = out0;
            assign out[127 - (i*32) - 1*8 : 120 - (i*32) - 1*8] = out1;
            assign out[127 - (i*32) - 2*8 : 120 - (i*32) - 2*8] = out2;
            assign out[127 - (i*32) - 3*8 : 120 - (i*32) - 3*8] = out3;
        end
    endgenerate

endmodule
