`timescale 1ns/1ns
`include "./generate_parameter.vh"

module dispatch_test();
localparam  CLK_TIME = 2;

reg clk,rst_n;

always #(CLK_TIME/2) clk = !clk;

localparam  PORT_NUB            =   `PORT_NUB_TOTAL;
localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  DATA_WIDTH_TOTAL    =   PORT_NUB * DATA_WIDTH;
localparam  WIDTH_SEL           =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY      =   $clog2(`PRIORITY);
localparam  WIDTH_WIEGHT        =   $clog2(`PRIORITY);
localparam  WIDTH_WIEGHT_TOTAL  =   PORT_NUB * WIDTH_WIEGHT;

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

wire      [PORT_NUB-1 : 0]              top_wr_sop;          
wire      [PORT_NUB-1 : 0]              top_wr_eop;          
wire      [PORT_NUB-1 : 0]              top_wr_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]      top_wr_data;
wire      [PORT_NUB-1 : 0]              top_rd_sop;          
wire      [PORT_NUB-1 : 0]              top_rd_eop;          
wire      [PORT_NUB-1 : 0]              top_rd_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]      top_rd_data;
wire                                    top_alm_ost_full;
wire      [WIDTH_WIEGHT_TOTAL-1 : 0]    top_wrr_wieght_in;

reg       [PORT_NUB-1 : 0]              top_ready;
reg                                     top_dispatch_sel;
reg       [WIDTH_WIEGHT-1 : 0]          wrr_wieght[PORT_NUB-1 : 0];

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

reg                            send_start        [PORT_NUB-1 : 0];
reg                            send_single       [PORT_NUB-1 : 0];
reg    [WIDTH_SEL-1 : 0]       send_dest         [PORT_NUB-1 : 0];
reg    [WIDTH_PRIORITY-1 : 0]  send_priority     [PORT_NUB-1 : 0];
reg    [WIDTH_LENGTH-1 : 0]    send_length       [PORT_NUB-1 : 0];
reg    [19 : 0]                send_send_cycle   [PORT_NUB-1 : 0];
wire                           send_ready        [PORT_NUB-1 : 0];
wire                           send_done         [PORT_NUB-1 : 0];

generate 
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin: send

        wire                            wr_sop;
        wire                            wr_vld;
        wire    [DATA_WIDTH-1 : 0]      wr_data;
        wire                            wr_eop;

        wire                            rd_sop;
        wire                            rd_vld;
        wire    [DATA_WIDTH-1 : 0]      rd_data;
        wire                            rd_eop;

        assign  rd_data        = top_rd_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
        assign  rd_sop         = top_rd_sop[i];
        assign  rd_eop         = top_rd_eop[i];
        assign  rd_vld         = top_rd_vld[i];

        assign  top_wr_sop[i]  = wr_sop; 
        assign  top_wr_eop[i]  = wr_eop; 
        assign  top_wr_vld[i]  = wr_vld; 
        assign  top_wr_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] = wr_data; 

        assign  top_wrr_wieght_in[(i+1)*WIDTH_WIEGHT-1 : i*WIDTH_WIEGHT] = wrr_wieght[i];

        send_module
        #(
            .tx_port(i)
        )
        send_module
        (
            .clk            (clk_250Mhz),
            .rst_n          (sys_rst_n),
            .start          (send_start[i]),
            .single         (send_single[i]),
            .send_cycle     (send_send_cycle[i]),
            .done           (send_done[i]),
            .ready          (send_ready[i]),
            .dest           (send_dest[i]),
            .priority       (send_priority[i]),
            .length         (send_length[i]),
            .wr_sop         (wr_sop),
            .wr_eop         (wr_eop),
            .wr_vld         (wr_vld),
            .wr_data        (wr_data)
        );

    end

endgenerate

task init;
    integer i;
    begin
        top_dispatch_sel = 1; //默认sp调度
        for(i=0; i<PORT_NUB; i=i+1)begin
            top_ready[i] = 1;
            send_start[i] = 0;
            send_dest[i] = 0;
            send_priority[i] = 0;
            send_length[i] = 0;
            send_single[i] = 0;
            send_send_cycle[i] = 0;
            wrr_wieght[i] = 1;
        end
    end
endtask

initial begin
    clk = 0;
    rst_n = 0;
    init();

    // top_dispatch_sel = 0; //wrr调度
    top_dispatch_sel = 1; //sp调度
    wrr_wieght[0] = 1;
    wrr_wieght[1] = 1;
    wrr_wieght[2] = 3;
    wrr_wieght[3] = 1;

    #(10*CLK_TIME);
    rst_n = 1;
    #(10*CLK_TIME);
    send_length[1] = 30;
    send_send_cycle[1] = 100;
    send_dest[1] = 0;
    send_start[1] = 1;
    send_priority[1] = 1;
    
    send_length[2] = 30;
    send_send_cycle[2] = 100;
    send_dest[2] = 0;
    send_start[2] = 1;
    send_priority[2] = 2;

    send_length[3] = 30;
    send_send_cycle[3] = 100;
    send_dest[3] = 0;
    send_start[3] = 1;
    send_priority[3] = 3;

    #(1000*CLK_TIME);
    $stop();
end

endmodule
