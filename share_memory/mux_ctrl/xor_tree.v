`timescale 1ns/1ns

module xor_tree
#(
    parameter   N = 8
)
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire    [N-1 : 0]           in,
    output  wire                        out
);

generate
    if(N == 2)begin
        assign out = in[N-1] ^ in[0];
    end
    else begin

        wire    [N/2-1 : 0] in_1,in_2;
        wire                out_1,out_2;

        xor_tree#(.N(N/2))
        xor_tree_1
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(in_1),
            .out(out_1)
        );

        assign in_1 = in[N/2-1 : 0];

        xor_tree#(.N(N/2))
        xor_tree_2
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(in_2),
            .out(out_2)
        );

        assign in_2 = in[N-1 : N/2];
        assign out  = out_1 ^ out_2;

    end
endgenerate

endmodule
