`timescale 1ns/1ns
`include "./share_memory/generate_parameter.vh"

module top_nxn
(
    input       wire                                        clk,
    input       wire                                        rst_n,

    input       wire    [PORT_NUB_TOTAL-1 : 0]              wr_sop,          
    input       wire    [PORT_NUB_TOTAL-1 : 0]              wr_eop,          
    input       wire    [PORT_NUB_TOTAL-1 : 0]              wr_vld,          
    input       wire    [DATA_WIDTH_TOTAL-1 : 0]            wr_data,

    output      wire    [PORT_NUB_TOTAL-1 : 0]              rd_sop,          
    output      wire    [PORT_NUB_TOTAL-1 : 0]              rd_eop,          
    output      wire    [PORT_NUB_TOTAL-1 : 0]              rd_vld,          
    output      wire    [DATA_WIDTH_TOTAL-1 : 0]            rd_data,

    output      wire                                        full,
    input       wire    [PORT_NUB_TOTAL-1 : 0]              ready
);

localparam  PORT_NUB_TOTAL      =   `PORT_NUB_TOTAL;
localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  DATA_WIDTH_TOTAL    =   PORT_NUB_TOTAL*`DATA_WIDTH;

localparam  WIDTH_SIG_PORT      =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT  =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_FILTER =  2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ0  =   $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ1  =   `DATA_WIDTH;
localparam  WIDTH_TOTAL  =   PORT_NUB_TOTAL * WIDTH_PORT; 
localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_SEL_TOTAL =   PORT_NUB_TOTAL * WIDTH_SEL; 

wire    [WIDTH_TOTAL-1 : 0]                 port_in;
wire    [WIDTH_VOQ1*PORT_NUB_TOTAL-1 : 0]   port_out;
wire    [WIDTH_SEL_TOTAL-1 : 0]             rd_sel;
wire    [PORT_NUB_TOTAL-1 : 0]              rd_en;
wire    [PORT_NUB_TOTAL**2-1 : 0]           empty;
wire                                        full;

switch_moudle switch_moudle
(
    .clk(clk),
    .rst_n(rst_n),
    .port_in(port_in),
    .port_out(port_out),
    .rd_sel(rd_sel),
    .rd_en(rd_en),
    .empty(empty),
    .full(full)
);

generate
    genvar i;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: layout

        wire                        in_wr_sop;
        wire                        in_wr_eop;
        wire                        in_wr_vld;
        wire    [DATA_WIDTH-1 : 0]  in_wr_data;
        wire    [WIDTH_SEL-1 : 0]   in_rx;
        wire    [WIDTH_SEL-1 : 0]   in_tx;
        wire                        in_vld;
        wire    [DATA_WIDTH-1 : 0]  in_data;

        //数据输入连线
        data_controller in_module
        (
            .clk(clk),
            .rst(rst_n),
            .wr_sop(in_wr_sop),
            .wr_eop(in_wr_eop),
            .wr_vld(in_wr_vld),
            .wr_data(in_wr_data),
            .data(in_data)
        );

        assign in_wr_sop         = wr_sop[i];
        assign in_wr_eop         = wr_eop[i];
        assign in_wr_vld         = wr_vld[i];
        assign in_wr_data        = wr_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
        assign in_data_data      = in_data[DATA_WIDTH - 1 : 1 + 2 * WIDTH_SIG_PORT];
        assign in_data_prefix    = in_data[1 + WIDTH_SIG_PORT - 1 : 0];
        assign port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = {in_data_prefix,i,in_data_data};

        wire                            out_rd_sop;
        wire                            out_rd_eop;
        wire                            out_ready;
        wire                            out_rd_vld;
        wire    [DATA_WIDTH-1 : 0]      out_rd_data;
        wire                            out_rd_en;
        wire    [WIDTH_SEL-1 : 0]       out_rd_sel;
        wire    [DATA_WIDTH-1 : 0]      out_data;
        wire    [PORT_NUB_TOTAL : 0]    out_empty;

        sel_control out_module
        (
            .clk(clk),
            .rst_n(rst_n),
            .rd_sop(out_rd_sop),
            .rd_eop(out_rd_eop),
            .rd_vld(out_rd_vld),
            .ready(out_ready),
            .rd_data(out_rd_data),
            .rd_en(out_rd_en),
            .rd_sel(out_rd_sel),
            .empty(out_empty),
            .data_in(out_data),
            .error(out_error)
        );

        assign  rd_sop[i]   = out_rd_sop;
        assign  rd_eop[i]   = out_rd_eop;
        assign  rd_vld[i]   = out_rd_vld;
        assign  rd_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]  = out_rd_data;
        assign  out_ready   = ready[i];
        assign  rd_en[i]    = out_rd_en;
        assign  rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = out_rd_sel;
        assign  out_empty   = empty[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL]; 
        assign  out_data    = port_out[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH + 1 + 2 * WIDTH_SIG_PORT];//直接读数据不读端口之类的数据

    end

endgenerate

endmodule
