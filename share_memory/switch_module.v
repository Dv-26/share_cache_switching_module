`timescale 1ns/1ns
`include "../generate_parameter.vh"

module switch_moudle
(
    input       wire                                        clk,
    input       wire                                        rst_n,

    input       wire    [PORT_NUB_TOTAL-1 : 0]              vld_in,
    input       wire    [WIDTH_SEL_TOTAL-1 : 0]             rx_in,
    input       wire    [WIDTH_SEL_TOTAL-1 : 0]             tx_in,
    input       wire    [WIDTH_VOQ1*PORT_NUB_TOTAL-1 : 0]   port_in,
    output      wire    [PORT_NUB_TOTAL-1 : 0]              ready,

    input       wire    [WIDTH_SEL_TOTAL-1 : 0]             rd_sel,
    output      wire    [PORT_NUB_TOTAL**2-1 : 0]           empty,
    input       wire    [PORT_NUB_TOTAL-1 : 0]              rd_en,
    input       wire    [PORT_NUB_TOTAL-1 : 0]              rd_done_in,
    output      wire    [WIDTH_VOQ1*PORT_NUB_TOTAL-1 : 0]   port_out,


    output      wire                                        full,
    output      wire                                        alm_ost_full
);

reg     [WIDTH_SEL-1 : 0]               shift_select;

localparam  PORT_NUB_TOTAL  =   `PORT_NUB_TOTAL;
localparam  DATA_WIDTH      =   `DATA_WIDTH;

localparam  WIDTH_SEL       =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT      =   1 + 2 * WIDTH_SEL + `DATA_WIDTH;
localparam  WIDTH_FILTER    =   2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ0      =   $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_VOQ1      =   `DATA_WIDTH;
localparam  WIDTH_TOTAL     =   PORT_NUB_TOTAL * WIDTH_PORT; 
localparam  WIDTH_SEL_TOTAL =   PORT_NUB_TOTAL * WIDTH_SEL; 

