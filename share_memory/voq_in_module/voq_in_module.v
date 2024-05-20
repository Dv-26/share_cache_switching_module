`include "../../generate_parameter.vh"

module voq_in_module
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [WIDTH_PORT-1 : 0]  data_in,
    input   wire                        voq_full,
    input   wire    [WIDTH_SEL-1 : 0]   nub,
    input   wire                        wr_en_in,

    output  wire                        wr_en_out,
    output  wire    [WIDTH_PORT-1 : 0]  data_out,
    output  wire                        full

);

localparam  PORT_NUB        = `PORT_NUB_TOTAL;
localparam  WIDTH_SEL       = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT      = WIDTH_SEL + `DATA_WIDTH;
localparam  WIDTH_FIFO      = WIDTH_PORT + 1;
localparam  WIDTH_LENGTH    = $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_CRC       =`CRC32_LENGTH;
localparam  WIDTH_PRIORITY  = $clog2(`PRIORITY);


wire                            top_wr_en;
wire    [WIDTH_LENGTH-1 : 0]    length;
wire    [WIDTH_SEL-1 : 0]       tx_in;
wire    [WIDTH_SEL-1 : 0]       tx_out;
wire                        cut_1to2_out;

assign top_wr_en = !full & wr_en_in;
assign tx_in = data_in[WIDTH_PORT-1 : WIDTH_PORT-WIDTH_SEL];
assign tx_out = fifo1_rd_data[WIDTH_PORT-1 : WIDTH_PORT-WIDTH_SEL];

assign length = data_in[WIDTH_LENGTH+WIDTH_CRC+WIDTH_PRIORITY-1 : WIDTH_CRC+WIDTH_PRIORITY];

wire                            data_vld;

wire    [PORT_NUB-1 : 0]        tx_data_vld;
wire    [PORT_NUB-1 : 0]        tx_cut_1to2;

assign  data_vld = |tx_data_vld;
assign  cut_1to2_out = |tx_cut_1to2;

generate 
    genvar i;

    for(i=0; i<PORT_NUB; i=i+1)begin :tx_fsm

        wire    tx_manage_valid;
        wire    cut_1to2;

        tx_manage_fsm
        #(.NUB(i))
        tx_manage_fsm
        (
            .clk(clk),
            .rst_n(rst_n),
            .length_in(length),
            .tx_in(tx_in),
            .nub_in(nub),
            .top_rd_en_in(top_wr_en),
            .valid_out(tx_manage_valid),
            .cut_1to2_out(cut_1to2)
        );

        assign  tx_data_vld[i] = tx_manage_valid;
        assign  tx_cut_1to2[i] = cut_1to2;

    end


    wire    [WIDTH_FIFO-1 : 0]  fifo1_wr_data;
    wire    [WIDTH_FIFO-1 : 0]  fifo1_rd_data;
    wire                        fifo1_wr_en,fifo1_rd_en;
    wire                        fifo1_full,fifo1_empty;
    

    reg_fifo
    #(
        .DATA_WIDTH(WIDTH_FIFO),
        .DEPTH(20)
    )
    fifo_1
    (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo1_wr_en),
        .wr_data(fifo1_wr_data),
        .rd_en(fifo1_rd_en),
        .rd_data(fifo1_rd_data),
        .full(full),
        .empty(fifo1_empty)
    );

    assign  fifo1_wr_data   = {cut_1to2_out, data_in};
    assign  fifo1_wr_en     = data_vld;

    wire    cut_1to2_in,cut_2to1_in;

    assign cut_1to2_in = fifo1_rd_data[WIDTH_FIFO-1] && !fifo1_empty; 

    wire    [WIDTH_PORT+1-1 : 0]  fifo2_mux[PORT_NUB-1 : 0];
    wire    [WIDTH_PORT-1 : 0]  fifo2_rd_data;
    wire                        fifo2_rd_en;

    for(i=0; i<PORT_NUB; i=i+1)begin: loop2
        
        wire    [WIDTH_PORT-1 : 0]  wr_data;
        wire    [WIDTH_PORT-1 : 0]  rd_data;
        wire                        wr_en,rd_en;
        wire                        empty;

        reg_fifo
        #(
            .DATA_WIDTH(WIDTH_PORT),
            .DEPTH(16)
        )
        fifo_2
        (
            .clk(clk),
            .rst_n(rst_n),
            .wr_en(wr_en),
            .wr_data(wr_data),
            .rd_en(rd_en),
            .rd_data(rd_data),
            .empty(empty)
        );

        assign wr_data = data_in;
        assign fifo2_mux[i] = {empty, rd_data}; 
        assign wr_en = (top_wr_en && tx_in == i)? !fifo1_wr_en:1'b0;
        assign rd_en = (tx_out == i)? fifo2_rd_en:1'b0;

    end

    assign fifo2_rd_data = fifo2_mux[tx_out];
    assign data_out = (out_sel)? fifo1_rd_data[WIDTH_PORT-1 : 0]:fifo2_rd_data;
    
    fifo_rd_fsm
    fifo_rd_fsm
    (
        .clk(clk),
        .rst_n(rst_n),
        .out_sel_out(out_sel),
        .fifo1_rd_en(fifo1_rd_en),
        .fifo2_rd_en(fifo2_rd_en),
        .voq_full_in(voq_full),
        .fifo_empty_in(fifo1_empty),
        .cut_1to2_in(cut_1to2_in),
        .cut_2to1_in(cut_2to1_in),
        .top_wr_en_out(wr_en_out)
    );

    assign cut_2to1_in = fifo2_mux[tx_out][WIDTH_PORT];

endgenerate

endmodule



