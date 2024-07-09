`timescale 1ns/1ns
`include "./generate_parameter.vh"

module send_tb();
localparam  CLK_TIME = 8;

reg clk,rst_n;

always #(CLK_TIME/2) clk = !clk;

localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  WIDTH_SEL           =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY      =   $clog2(`PRIORITY);

reg                             start;
reg                             single;
reg     [WIDTH_SEL-1 : 0]       dest;
reg     [WIDTH_PRIORITY-1 : 0]  priority;
reg     [WIDTH_LENGTH-1 : 0]    length;
reg     [19 : 0]                send_cycle;

wire                            ready;
wire                            done;
wire                            wr_sop;
wire                            wr_eop;
wire                            wr_vld;
wire    [DATA_WIDTH-1 : 0]      wr_data;

send_module
#(
    .tx_port(2)
)
send_module
(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .single(single),
    .send_cycle(send_cycle),
    .done(done),
    .ready(ready),
    .dest(dest),
    .priority(priority),
    .length(length),
    .wr_sop(wr_sop),
    .wr_eop(wr_eop),
    .wr_vld(wr_vld),
    .wr_data(wr_data)
);

initial 
begin
    clk = 1;
    rst_n = 0;
    start = 0;
    single = 0;
    priority = 2;
    send_cycle = 20;
    dest = 2;
    length = 10;
    #(10*CLK_TIME) 
    rst_n = 1;
    #(5*CLK_TIME) 
    start = 1;
    #(50*CLK_TIME);
    start = 0;
    #(30*CLK_TIME) 
    start = 1;
    single = 1;
    #(50*CLK_TIME);
    $stop();
end

endmodule
