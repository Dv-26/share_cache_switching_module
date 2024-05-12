`timescale 1ns/1ps
`include "../generate_parameter.vh"
`define CLK_TIME 4
`define SIM


module switch_tb();

reg                                     clk,rst_n;

always #(`CLK_TIME/2) clk = !clk;

localparam  PORT_NUB = `PORT_NUB_TOTAL;
localparam  PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam  DATA_WIDTH  =   `DATA_WIDTH;
localparam  WIDTH_PORT_IN  =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_TOTAL_IN =   PORT_NUB * WIDTH_PORT_IN; 
localparam  WIDTH_PORT_OUT = `DATA_WIDTH;
localparam  WIDTH_TOTAL_OUT =   PORT_NUB * WIDTH_PORT_OUT; 

localparam  WIDTH_SEL   =   $clog2(PORT_NUB);

reg                                     clk,rst_n;
wire    [WIDTH_TOTAL_IN-1:0]            port_in;
wire    [WIDTH_TOTAL_OUT-1:0]           port_out;
wire    [WIDTH_SEL*PORT_NUB-1 : 0]      rd_sel_total;
reg     [PORT_NUB-1 : 0]                rd_en;
wire    [PORT_NUB**2-1 : 0]             empty;
wire                                    full;

wire    [PORT_NUB-1 : 0]                port_vaild_in;
wire    [WIDTH_SEL-1 : 0]               rx_port_in[PORT_NUB-1 : 0];
wire    [WIDTH_SEL-1 : 0]               tx_port_in[PORT_NUB-1 : 0];
wire    [DATA_WIDTH-1 : 0]              data_in[PORT_NUB-1 : 0];

wire    [DATA_WIDTH-1 : 0]              data_out[PORT_NUB-1 : 0];
reg     [WIDTH_SEL-1 : 0]               rd_sel[PORT_NUB-1 : 0];
wire    [PORT_NUB-1 : 0]                empty_out[PORT_NUB-1 : 0];

wire                                    tx_done[PORT_NUB-1 : 0];
reg                                     tx_start[PORT_NUB-1 : 0];
reg     [WIDTH_SEL-1 : 0]               rx[PORT_NUB-1 : 0];

generate 
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin :loop

        tx_module
        #(
            .dest(i)
        )
        tx_module
        (
            .clk(clk),
            .rst_n(rst_n),
            .start(tx_start[i]),
            .rx_port(rx_port_in[i]),
            .tx_port(tx_port_in[i]),
            .data_port(data_in[i]),
            .vaild(port_vaild_in[i]),
            .done(tx_done[i])
        );

        assign data_out[i] = port_out[(i+1)*WIDTH_PORT_OUT-1 : i*WIDTH_PORT_OUT];
        assign port_in[(i+1)*WIDTH_PORT_IN-1 : i*WIDTH_PORT_IN] = {port_vaild_in[i],rx_port_in[i],tx_port_in[i],data_in[i]};
        assign rd_sel_total[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = rd_sel[i];
        // assign rd_sel[i] = rd_sel_total[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign empty_out[i] = empty[(i+1)*PORT_NUB-1 : i*PORT_NUB];
    end
endgenerate


switch_moudle switch_moudle
(
    .clk(clk),
    .rst_n(rst_n),
    .port_in(port_in),
    .port_out(port_out),
    .rd_sel(rd_sel_total),
    .rd_en(rd_en),
    .empty(empty),
    .full(full)
);

task init;
    integer j;        
    begin
        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
            rd_sel[j] = 0;
            rd_en[j] = 0;
            tx_start[j] = 0;
            // port_vaild_in[j] = 0;
            // rx_port_in[j] = 0;
            // tx_port_in[j] = 0;
        end
    end
endtask

// task tx;
//     input   integer tx;
//     input   integer rx;
//
//     integer i;
//     begin
//         for(i=0; i<10; i=i+1)begin
//             port_vaild_in[tx] <= 1'b1;
//             rx_port_in[tx]  <= rx;
//             tx_port_in[tx]  <= tx;
//             data_in[tx]      <= tx * 10 + rx;
//             #`CLK_TIME;
//         end
//         port_vaild_in[tx] <= 1'b0;
//     end
// endtask

task rd;
    input   integer rx_sel;
    integer i;
    begin
        @(negedge clk)begin
            for(i=0; i<PORT_NUB; i=i+1)begin: loop
                if(!empty_out[rx_sel][i])begin
                    rd_sel[rx_sel] <= i;
                    rd_en[rx_sel] <= 1'b1;
                    disable loop;
                end
            end
        end
    end
endtask

integer n,m;

initial
begin
    while(1)begin
        for(m=0; m<PORT_NUB; m=m+1)begin
            rd(m);
        end
    end
end

initial 
begin
    init();
    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(5*`CLK_TIME);

    for(n=0; n<PORT_NUB; n=n+1)begin
        tx_start[n] = 1;
    end


    #(100*`CLK_TIME);
    $stop();

end

endmodule



