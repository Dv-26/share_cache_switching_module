`timescale 1ns/1ns
`include "../../generate_parameter.vh"
`define CLK_TIME 4

module  encode_tb();

reg                                     clk,rst_n;

always #(`CLK_TIME/2) clk = !clk;

localparam PORT_NUB         = `PORT_NUB_TOTAL;
localparam WIDTH_SEL        = $clog2(`PORT_NUB_TOTAL);

reg     [PORT_NUB-1 : 0]    in;
wire    [WIDTH_SEL-1 : 0]   out_new,out_old;     

encode_pk#(.N(PORT_NUB))
encode_1
(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out_new(out_new),
    .out_old(out_old)
);

integer i;
initial
begin
    in = 0;
    #(`CLK_TIME);
    for(i=0; i<PORT_NUB; i=i+1)begin
        if(i==0)
            in = 1;
        else
            in = in << 1;
        #(`CLK_TIME);
    end
    #(`CLK_TIME);
    $stop();
end

endmodule
