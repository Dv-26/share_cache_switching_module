`timescale 1ns/1ps

module handshake_tb;

reg tx_clk,rx_clk,rst_n;

localparam IN_CLK_TIME  = 4;  
localparam OUT_CLK_TIME = 9;  
always #(IN_CLK_TIME/2)     tx_clk = !tx_clk;
always #(OUT_CLK_TIME/2)    rx_clk = !rx_clk;

initial
begin
    data_in = 0;
    rx_ready = 0;
    tx_valid = 0;
    tx_clk = 0;
    rx_clk = 1;
    rst_n = 0;
    #(10*IN_CLK_TIME);
    rst_n = 1;
    #(10*IN_CLK_TIME);
    @(posedge tx_clk)begin
        tx_valid <= 1;
        data_in <= 1;
    end

end

reg             tx_valid;
reg     [4:0]   data_in;
reg             rx_ready;
wire            tx_ready;     
wire    [4:0]   data_out;
wire            rx_valid;


cdc_handshake 
#(
    .DATA_WIDTH(5)
)
cdc_handshake
(
    .rst_n(rst_n),
    .tx_clk(tx_clk),
    .rx_clk(rx_clk),
    .tx_valid(tx_valid),
    .data_in(data_in),
    .tx_ready(tx_ready),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),
    .data_out(data_out)
);


endmodule
