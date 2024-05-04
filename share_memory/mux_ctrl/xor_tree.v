`timescale 1ns/1ns

module xor_tree
#(
    parameter   N           = 8,
    parameter   PIPELINE    = 1
)
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire    [N-1 : 0]           in,
    output  wire                        out
);

generate
    if(N == 2)begin
        if(PIPELINE)begin
            reg out_reg;
            always @(posedge clk or negedge rst_n)
                if(!rst_n)
                    out_reg <= 1'b0;
                else
                    out_reg <= in[N-1] ^ in[0];

            assign out = out_reg;
        end
        else
            assign out = in[N-1] ^ in[0];
    end
    else begin

        wire    [N/2-1 : 0] in_1,in_2;
        wire                out_1,out_2;
        reg out_reg;

        xor_tree#(.N(N/2),.PIPELINE(PIPELINE))
        xor_tree_1
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(in_1),
            .out(out_1)
        );

        assign in_1 = in[N/2-1 : 0];

        xor_tree#(.N(N/2),.PIPELINE(PIPELINE))
        xor_tree_2
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(in_2),
            .out(out_2)
        );

        assign in_2 = in[N-1 : N/2];

        if(PIPELINE)begin
            always @(posedge clk or negedge rst_n)
                if(!rst_n)
                    out_reg <= 1'b0;
                else
                    out_reg <= out_1 ^ out_2;

            assign out = out_reg;
        end
        else
            assign out = out_1 ^ out_2;

    end
endgenerate

endmodule
