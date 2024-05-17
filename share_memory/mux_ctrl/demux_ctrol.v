`include "../../generate_parameter.vh"

module demux_ctrol
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire    [WIDTH_SEL-1 : 0]       cnt_in,
    input   wire    [WIDTH_SEL_TOTAL-1 : 0] rx_in,

    input   wire    [PORT_NUB**2-1 : 0]     fifo_full,
    input   wire    [PORT_NUB**2-1 : 0]     voq_empty,

    output  wire    [WIDTH_SEL_TOTAL-1 : 0] voq_rd_sel,
    output  wire    [WIDTH_SEL_TOTAL-1 : 0] voq_rd_sel_f,
    output  wire    [PORT_NUB-1 : 0]        voq_rd_en
);

localparam WIDTH_SEL_TOTAL  = PORT_NUB * WIDTH_SEL; 
localparam WIDTH_SEL        = $clog2(`PORT_NUB_TOTAL);
localparam PORT_NUB         = `PORT_NUB_TOTAL;

wire    full[PORT_NUB-1 : 0][PORT_NUB-1 : 0];
wire    empty[PORT_NUB-1 : 0][PORT_NUB-1 : 0];
wire    [WIDTH_SEL-1 : 0]   rx[PORT_NUB-1 : 0];

reg [WIDTH_SEL-1 : 0]   shift_reg[PORT_NUB-1 : 0];

generate
    genvar i,j;

    for(i=0; i<PORT_NUB; i=i+1)begin: loopi
        for(j=0; j<PORT_NUB; j=j+1)begin: loopj
            assign  full[i][j] = fifo_full[i*PORT_NUB+j];
            assign  empty[i][j] = voq_empty[i*PORT_NUB+j];
        end
        assign rx[i] = rx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
    end
    
    for(i=0; i<PORT_NUB; i=i+1)begin: loop

        reg  [WIDTH_SEL-1 : 0]  shift_reg_f;
        wire [WIDTH_SEL-1 : 0]  shift_reg_n;

        if(i == 0)begin
            assign shift_reg_n = cnt_in;
        end
        else begin
            assign shift_reg_n = shift_reg[i-1];
        end

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                shift_reg[i] <= 0;
                shift_reg_f <= 0;
            end
            else begin
                shift_reg[i] <= shift_reg_n;
                shift_reg_f <= shift_reg[i];
            end
        end

        assign voq_rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = shift_reg[i];
        assign voq_rd_sel_f[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = shift_reg_f;
        assign voq_rd_en[i] = !empty[i][shift_reg_f] & !full[rx[i]][shift_reg_f];
        
    end
endgenerate

endmodule

