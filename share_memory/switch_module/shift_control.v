`timescale 1ns/1ns
`include "../generate_parameter.vh"

module shift_control
(
    input       wire                        clk,
    input       wire                        rst_n,

    input       wire    [WIDTH_IN-1 : 0]    port_in, 
    output      wire    [WIDTH_OUT-1 : 0]   port_out
);

localparam  WIDTH_PORT  = 1 + WIDTH;
localparam  WIDTH       = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_IN    = `PORT_NUB_TOTAL* WIDTH_PORT;
localparam  WIDTH_OUT   = WIDTH*`PORT_NUB_TOTAL;   

wire    [WIDTH-1 : 0]     adder_tree_out[`PORT_NUB_TOTAL : 0];
wire    [(`PORT_NUB_TOTAL+1)*WIDTH-1 : 0]  prefix_sum_in,prefix_sum_out;

generate 

    genvar i,j;

    for(i=0; i<=`PORT_NUB_TOTAL; i=i+1)begin: loop0

        wire    [`PORT_NUB_TOTAL-1 : 0]                       port_valid;
        wire    [WIDTH*`PORT_NUB_TOTAL-1 : 0] adder_tree_in;    


        for(j=0; j<`PORT_NUB_TOTAL; j=j+1)begin: loop1
            if(i == 0)
                assign port_valid[j] = ~port_in[(j+1)*WIDTH_PORT-1];
            else begin
                wire    [WIDTH-1 : 0]                                   rx_port;
                assign rx_port = port_in[(j+1)*WIDTH_PORT-2 : j*WIDTH_PORT];
                assign port_valid[j] = (rx_port == i-1)? 1'b1:1'b0;
            end
            assign adder_tree_in[j*WIDTH] = port_valid[j];
            assign adder_tree_in[(j+1)*WIDTH-1 : j*WIDTH+1] = {(WIDTH-1){1'b0}};
        end

        adder_tree
        #(
            .PORT_NUB(`PORT_NUB_TOTAL)
        )
        adder_tree
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(adder_tree_in),
            .port_out(adder_tree_out[i])
        );

    end

    for(i=0; i<`PORT_NUB_TOTAL+1; i=i+1)begin :loop2
        assign prefix_sum_in[(i+1)*WIDTH-1 : i*WIDTH] = adder_tree_out[i];
    end

endgenerate


prefix_sum prefix_sum
(
    .clk(clk),
    .rst_n(rst_n),
    .port_in(prefix_sum_in), 
    .port_out(prefix_sum_out)
);

generate

    genvar z,n;
    wire    [WIDTH-1 : 0]   shift_f[WIDTH-1 : 0][`PORT_NUB_TOTAL : 0];
    reg     [WIDTH-1 : 0]   out_reg[`PORT_NUB_TOTAL-1 : 0];

    for(z=0; z<WIDTH; z=z+1)begin :loop3

        for(n=0; n<`PORT_NUB_TOTAL+1; n=n+1)begin: loop4

            reg [WIDTH-1 : 0] node_reg;

            if(z == 0)begin

                always@(posedge clk or negedge rst_n)begin
                    if(!rst_n)
                        node_reg <= {WIDTH{1'b0}};
                    else
                        node_reg <= adder_tree_out[n] + node_reg;
                end

            end
            else begin

                always@(posedge clk or negedge rst_n)begin
                    if(!rst_n)
                        node_reg <= {WIDTH{1'b0}};
                    else
                        node_reg <= shift_f[z-1][n];
                end

            end

            assign shift_f[z][n] = node_reg;

        end

    end

    for(z=0; z<`PORT_NUB_TOTAL; z=z+1)begin :loop5
        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                out_reg[z] <= {WIDTH{1'b0}};
            else
                // out_reg[z] <= prefix_sum_out[(z+1)*WIDTH-1 : z*WIDTH] - shift_f[WIDTH-1][z+1];
                out_reg[z] <= shift_f[WIDTH-1][z+1] - prefix_sum_out[(z+1)*WIDTH-1 : z*WIDTH];
        end
        assign port_out[(z+1)*WIDTH-1 : z*WIDTH] = out_reg[z];
    end
    

endgenerate

endmodule
