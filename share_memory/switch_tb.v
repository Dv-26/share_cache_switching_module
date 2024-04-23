`timescale 1ns/1ns
`include "./generate_parameter.vh"
`define CLK_TIME 2


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

reg     [PORT_NUB-1 : 0]                port_vaild_in;
reg     [WIDTH_SEL-1 : 0]               rx_port_in[PORT_NUB-1 : 0];
reg     [WIDTH_SEL-1 : 0]               tx_port_in[PORT_NUB-1 : 0];
reg     [DATA_WIDTH-1 : 0]              data_in[PORT_NUB-1 : 0];

wire    [DATA_WIDTH-1 : 0]              data_out[PORT_NUB-1 : 0];
reg     [WIDTH_SEL-1 : 0]               rd_sel[PORT_NUB-1 : 0];
wire    [PORT_NUB-1 : 0]                empty_out[PORT_NUB-1 : 0];

generate 
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin :loop
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
    .empty(empty)
);

task init;
    integer j;        
    begin
        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
            rd_sel[j] = 0;
            rd_en[j] = 0;
            port_vaild_in[j] = 0;
            rx_port_in[j] = 0;
            tx_port_in[j] = 0;
        end
    end
endtask

task tx;
    // input   integer tx;
    input   integer rx;
    integer i,j;
    begin
        for(i=0; i<10; i=i+1)begin
            @(posedge clk)begin

                for(j=0; j<PORT_NUB; j=j+1)begin
                    port_vaild_in[j] <= 1;
                    rx_port_in[j] <= rx;
                    tx_port_in[j] <= j;
                    data_in[j] <= rx * 10 + i;
                end

            end
        end
        #`CLK_TIME
        port_vaild_in <= 0;
    end
endtask

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
        #(`CLK_TIME);
        rd_en[rx_sel] = 1'b0;
    end
endtask

always begin
    // fork
        rd(0);
        // rd(1);
        // rd(2);
        // rd(3);
    // join
end


integer n,m;
initial 
begin
    init();
    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(5*`CLK_TIME);

    // tx(0,1);

    tx(0);
    // fork
    // join

    #(30*`CLK_TIME);
    #(20*`CLK_TIME);
    $stop();

end


endmodule

