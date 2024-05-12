`timescale 1ns/1ns
`include "../../generate_parameter.vh"
`define CLK_TIME 2

module  ctrl_unit_tb();

reg                                     clk,rst_n;

always #(`CLK_TIME/2) clk = !clk;


localparam WIDTH_SEL_TOTAL  = PORT_NUB * WIDTH_SEL; 
localparam WIDTH_SEL        = $clog2(`PORT_NUB_TOTAL);
localparam PORT_NUB         = `PORT_NUB_TOTAL;

wire    [WIDTH_SEL-1 : 0]       select[PORT_NUB-1 : 0];
wire    [WIDTH_SEL-1 : 0]       sel_mux[PORT_NUB-1 : 0];

wire    [PORT_NUB-1 : 0]        rd_out;
wire    [WIDTH_SEL_TOTAL-1 : 0] rd_sel;
wire    [WIDTH_SEL_TOTAL-1 : 0] mux_sel;
reg     [PORT_NUB-1 : 0]        full_in;


mux_ctrl mux_ctrl_tb
(
    .clk(clk),
    .rst_n(rst_n),
    .rd_out(rd_out),
    .rd_sel(rd_sel),
    .mux_sel(mux_sel),
    .full_in(full_in)
);

generate
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin: loop
        assign  select[i]   = rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign  sel_mux[i]  = mux_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
    end
endgenerate

initial 
begin

    full_in = 0;
    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(10*`CLK_TIME);
    full_in = 4'b1111;
    #(10*`CLK_TIME);
    full_in = 4'b0111;
    #(10*`CLK_TIME);

    $stop();

end

endmodule
