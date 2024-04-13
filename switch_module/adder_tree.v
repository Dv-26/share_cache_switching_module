`timescale 1ns/1ns
`include    "../generate_parameter.vh"

module adder_tree
#(
    parameter   PORT_NUB    = 16
)
(
    input       wire                            clk,
    input       wire                            rst_n,

    input       wire    [WIDTH_TOTAL - 1 : 0]   port_in, 
    output      wire    [WIDTH_PORT - 1 : 0]   port_out
);

localparam  WIDTH_PORT  = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_TOTAL = PORT_NUB * WIDTH_PORT;


//generate递归是个好东西
generate
    
    if(PORT_NUB == 2)begin

        reg [WIDTH_PORT-1 : 0]    add_reg;
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                add_reg <= {WIDTH_PORT{1'b0}};
            else
                add_reg <= port_in[2*WIDTH_PORT-1 : WIDTH_PORT] + port_in [WIDTH_PORT-1 : 0];
        end
        assign port_out = add_reg;

    end
    else begin

        wire [WIDTH_PORT-1 : 0] adder_0,adder_1;

        adder_tree
        #(
            .PORT_NUB(PORT_NUB/2)
        )
        adder_tree_0
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(port_in[WIDTH_TOTAL/2-1 : 0]), 
            .port_out(adder_0)
        );

        adder_tree
        #(
            .PORT_NUB(PORT_NUB/2)
        )
        adder_tree_1
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(port_in[WIDTH_TOTAL-1 : WIDTH_TOTAL/2]), 
            .port_out(adder_1)
        );

        wire [2*WIDTH_PORT-1 : 0] adder_2_in;

        adder_tree
        #(
            .PORT_NUB(2)
        )
        adder_tree_2
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(adder_2_in), 
            .port_out(port_out)
        );

        assign adder_2_in = {adder_0,adder_1};

    end


endgenerate

endmodule
