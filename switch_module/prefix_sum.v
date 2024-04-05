`timescale 1ns/1ns
`include "./defind.vh"

module prefix_sum
(
    input       wire                            clk,
    input       wire                            rst_n,

    input       wire    [WIDTH_TOTAL - 1 : 0]   port_in, 
    output      wire    [WIDTH_TOTAL - 1 : 0]   port_out
);

localparam  WIDTH_PORT  = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_TOTAL = (`PORT_NUB_TOTAL + 1) * WIDTH_PORT;

wire [WIDTH_PORT-1 : 0] port_in_f[WIDTH_PORT-1 : 0][`PORT_NUB_TOTAL : 0];

generate
    genvar i,j;

    for(i=0; i<`PORT_NUB_TOTAL+1; i=i+1)begin: loop
        assign port_in_f[0][i] = port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
    end

    for(i=0; i<$clog2(`PORT_NUB_TOTAL); i=i+1)begin: loop1
        

        for(j=0; j<`PORT_NUB_TOTAL+1; j=j+1)begin: loop2

            reg [WIDTH_PORT-1 : 0]  node_reg;

            if(j<2**i)begin

                always@(posedge clk or negedge rst_n)
                    if(!rst_n)
                        node_reg <= {WIDTH_PORT{1'b0}};
                    else
                        node_reg <= port_in_f[i][j];

            end
            else begin

                always@(posedge clk or negedge rst_n)begin
                    if(!rst_n)begin
                        node_reg <= {WIDTH_PORT{1'b0}};
                    end
                    else begin
                        node_reg <= port_in_f[i][j] + port_in_f[i][j - 2**i];
                    end
                end

            end


            if(i == $clog2(`PORT_NUB_TOTAL) - 1)begin
                assign port_out[(j+1)*WIDTH_PORT-1 : j*WIDTH_PORT] = node_reg;
            end
            else begin
                assign port_in_f[i+1][j] = node_reg;
            end

        end

    end



endgenerate

endmodule
