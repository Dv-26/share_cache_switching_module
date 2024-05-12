`timescale 1ns/1ns
`include "../../generate_parameter.vh"

module  shift_reg
#(
    parameter   DELAY   =   3,
    parameter   WIDTH   =   3,
    parameter   NUB     =   1
)
(
    input       wire                            clk,
    input       wire                            rst_n,

    input       wire    [WIDTH*NUB - 1 : 0]   port_in, 
    output      wire    [WIDTH*NUB - 1 : 0]   port_out
);

wire    [WIDTH-1 : 0]   shift[DELAY-1 : 0][NUB-1 : 0];

generate
    genvar i,j;

    for(i=0; i<DELAY; i=i+1)begin: loop
        for(j=0; j<NUB; j=j+1)begin: loop2
            reg [WIDTH-1 : 0]node_reg;
            if(i == 0)begin
                always @(posedge clk or negedge rst_n)begin
                    if(!rst_n)
                        node_reg <= {WIDTH{1'b0}};
                    else
                        node_reg <= port_in[(j+1)*WIDTH-1 : j*WIDTH];
                end
            end
            else begin
                always @(posedge clk or negedge rst_n)begin
                    if(!rst_n)
                        node_reg <= {WIDTH{1'b0}};
                    else
                        node_reg <= shift[i][j];
                end
            end

            if(i == DELAY-1)begin
                assign port_out[(j+1)*WIDTH-1 : j*WIDTH] = node_reg;
            end
            else begin
                assign shift[i+1][j] = node_reg;
            end
        end
    end

endgenerate

endmodule
