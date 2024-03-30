`timescale 1ns/1ns
`include "./defind.vh"

module sort_module
#(
    parameter   PORT_NUB        = `PORT_NUB_TOTAL
)
(
    input       wire                            clk,
    input       wire                            rst_n,

    input       wire    [WIDTH_TOTAL - 1 : 0]   port_in, 
    output      wire    [WIDTH_TOTAL - 1 : 0]   port_out
);

localparam  WIDTH_PORT  =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_TOTAL =   PORT_NUB * WIDTH_PORT; 

wire     [WIDTH_TOTAL - 1 : 0]   port_f;

generate 


    if(PORT_NUB == 2)begin
        exchange_unit
        #(
            .DATA_WIDTH(`DATA_WIDTH),
            .PORT_NUB(`PORT_NUB_TOTAL)
        )
        exchang_unit
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in_1(port_in[WIDTH_PORT - 1 : 0]),
            .port_out_1(port_out[WIDTH_PORT - 1 : 0]),
            .port_in_2(port_in[2 * WIDTH_PORT - 1 : WIDTH_PORT]),
            .port_out_2(port_out[2 * WIDTH_PORT - 1 : WIDTH_PORT])
        );
    end
    else begin
        sort_module#(.PORT_NUB(PORT_NUB/2))
        sort_module_0
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(port_in[WIDTH_TOTAL/2-1 : 0]), 
            .port_out(port_f[WIDTH_TOTAL/2-1 : 0])
        );

        sort_module#(.PORT_NUB(PORT_NUB/2))
        sort_module_1
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(port_in[WIDTH_TOTAL-1 : WIDTH_TOTAL/2]), 
            .port_out(port_f[WIDTH_TOTAL-1 : WIDTH_TOTAL/2])
        );

    end

    if(PORT_NUB != 2)begin

        odd_even_sort
        #(
            .PORT_NUB(PORT_NUB)
        )
        odd_even_sott
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(port_f), 
            .port_out(port_out)
        );

    end

endgenerate



endmodule


