`timescale 1ns/1ns 
`include "../generate_parameter.vh"

module filter
#(
    parameter   dest   =   0
)
(
    input       wire                                clk,
    input       wire                                rst_n,
    input       wire    [WIDTH_TOTAL_IN - 1 : 0]    port_in, 
    output      wire    [WIDTH_TOTAL_OUT - 1 : 0]   port_out,
    output      wire    [`PORT_NUB_TOTAL-1 : 0]     port_vaild
);

localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL); 
localparam  WIDTH_PORT_IN  = 1+2*WIDTH_SEL+`DATA_WIDTH;
localparam  WIDTH_PORT_OUT  = 2*WIDTH_SEL+`DATA_WIDTH;
localparam  WIDTH_TOTAL_IN = `PORT_NUB_TOTAL * WIDTH_PORT_IN;
localparam  WIDTH_TOTAL_OUT = `PORT_NUB_TOTAL * WIDTH_PORT_OUT;

wire    [WIDTH_TOTAL_OUT - 1 : 0]   port_out_n;

generate
    genvar i;
    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin : loop
        wire    [$clog2(`PORT_NUB_TOTAL)-1 : 0]    tx_ports,rx_ports;    
        wire    [`DATA_WIDTH-1 : 0]          data;
        wire                                valid;
        assign  {valid,rx_ports,tx_ports,data} = port_in[(i+1)*WIDTH_PORT_IN-1 : i*WIDTH_PORT_IN];
        assign  port_out_n[(i+1)*WIDTH_PORT_OUT-1 : i*WIDTH_PORT_OUT] = (rx_ports == dest)? {rx_ports,tx_ports,data}:{WIDTH_PORT_OUT{1'b0}};
        assign  port_vaild[i] = (valid == 1'b1)? (rx_ports == dest)? 1'b1:1'b0:1'b0;
    end

    if(`PIPELINE)begin
        shift_reg                       //流水线对齐
        #(
            .DELAY(WIDTH_SEL),
            .WIDTH(WIDTH_TOTAL_OUT),
            .NUB(1)
        )
        port_out_shift
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(port_out_n), 
            .port_out(port_out)
        );
    end
    else begin
        assign port_out = port_out_n;
    end

endgenerate


endmodule

