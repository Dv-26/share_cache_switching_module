`timescale 1ns/1ns
`include "generate_parameter.vh"

module switch_moudle
(
    input   wire                                    clk,
    input   wire                                    rst_n,

    input       wire    [WIDTH_TOTAL-1 : 0]         port_in,
    output      wire    [WIDTH_TOTAL-1 : 0]         port_out,
    input       wire    [WIDTH_SEL_TOTAL-1 : 0]     rd_sel,
    input       wire    [PORT_NUB_TOTAL-1 : 0]      rd_en
    // output      wire    [PORT_NUB**2-1 : 0]         empty,
    // output      wire    [PORT_NUB-1 : 0]            full
);

localparam  PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam  DATA_WIDTH  =   `DATA_WIDTH;

localparam  WIDTH_PORT  =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_TOTAL  =   PORT_NUB_TOTAL * WIDTH_PORT; 
localparam  WIDTH_SEL   = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_SEL_TOTAL =   PORT_NUB_TOTAL * WIDTH_SEL; 


wire    [WIDTH_TOTAL-1 : 0]             shift_out;
reg     [WIDTH_SEL-1 : 0]               shift_select;

barrel_shift barrel_shift
(
    .clk(clk),
    .rst_n(rst_n),
    .select(shift_select),
    .port_in(port_in), 
    .port_out(shift_out)
);

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        shift_select <= {WIDTH_SEL{1'b0}};
    else
        shift_select <= shift_select + 1;
end

wire    [WIDTH_PORT-1 : 0]  filter[PORT_NUB_TOTAL-1 : 0][PORT_NUB_TOTAL-1 : 0];
wire    filter_vaild[PORT_NUB_TOTAL-1 : 0][PORT_NUB_TOTAL-1 : 0];
wire    [WIDTH_SEL-1 : 0]   filter_rx[PORT_NUB_TOTAL-1 : 0][PORT_NUB_TOTAL-1 : 0];

generate
    genvar i,j;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop1

        wire    [WIDTH_TOTAL-1 : 0]         filter_out;
        wire    [PORT_NUB_TOTAL-1 : 0]      vaild;

        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin: loop2
            assign  filter[i][j] = filter_out[(j+1)*WIDTH_PORT-1 : j*WIDTH_PORT] ;
            assign  filter_vaild[i][j] = vaild[j];
            assign  filter_rx[i][j] = filter[i][j][WIDTH_PORT-2 : WIDTH_PORT-1-WIDTH_SEL];
        end

        filter#(.dest(i))filter
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(shift_out), 
            .port_out(filter_out),
            .port_vaild(vaild)
        );

    end

    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop3

        wire    [WIDTH_PORT-1 : 0]  mux[PORT_NUB_TOTAL-1 : 0];
        reg     [WIDTH_SEL-1 : 0]   mux_sel;
        wire    [WIDTH_PORT-1 : 0]  voq_wr_data;
        reg     [WIDTH_SEL-1 : 0]   voq_wr_sel;
        wire    [WIDTH_PORT-1 : 0]  voq_rd_data;
        wire                        voq_rd_en;
        wire    [WIDTH_SEL-1 : 0]   voq_rd_sel;
        reg                         voq_wr_en;

        assign voq_rd_en = rd_en[i];
        assign voq_rd_sel = rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];

        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin: loop4
            assign mux[j] = filter[j][i];
            assign port_out[(j+1)*WIDTH_PORT-1 : j*WIDTH_PORT] = voq_rd_data;
        end

        integer n;
        always@(*)begin
            voq_wr_en = filter_vaild[0][i];
            mux_sel = 0;
            voq_wr_sel = filter_rx[0][i];
            for(n=1; n<PORT_NUB_TOTAL; n=n+1)begin
                voq_wr_en = voq_wr_en | filter_vaild[n][i];
                if(filter_vaild[n][i])begin
                    mux_sel = n;
                    voq_wr_sel = filter_rx[n][i];
                end
            end
        end

        assign voq_wr_data = mux[mux_sel];

        voq
        #(
            .DEPTH(16)
        )
        voq
        (
            .clk(clk),
            .rst_n(rst_n),
            .wr_data(voq_wr_data),
            .wr_vaild(voq_wr_en),
            .wr_sel(voq_wr_sel),
            .rd_data(voq_rd_data),
            .rd_vaild(voq_rd_en),
            .rd_sel(voq_rd_sel),
            .full(),
            .empty()
        );

    end

endgenerate


endmodule
