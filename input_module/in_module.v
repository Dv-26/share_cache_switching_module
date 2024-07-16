`timescale 1ns/1ns
`include "../generate_parameter.vh"

module in_module
#(
    parameter   num = 0
)
(
    input   wire                            rst_n,
    input   wire                            external_clk,
    input   wire                            internal_clk,
    input   wire                            wr_sop,
    input   wire                            wr_eop,
    input   wire                            wr_vld,
    input   wire                            full_in,
    input   wire                            ready_in,
    input   wire    [DATA_WIDTH-1 : 0]      wr_data,
    output  wire    [WIDTH_SEL-1 : 0]       rx,
    output  wire    [WIDTH_SEL-1 : 0]       tx,
    output  wire                            vld,
    output  wire    [DATA_WIDTH-1 : 0]      data
);


localparam  WIDTH_LENGTH    =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY  =   $clog2(`PRIORITY);
localparam  WIDTH_HAND      =   16+WIDTH_LENGTH+WIDTH_PRIORITY+WIDTH_SEL+1;   
localparam  DATA_WIDTH      =   `DATA_WIDTH;
localparam  WIDTH_SEL       =   $clog2(`PORT_NUB_TOTAL);

wire            wr_en;
wire    [15 : 0]    crc_out;
wire                crc_rst_n;

crc16_32bit crc 
(
    .clk(external_clk),
    .rst_n(crc_rst_n),
    .data_in(wr_data),
    .crc_out(crc_out),
    .crc_en(wr_en)
);


wire    [DATA_WIDTH-1 : 0]  fifo_rd_data;
wire                        fifo_rd_en;
wire                        error;

dc_fifo 
#(
    .DATA_BIT(DATA_WIDTH),
    .DATA_DEPTH(256)
)
dc_fifo
(
    .rst_n(rst_n),
    .wr_clk(external_clk),
    .wr_data(wr_data),
    .wr_en(wr_en),
    .rd_clk(internal_clk),
    .rd_data(fifo_rd_data),
    .rd_en(fifo_rd_en)
);


wire    [DATA_WIDTH-1 : 0]  ctrl_data_reg;
wire            wr_done;
wire            wr_control_ready;


in_wr_controller_fsm wr_controller
(
    .clk(external_clk),
    .rst_n(rst_n),
    .eop(wr_eop),
    .sop(wr_sop),
    .valid(wr_vld),
    .ctrl_data_in(wr_data),
    .wr_en(wr_en),
    .error_out(error),
    .crc_rst_n(crc_rst_n),
    .done(wr_done),
    .ready(wr_control_ready),
    .ctrl_data_reg(ctrl_data_reg)
);

wire    [WIDTH_SEL-1 : 0]           in_dest;
wire    [WIDTH_PRIORITY-1 : 0]      in_priority;
wire    [WIDTH_LENGTH-1 : 0]        in_data_length;

wire    [WIDTH_SEL-1 : 0]           out_dest;
wire    [WIDTH_PRIORITY-1 : 0]      out_priority;
wire    [WIDTH_LENGTH-1 : 0]        out_data_length;
wire    [15 : 0]                    out_crc;

wire    [WIDTH_HAND-1 : 0]          handshake_in;
wire    [WIDTH_HAND-1 : 0]          handshake_out;
wire                                error_out;
wire                                rx_valid,rx_ready;

cdc_handshake 
#(
    .DATA_WIDTH(WIDTH_HAND)
)
cdc_handshake
(
    .rst_n(rst_n),
    .tx_clk(external_clk),
    .rx_clk(internal_clk),
    .tx_valid(wr_done),
    .data_in(handshake_in),
    .tx_ready(wr_control_ready),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),
    .data_out(handshake_out)
);

assign  in_dest         = ctrl_data_reg[WIDTH_LENGTH+WIDTH_PRIORITY+WIDTH_SEL-1 : WIDTH_LENGTH+WIDTH_PRIORITY];
assign  in_priority     = ctrl_data_reg[WIDTH_LENGTH+WIDTH_PRIORITY-1 : WIDTH_LENGTH];
assign  in_data_length  = ctrl_data_reg[WIDTH_LENGTH-1 : 0];

assign  handshake_in    = {error,crc_out,in_dest,in_priority,in_data_length};
assign  {error_out,out_crc,out_dest,out_priority,out_data_length} = handshake_out;

wire    [DATA_WIDTH-1 : 0]          ctrl_data_out;
wire    [WIDTH_SEL-1 : 0]   rd_control_rx_in;
wire    [8:0]               rd_control_length;
wire                        out_sel;

in_rd_controller_fsm rd_control
(
    .clk(internal_clk),
    .rst_n(rst_n),
    .start(rx_valid),
    .rx_in(out_dest),
    .error_in(error_out),
    .data_length(out_data_length),
    .rx_out(rx),
    .fifo_rd_en(fifo_rd_en),
    .ready(rx_ready),
    .full_in(full_in),
    .out_valid(vld),
    .out_sel(out_sel),
    .ready_in(ready_in)
);

assign  ctrl_data_out = {~out_data_length,out_data_length,out_crc,out_priority}; 
//取反码用于后级模块判断控制帧
assign  data = (out_sel == 1)? ctrl_data_out:fifo_rd_data;
assign  tx = num;

endmodule
