`timescale 1ns/1ns
`include "../generate_parameter.vh"

module switch_moudle
(
    input       wire                                        clk,
    input       wire                                        rst_n,

    input       wire    [PORT_NUB-1 : 0]                    vld_in,
    input       wire    [WIDTH_SEL_TOTAL-1 : 0]             rx_in,
    input       wire    [WIDTH_SEL_TOTAL-1 : 0]             tx_in,
    input       wire    [WIDTH_PORT_TOTAL-1 : 0]            port_in,
    output      wire    [WIDTH_PORT_TOTAL-1 : 0]            port_out,
    input       wire    [WIDTH_SEL_TOTAL-1 : 0]             rd_sel,
    input       wire    [PORT_NUB-1 : 0]                    rd_en,
    output      wire    [PORT_NUB-1 : 0]                    ready,

    output      wire    [PORT_NUB**2-1 : 0]                 empty,
    output      wire                                        full,
    output      wire                                        alm_ost_full
);

localparam  PORT_NUB = `PORT_NUB_TOTAL;
localparam  WIDTH_SEL = $clog2(PORT_NUB);
localparam  WIDTH_SEL_TOTAL = WIDTH_SEL * PORT_NUB;
localparam  WIDTH_PORT = `DATA_WIDTH;
localparam  WIDTH_PORT_TOTAL = WIDTH_PORT * PORT_NUB;
localparam  WIDTH_BARREL = 1 + 2*WIDTH_SEL + WIDTH_PORT;
localparam  WIDTH_BARREL_TOTAL = PORT_NUB * WIDTH_BARREL;
localparam  WIDTH_VOQ = WIDTH_SEL + WIDTH_PORT;
localparam  WIDTH_MUX = 1 + WIDTH_SEL + WIDTH_PORT;

reg     [WIDTH_SEL-1 : 0]   cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= 0;
    else
        cnt <= cnt + 1;
end

wire    [WIDTH_BARREL_TOTAL-1 : 0]  shift_in;
wire    [WIDTH_BARREL_TOTAL-1 : 0]  shift_out;

barrel_shift barrel_shift
(
    .clk(clk),
    .rst_n(rst_n),
    .select(cnt),
    .port_in(shift_in), 
    .port_out(shift_out)
);

wire    [WIDTH_MUX-1: 0]        mux[PORT_NUB-1 : 0][PORT_NUB-1 : 0];
wire    [PORT_NUB**2-1 : 0]     fifo_full;
wire    [PORT_NUB**2-1 : 0]     voq_empty;

