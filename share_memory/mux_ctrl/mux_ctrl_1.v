`timescale 1ns/1ns
`include "../../generate_parameter.vh"

module  mux_ctrl_1
#(
    parameter PIPELINE = 0
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    output  wire    [PORT_NUB-1 : 0]        rd_out,
    output  reg     [PORT_NUB-1 : 0]        wr_out,
    output  wire    [WIDTH_SEL_TOTAL-1 : 0] rd_sel,
    output  wire    [WIDTH_SEL_TOTAL-1 : 0] mux_sel,

    input   wire    [WIDTH_SEL_TOTAL-1 : 0] cnt_in,
    input   wire    [PORT_NUB-1 : 0]        full_in,
    input   wire    [PORT_NUB**2-1 : 0]     empty_in
);

localparam WIDTH_SEL_TOTAL  = PORT_NUB * WIDTH_SEL; 
localparam WIDTH_SEL        = $clog2(`PORT_NUB_TOTAL);
localparam PORT_NUB         = `PORT_NUB_TOTAL;


wire    [WIDTH_SEL-1 : 0]   shift_count[PORT_NUB-1 : 0];
wire    [WIDTH_SEL-1 : 0]   mux_sel_n[PORT_NUB-1 : 0];
wire    [PORT_NUB-1 : 0]    unit_en_out[PORT_NUB-1 : 0];
wire    [PORT_NUB-1 : 0]    unit_en_out_shift[PORT_NUB-1 : 0];
wire    [PORT_NUB-1 : 0]    voq_empty[PORT_NUB-1 : 0];

integer n;
generate
    genvar i,j;

    for(i=0; i<PORT_NUB; i=i+1)begin: loop0

        wire    [WIDTH_SEL-1 : 0]   shift_out;
        wire    [WIDTH_SEL-1 : 0]   mux_sel_out;
        wire    [WIDTH_SEL-1 : 0]   mux_sel_shift_out;
        reg     [WIDTH_SEL-1 : 0]   mux_sel_reg;
        wire    [WIDTH_SEL-1 : 0]   shift_in;
        wire                        voq_full_in;
        wire    [PORT_NUB-1 : 0]    en_out;
        wire    [PORT_NUB-1 : 0]    en_shift_out;

        ctrl_unit #(.dest(i))
        ctrl_unit 
        (
            .clk(clk),
            .rst_n(rst_n),
            .shift_out(shift_out),
            .shift_in(shift_in),
            .voq_full_in(voq_full_in),
            .mux_sel_out(mux_sel_out),
            .en_out(en_out)
        );
        
        if(i == PORT_NUB-1)
            assign shift_in = cnt_in;
        else
            assign shift_in = shift_count[i+1];

        if(PIPELINE)begin
            shift_reg                       //流水线对齐
            #(
                .DELAY(WIDTH_SEL - 1),
                .WIDTH(WIDTH_SEL),
                .NUB(1)
            )
            mux_sel_shift
            (
                .clk(clk),
                .rst_n(rst_n),
                .port_in(mux_sel_out), 
                .port_out(mux_sel_shift_out)
            );

            shift_reg                       //流水线对齐
            #(
                .DELAY(WIDTH_SEL - 1),
                .WIDTH(PORT_NUB),
                .NUB(1)
            )
            en_out_shift
            (
                .clk(clk),
                .rst_n(rst_n),
                .port_in(en_out), 
                .port_out(en_shift_out)
            );
        end
        else begin
            assign mux_sel_shift_out = mux_sel_out;
            assign en_shift_out = en_out;
        end

        always @(posedge clk)begin
            mux_sel_reg <= mux_sel_shift_out;
        end

        assign  mux_sel_n[i]   =   mux_sel_shift_out;
        assign  mux_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = mux_sel_reg;
        assign  shift_count[i] = shift_out;
        assign  voq_full_in = full_in[i];
        assign  unit_en_out[i] = en_out;
        assign  unit_en_out_shift[i] = en_shift_out;

        assign voq_empty[i] = empty_in[(i+1)*PORT_NUB-1 : i*PORT_NUB];

    end

    for(i=0; i<PORT_NUB; i=i+1)begin: loop1
        wire                        mux[PORT_NUB-1 : 0];
        wire    [PORT_NUB-1 : 0]    encode_in;
        wire    [WIDTH_SEL-1 : 0]   sel;

        for(j=0 ; j<PORT_NUB; j=j+1)begin: loop2
            assign encode_in[j] = unit_en_out[j][i]; 
            assign mux[j] = unit_en_out_shift[j][i]; 
        end
        
        // always @(*)begin
        //     sel = 0;
        //     for(n=0; n<PORT_NUB; n=n+1)begin
        //         if(mux[n])
        //             sel = n;
        //     end
        // end

        encode#(.N(`PORT_NUB_TOTAL),.PIPELINE(PIPELINE))
        encode
        (
            .clk(clk),
            .rst_n(rst_n),
            .in(encode_in),
            .out(sel)
        );
        
        assign rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = sel;
        assign rd_out[i] = mux[sel];

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                wr_out[i] <= 1'b0;
            else
                wr_out[i] <= rd_out[mux_sel_n[i]] & (!voq_empty[mux_sel_n[i]][i]);
        end
    end
endgenerate

endmodule
