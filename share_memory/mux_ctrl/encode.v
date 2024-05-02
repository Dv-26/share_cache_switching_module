
module  encode
#(
    parameter   N = 16 
)
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire    [WIDTH_IN-1 : 0]    in,
    output  wire    [WIDTH_OUT-1 : 0]   out
);

localparam  WIDTH_IN    = N;
localparam  WIDTH_OUT   = $clog2(N);

generate
    genvar i;
    if(N == 2)begin
        assign  out = in[N-1];
    end
    else begin

        wire    [N/2-1 : 0]             in_1,in_2;
        wire    [$clog2(N/2)-1 : 0]     out_1,out_2;

        encode#(.N(N/2))
        encode_1
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(in_1),
            .out(out_1)
        );

        assign in_1 = in[N/2-1 : 0];

        encode#(.N(N/2))
        encode_2
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(in_2),
            .out(out_2)
        );

        assign in_2 = in[N-1 : N/2];

        wire    xor_out;
        
        xor_tree#(.N(N/2))
        xor_tree
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(in_2),
            .out(xor_out)
        );

        assign out[WIDTH_OUT-1] = xor_out;
        for(i=0; i<WIDTH_OUT-1; i=i+1)begin: loop
            assign out[i] = out_1[i] ^ out_2[i];
        end

    end

endgenerate

endmodule
