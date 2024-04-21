`timescale 1ns/1ns
`include "../../generate_parameter.vh"
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

reg     [PORT_NUB-1 : 0]                port_valid_in;
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
        assign port_in[(i+1)*WIDTH_PORT_IN-1 : i*WIDTH_PORT_IN] = {port_valid_in[i],rx_port_in[i],tx_port_in[i],data_in[i]};
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
            port_valid_in[j] = 0;
            rx_port_in[j] = 0;
            tx_port_in[j] = 0;
        end
    end
endtask

task rd;
    input   integer rx_sel;
    input   integer tx_sel;
    begin
        @(negedge clk)begin
            rd_sel[rx_sel] <= tx_sel;
            rd_en[rx_sel] <= 1'b1;
        end
        #(`CLK_TIME);
        rd_en[rx_sel] = 1'b0;
    end
endtask

integer n = 0;
task update;
    integer j;
    begin
        @(posedge clk)begin

            for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
                port_valid_in[j] = 1;
                // rx_port_in[j] = $random % PORT_NUB_TOTAL;
                rx_port_in[j] = PORT_NUB_TOTAL-1 - j;
                tx_port_in[j] = j;
                data_in[j] = (PORT_NUB_TOTAL-1 - j)*10 + n ;
            end
            #`CLK_TIME;
            for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
                port_valid_in[j] = 0;
            end
        end
    end
endtask


integer n,m;
initial 
begin

    init();
    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(5*`CLK_TIME);

    repeat(20)begin
        update();
        n = n + 1;
        // tx_port_in[0] = 4;
        // tx_port_in[1] = 1;
        // tx_port_in[2] = 3;
        // tx_port_in[3] = 2;
    end

    #(30*`CLK_TIME);

    repeat(10)begin
        rd(1,2);
    end
    repeat(10)begin
        rd(1,1);
    end
    repeat(10)begin
        rd(1,3);
    end
    repeat(10)begin
        rd(1,0);
    end
    // for(n=0; n<PORT_NUB; n=n+1)begin
    //     for(m=0; m<PORT_NUB; m=m+1)begin
    //         rd(n,m);
    //     end
    // end

    #(20*`CLK_TIME);
    $stop();

end

endmodule

