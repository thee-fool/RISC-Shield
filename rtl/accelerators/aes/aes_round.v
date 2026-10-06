`timescale 1ns/1ps

module aes_round (
    input  wire [127:0] in,
    input  wire [127:0] round_key,
    input  wire         is_final_round,
    output wire [127:0] out
);

    wire [127:0] sub_bytes_out;
    wire [127:0] shift_rows_out;
    wire [127:0] mix_columns_out;
    wire [127:0] add_round_key_in;

    aes_sub_bytes sub_bytes_inst (
        .in(in),
        .out(sub_bytes_out)
    );

    aes_shift_rows shift_rows_inst (
        .in(sub_bytes_out),
        .out(shift_rows_out)
    );

    aes_mix_columns mix_columns_inst (
        .in(shift_rows_out),
        .out(mix_columns_out)
    );

    // Final round skips MixColumns
    assign add_round_key_in = is_final_round ? shift_rows_out : mix_columns_out;

    aes_add_round_key add_round_key_inst (
        .in(add_round_key_in),
        .round_key(round_key),
        .out(out)
    );

endmodule
