`include "./generate_parameter.vh"
module send_test
(
    input   wire    clk,
    input   wire    rst_n,

    output  wire    full
);

localparam  PORT_NUB            =   `PORT_NUB_TOTAL;
localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  DATA_WIDTH_TOTAL    =   PORT_NUB * DATA_WIDTH;
localparam  WIDTH_SEL           =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY      =   $clog2(`PRIORITY);

wire    internal_clk;
wire    clk_250Mhz;
wire    locked;

clk_wiz_0 clk_generate
(
    // Clock out ports
    .clk_out1(clk_250Mhz),    // output clk_out1 250Mhz
    .clk_out2(internal_clk),    // output clk_out1 250Mhz
    // Status and control signals
    .reset(~rst_n),         // input reset
    .locked(locked),        // output locked
    // Clock in ports
    .clk_in1(clk)           // input clk_in1
);      

assign sys_rst_n = rst_n && locked;

wire [PORT_NUB-1 : 0] wr_sop_or; 
assign wr_sop_out = |wr_sop_or;

(* MARK_DEBUG = "true" *)wire                            wr_sop_0;
(* MARK_DEBUG = "true" *)wire                            wr_eop_0;
(* MARK_DEBUG = "true" *)wire                            wr_vld_0;

(* MARK_DEBUG = "true" *)wire                            wr_sop_1;
(* MARK_DEBUG = "true" *)wire                            wr_eop_1;
(* MARK_DEBUG = "true" *)wire                            wr_vld_1;

(* MARK_DEBUG = "true" *)wire                            wr_sop_2;
(* MARK_DEBUG = "true" *)wire                            wr_eop_2;
(* MARK_DEBUG = "true" *)wire                            wr_vld_2;

(* MARK_DEBUG = "true" *)wire                            rd_sop_3;
(* MARK_DEBUG = "true" *)wire                            rd_eop_3;
(* MARK_DEBUG = "true" *)wire                            rd_vld_3;

(* MARK_DEBUG = "true" *)wire                            rd_sop_0;
(* MARK_DEBUG = "true" *)wire                            rd_eop_0;
(* MARK_DEBUG = "true" *)wire                            rd_vld_0;

(* MARK_DEBUG = "true" *)wire                            rd_sop_1;
(* MARK_DEBUG = "true" *)wire                            rd_eop_1;
(* MARK_DEBUG = "true" *)wire                            rd_vld_1;

(* MARK_DEBUG = "true" *)wire                            rd_sop_2;
(* MARK_DEBUG = "true" *)wire                            rd_eop_2;
(* MARK_DEBUG = "true" *)wire                            rd_vld_2;

(* MARK_DEBUG = "true" *)wire                            rd_sop_3;
(* MARK_DEBUG = "true" *)wire                            rd_eop_3;
(* MARK_DEBUG = "true" *)wire                            rd_vld_3;

wire    [0 : 0]                wr_sop[PORT_NUB-1 : 0];
wire    [0 : 0]                wr_eop[PORT_NUB-1 : 0];
wire    [0 : 0]                wr_vld[PORT_NUB-1 : 0];
(* MARK_DEBUG = "true" *)wire    [DATA_WIDTH-1 : 0]     wr_data[PORT_NUB-1 : 0];

wire    [0 : 0]                rd_sop[PORT_NUB-1 : 0];
wire    [0 : 0]                rd_eop[PORT_NUB-1 : 0];
wire    [0 : 0]                rd_vld[PORT_NUB-1 : 0];
(* MARK_DEBUG = "true" *)wire    [DATA_WIDTH-1 : 0]     rd_data[PORT_NUB-1 : 0];

assign wr_sop_0 = wr_sop[0];
assign wr_sop_1 = wr_sop[1];
assign wr_sop_2 = wr_sop[2];
assign wr_sop_3 = wr_sop[3];

assign wr_eop_0 = wr_eop[0];
assign wr_eop_1 = wr_eop[1];
assign wr_eop_2 = wr_eop[2];
assign wr_eop_3 = wr_eop[3];

assign wr_vld_0 = wr_vld[0];
assign wr_vld_1 = wr_vld[1];
assign wr_vld_2 = wr_vld[2];
assign wr_vld_3 = wr_vld[3];

assign rd_sop_0 = rd_sop[0];
assign rd_sop_1 = rd_sop[1];
assign rd_sop_2 = rd_sop[2];
assign rd_sop_3 = rd_sop[3];

assign rd_eop_0 = rd_eop[0];
assign rd_eop_1 = rd_eop[1];
assign rd_eop_2 = rd_eop[2];
assign rd_eop_3 = rd_eop[3];

assign rd_vld_0 = rd_vld[0];
assign rd_vld_1 = rd_vld[1];
assign rd_vld_2 = rd_vld[2];
assign rd_vld_3 = rd_vld[3];

wire      [PORT_NUB-1 : 0]              top_wr_sop;          
wire      [PORT_NUB-1 : 0]              top_wr_eop;          
wire      [PORT_NUB-1 : 0]              top_wr_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]      top_wr_data;
wire      [PORT_NUB-1 : 0]              top_rd_sop;          
wire      [PORT_NUB-1 : 0]              top_rd_eop;          
wire      [PORT_NUB-1 : 0]              top_rd_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]      top_rd_data;

(* MARK_DEBUG="true" *)wire                                          top_full;
(* MARK_DEBUG="true" *)wire                                          top_alm_ost_full;
wire      [PORT_NUB-1 : 0]              top_ready;

assign full = top_full;

top_nxn top_test 
(
    .internal_clk       (internal_clk),
    .external_clk       (clk_250Mhz),
    .rst_n              (sys_rst_n),
    .wr_sop             (top_wr_sop),          
    .wr_eop             (top_wr_eop),          
    .wr_vld             (top_wr_vld),          
    .wr_data            (top_wr_data),
    .rd_sop             (top_rd_sop),          
    .rd_eop             (top_rd_eop),          
    .rd_vld             (top_rd_vld),          
    .rd_data            (top_rd_data),
    .ready              (top_ready),
    .full               (top_full),
    .alm_ost_full       (top_alm_ost_full)
);

assign top_ready = {PORT_NUB{1'b1}};

generate 
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin: send

        assign rd_data[i]   =   top_rd_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
        assign rd_sop[i]    =   top_rd_sop[i];
        assign rd_eop[i]    =   top_rd_eop[i];
        assign rd_vld[i]    =   top_rd_vld[i];

        assign top_wr_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]   =  wr_data[i];
        assign top_wr_sop[i]    =   wr_sop[i];
        assign top_wr_eop[i]    =   wr_eop[i];
        assign top_wr_vld[i]    =   wr_vld[i];

        (* MARK_DEBUG="true" *) wire                            start;
        (* MARK_DEBUG="true" *) wire                            done;

        wire                            single;
        wire                            ready;
        wire    [WIDTH_SEL-1 : 0]       dest;
        wire    [WIDTH_PRIORITY-1 : 0]  priority;
        wire    [WIDTH_LENGTH-1 : 0]    length;
        wire    [19 : 0]                send_cycle;


        vio_0 vio 
        (
          .clk(clk_250Mhz),                // input wire clk
          .probe_out0(start),  // output wire [0 : 0] probe_out0
          .probe_out1(single),  // output wire [0 : 0] probe_out1
          .probe_out2(dest),  // output wire [1 : 0] probe_out2
          .probe_out3(priority),  // output wire [2 : 0] probe_out3
          .probe_out4(length),  // output wire [7 : 0] probe_out4
          .probe_out5(send_cycle)  // output wire [19 : 0] probe_out5
        );

        send_module
        #(
            .tx_port(i)
        )
        send_module
        (
            .clk(clk_250Mhz),
            .rst_n(sys_rst_n),
            .start(start),
            .single(single),
            .send_cycle(send_cycle),
            .done(done),
            .ready(ready),
            .dest(dest),
            .priority(priority),
            .length(length),
            .wr_sop(wr_sop[i]),
            .wr_eop(wr_eop[i]),
            .wr_vld(wr_vld[i]),
            .wr_data(wr_data[i])
        );

    end

endgenerate

endmodule