// ready_generate ready_generate
// (
//     .clk        (clk),
//     .rst_n      (rst_n),
//     .cnt_in     (shift_select),
//     .vld_in     (vld_in), 
//     .ready_out  (ready)
// );
assign ready = (shift_select == PORT_NUB_TOTAL-1)? {PORT_NUB_TOTAL{1'b1}}:0;

wire    [WIDTH_TOTAL-1 : 0]             shift_in;
wire    [WIDTH_TOTAL-1 : 0]             shift_out;

genvar i,j;

barrel_shift barrel_shift
(
    .clk(clk),
    .rst_n(rst_n),
    .select(shift_select),
    .port_in(shift_in), 
    .port_out(shift_out)
);

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        shift_select <= {WIDTH_SEL{1'b0}};
    else
        shift_select <= shift_select + 1;
end

generate

    wire    [WIDTH_VOQ0-1 : 0]          voq0_out[PORT_NUB_TOTAL-1 : 0];
    wire                                voq0_rd_en[PORT_NUB_TOTAL-1 : 0];
    wire    [WIDTH_SEL-1 : 0]           voq0_rd_sel[PORT_NUB_TOTAL-1 : 0];
    wire    [PORT_NUB_TOTAL-1 : 0]      voq0_alm_ost_full;
    wire    [PORT_NUB_TOTAL-1 : 0]      voq0_full;
    wire    [PORT_NUB_TOTAL**2-1 : 0]   voq0_empty;


    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop1

        wire                        vld,shift2voq0_vld;
        wire    [WIDTH_SEL-1 : 0]   rx;
        wire    [WIDTH_SEL-1 : 0]   tx,shift2voq0_tx;
        wire    [DATA_WIDTH-1 : 0]  data;
        wire    [WIDTH_VOQ0-1 : 0]  shift2voq0_data;

        assign rx   = rx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign tx   = tx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign vld  = (rx != tx)? vld_in[i]:1'b0;
        assign data = port_in[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
        assign shift_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = {vld,rx,tx,data}; 

        wire    [WIDTH_VOQ0-1 : 0]      voq_rd_data;
        wire    [PORT_NUB_TOTAL-1 : 0]  voq_empty;
        wire                            voq_full;  

        voq
        #(
            .NAME(i),
            .DEPTH(`DEPTH),
            .DATA_WIDTH(WIDTH_VOQ0),
            .THRESHOLD(`DATA_LENGTH_MAX/PORT_NUB_TOTAL)
        )
        voq_0
        (
            .clk(clk),
            .rst_n(rst_n),
            .wr_data(shift2voq0_data),
            .wr_vaild(shift2voq0_vld),
            .wr_sel(shift2voq0_tx),
            .rd_data(voq0_out[i]),
            .rd_vaild(voq0_rd_en[i]),
            .rd_sel(voq0_rd_sel[i]),
            .full(voq0_full[i]),
            .empty(voq_empty),
            .alm_ost_full(voq0_alm_ost_full[i])
        );

        assign  {shift2voq0_vld, shift2voq0_tx, shift2voq0_data} = shift_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
        assign  voq0_empty[(i+1)*PORT_NUB_TOTAL-1 : i*PORT_NUB_TOTAL] = voq_empty; 

    end

    wire    [WIDTH_SEL_TOTAL-1 : 0]     mux_ctrl_mux_sel;
    wire    [WIDTH_SEL_TOTAL-1 : 0]     mux_ctrl_rd_sel;
    wire    [PORT_NUB_TOTAL-1 : 0]      mux_ctrl_full_in;
    wire    [PORT_NUB_TOTAL-1 : 0]      mux_ctrl_rd_out;
    wire    [PORT_NUB_TOTAL-1 : 0]      mux_ctrl_wr_out;
    wire    [WIDTH_SEL-1 : 0]           mux_sel_1[PORT_NUB_TOTAL-1 : 0];
    wire    [WIDTH_SEL-1 : 0]           mux_ctrl_cnt_in;


    mux_ctrl_1 mux_ctrl_1
    (
        .clk(clk),
        .rst_n(rst_n),
        .rd_out(mux_ctrl_rd_out),
        .wr_out(mux_ctrl_wr_out),
        .rd_sel(mux_ctrl_rd_sel),
        .mux_sel(mux_ctrl_mux_sel),
        .full_in(mux_ctrl_full_in),
        .cnt_in(mux_ctrl_cnt_in),
        .empty_in(voq0_empty)
    );

    assign mux_ctrl_cnt_in = shift_select;

    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop6
        assign voq0_rd_sel[i]   = mux_ctrl_rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign voq0_rd_en[i]    = mux_ctrl_rd_out[i];
        assign mux_sel_1[i]     = mux_ctrl_mux_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
    end

    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop5

        wire    [WIDTH_VOQ0+WIDTH_SEL-1 : 0]    mux[PORT_NUB_TOTAL-1 : 0];
        wire    [WIDTH_VOQ0+WIDTH_SEL-1 : 0]    mux_out;
        wire    [WIDTH_VOQ0-1 : 0]              voq_in_module_data_in;
        wire    [WIDTH_VOQ0-1 : 0]              voq_in_module_data_out;
        wire                                    voq_in_module_full;
        wire                                    voq_in_module_wr_in;
        wire                                    voq_in_module_wr_out;
        wire    [WIDTH_SEL-1 : 0]               voq_in_module_nub; 
        wire    [PORT_NUB_TOTAL-1 : 0]          voq_in_module_done; 

        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
            assign mux[j] = {j,voq0_out[j]};
        end
        wire                        voq_full;

        voq_in_module voq_in_module
        (
            .clk(clk),
            .rst_n(rst_n),
            .voq_full_in(voq_full),
            .data_in(voq_in_module_data_in),
            .nub(voq_in_module_nub),
            .valid_in(voq_in_module_wr_in),
            .valid_out(voq_in_module_wr_out),
            .data_out(voq_in_module_data_out),
            .done_out(voq_in_module_done)
        );

        assign mux_out = mux[mux_sel_1[i]];  
        assign voq_in_module_nub = mux_out[WIDTH_SEL+WIDTH_VOQ0-1 : WIDTH_VOQ0]; 
        assign voq_in_module_data_in = mux_out[WIDTH_VOQ0-1 : 0];
        assign voq_in_module_wr_in = mux_ctrl_wr_out[i];

        wire    [PORT_NUB_TOTAL-1 : 0]    package_cnt_minus;
        wire    [PORT_NUB_TOTAL-1 : 0]    package_cnt_empty;
        wire    [WIDTH_SEL-1 : 0]         package_cnt_sel;

        package_cnt package_cnt
        (
            .clk            (clk),
            .rst_n          (rst_n),
            .cnt_add        (voq_in_module_done),
            .cnt_minus      (package_cnt_minus),
            .minus_sel      (package_cnt_sel),
            .cnt_eq_zero    (package_cnt_empty)
        );

        assign package_cnt_sel = rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL]; 
        assign empty[(i+1)*PORT_NUB_TOTAL-1 : i*PORT_NUB_TOTAL] = package_cnt_empty;
        assign package_cnt_minus                                = rd_done_in[i];

        wire    [WIDTH_VOQ1-1 : 0]      voq_wr_data;
        wire    [WIDTH_SEL-1 : 0]       voq_wr_sel;
        wire                            voq_wr_en;
        wire    [WIDTH_VOQ1-1 : 0]      voq_rd_data;
        wire    [WIDTH_SEL-1 : 0]       voq_rd_sel;
        wire                            voq_rd_en;
        wire    [PORT_NUB_TOTAL-1 : 0]  voq_empty;

        voq
        #(
            .NAME(PORT_NUB_TOTAL+i),
            .DEPTH(`DEPTH),
            .DATA_WIDTH(WIDTH_VOQ1),
            .THRESHOLD(WIDTH_SEL-1)
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
            // .full(voq_full),    //因为流水线会滞后log2(N)个时钟周期，�?以满信号要提�? 防止丢数�?
            .full_next(voq_full),
            .empty(voq_empty)
        );

        assign voq_wr_data = voq_in_module_data_out[WIDTH_VOQ1-1 : 0];
        assign voq_wr_sel = voq_in_module_data_out[WIDTH_VOQ0-1 : WIDTH_VOQ0-WIDTH_SEL];
        assign voq_wr_en = voq_in_module_wr_out;
        assign mux_ctrl_full_in[i] = voq_full;
        assign port_out[(i+1)*WIDTH_VOQ1-1 : i*WIDTH_VOQ1] = voq_rd_data;
        assign voq_rd_sel = rd_sel[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign voq_rd_en = rd_en[i];
    end


endgenerate

assign full = |voq0_full;
assign alm_ost_full = |voq0_alm_ost_full;

endmodule
