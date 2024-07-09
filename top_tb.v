`timescale 1ns/1ps
`include "./generate_parameter.vh"

module top_tb();

localparam  CLK_TIME = 8;
localparam  INTERNAL_CLK_TIME = 4;

reg clk,rst_n;

always #(CLK_TIME/2) clk = !clk;

initial 
begin
    clk = 1;
    rst_n = 0;
    #(10*CLK_TIME) 
    rst_n = 1;
end

wire    external_clk,internal_clk;
wire    sys_rst_n;

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

wire      [PORT_NUB_TOTAL-1 : 0]              top_wr_sop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_wr_eop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_wr_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]            top_wr_data;
wire      [PORT_NUB_TOTAL-1 : 0]              top_rd_sop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_rd_eop;          
wire      [PORT_NUB_TOTAL-1 : 0]              top_rd_vld;          
wire      [DATA_WIDTH_TOTAL-1 : 0]            top_rd_data;
wire                                          top_full;
wire                                          top_alm_ost_full;
reg       [PORT_NUB_TOTAL-1 : 0]              top_ready;

top_nxn top_tb
(
    .external_clk(external_clk),
    .internal_clk(internal_clk),
    .rst_n(sys_rst_n),
    .wr_sop(top_wr_sop),          
    .wr_eop(top_wr_eop),          
    .wr_vld(top_wr_vld),          
    .wr_data(top_wr_data),
    .rd_sop(top_rd_sop),          
    .rd_eop(top_rd_eop),          
    .rd_vld(top_rd_vld),          
    .rd_data(top_rd_data),
    .full(top_full),
    .alm_ost_full(top_alm_ost_full),
    .ready(top_ready)
);

wire    [10:0]   tx_cnt,rx_cnt;
cnt tx_package_cnt
(
    .clk(external_clk),
    .rst_n(sys_rst_n),
    .in(top_wr_sop),
    .cnt_out(tx_cnt)
);
cnt rx_package_cnt
(
    .clk(external_clk),
    .rst_n(sys_rst_n),
    .in(top_rd_sop),
    .cnt_out(rx_cnt)
);

reg                             send_start[PORT_NUB_TOTAL-1 : 0];
reg     [WIDTH_SEL-1 : 0]       send_dest[PORT_NUB_TOTAL-1 : 0];
reg     [WIDTH_PRIORITY-1 : 0]  send_priority[PORT_NUB_TOTAL-1 : 0];
reg     [WIDTH_LENGTH-1 : 0]    send_length[PORT_NUB_TOTAL-1 : 0];
wire    [PORT_NUB_TOTAL-1 : 0]  send_done;
wire    [PORT_NUB_TOTAL-1 : 0]  send_ready;

generate
    genvar i;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: layout

        wire                            start;
        wire                            done;
        wire                            ready;
        wire    [WIDTH_SEL-1 : 0]       dest;
        wire    [WIDTH_PRIORITY-1 : 0]  priority;
        wire    [WIDTH_LENGTH-1 : 0]    length;

        wire                            wr_sop;
        wire                            wr_eop;
        wire                            wr_vld;
        wire    [DATA_WIDTH-1 : 0]      wr_data;

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
            .wr_sop(wr_sop),
            .wr_eop(wr_eop),
            .wr_vld(wr_vld),
            .wr_data(wr_data)
        );

        assign start = send_start[i];
        assign send_done[i] = done;
        assign send_ready[i] = ready;
        assign dest = send_dest[i];
        assign priority = send_priority[i];
        assign length = send_length[i];
        assign top_wr_sop[i] = wr_sop;
        assign top_wr_eop[i] = wr_eop;
        assign top_wr_vld[i] = wr_vld;
        assign top_wr_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] = wr_data;

        wire                            rd_sop;
        wire                            rd_eop;
        wire                            rd_vld;
        wire    [DATA_WIDTH-1 : 0]      rd_data;

        assign rd_sop = top_rd_sop[i];
        assign rd_eop = top_rd_eop[i];
        assign rd_vld = top_rd_vld[i];
        assign rd_data = top_rd_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];

    end
endgenerate

task init;
    integer i;
    begin
        for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin
            top_ready[i] = 0;
            send_start[i] = 0;
            send_dest[i] = 0;
            send_priority[i] = 0;
            send_length[i] = 0;
        end
    end
endtask

task send;
    input   integer tx;
    input   integer rx;
    input   integer priority;
    input   integer data_length;
    begin
        if(tx != rx)begin
            @(posedge clk)begin
                send_dest[tx] <= rx;
                send_priority[tx] <= priority;
                send_length[tx] <= data_length;
                send_start[tx] <= 1;
            end
            #(CLK_TIME)
            send_start[tx] = 0;
        end
    end
endtask

task random_send;
    integer rx;
    integer priority;
    integer data_length;
    integer n;
    begin
        for(n=0; n<PORT_NUB_TOTAL; n=n+1)begin
            if(send_ready[n])begin
                rx = {$random} % PORT_NUB_TOTAL;
                //priority = {$random} % `PRIORITY;
                priority = 1;
                data_length = ({$random} % 50) + 16;
                send(n,rx,priority,data_length);
            end
        end
    end
endtask

task wada;
    integer a;
    begin
        for(a=0; a<PORT_NUB_TOTAL; a=a+1)begin
            top_ready[a] = 1;
        end
    end
endtask


integer times;
integer n;
initial 
begin
    init();
    wada();
    top_ready[0] = 0;
    #(50*CLK_TIME)
    for(times = 0; times<500; times=times+1)begin
        if(times == 250)
            top_ready[0] = 1;
        wait(|send_ready)
            random_send();
            #((500)*CLK_TIME);
    end
    #(600*CLK_TIME)
    #(2500*CLK_TIME)
    $stop();
end


endmodule



module cnt
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire    [PORT_NUB_TOTAL-1 : 0]  in,
    output  wire    [10:0]                  cnt_out
);

localparam  PORT_NUB_TOTAL      =   `PORT_NUB_TOTAL;
localparam  WIDTH_SEL           =   $clog2(PORT_NUB_TOTAL);

wire    [PORT_NUB_TOTAL-1 : 0]  rise;
reg     [WIDTH_SEL-1 : 0]       sum;
reg     [10:0]   cnt;

generate

    genvar i;

    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop

        reg [1:0]   shift_reg;

        always@ (posedge clk or negedge rst_n)begin
            if(!rst_n)
                shift_reg <= 0;
            else 
                shift_reg <= {shift_reg[0],  in[i]};
        end

        assign rise[i] = shift_reg[1] && ~shift_reg[0];

    end

endgenerate

integer n;
always @(*)begin
    sum = rise[0];
    for(n=1; n<PORT_NUB_TOTAL; n=n+1)begin
        sum = sum + rise[n];
    end
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= 0;
    else
        cnt <= cnt + sum;
end

assign cnt_out = cnt;

endmodule

