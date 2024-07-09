`include "./generate_parameter.vh"

module top_test
(
    input   wire    clk,
    input   wire    rst_n,

    output  wire    full  
);

localparam  PORT_NUB_TOTAL      =   `PORT_NUB_TOTAL;
localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  DATA_WIDTH_TOTAL    =   PORT_NUB_TOTAL*`DATA_WIDTH;

localparam  WIDTH_LENGTH    =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY  =   $clog2(`PRIORITY);
localparam  WIDTH_HAND      =   16+WIDTH_LENGTH+WIDTH_PRIORITY+WIDTH_SEL;   
localparam  WIDTH_SIG_PORT  =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT      =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_FILTER    =   2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ0      =   $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ1      =   `DATA_WIDTH;
localparam  WIDTH_TOTAL     =   PORT_NUB_TOTAL * WIDTH_PORT; 
localparam  WIDTH_SEL       =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_SEL_TOTAL =   PORT_NUB_TOTAL * WIDTH_SEL; 

wire    internal_clk;

(* MARK_DEBUG="true" *)wire    external_clk;

(* MARK_DEBUG="true" *)wire    sys_rst_n;

clk_wiz_0 clk_generate
(
    // Clock out ports
    .clk_out1(external_clk),    // output clk_out1 100Mhz
    .clk_out2(internal_clk),    // output clk_out2 50Mhz
    // Status and control signals
    .reset(~rst_n),         // input reset
    .locked(locked),        // output locked
    // Clock in ports
    .clk_in1(clk)           // input clk_in1
);      
assign sys_rst_n = rst_n & locked;

wire      [PORT_NUB_TOTAL-1 : 0]              top_wr_sop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_wr_eop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_wr_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]            top_wr_data;
wire      [PORT_NUB_TOTAL-1 : 0]              top_rd_sop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_rd_eop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_rd_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]            top_rd_data;
(* MARK_DEBUG="true" *)wire                                          top_full;
(* MARK_DEBUG="true" *)wire                                          top_alm_ost_full;
assign full = top_full;
wire      [PORT_NUB_TOTAL-1 : 0]              top_ready;

top_nxn top_test 
(
    .internal_clk       (internal_clk),
    .external_clk       (external_clk),
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


(* MARK_DEBUG="true" *) wire                        wr_sop[PORT_NUB_TOTAL-1 : 0];
(* MARK_DEBUG="true" *) wire                        wr_eop[PORT_NUB_TOTAL-1 : 0];
(* MARK_DEBUG="true" *) wire                        wr_vld[PORT_NUB_TOTAL-1 : 0];
(* MARK_DEBUG="true" *) wire    [DATA_WIDTH-1 : 0]  wr_data[PORT_NUB_TOTAL-1 : 0];

(* MARK_DEBUG="true" *) wire                        rd_sop[PORT_NUB_TOTAL-1 : 0];
(* MARK_DEBUG="true" *) wire                        rd_eop[PORT_NUB_TOTAL-1 : 0];
(* MARK_DEBUG="true" *) wire                        rd_vld[PORT_NUB_TOTAL-1 : 0];
(* MARK_DEBUG="true" *) wire    [DATA_WIDTH-1 : 0]  rd_data[PORT_NUB_TOTAL-1 : 0];

generate
    genvar i;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: link

        (* MARK_DEBUG="true" *) wire                            start;
        wire                            done;
        wire                            ready;
        wire    [WIDTH_SEL-1 : 0]       dest;
        wire    [WIDTH_PRIORITY-1 : 0]  priority;
        wire    [WIDTH_LENGTH-1 : 0]    length;

        vio_1 vio 
        (
          .clk(external_clk),                // input wire clk
          .probe_out0(start),  // output wire [0 : 0] probe_out0
          .probe_out1(priority),  // output wire [2 : 0] probe_out1
          .probe_out2(dest),  // output wire [1 : 0] probe_out2
          .probe_out3(length)  // output wire [7 : 0] probe_out3
        );

        send_module
        #(
            .tx_port(i)
        )
        send_module
        (
            .clk(external_clk),
            .rst_n(sys_rst_n),
            .start(start),
            .ready(ready),
            .done(done),
            .dest(dest),
            .priority(priority),
            .length(length),
            .wr_sop(wr_sop[i]),
            .wr_eop(wr_eop[i]),
            .wr_vld(wr_vld[i]),
            .wr_data(wr_data[i])
        );

        assign top_ready[i]  = 1'b1;
        assign top_wr_sop[i] = wr_sop[i];
        assign top_wr_eop[i] = wr_eop[i];
        assign top_wr_vld[i] = wr_vld[i];
        assign top_wr_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] = wr_data[i];

        assign rd_sop[i] = top_rd_sop[i];
        assign rd_eop[i] = top_rd_eop[i];
        assign rd_vld[i] = top_rd_vld[i];
        assign rd_data[i] = top_rd_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
    end
endgenerate

endmodule
