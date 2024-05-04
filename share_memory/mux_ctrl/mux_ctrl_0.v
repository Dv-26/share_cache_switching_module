`timescale 1ns/1ns 
`include "../generate_parameter.vh"

module mux_ctrl_0
(
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [`PORT_NUB_TOTAL**2-1 : 0]  port_vaild,
    input   wire    [`PORT_NUB_TOTAL-1 : 0]     full_in,

    output  wire    [`PORT_NUB_TOTAL-1 : 0]     wr_en_out,
    output  wire    [WIDTH_SEL_TOTAL-1 : 0]     mux_sel
);

localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL); 
localparam  WIDTH_SEL_TOTAL = WIDTH_SEL * `PORT_NUB_TOTAL; 
localparam  WIDTH_PORT_OUT  = 2*WIDTH_SEL+`DATA_WIDTH;
localparam  WIDTH_TOTAL_OUT = `PORT_NUB_TOTAL * WIDTH_PORT_OUT;

wire    full;
assign  full = &full_in;

generate
    genvar i,j;

    wire    [`PORT_NUB_TOTAL-1 : 0] vaild[`PORT_NUB_TOTAL-1 : 0];
    reg     [WIDTH_SEL-1 : 0]       sel[`PORT_NUB_TOTAL-1 : 0];

    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin: loop0
        for(j=0; j<`PORT_NUB_TOTAL; j=j+1)begin: loop1
            assign vaild[i][j] = port_vaild[j*`PORT_NUB_TOTAL+i];
        end
        assign mux_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = sel[i];
    end

    integer n;
    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin: loop2
        // always@(*)begin: encoder
        //     sel[i] = 0;
        //     for(n=0; n<`PORT_NUB_TOTAL; n=n+1)begin
        //         if(vaild[i][n])begin
        //             sel[i] = n;
        //             disable encoder;
        //         end
        //     end
        // end

        wire    [WIDTH_SEL-1 : 0]   encode_out;

        encode#(.N(`PORT_NUB_TOTAL),.PIPELINE(`PIPELINE))
        encode
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(vaild[i]),
            .out(encode_out)
        );

        if(`PIPELINE)begin
            always@(posedge clk or negedge rst_n)   //流水线对齐
                if(!rst_n)
                    sel[i]  <= 0;
                else
                    sel[i]  <= encode_out;
        end
        else begin
            always@(*)
                sel[i] = encode_out;
        end

        

        // assign wr_en_out[i] = (| vaild[i]) & !full;

        xor_tree#(.N(`PORT_NUB_TOTAL),.PIPELINE(`PIPELINE))
        xor_tree
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(vaild[i]),
            .out(wr_en_out[i])
        );

    end

endgenerate

endmodule
