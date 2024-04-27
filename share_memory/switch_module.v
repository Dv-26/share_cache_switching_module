`timescale 1ns/1ns
`include "./generate_parameter.vh"

module switch_moudle
(
    input   wire                                            clk,
    input   wire                                            rst_n,

    input       wire    [WIDTH_TOTAL-1 : 0]                 port_in,
    output      wire    [WIDTH_VOQ1*PORT_NUB_TOTAL-1 : 0]   port_out,
    input       wire    [WIDTH_SEL_TOTAL-1 : 0]             rd_sel,
    input       wire    [PORT_NUB_TOTAL-1 : 0]              rd_en,

    output      wire    [PORT_NUB_TOTAL**2-1 : 0]           empty
);

localparam  PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam  DATA_WIDTH  =   `DATA_WIDTH;

localparam  WIDTH_PORT  =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_FILTER =  2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ0  =   $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ1  =   `DATA_WIDTH;
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

wire    [WIDTH_FILTER-1 : 0]    filter_data[PORT_NUB_TOTAL-1 : 0][PORT_NUB_TOTAL-1 : 0];
wire    [PORT_NUB_TOTAL**2-1 : 0]  filter_vaild;

generate
    genvar i,j;


    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop1

        wire    [WIDTH_FILTER*PORT_NUB_TOTAL-1 : 0]         filter_out;
        wire    [PORT_NUB_TOTAL-1 : 0]      vaild;

        filter#(.dest(i))filter
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(shift_out), 
            .port_out(filter_out),
            .port_vaild(vaild)
        );

        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin: loop2
            assign  filter_data[i][j] = filter_out[(j+1)*WIDTH_FILTER-1 : j*WIDTH_FILTER] ;
        end
        assign  filter_vaild[(i+1)*PORT_NUB_TOTAL-1 : i*PORT_NUB_TOTAL] = vaild;

    end

    wire    [PORT_NUB_TOTAL-1 : 0]  voq0_wr_en;
    wire    [WIDTH_SEL_TOTAL-1 : 0] mux0_ctrl_mux_sel;

    mux_ctrl_0 mux_ctrl_0
    (
        .clk(clk),
        .rst_n(rst_n),
        .port_vaild(filter_vaild),
        .wr_en_out(voq0_wr_en),
        .mux_sel(mux0_ctrl_mux_sel)
    );

    wire    [WIDTH_VOQ0-1 : 0]  voq0_out[PORT_NUB_TOTAL-1 : 0];
    wire    [WIDTH_SEL-1 : 0]   voq0_rd_sel[PORT_NUB_TOTAL-1 : 0];
    wire    [PORT_NUB_TOTAL-1 : 0]    voq0_rd_en;
    wire    [PORT_NUB_TOTAL**2-1 : 0]   voq0_empty;

    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop3

        wire    [WIDTH_FILTER-1 : 0]  mux[PORT_NUB_TOTAL-1 : 0];
        wire    [WIDTH_FILTER-1 : 0]  mux_out;
        wire    [WIDTH_SEL-1 : 0]   mux_sel;
        wire    [WIDTH_VOQ0-1 : 0]  voq_wr_data;
        wire    [WIDTH_SEL-1 : 0]   voq_wr_sel;
        wire    [WIDTH_VOQ0-1 : 0]  voq_rd_data;
        wire                        voq_rd_en;
        wire    [WIDTH_SEL-1 : 0]   voq_rd_sel;
        wire                         voq_wr_en;
        wire    [PORT_NUB_TOTAL-1 : 0]voq_empty;


        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin: loop4
            assign mux[j] = filter_data[j][i];
        end

        voq
        #(
            .DEPTH(16),
            .DATA_WIDTH(WIDTH_VOQ0)
        )
        voq_0
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
            .empty(voq_empty)
        );

        assign  mux_sel     = mux0_ctrl_mux_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign  voq_rd_en   = voq0_rd_en[i];
        assign  voq_rd_sel  = voq0_rd_sel[i];
        assign  voq0_out[i] = voq_rd_data ;    
        assign  mux_out     = mux[mux_sel];
        assign  voq_wr_data = mux_out[WIDTH_VOQ0-1 : 0];
        assign  voq_wr_en   = voq0_wr_en[i];
        assign  voq_wr_sel  = mux_out[WIDTH_FILTER-1 : WIDTH_FILTER-WIDTH_SEL];
        assign  voq0_empty[(i+1)*PORT_NUB_TOTAL-1 : i*PORT_NUB_TOTAL] = voq_empty; 
    end

    wire [WIDTH_SEL_TOTAL-1 : 0]    mux_ctrl_mux_sel;
    wire [WIDTH_SEL_TOTAL-1 : 0]    mux_ctrl_rd_sel;
    wire    [PORT_NUB_TOTAL-1 : 0]  mux_ctrl_full_in;
    wire    [PORT_NUB_TOTAL-1 : 0]  mux_ctrl_rd_out;
    wire    [PORT_NUB_TOTAL-1 : 0]  mux_ctrl_wr_out;
    wire    [WIDTH_SEL-1 : 0]       mux_sel_1[PORT_NUB_TOTAL-1 : 0];


    mux_ctrl_1 mux_ctrl_1
    (
        .clk(clk),
        .rst_n(rst_n),
        .rd_out(mux_ctrl_rd_out),
        .wr_out(mux_ctrl_wr_out),
        .rd_sel(mux_ctrl_rd_sel),
        .mux_sel(mux_ctrl_mux_sel),
        .full_in(mux_ctrl_full_in),
        .empty_in(voq0_empty)
    );

    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop6
        assign voq0_rd_sel[i] = mux_ctrl_rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign voq0_rd_en[i] = mux_ctrl_rd_out;
        assign mux_sel_1[i] = mux_ctrl_mux_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
    end


    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop5

        wire    [WIDTH_VOQ0-1 : 0]  mux[PORT_NUB_TOTAL-1 : 0];
        wire    [WIDTH_VOQ0-1 : 0]  mux_out;
        wire    [WIDTH_VOQ1-1 : 0]  voq_wr_data;
        wire    [WIDTH_SEL-1 : 0]   voq_wr_sel;
        wire                        voq_wr_en;
        wire    [WIDTH_VOQ1-1 : 0]  voq_rd_data;
        wire    [WIDTH_SEL-1 : 0]   voq_rd_sel;
        wire                        voq_rd_en;
        wire                        voq_full;
        wire    [PORT_NUB_TOTAL-1 : 0]voq_empty;

        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
            assign mux[j] = voq0_out[j];
        end

        voq
        #(
            .DEPTH(16),
            .DATA_WIDTH(WIDTH_VOQ1)
        )
        voq_1
        (
            .clk(clk),
            .rst_n(rst_n),
            .wr_data(voq_wr_data),
            .wr_vaild(voq_wr_en),
            .wr_sel(voq_wr_sel),
            .rd_data(voq_rd_data),
            .rd_vaild(voq_rd_en),
            .rd_sel(voq_rd_sel),
            .full(voq_full),
            .empty(voq_empty)
        );

        assign mux_out = mux[mux_sel_1[i]];  
        assign voq_wr_data = mux_out[WIDTH_VOQ1-1 : 0];
        assign voq_wr_sel = mux_out[WIDTH_VOQ0-1 : WIDTH_VOQ0-WIDTH_SEL];
        assign voq_wr_en = mux_ctrl_wr_out[i];
        assign port_out[(i+1)*WIDTH_VOQ1-1 : i*WIDTH_VOQ1] = voq_rd_data;
        assign voq_rd_sel = rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign voq_rd_en = rd_en[i];
        assign mux_ctrl_full_in[i] = voq_full;
        assign empty[(i+1)*PORT_NUB_TOTAL-1 : i*PORT_NUB_TOTAL] = voq_empty;
    end

endgenerate


endmodule