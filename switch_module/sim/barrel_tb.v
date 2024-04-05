`timescale 1ns/1ns
`include "../defind.vh"
`define CLK_TIME 2

module barrel_tb();
reg clk,rst_n;
always #(`CLK_TIME/2) clk = !clk;

localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL); 
localparam  WIDTH_PORT  = 1+2*$clog2(`PORT_NUB_TOTAL)+`DATA_WIDTH;
localparam  WIDTH_TOTAL = `PORT_NUB_TOTAL * WIDTH_PORT;

reg                             clk;
reg                             rst_n;
reg       [WIDTH_SEL-1 : 0]     select;
wire      [WIDTH_TOTAL-1 : 0]   port_in; 
wire      [WIDTH_TOTAL-1 : 0]   port_out;

reg         [WIDTH_PORT-1 : 0]       in[`PORT_NUB_TOTAL-1 : 0];
wire        [WIDTH_PORT-1 : 0]       out[`PORT_NUB_TOTAL-1 : 0];

generate
    genvar i;
    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin: loop
        assign  port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = in[i];
        assign  out[i]  = port_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
    end
endgenerate

barrel_shift barrel_shift
(
    .clk(clk),
    .rst_n(rst_n),
    .select(select),
    .port_in(port_in), 
    .port_out(port_out)
);

integer j;

initial
begin
    for(j=0; j<`PORT_NUB_TOTAL; j=j+1)begin
        in[j] = j;
    end
    select = 0;
    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(5*`CLK_TIME);
    for(j=0; j<`PORT_NUB_TOTAL; j=j+1)begin
        @(posedge clk)begin
            select <= j;
        end
    end
    #(5*`CLK_TIME);
    $stop();

end
endmodule
