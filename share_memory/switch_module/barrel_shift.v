`timescale 1ns/1ns 
`include "../../generate_parameter.vh"

module barrel_shift
(
    input       wire                            clk,
    input       wire                            rst_n,
    input       wire    [WIDTH_SEL-1 : 0]       select,
    input       wire    [WIDTH_TOTAL - 1 : 0]   port_in, 
    output      wire    [WIDTH_TOTAL - 1 : 0]   port_out
);


localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL); 
localparam  WIDTH_PORT  = 1+2*$clog2(`PORT_NUB_TOTAL)+`DATA_WIDTH;
localparam  WIDTH_TOTAL = `PORT_NUB_TOTAL * WIDTH_PORT;

wire    [WIDTH_SEL-1 : 0]   sel_f[WIDTH_SEL-1 : 0];
wire    [WIDTH_PORT-1 : 0]  port_f[WIDTH_SEL-1 :0][`PORT_NUB_TOTAL-1 : 0];

assign sel_f[0] = select;

generate
    genvar i,j;

    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin: loop0
        assign port_f[0][i] = port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
    end

    for(i=0; i<WIDTH_SEL; i=i+1)begin: loop1

        reg [WIDTH_SEL-1 : 0]   sel_reg;
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                sel_reg <= {WIDTH_SEL{1'b0}};
            else
                sel_reg <= sel_f[i];
        end
        assign sel_f[i+1] = sel_reg;

        for(j=0; j<`PORT_NUB_TOTAL; j=j+1)begin: loop2

            reg [WIDTH_PORT-1 : 0] port_reg;
            always @(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    port_reg <= {WIDTH_PORT{1'b0}};
                end
                else begin
                    if(sel_f[i][i])
                        port_reg <= port_f[i][(j+`PORT_NUB_TOTAL-2**i)%`PORT_NUB_TOTAL]; 
                    else
                        port_reg <= port_f[i][j];
                end
            end

            if(i == WIDTH_SEL-1)
                assign port_out[(j+1)*WIDTH_PORT-1 : j*WIDTH_PORT] = port_reg;
            else
                assign port_f[i+1][j] = port_reg;

        end

    end
endgenerate

endmodule

