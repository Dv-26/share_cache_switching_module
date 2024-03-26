`timescale 1ns/1ns
`define PORT_NUB_TOTAL 16
`define DATA_WIDTH 8

module merge_module
#(
    parameter   PORT_NUB        = 16
)
(
    input       wire                            clk,
    input       wire                            rst_n,

    input       wire    [WIDTH_TOTAL - 1 : 0]   port_in, 
    output      wire    [WIDTH_TOTAL - 1 : 0]   port_out
);

localparam  WIDTH_PORT  =   2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_TOTAL =   PORT_NUB * WIDTH_PORT; 

generate 

    reg [WIDTH_PORT-1:0] reg_head,reg_tail;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            reg_head <= {WIDTH_PORT{1'b0}};
            reg_tail <= {WIDTH_PORT{1'b0}};
        end
        else begin
            reg_head <= port_in[WIDTH_TOTAL-1 : WIDTH_TOTAL - WIDTH_PORT];
            reg_tail <= port_in[WIDTH_PORT-1 : 0];
        end
    end

    assign port_out[WIDTH_PORT-1 : 0] = reg_tail;
    assign port_out[WIDTH_TOTAL-1 : WIDTH_TOTAL - WIDTH_PORT] = reg_head;

    genvar i;
    for(i = 1; i < PORT_NUB - 1; i = i+2)begin :loop

        exchange_unit
        #(
            .DATA_WIDTH(`DATA_WIDTH),
            .PORT_NUB(`PORT_NUB_TOTAL)
        )
        exchang_unit
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in_1(port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT]),
            .port_out_1(port_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT]),

            .port_in_2(port_in[(i+2)*WIDTH_PORT-1 : (i+1)*WIDTH_PORT]),
            .port_out_2(port_out[(i+2)*WIDTH_PORT-1 : (i+1)*WIDTH_PORT])
        );

    end

endgenerate



endmodule


