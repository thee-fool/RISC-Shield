`timescale 1ns/1ps

module aes_add_round_key (
    input  wire [127:0] in,
    input  wire [127:0] round_key,
    output wire [127:0] out
);

    assign out = in ^ round_key;

endmodule
