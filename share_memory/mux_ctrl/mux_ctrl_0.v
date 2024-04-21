`timescale 1ns/1ns 
`include "../generate_parameter.vh"

module mux_ctrl_0
(
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [`PORT_NUB_TOTAL**2-1 : 0]  port_vaild,

    output  wire    [`PORT_NUB_TOTAL-1 : 0]     wr_en_out,
    output  wire    [WIDTH_SEL_TOTAL-1 : 0]     mux_sel

);

localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL); 
localparam  WIDTH_SEL_TOTAL = WIDTH_SEL * `PORT_NUB_TOTAL; 
localparam  WIDTH_PORT_OUT  = 2*WIDTH_SEL+`DATA_WIDTH;
localparam  WIDTH_TOTAL_OUT = `PORT_NUB_TOTAL * WIDTH_PORT_OUT;

generate
    genvar i,j;

    wire    [`PORT_NUB_TOTAL-1 : 0] vaild[`PORT_NUB_TOTAL-1 : 0];
    reg    [WIDTH_SEL-1 : 0]       sel[`PORT_NUB_TOTAL-1 : 0];

    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin: loop0
        for(j=0; j<`PORT_NUB_TOTAL; j=j+1)begin: loop1
            assign vaild[i][j] = port_vaild[i*`PORT_NUB_TOTAL+j];
        end
        assign mux_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = sel[i];
    end

    integer n;
    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin: loop2
        assign wr_en_out[i] = | vaild[i];
        always@(*)begin
            sel[i] = 0;
            for(n=0; n<`PORT_NUB_TOTAL; n=n+1)begin
                if(vaild[i][n])
                    sel[i] = n;
            end
        end
    end

endgenerate

endmodule
