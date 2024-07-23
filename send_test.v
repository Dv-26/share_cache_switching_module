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
localparam  WIDTH_WIEGHT        =   $clog2(`PRIORITY);
localparam  WIDTH_WIEGHT_TOTAL  =   PORT_NUB * WIDTH_WIEGHT;

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

assign sys_rst_n = locked && rst_n;

wire [PORT_NUB-1 : 0] wr_sop_or; 
assign wr_sop_out = |wr_sop_or;

wire      [PORT_NUB-1 : 0]              top_wr_sop;          
wire      [PORT_NUB-1 : 0]              top_wr_eop;          
wire      [PORT_NUB-1 : 0]              top_wr_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]      top_wr_data;
wire      [PORT_NUB-1 : 0]              top_rd_sop;          
wire      [PORT_NUB-1 : 0]              top_rd_eop;          
wire      [PORT_NUB-1 : 0]              top_rd_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]      top_rd_data;

generate

    (* MARK_DEBUG = "true" *)wire                            wr_sop_0;
    (* MARK_DEBUG = "true" *)wire                            wr_eop_0;
    (* MARK_DEBUG = "true" *)wire                            wr_vld_0;
    (* MARK_DEBUG = "true" *)wire                            rd_sop_0;
    (* MARK_DEBUG = "true" *)wire                            rd_eop_0;
    (* MARK_DEBUG = "true" *)wire                            rd_vld_0;

    assign wr_sop_0 = top_wr_sop[0];
    assign wr_eop_0 = top_wr_eop[0];
    assign wr_vld_0 = top_wr_vld[0];
    assign rd_sop_0 = top_rd_sop[0];
    assign rd_eop_0 = top_rd_eop[0];
    assign rd_vld_0 = top_rd_vld[0];

    (* MARK_DEBUG = "true" *)wire                            wr_sop_1;
    (* MARK_DEBUG = "true" *)wire                            wr_eop_1;
    (* MARK_DEBUG = "true" *)wire                            wr_vld_1;
    (* MARK_DEBUG = "true" *)wire                            rd_sop_1;
    (* MARK_DEBUG = "true" *)wire                            rd_eop_1;
    (* MARK_DEBUG = "true" *)wire                            rd_vld_1;

    assign wr_sop_1 = top_wr_sop[1];
    assign wr_eop_1 = top_wr_eop[1];
    assign wr_vld_1 = top_wr_vld[1];
    assign rd_sop_1 = top_rd_sop[1];
    assign rd_eop_1 = top_rd_eop[1];
    assign rd_vld_1 = top_rd_vld[1];

    (* MARK_DEBUG = "true" *)wire                            wr_sop_2;
    (* MARK_DEBUG = "true" *)wire                            wr_eop_2;
    (* MARK_DEBUG = "true" *)wire                            wr_vld_2;
    (* MARK_DEBUG = "true" *)wire                            rd_sop_2;
    (* MARK_DEBUG = "true" *)wire                            rd_eop_2;
    (* MARK_DEBUG = "true" *)wire                            rd_vld_2;

    assign wr_sop_2 = top_wr_sop[2];
    assign wr_eop_2 = top_wr_eop[2];
    assign wr_vld_2 = top_wr_vld[2];
    assign rd_sop_2 = top_rd_sop[2];
    assign rd_eop_2 = top_rd_eop[2];
    assign rd_vld_2 = top_rd_vld[2];

    (* MARK_DEBUG = "true" *)wire                            wr_sop_3;
    (* MARK_DEBUG = "true" *)wire                            wr_eop_3;
    (* MARK_DEBUG = "true" *)wire                            wr_vld_3;
    (* MARK_DEBUG = "true" *)wire                            rd_sop_3;
    (* MARK_DEBUG = "true" *)wire                            rd_eop_3;
    (* MARK_DEBUG = "true" *)wire                            rd_vld_3;

    assign wr_sop_3 = top_wr_sop[3];
    assign wr_eop_3 = top_wr_eop[3];
    assign wr_vld_3 = top_wr_vld[3];
    assign rd_sop_3 = top_rd_sop[3];
    assign rd_eop_3 = top_rd_eop[3];
    assign rd_vld_3 = top_rd_vld[3];

    if(PORT_NUB > 4)begin

        (* MARK_DEBUG = "true" *)wire                            wr_sop_4;
        (* MARK_DEBUG = "true" *)wire                            wr_eop_4;
        (* MARK_DEBUG = "true" *)wire                            wr_vld_4;
        (* MARK_DEBUG = "true" *)wire                            rd_sop_4;
        (* MARK_DEBUG = "true" *)wire                            rd_eop_4;
        (* MARK_DEBUG = "true" *)wire                            rd_vld_4;

        assign wr_sop_4 = top_wr_sop[4];
        assign wr_eop_4 = top_wr_eop[4];
        assign wr_vld_4 = top_wr_vld[4];
        assign rd_sop_4 = top_rd_sop[4];
        assign rd_eop_4 = top_rd_eop[4];
        assign rd_vld_4 = top_rd_vld[4];

        (* MARK_DEBUG = "true" *)wire                            wr_sop_5;
        (* MARK_DEBUG = "true" *)wire                            wr_eop_5;
        (* MARK_DEBUG = "true" *)wire                            wr_vld_5;
        (* MARK_DEBUG = "true" *)wire                            rd_sop_5;
        (* MARK_DEBUG = "true" *)wire                            rd_eop_5;
        (* MARK_DEBUG = "true" *)wire                            rd_vld_5;

        assign wr_sop_5 = top_wr_sop[5];
        assign wr_eop_5 = top_wr_eop[5];
        assign wr_vld_5 = top_wr_vld[5];
        assign rd_sop_5 = top_rd_sop[5];
        assign rd_eop_5 = top_rd_eop[5];
        assign rd_vld_5 = top_rd_vld[5];

        (* MARK_DEBUG = "true" *)wire                            wr_sop_6;
        (* MARK_DEBUG = "true" *)wire                            wr_eop_6;
        (* MARK_DEBUG = "true" *)wire                            wr_vld_6;
        (* MARK_DEBUG = "true" *)wire                            rd_sop_6;
        (* MARK_DEBUG = "true" *)wire                            rd_eop_6;
        (* MARK_DEBUG = "true" *)wire                            rd_vld_6;

        assign wr_sop_6 = top_wr_sop[6];
        assign wr_eop_6 = top_wr_eop[6];
        assign wr_vld_6 = top_wr_vld[6];
        assign rd_sop_6 = top_rd_sop[6];
        assign rd_eop_6 = top_rd_eop[6];
        assign rd_vld_6 = top_rd_vld[6];

        (* MARK_DEBUG = "true" *)wire                            wr_sop_7;
        (* MARK_DEBUG = "true" *)wire                            wr_eop_7;
        (* MARK_DEBUG = "true" *)wire                            wr_vld_7;
        (* MARK_DEBUG = "true" *)wire                            rd_sop_7;
        (* MARK_DEBUG = "true" *)wire                            rd_eop_7;
        (* MARK_DEBUG = "true" *)wire                            rd_vld_7;

        assign wr_sop_7 = top_wr_sop[7];
        assign wr_eop_7 = top_wr_eop[7];
        assign wr_vld_7 = top_wr_vld[7];
        assign rd_sop_7 = top_rd_sop[7];
        assign rd_eop_7 = top_rd_eop[7];
        assign rd_vld_7 = top_rd_vld[7];

    end
endgenerate

(* MARK_DEBUG = "true" *)wire    [DATA_WIDTH-1 : 0]     wr_data[PORT_NUB-1 : 0];
(* MARK_DEBUG = "true" *)wire    [DATA_WIDTH-1 : 0]     rd_data[PORT_NUB-1 : 0];
(* MARK_DEBUG = "true" *)wire                                       top_full;
(* MARK_DEBUG = "true" *)wire                                       top_alm_ost_full;
wire                                                                top_dispatch_sel;
wire      [WIDTH_WIEGHT_TOTAL-1 : 0]                                top_wrr_wieght_in;
wire      [PORT_NUB-1 : 0]                                          top_ready;
wire      [WIDTH_WIEGHT-1 : 0]                                      wrr_wieght[PORT_NUB-1 : 0];

assign full = top_alm_ost_full;

wire      [WIDTH_WIEGHT_TOTAL-1 : 0]            top_wrr_wieght_in;
reg       [PORT_NUB-1 : 0]                      top_ready;

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
    .alm_ost_full       (top_alm_ost_full),
    .dispatch_sel       (top_dispatch_sel),
    .wrr_wieght_in      (top_wrr_wieght_in)
);

vio_1 dispatch 
(
  .clk              (clk_250Mhz),             // input wire clk
  .probe_out0       (top_dispatch_sel),         // output wire [0 : 0] probe_out0
  .probe_out1       (wrr_wieght[0]),            // output wire [2 : 0] probe_out1
  .probe_out2       (wrr_wieght[1]),            // output wire [2 : 0] probe_out2
  .probe_out3       (wrr_wieght[2]),            // output wire [2 : 0] probe_out3
  .probe_out4       (wrr_wieght[3])             // output wire [2 : 0] probe_out4
  .probe_out5       (wrr_wieght[4])             // output wire [2 : 0] probe_out4
  .probe_out6       (wrr_wieght[5])             // output wire [2 : 0] probe_out4
  .probe_out7       (wrr_wieght[6])             // output wire [2 : 0] probe_out4
  .probe_out8       (wrr_wieght[7])             // output wire [2 : 0] probe_out4
);

assign top_ready = {PORT_NUB{1'b1}};

generate 
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin: send

        assign rd_data[i]   =   top_rd_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
        assign top_wr_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]   =  wr_data[i];

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
            .wr_sop(top_wr_sop[i]),
            .wr_eop(top_wr_eop[i]),
            .wr_vld(top_wr_vld[i]),
            .wr_data(wr_data[i])
        );

        assign top_wrr_wieght_in[(i+1)*WIDTH_WIEGHT-1 : i*WIDTH_WIEGHT] = wrr_wieght[i];

    end

endgenerate

endmodule
