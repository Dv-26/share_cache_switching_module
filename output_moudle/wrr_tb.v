`timescale 1ns/1ns
`include "../generate_parameter.vh"

module wrr_tb();

localparam  WIDTH_WIEGHT    =   $clog2(`PRIORITY);
localparam  PORT_NUB        =   `PORT_NUB_TOTAL;
localparam  WIDTH_OUT       =   $clog2(PORT_NUB); 
localparam  WIDTH_PORT_IN   =   PORT_NUB * WIDTH_OUT;
localparam  WIDTH_IN        =   PORT_NUB * $clog2(`PRIORITY);

reg	                        clk;
reg	                        rst_n;
reg	                        en;
reg     [PORT_NUB-1 : 0]    req_in;
reg     [WIDTH_IN-1 : 0]    wieght_in;
wire    [WIDTH_OUT-1 : 0]   port_out;
wire                        valid_out;

wrr#(.NUB(0))wrr
(
    .clk        (clk),
    .rst_n      (rst_n),
    .en         (en),
    .req_in     (req_in),
    .wieght_in  (wieght_in),
    .port_out   (port_out),
    .valid_out  (valid_out)
);

always #1 clk = !clk;

initial
begin
    clk = 1;
    rst_n = 0;
    en = 0;
    req_in = 0;
    wieght_in = {3'd4, 3'd3, 3'd2, 3'd0};
    #10;
    rst_n = 1;
    #10;
    en = 1;
    req_in[3] = 1;
    req_in[2] = 1;
    req_in[1] = 1;
    #100;
    req_in[1] = 0;
    #100;
    req_in[2] = 0;
    #100;
    $stop();
end
    

endmodule
