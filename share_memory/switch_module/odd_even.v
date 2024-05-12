`timescale 1ns/1ns
`include "../../generate_parameter.vh"

module odd_even_sort
#(
    parameter   PORT_NUB        = 4
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


        wire    [WIDTH_TOTAL/2-1 : 0]   odd_in,even_in;
        wire    [WIDTH_TOTAL/2-1 : 0]   odd_out,even_out;

        odd_even_sort#(.PORT_NUB(PORT_NUB/2))
        odd
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(odd_in), 
            .port_out(odd_out)
        );

        odd_even_sort#(.PORT_NUB(PORT_NUB/2))
        even
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(even_in), 
            .port_out(even_out)
        );

        genvar i;
        for(i = 0;i < PORT_NUB;i = i+2)begin : loop
            assign  odd_in[(i/2+1)*WIDTH_PORT-1 : (i/2)*WIDTH_PORT]   = port_in[ (i+1)*WIDTH_PORT-1 : i*WIDTH_PORT ];
            assign  port_f[ (i+1)*WIDTH_PORT-1 : i*WIDTH_PORT ] = odd_out[(i/2+1)*WIDTH_PORT-1 : (i/2)*WIDTH_PORT];
            assign  even_in[(i/2+1)*WIDTH_PORT-1 : (i/2)*WIDTH_PORT]  = port_in[ (i+2)*WIDTH_PORT-1 : (i+1)*WIDTH_PORT ];
            assign  port_f[ (i+2)*WIDTH_PORT-1 : (i+1)*WIDTH_PORT ] = even_out[(i/2+1)*WIDTH_PORT-1 : (i/2)*WIDTH_PORT];
        end

    end

    if(PORT_NUB != 2)begin

        merge_module
        #(
            .PORT_NUB(PORT_NUB)
        )
        merge_module
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(port_f), 
            .port_out(port_out)
        );

    end

endgenerate


endmodule
