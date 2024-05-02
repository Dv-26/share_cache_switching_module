
module  encode_old
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

reg [WIDTH_OUT-1 : 0]   out_n;

integer i;
always@(*)begin
    out_n = 0;
    for(i=0; i<N; i=i+1)begin
        if(in[i])
            out_n = i;
    end
end

assign out = out_n;

endmodule
