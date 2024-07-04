`include "../generate_parameter.vh"

module switch_module
#(
    parameter   PORT_NUB = 16
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    input   wire    [WIDTH_TOTAL-1 : 0]     rx_total,
    input   wire    [WIDTH_TOTAL-1 : 0]     tx_total,

    input   wire    [WIDTH_EXTERNAL_TOTAL-1 : 0]  external_in,
    output  wire    [WIDTH_EXTERNAL_TOTAL-1 : 0]  external_out,

    input   wire    [WIDTH_INTERNAL_TOTAL-1 : 0]  internal_in,
    output  wire    [WIDTH_INTERNAL_TOTAL-1 : 0]  internal_out
);

localparam  DATA_WIDTH                  = `DATA_WIDTH;
localparam  WIDTH_TOTAL                 = PORT_NUB * DATA_WIDTH;

localparam  WIDTH_INTERNAL_TOTAL        = PORT_NUB * DATA_WIDTH;
localparam  WIDTH_EXTERNAL              = $clog2(`PORT_NUB_TOTAL/PORT_NUB) * DATA_WIDTH; 
localparam  WIDTH_EXTERNAL_TOTAL        = PORT_NUB * WIDTH_EXTERNAL; 

generate
    genvar i;
    wire    [WIDTH_EXTERNAL_TOTAL + WIDTH_INTERNAL_TOTAL - 1 : 0]   ex_in,ex_out;
    wire    [WIDTH_EXTERNAL+DATA_WIDTH-1 : 0] port_in[PORT_NUB-1 : 0];
    wire    [WIDTH_EXTERNAL+DATA_WIDTH-1 : 0] port_out[PORT_NUB-1 : 0];

    for(i=0; i<PORT_NUB; i=i+1)begin: wiring


        assign  port_in[i] = {external_in[(i+1)*WIDTH_EXTERNAL-1 : i*WIDTH_EXTERNAL], internal_in[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]};
        assign  {external_out[(i+1)*WIDTH_EXTERNAL-1 : i*WIDTH_EXTERNAL], internal_out[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]} = port_out[i];

        assign  ex_in[(i+1)*(WIDTH_EXTERNAL+DATA_WIDTH)-1 : i*(WIDTH_EXTERNAL+DATA_WIDTH)] = port_in[i];
        assign  port_out[i] = ex_out[(i+1)*(WIDTH_EXTERNAL+DATA_WIDTH)-1 : i*(WIDTH_EXTERNAL+DATA_WIDTH)];

    end

    if(PORT_NUB == 1)begin

        unit unit
        (
            .clk(clk),
            .rst_n(rst_n),
            .rx(rx_total),
            .tx(tx_total),
            .data_in(ex_in),
            .data_out(ex_out)
        );

    end
    else begin

        wire    [WIDTH_INTERNAL_TOTAL/2-1 : 0]    internal_1to2,internal_2to1;
        wire    [WIDTH_TOTAL/2-1 : 0]       rx_1,tx_1;
        wire    [WIDTH_TOTAL/2-1 : 0]       rx_2,tx_2;

        switch_module#(.PORT_NUB(PORT_NUB/2))
        switch_module_1
        (
            .clk(clk),
            .rst_n(rst_n),
            .rx_total(rx_1),
            .tx_total(tx_1),
            .internal_in(internal_2to1),
            .internal_out(internal_1to2),
            .external_in(ex_in),
            .external_out(ex_out)
        );

        switch_module#(.PORT_NUB(PORT_NUB/2))
        switch_module_2
        (
            .clk(clk),
            .rst_n(rst_n),
            .rx_total(rx_2),
            .tx_total(tx_2),
            .internal_in(internal_1to2),
            .internal_out(internal_2to1),
            .external_in(ex_in),
            .external_out(ex_out)
        );

        assign {rx_2, rx_1} = rx_total;
        assign {tx_2, tx_1} = tx_total;

    end

endgenerate

endmodule
