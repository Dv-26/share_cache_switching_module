`timescale 1ns/1ns
`define CLK_TIME 2
`include "../generate_parameter.vh"
module voq_tb();

localparam  WIDTH_PORT  =   2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_SEL   =   $clog2(`PORT_NUB_TOTAL);

reg                             clk;
reg                             rst_n;
reg       [WIDTH_PORT-1:0]      wr_data;
reg                             wr_en;
reg       [WIDTH_SEL-1:0]       wr_client;
wire      [WIDTH_PORT-1:0]      rd_data;
wire                            full;
wire      [`PORT_NUB_TOTAL-1 : 0]   empty;
reg                             rd_en;
reg       [WIDTH_SEL-1:0]       rd_client;

voq
#(
    .DEPTH(16)
)
voq_tb
(
    .clk(clk),
    .rst_n(rst_n),
    .wr_data(wr_data),
    .wr_vaild(wr_en),
    .wr_sel(wr_client),
    .rd_data(rd_data),
    .rd_vaild(rd_en),
    .rd_sel(rd_client),
    .full(full),
    .empty(empty)
);

always #(`CLK_TIME/2) clk = ~clk; 

integer i,j;

initial
begin
    clk = 0;
    rst_n = 0;
    wr_data = 1;
    wr_client = 0;
    wr_en = 1'b0;
    rd_client = 0;
    rd_en = 1'b0;
    #(20*`CLK_TIME);
    rst_n = 1;

    #(20*`CLK_TIME);

    for(j=0;j<4;j=j+1)begin
        for(i=0;i<4;i=i+1)begin
            wr_data = j*4+i;
            wr_client = i;
            #(5*`CLK_TIME);
            wr_en = 1'b1;
            #(`CLK_TIME);
            wr_en = 1'b0;
        end
    end

    #(20*`CLK_TIME);

    for(j=0;j<4;j=j+1)begin
        for(i=0;i<4;i=i+1)begin
            rd_client = j;
            rd_en = 1'b1;
            #(`CLK_TIME);
            rd_en = 1'b0;
            #(5*`CLK_TIME);
        end
    end

    #(20*`CLK_TIME);
    $stop();
    
end

initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0,voq_tb);
end

endmodule
