`timescale 1ns/1ns
`include "../../generate_parameter.vh"
`define CLK_TIME 2

module multi_channel_fifo_tb();

localparam  DEPTH       =   10;
localparam  WIDTH_PORT  = 1 + 2*$clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_TOTAL = `PORT_NUB_TOTAL * WIDTH_PORT;
localparam  WIDTH_SEL   = `PORT_NUB_TOTAL * $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PRT   = $clog2(`PORT_NUB_TOTAL*DEPTH);

reg                       clk;
reg                       rst_n;
reg   [WIDTH_PORT-1 : 0]  wr_data;
reg                       wr_en;
reg   [WIDTH_SEL-1 : 0]   wr_sel;
wire  [WIDTH_PORT-1 : 0]  rd_data;
reg                       rd_en;
reg   [WIDTH_SEL-1 : 0]   rd_sel;
wire  [`PORT_NUB_TOTAL-1 : 0]    empty;
wire  [`PORT_NUB_TOTAL-1 : 0]    full;

always #(`CLK_TIME/2) clk = !clk;

multi_channel_fifo
#(
    .PORT_NUB(`PORT_NUB_TOTAL),
    .DEPTH(DEPTH)
)
multi_channel_fifo_tb
(
    .clk(clk),
    .rst_n(rst_n),
    .wr_data(wr_data),
    .wr_en(wr_en),
    .wr_sel(wr_sel),
    .rd_data(rd_data),
    .rd_en(rd_en),
    .rd_sel(rd_sel),
    .empty(empty),
    .full(full)
);

task wr;
    input   integer sel;
    input   integer data; 
    begin
        @(negedge clk)begin
            wr_sel <= sel;
            wr_data <= data;
            wr_en <= 1'b1;
        end
        #(`CLK_TIME);
        wr_en = 1'b0;
    end
endtask

task rd;
    input   integer sel;
    begin
        @(negedge clk)begin
            rd_sel <= sel;
            rd_en <= 1'b1;
        end
        #(`CLK_TIME);
        rd_en = 1'b0;
    end
endtask

integer i,j=0;
initial 
begin

    wr_data = 0;
    wr_en = 0;
    wr_sel = 0;
    rd_en = 0;
    rd_sel = 0;         
    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(5*`CLK_TIME);

    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin
        wr(i,i);
        rd(i);
    end

    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin
        for(j=0; j<DEPTH; j=j+1)begin
            wr(i,i*10+j);
        end
    end

    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin
        repeat(DEPTH)begin
            rd(i);
        end
    end

    #(20*`CLK_TIME);
    $stop();

end

endmodule

