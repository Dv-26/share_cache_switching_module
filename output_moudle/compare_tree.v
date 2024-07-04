`include "../generate_parameter.vh"
module compare_tree 
#(
    parameter   PORT_NUB    = 8,
    parameter   WIDTH_WIEGHT = 8
)
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [PORT_NUB-1 : 0]    valid_in,
    input   wire    [WIDTH_IN-1 : 0]    wieght_in,
    output  wire    [WIDTH_OUT-1 : 0]   port_out,
    output  wire                        valid_out
);

localparam  PORT_NUB_TOTAL  =   `PORT_NUB_TOTAL;
localparam  WIDTH_OUT       =   $clog2(PORT_NUB_TOTAL); 
localparam  WIDTH_PORT_IN   =   PORT_NUB * WIDTH_OUT;
localparam  WIDTH_IN        =   PORT_NUB * $clog2(`PRIORITY);

wire    [WIDTH_PORT_IN-1 : 0]   port_in;

generate 
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin: port
        assign port_in[(i+1)*WIDTH_OUT-1 : i*WIDTH_OUT] = i;
    end
endgenerate


compare_tree_internal
#(
    .PORT_NUB(PORT_NUB),
    .WIDTH_WIEGHT(WIDTH_WIEGHT)
)
compare_tree_internal
(
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .port_in(port_in),
    .wieght_in(wieght_in),
    .out_port(port_out),
    .out_valid(valid_out)
);

endmodule

module compare_tree_internal
#(
    parameter   PORT_NUB = 8,
    parameter   WIDTH_WIEGHT = 8
)
(
    input   wire                                clk,
    input   wire                                rst_n,

    input   wire    [PORT_NUB-1 : 0]            valid_in,
    input   wire    [WIDTH_PORT_IN-1 : 0]       port_in,
    input   wire    [WIDTH_WIEGHT_IN-1 : 0]     wieght_in,

    output  wire    [WIDTH_OUT-1 : 0]           out_port,
    output  wire    [WIDTH_WIEGHT-1 : 0]        out_wieght,
    output  wire                                out_valid
);

localparam  PORT_NUB_TOTAL      =   `PORT_NUB_TOTAL;
localparam  WIDTH_OUT           =   $clog2(PORT_NUB_TOTAL); 
localparam  WIDTH_PORT_IN       =   PORT_NUB * WIDTH_OUT;
localparam  WIDTH_WIEGHT_IN     =   PORT_NUB * WIDTH_WIEGHT;

generate 

    wire    [WIDTH_PORT_IN/2 - 1 : 0]       a_port,b_port;
    wire    [WIDTH_WIEGHT_IN/2 - 1 : 0]     a_wieght,b_wieght;
    wire    [PORT_NUB/2 - 1: 0]             a_valid,b_valid;

    assign {b_port, a_port}     =   port_in;
    assign {b_wieght, a_wieght} =   wieght_in;
    assign {b_valid, a_valid}   =   valid_in;
    
    if(PORT_NUB == 2)begin

        compare_unit#(.WIDTH_WIEGHT(WIDTH_WIEGHT))
        compare
        (
            .clk(clk),
            .rst_n(rst_n),
            .a_valid(a_valid),
            .a_wieght(a_wieght),
            .a_port(a_port),
            .b_valid(b_valid),
            .b_wieght(b_wieght),
            .b_port(b_port),
            .out_valid(out_valid),
            .out_wieght(out_wieght),
            .out_port(out_port)
        );

    end
    else begin

        wire                                a_out_valid,b_out_valid;
        wire    [WIDTH_WIEGHT-1 : 0]        a_out_wieght,b_out_wieght;
        wire    [WIDTH_OUT-1 : 0]           a_out_port,b_out_port;

        compare_tree_internal
        #(
            .PORT_NUB(PORT_NUB/2),
            .WIDTH_WIEGHT(WIDTH_WIEGHT)
        )
        compare_tree_internal_a
        (
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(a_valid),
            .port_in(a_port),
            .wieght_in(a_wieght),
            .out_port(a_out_port),
            .out_wieght(a_out_wieght),
            .out_valid(a_out_valid)
        );

        compare_tree_internal
        #(
            .PORT_NUB(PORT_NUB/2),
            .WIDTH_WIEGHT(WIDTH_WIEGHT)
        )
        compare_tree_internal_b
        (
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(b_valid),
            .port_in(b_port),
            .wieght_in(b_wieght),
            .out_port(b_out_port),
            .out_wieght(b_out_wieght),
            .out_valid(b_out_valid)
        );

        compare_unit
        #(
            .WIDTH_WIEGHT(WIDTH_WIEGHT)
        )
        compare_ab
        (
            .clk(clk),
            .rst_n(rst_n),
            .a_valid(a_out_valid),
            .a_wieght(a_out_wieght),
            .a_port(a_out_port),
            .b_valid(b_out_valid),
            .b_wieght(b_out_wieght),
            .b_port(b_out_port),
            .out_valid(out_valid),
            .out_wieght(out_wieght),
            .out_port(out_port)
        );

    end

endgenerate

endmodule

module compare_unit
#(
    WIDTH_WIEGHT = 8
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    input   wire                            a_valid,
    input   wire    [WIDTH_WIEGHT-1 : 0]     a_wieght,
    input   wire    [WIDTH_OUT-1 : 0]       a_port,

    input   wire                            b_valid,
    input   wire    [WIDTH_WIEGHT-1 : 0]     b_wieght,
    input   wire    [WIDTH_OUT-1 : 0]       b_port,

    output  wire                            out_valid,
    output  wire    [WIDTH_WIEGHT-1 : 0]     out_wieght,
    output  wire    [WIDTH_OUT-1 : 0]       out_port
);

localparam  PORT_NUB_TOTAL      =   `PORT_NUB_TOTAL;
localparam  WIDTH_OUT           =   $clog2(PORT_NUB_TOTAL); 

reg     [WIDTH_WIEGHT + WIDTH_OUT : 0]  out;
wire    [WIDTH_WIEGHT + WIDTH_OUT : 0]  a;
wire    [WIDTH_WIEGHT + WIDTH_OUT : 0]  b;
wire                                    a_than_b;

assign  {out_valid, out_wieght, out_port} = out;
assign  a   = {a_valid, a_wieght, a_port};
assign  b   = {b_valid, b_wieght, b_port};

always@(*)begin
    case({a_valid, b_valid})
        2'b00:begin
            out = 0;
        end
        2'b01:begin
            out = b;
        end
        2'b10:begin
            out = a;
        end
        2'b11:begin
            if(a_wieght >= b_wieght)
                out = a;
            else
                out = b;
        end
    endcase
end

endmodule
