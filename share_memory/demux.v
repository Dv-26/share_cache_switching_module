module demux
#(
    parameter   DATA_WIDTH  = 8,
    parameter   NUB         = 4
)
(
    input   wire    [WIDTH_PORT-1 : 0]          port_in,
    input   wire    [WIDTH_SEL-1 : 0]           sel_in,
    output  wire    [WIDTH_PORT_TOTAL-1 : 0]    port_out
);

localparam WIDTH_PORT = DATA_WIDTH;  
localparam WIDTH_PORT_TOTAL = NUB * DATA_WIDTH;
localparam WIDTH_SEL = $clog2(NUB);

generate
    genvar i;
    for(i=0; i<NUB; i=i+1)begin: loop
        assign  port_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = (sel_in == i)? port_in:{WIDTH_PORT{1'b0}};
    end
endgenerate

endmodule

