`timescale 1ns/1ns
`define CLK_TIME 2
module voq_tb();

reg                 clk;
reg                 rst_n;
reg       [7:0]     wr_data;
reg                 wr_en;
reg       [1:0]     wr_client;
wire      [7:0]     rd_data;
reg                 rd_en;
reg       [1:0]     rd_client;

voq
#(
    .DATA_WIDTH(8),
    .DEPTH(20),
    .QUEUE_NUB(4)
)
voq_tb
(
    .clk(clk),
    .rst_n(rst_n),
    .wr_data(wr_data),
    .wr_en(wr_en),
    .wr_client(wr_client),
    .rd_data(rd_data),
    .rd_en(rd_en),
    .rd_client(rd_client)
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
