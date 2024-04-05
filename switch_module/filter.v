`timescale 1ns/1ns 
`include "./defind.vh"

module filter
#(
    parameter   dest   =   0
)
(
    input       wire                            clk,
    input       wire                            rst_n,
    input       wire    [WIDTH_TOTAL - 1 : 0]   port_in, 
    output      wire    [WIDTH_TOTAL - 1 : 0]   port_out,
    output      wire    [`PORT_NUB_TOTAL-1 : 0] port_vaild
);

localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL); 
localparam  WIDTH_PORT  = 1+2*$clog2(`PORT_NUB_TOTAL)+`DATA_WIDTH;
localparam  WIDTH_TOTAL = `PORT_NUB_TOTAL * WIDTH_PORT;

generate
    genvar i;
    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin : loop
        wire    [$clog2(`PORT_NUB_TOTAL)-1 : 0]    tx_ports,rx_ports;    
        wire    [`DATA_WIDTH-1 : 0]          data;
        wire                                valid;
        assign  {valid,rx_ports,tx_ports,data} = port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
        assign  port_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = (rx_ports == dest)? port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT]:{WIDTH_PORT{1'b0}};
        assign  port_vaild[i] = (valid == 1'b1)? (rx_ports == dest)? 1'b1:1'b0:1'b0;
    end
endgenerate

endmodule
