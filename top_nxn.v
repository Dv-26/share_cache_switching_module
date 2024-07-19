`timescale 1ns/1ns
`include "generate_parameter.vh"

module top_nxn
(
    input       wire                                        internal_clk,
    input       wire                                        external_clk,
    input       wire                                        rst_n,

    input       wire    [PORT_NUB_TOTAL-1 : 0]              wr_sop,          
    input       wire    [PORT_NUB_TOTAL-1 : 0]              wr_eop,          
    input       wire    [PORT_NUB_TOTAL-1 : 0]              wr_vld,          
    input       wire    [DATA_WIDTH_TOTAL-1 : 0]            wr_data,

    output      wire    [PORT_NUB_TOTAL-1 : 0]              rd_sop,          
    output      wire    [PORT_NUB_TOTAL-1 : 0]              rd_eop,          
    output      wire    [PORT_NUB_TOTAL-1 : 0]              rd_vld,          
    output      wire    [DATA_WIDTH_TOTAL-1 : 0]            rd_data,
    input       wire    [PORT_NUB_TOTAL-1 : 0]              ready,
    output      wire                                        full,
    output      wire                                        alm_ost_full,

    input       wire                                        dispatch_sel,
    input       wire    [WIDTH_WIEGHT_TOTAL-1 : 0]          wrr_wieght_in
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
localparam  WIDTH_WIEGHT        =   $clog2(`PRIORITY);
localparam  WIDTH_WIEGHT_TOTAL  =   PORT_NUB_TOTAL * WIDTH_WIEGHT;

wire    [WIDTH_SEL_TOTAL-1 : 0]             rx_in;
wire    [WIDTH_SEL_TOTAL-1 : 0]             tx_in;
wire    [PORT_NUB_TOTAL-1 : 0]              vld_in;
wire    [WIDTH_VOQ1*PORT_NUB_TOTAL-1 : 0]   port_in;
wire    [WIDTH_VOQ1*PORT_NUB_TOTAL-1 : 0]   port_out;
wire    [WIDTH_SEL_TOTAL-1 : 0]             rd_sel;
wire    [PORT_NUB_TOTAL-1 : 0]              rd_en;
wire    [PORT_NUB_TOTAL-1 : 0]              rd_done_in;
wire    [PORT_NUB_TOTAL**2-1 : 0]           empty;
wire                                        full;
wire    [PORT_NUB_TOTAL-1 : 0]              ready_out;


switch_moudle switch_moudle
(
    .clk(internal_clk),
    .rst_n(rst_n),
    .rx_in(rx_in),
    .tx_in(tx_in),
    .vld_in(vld_in),
    .port_in(port_in),
    .port_out(port_out),
    .rd_sel(rd_sel),
    .rd_en(rd_en),
    .rd_done_in(rd_done_in),
    .empty(empty),
    .full(full),
    .ready(ready_out),
    .alm_ost_full(alm_ost_full)
);

wire    [WIDTH_WIEGHT_TOTAL : 0]    dispatch_config_in;
wire    [WIDTH_WIEGHT_TOTAL : 0]    dispatch_config_out;

cdc #(.DATA_WIDTH(1+WIDTH_WIEGHT_TOTAL))
dispatch_config
(
    .tx_clk     (external_clk),
    .rx_clk     (internal_clk),
    .rst_n      (rst_n),
    .in_data    (dispatch_config_in),
    .out_data   (dispatch_config_out)
);

assign dispatch_config_in = {dispatch_sel, wrr_wieght_in};

generate
    genvar i;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: layout

        wire                             in_wr_sop;
        wire                             in_wr_eop;
        wire                             in_wr_vld;
        wire    [DATA_WIDTH-1 : 0]       in_wr_data;
        wire    [WIDTH_SEL-1 : 0]        in_rx;
        wire    [WIDTH_SEL-1 : 0]        in_tx;
        wire                             in_vld;
        wire    [DATA_WIDTH-1 : 0]       in_data;
        wire                            in_ready;
        wire    [WIDTH_SIG_PORT - 1 : 0] in_local_port_info;
        wire    [DATA_WIDTH - 1 - 1 - 2 * WIDTH_SIG_PORT : 0] in_data_data;
        wire    [1 + WIDTH_SIG_PORT - 1 : 0] in_data_prefix;

        //数据输入连线
        in_module#(.num(i))
        in_module
        (
            .external_clk(external_clk),
            .internal_clk(internal_clk),
            .rst_n(rst_n),
            .wr_sop(in_wr_sop),
            .wr_eop(in_wr_eop),
            .wr_vld(in_wr_vld),
            .wr_data(in_wr_data),
            .rx(in_rx),
            .tx(in_tx),
            .vld(in_vld),
            .ready_in(in_ready),
            .full_in(alm_ost_full),
            .data(in_data)
        );

        assign in_wr_sop                                    = wr_sop[i];
        assign in_wr_eop                                    = wr_eop[i];
        assign in_wr_vld                                    = wr_vld[i];
        assign in_wr_data                                   = wr_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
        assign in_data_data                                 = in_data[DATA_WIDTH - 1 : 1 + 2 * WIDTH_SIG_PORT];
        assign in_data_prefix                               = in_data[1 + WIDTH_SIG_PORT - 1 : 0];
        assign port_in[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]   = in_data;
        assign rx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL]       = in_rx; 
        assign tx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL]       = in_tx; 
        assign vld_in[i]                                    = in_vld;
        assign in_ready                                     = ready_out[i];

        wire                            out_rd_sop;
        wire                            out_rd_eop;
        wire                            out_ready;
        wire                            out_rd_vld;
        wire    [DATA_WIDTH-1 : 0]      out_rd_data;
        wire                            out_rd_en;
        wire                            out_rd_done;
        wire    [WIDTH_SEL-1 : 0]       out_rd_sel;
        wire    [DATA_WIDTH-1 : 0]      out_data;
        wire    [PORT_NUB_TOTAL : 0]    out_empty;
        wire                            out_qos_controll; //输出模式控制

        output_module#(.NUB(i))
        output_module
        (
            .internal_clk   (internal_clk), 
            .external_clk   (external_clk),
            .rst_n          (rst_n), 
            .empty_in       (out_empty),
            .port_in        (out_data),
            .rd_sel         (out_rd_sel),
            .rd_en          (out_rd_en),
            .rd_done        (out_rd_done),
            .ready_in       (out_ready),
            .rd_sop         (out_rd_sop),
            .rd_eop         (out_rd_eop),
            .rd_vld         (out_rd_vld),
            .rd_data        (out_rd_data),
            .dispatch_sel   (dispatch_config_out[WIDTH_WIEGHT_TOTAL]),
            .wrr_wieght_in  (dispatch_config_out[WIDTH_WIEGHT_TOTAL-1 : 0])
        );

        assign  rd_sop[i]        = out_rd_sop;
        assign  rd_eop[i]        = out_rd_eop;
        assign  rd_vld[i]        = out_rd_vld;
        assign  rd_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]  = out_rd_data;
        assign  out_ready        = ready[i];
        assign  rd_done_in[i]    = out_rd_done; 
        assign  rd_en[i]         = out_rd_en;
        assign  rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = out_rd_sel;
        assign  out_empty        = empty[(i+1)*PORT_NUB_TOTAL-1 : i*PORT_NUB_TOTAL]; 
        assign  out_data         = port_out[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];//直接读数据不读端口之类的数据

    end

endgenerate

endmodule
