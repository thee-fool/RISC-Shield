`timescale 1ns/1ps

module aes_sub_bytes (
    input  wire [127:0] in,
    output wire [127:0] out
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : sbox_gen
            aes_sbox sbox_inst (
                .in(in[(i*8)+7 : i*8]),
                .out(out[(i*8)+7 : i*8])
            );
        end
    endgenerate

endmodule