generate
    genvar i,j;
    for(i=0; i<PORT_NUB; i=i+1)begin: loop1

        wire                        shift_vld_in;
        wire    [WIDTH_SEL-1 : 0]   shift_rx_in;
        wire    [WIDTH_SEL-1 : 0]   shift_tx_in;
        wire    [WIDTH_PORT-1 : 0]  shift_data_in;

        assign  shift_vld_in    = vld_in[i];
        assign  shift_rx_in     = rx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign  shift_tx_in     = tx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign  shift_data_in   = port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];

        assign  shift_in[(i+1)*WIDTH_BARREL-1 : i*WIDTH_BARREL] = {shift_vld_in, shift_rx_in, shift_tx_in, shift_data_in};

        
    end

    wire    [WIDTH_SEL_TOTAL-1 : 0]     demux_ctrl_rd_sel;
    wire    [WIDTH_SEL_TOTAL-1 : 0]     demux_ctrl_rd_sel_f;
    wire    [WIDTH_SEL_TOTAL-1 : 0]     demux_ctrl_rx_in;
    wire    [PORT_NUB-1 : 0]            demux_ctrl_rd_en_out;

    demux_ctrol demux_ctrol
    (
        .clk(clk),
        .rst_n(rst_n),
        .cnt_in(cnt),
        .rx_in(demux_ctrl_rx_in),
        .fifo_full(fifo_full),
        .voq_empty(voq_empty),
        .voq_rd_sel(demux_ctrl_rd_sel),
        .voq_rd_sel_f(demux_ctrl_rd_sel_f),
        .voq_rd_en(demux_ctrl_rd_en_out)
    );

    for(i=0; i<PORT_NUB; i=i+1)begin :loop5

        wire                        shift_vld_out;
        wire    [WIDTH_SEL-1 : 0]   shift_rx_out;
        wire    [WIDTH_SEL-1 : 0]   shift_tx_out;
        wire    [WIDTH_PORT-1 : 0]  shift_data_out;

        assign {shift_vld_out,shift_rx_out,shift_tx_out,shift_data_out} = shift_out[(i+1)*WIDTH_BARREL-1 : i*WIDTH_BARREL];

        wire    [WIDTH_VOQ-1 : 0]   voq_data_in;
        wire    [WIDTH_VOQ-1 : 0]   voq_out;
        wire    [WIDTH_PORT-1 : 0]  voq_data_out;
        wire    [WIDTH_SEL-1 : 0]   voq_rx_out;
        wire    [WIDTH_SEL-1 : 0]   voq_rd_sel;
        wire    [WIDTH_SEL-1 : 0]   voq_rd_sel_f;
        wire                        voq_rd_vld;
        wire                        voq_full;
        wire    [PORT_NUB-1 : 0]    voq_empty_out;

        voq
        #(
            .NAME(i),
            .DEPTH(`DEPTH),
            .THRESHOLD(200),
            .DATA_WIDTH(WIDTH_VOQ)
        )
        voq
        (
            .clk(clk),
            .rst_n(rst_n),
            .wr_data(voq_data_in),
            .wr_vaild(shift_vld_out),
            .wr_sel(shift_tx_out),
            .rd_data(voq_out),
            .rd_vaild(voq_rd_vld),
            .rd_sel(voq_rd_sel),
            .full(voq_full),
            .empty(voq_empty_out)
        );

        assign  voq_data_in = {shift_rx_out, shift_data_out};
        assign  voq_empty[(i+1)*PORT_NUB-1 : i*PORT_NUB] = voq_empty_out;
        assign  voq_rd_sel = demux_ctrl_rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign  voq_rd_sel_f = demux_ctrl_rd_sel_f[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign  voq_rd_vld = demux_ctrl_rd_en_out[i];
        assign  {voq_rx_out, voq_data_out} = voq_out;
        assign  demux_ctrl_rx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL] = voq_rx_out;

        wire    [WIDTH_MUX-1 : 0]   demux_in;
        wire    [(WIDTH_MUX*PORT_NUB)-1 : 0]    demux_out;
        
        demux
        #(
            .DATA_WIDTH(WIDTH_MUX),
            .NUB(PORT_NUB)
        )
        demux
        (
            .port_in(demux_in),
            .sel_in(voq_rx_out),
            .port_out(demux_out)
        );

        assign demux_in = {voq_rd_vld, voq_rd_sel_f, voq_data_out};

        for(j=0; j<PORT_NUB; j=j+1)begin: loop2
            assign mux[i][j] = demux_out[(i+1)*WIDTH_MUX-1 : i*WIDTH_MUX];
        end
        
    end

    for(i=0; i<PORT_NUB; i=i+1)begin: loop3

        wire    [WIDTH_PORT_TOTAL-1 : 0]    mux_fifo_data_in;
        wire    [PORT_NUB-1 : 0]            mux_fifo_wr_en;
        wire    [WIDTH_SEL_TOTAL-1 : 0]     mux_fifo_tx;
        wire    [WIDTH_PORT-1 : 0]          mux_fifo_data_out;
        wire    [PORT_NUB-1 : 0]            mux_fifo_full;
        wire    [PORT_NUB-1 : 0]            mux_fifo_empty;
        wire    [WIDTH_SEL-1 : 0]           mux_rd_sel;

        for(j=0; j<PORT_NUB; j=j+1)begin: loop4

            wire    [WIDTH_PORT-1 : 0]  data;
            wire                        wr_en;
            wire    [WIDTH_SEL-1 : 0]   tx;

            assign mux_fifo_data_in[(j+1)*WIDTH_PORT-1 : j*WIDTH_PORT] = data;
            assign mux_fifo_wr_en[j] = wr_en;
            assign mux_fifo_wr_tx = tx;
            assign {wr_en, tx, data} = mux[j][i];

        end

        mux_fifo mux_fifo
        (
            .clk(clk),
            .rst_n(rst_n),
            .wr_en(mux_fifo_wr_en),
            .rd_en(rd_en),
            .data_in(mux_fifo_data_in),
            .port_in(mux_fifo_tx),
            .sel(mux_rd_sel),
            .data_out(mux_fifo_data_out),
            .empty(mux_fifo_empty),
            .full(mux_fifo_full)
        );

        assign  empty[(i+1)*PORT_NUB-1 : i*PORT_NUB] = mux_fifo_empty;
        assign  fifo_full[(i+1)*PORT_NUB-1 : i*PORT_NUB] = mux_fifo_full;  
        assign  port_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = mux_fifo_data_out;
        assign  mux_rd_sel = rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];

        
    end

endgenerate




endmodule
