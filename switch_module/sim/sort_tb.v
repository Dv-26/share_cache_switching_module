`timescale 1ns/1ns
`include "../defind.vh"
`define CLK_TIME 2

module sort_tb();

 
localparam  PORT_NUB = `PORT_NUB_TOTAL;
localparam  PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam  DATA_WIDTH  =   `DATA_WIDTH;
localparam  WIDTH_PORT  =   2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_TOTAL =   PORT_NUB * WIDTH_PORT; 

reg                                     clk,rst_n;
wire    [WIDTH_TOTAL-1:0]               port_in;
wire    [WIDTH_TOTAL-1:0]               port_out;

reg     [$clog2(PORT_NUB_TOTAL)-1 :0]   rx_port_in[PORT_NUB_TOTAL-1:0];
reg     [$clog2(PORT_NUB_TOTAL)-1 :0]   tx_port_in[PORT_NUB_TOTAL-1:0];
reg     [DATA_WIDTH-1:0]                data_in[PORT_NUB_TOTAL-1:0];

wire    [$clog2(PORT_NUB_TOTAL)-1 :0]   rx_port_out[PORT_NUB_TOTAL-1:0];
wire    [$clog2(PORT_NUB_TOTAL)-1 :0]   tx_port_out[PORT_NUB_TOTAL-1:0];
wire    [DATA_WIDTH-1:0]                data_out[PORT_NUB_TOTAL-1:0];

generate 
    genvar i;
    for(i=0; i<16; i=i+1)begin :loop
        assign {rx_port_out[i],tx_port_out[i],data_out[i]} = port_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
        assign port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = {rx_port_in[i],tx_port_in[i],data_in[i]};
    end
endgenerate

always #(`CLK_TIME/2) clk = !clk;

sort_module
#(
    .PORT_NUB(PORT_NUB)
)
sort_module
(
    .clk(clk),
    .rst_n(rst_n),
    .port_in(port_in), 
    .port_out(port_out)
);

task update;
    integer j;
    begin
        @(posedge clk)begin

            for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
               rx_port_in[j] = $random % PORT_NUB_TOTAL;
               // rx_port_in[j] = 0;
               // data_in[j] = 0;
            end

        end
    end
endtask


initial 
begin

    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(5*`CLK_TIME);

    repeat(10)begin
        update();
        // tx_port_in[0] = 4;
        // tx_port_in[1] = 1;
        // tx_port_in[2] = 3;
        // tx_port_in[3] = 2;
    end

    #(20*`CLK_TIME);
    $stop();

end

endmodule
