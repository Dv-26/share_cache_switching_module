
module  encode_pk
#(
    parameter   N = 16 
)
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire    [WIDTH_IN-1 : 0]    in,
    output  wire    [WIDTH_OUT-1 : 0]   out_new,
    output  wire    [WIDTH_OUT-1 : 0]   out_old
);

localparam  WIDTH_IN    = N;
localparam  WIDTH_OUT   = $clog2(N);

encode#(.N(N))
encode_new
(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out_new)
);

encode_old#(.N(N))
encode_old
(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out_old)
);

endmodule
