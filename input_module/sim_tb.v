`timescale 1ns/1ps

module in_module_tb;

reg in_clk,out_clk,rst_n;

localparam IN_CLK_TIME  = 4;  
localparam OUT_CLK_TIME = 6;  

localparam  DATA_WIDTH      =   `DATA_WIDTH;
localparam  WIDTH_SEL       =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH    =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY  =   $clog2(`PRIORITY);

always #(IN_CLK_TIME/2)     in_clk = !in_clk;
always #(OUT_CLK_TIME/2)    out_clk = !out_clk;

initial
begin
    in_clk = 1;
    out_clk = 1;
    rst_n = 0;

    #(10*IN_CLK_TIME);

    rst_n = 1;
end

reg                             start;
wire                            done;
reg    [WIDTH_SEL-1 : 0]        dest;
reg    [WIDTH_PRIORITY-1 : 0]   priority;
reg    [WIDTH_LENGTH-1 : 0]     length;

wire                        wr_sop;
wire                        wr_eop;
wire                        wr_vld;
wire    [DATA_WIDTH-1 : 0]  wr_data;

send_module send_module
(
    .clk(in_clk),
    .rst_n(rst_n),
    .start(start),
    .done(done),
    .dest(dest),
    .priority(priority),
    .length(length),
    .wr_sop(wr_sop),
    .wr_eop(wr_eop),
    .wr_vld(wr_vld),
    .wr_data(wr_data)
);

wire    [WIDTH_SEL-1 : 0]       rx;
wire    [WIDTH_SEL-1 : 0]       tx;
wire                            vld;
wire    [DATA_WIDTH-1 : 0]      data;


in_module in_module
(
    .rst_n(rst_n),
    .in_clk(in_clk),
    .out_clk(out_clk),
    .wr_sop(wr_sop),
    .wr_eop(wr_eop),
    .wr_vld(wr_vld),
    .wr_data(wr_data),
    .rx(rx),
    .tx(tx),
    .vld(vld),
    .data(data)
);

initial
begin
    start = 0;
    dest = 2;
    priority = 3;
    length = 10;
    #(15*IN_CLK_TIME);
    @(posedge in_clk)
        start <= 1;
    #(5*IN_CLK_TIME);
    start = 0;
end

endmodule

