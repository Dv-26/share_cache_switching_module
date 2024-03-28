`timescale 1ns / 1ps

module exchange_unit
#(
    parameter   DATA_WIDTH = 128,
    parameter   PORT_NUB = 16
)
(
    input       wire        clk,
    input       wire        rst_n,

    input       wire    [WIDTH_RORT-1:0]    port_in_1,
    output      reg     [WIDTH_RORT-1:0]    port_out_1,

    input       wire    [WIDTH_RORT-1:0]    port_in_2,
    output      reg     [WIDTH_RORT-1:0]    port_out_2
);

localparam  WIDTH_RORT  =   2 * $clog2(PORT_NUB) + DATA_WIDTH;

wire    [$clog2(PORT_NUB)-1 : 0]    tx_ports_1,rx_ports_1;    
wire    [DATA_WIDTH-1 : 0]          data_1;
wire    [$clog2(PORT_NUB)-1 : 0]    tx_ports_2,rx_ports_2;    
wire    [DATA_WIDTH-1 : 0]          data_2;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        port_out_1 <= {WIDTH_RORT{1'b0}};
        port_out_2 <= {WIDTH_RORT{1'b0}};
    end
    else begin
        if(rx_ports_1 < rx_ports_2)begin
            port_out_1 <= {rx_ports_1,tx_ports_1,data_1};
            port_out_2 <= {rx_ports_2,tx_ports_2,data_2};
        end
        else begin
            port_out_2 <= {rx_ports_1,tx_ports_1,data_1};
            port_out_1 <= {rx_ports_2,tx_ports_2,data_2};
        end
    end
end

assign {rx_ports_1,tx_ports_1,data_1} = port_in_1;
assign {rx_ports_2,tx_ports_2,data_2} = port_in_2;

endmodule
