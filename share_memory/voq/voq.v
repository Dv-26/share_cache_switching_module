`timescale 1ns/1ns
`include "../generate_parameter.vh"

module voq
#(
    parameter   NAME        = 0,
    parameter   DEPTH       = 8,
    parameter   DATA_WIDTH  = 10
)
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [DATA_WIDTH-1 : 0]  wr_data,
    input   wire                        wr_vaild,
    input   wire    [WIDTH_SEL-1 : 0]   wr_sel,

    output  wire    [DATA_WIDTH-1 : 0]  rd_data,
    input   wire                        rd_vaild,
    input   wire    [WIDTH_SEL-1 : 0]   rd_sel,

    output  wire    [PORT_NUB-1 : 0]    empty,
    output  wire                        full
);


localparam  WIDTH_PORT  =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_ADDR  =   $clog2(DEPTH);
localparam  WIDTH_SEL   =   $clog2(`PORT_NUB_TOTAL);
localparam  PORT_NUB    =   `PORT_NUB_TOTAL;

wire    rd_en,wr_en;

wire  [WIDTH_ADDR-1 : 0]  multi_channel_in;
wire  [WIDTH_ADDR-1 : 0]  multi_channel_out;

multi_channel_fifo
#(
    .PORT_NUB(`PORT_NUB_TOTAL),
    .DEPTH(DEPTH)
)
multi_channel_fifo
(
    .clk(clk),
    .rst_n(rst_n),
    .wr_data(multi_channel_in),
    .wr_en(wr_en),
    .wr_sel(wr_sel),
    .rd_data(multi_channel_out),
    .rd_en(rd_en),
    .rd_sel(rd_sel),
    .empty(empty),
    .full()
);

wire                        free_ptr_rd;
wire                        free_ptr_wr;
wire    [WIDTH_ADDR-1:0]    free_ptr_w_data;
wire    [WIDTH_ADDR-1:0]    free_ptr_r_data;
wire                        free_ptr_empty;

free_ptr_fifo
#(
    .DEPTH(DEPTH)
)
free_ptr_fifo
(
    .clk(clk),
    .rst_n(rst_n),
    .rd(free_ptr_rd),
    .wr(free_ptr_wr),
    .w_data(free_ptr_w_data),
    .r_data(free_ptr_r_data),
    .empty(free_ptr_empty),
    .full()
);

assign  free_ptr_rd = wr_en;
assign  free_ptr_wr = rd_en;
assign  free_ptr_w_data = multi_channel_out;
assign  multi_channel_in = free_ptr_r_data ;
assign  full = free_ptr_empty;

wire                        sdram_wr_en;
wire                        sdram_rd_en;
wire    [DATA_WIDTH-1 : 0]  sdram_wr_data;
wire    [DATA_WIDTH-1 : 0]  sdram_rd_data;
wire    [WIDTH_ADDR-1 : 0]  sdram_wr_addr;
wire    [WIDTH_ADDR-1 : 0]  sdram_rd_addr;

ram
#(
    .NAME(NAME),
    .ADDR_WIDTH(WIDTH_ADDR),
    .DATA_WIDTH(DATA_WIDTH)
)
sram
(
    .clk(clk),
    .wr_en(sdram_wr_en),
    .wr_addr(sdram_wr_addr),
    .wr_data(wr_data),
    .rd_en(sdram_rd_en),
    .rd_data(rd_data),
    .rd_addr(sdram_rd_addr)
);

assign  sdram_wr_en = wr_en;
assign  sdram_rd_en = rd_en;
assign  sdram_wr_data = wr_data;
assign  sdram_rd_data = rd_data;
assign  sdram_wr_addr = free_ptr_r_data;
assign  sdram_rd_addr = multi_channel_out;

assign  wr_en = wr_vaild && !full;
assign  rd_en = rd_vaild && !empty[rd_sel];
endmodule
