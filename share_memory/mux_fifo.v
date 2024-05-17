`include "../generate_parameter.vh"

module mux_fifo
(
    input   wire                                clk,
    input   wire                                rst_n,

    input   wire    [PORT_NUB-1 : 0]            wr_en,
    input   wire                                rd_en,
    input   wire    [WIDTH_PORT_TOTAL-1 : 0]    data_in,
    input   wire    [WIDTH_SEL_TOTAL-1 : 0]     port_in,
    input   wire    [WIDTH_SEL-1 : 0]           sel,

    output  wire    [WIDTH_PORT-1 : 0]          data_out,
    output  wire    [PORT_NUB-1 : 0]            empty,
    output  wire    [PORT_NUB-1 : 0]            full

);

localparam  PORT_NUB = `PORT_NUB_TOTAL;
localparam  WIDTH_SEL = $clog2(PORT_NUB);
localparam  WIDTH_SEL_TOTAL = $clog2(PORT_NUB) * PORT_NUB;
localparam  WIDTH_PORT  = `DATA_WIDTH;
localparam  WIDTH_PORT_TOTAL = PORT_NUB * WIDTH_PORT;
localparam  WIDTH_SORT = 1 + WIDTH_SEL + WIDTH_PORT;
localparam  WIDTH_SORT_TOTAL = WIDTH_SORT * PORT_NUB;

generate
    genvar i,j;
    wire    [WIDTH_PORT-1 : 0]  fifo_data_out[PORT_NUB-1 : 0];
    wire    [WIDTH_SEL-1 : 0]   port[PORT_NUB-1 : 0];

    wire    [WIDTH_SORT_TOTAL-1 : 0]   sort_in;
    wire    [WIDTH_SORT_TOTAL-1 : 0]   sort_out;

    sort_module 
    #(
        .PORT_NUB(PORT_NUB)
    )
    sort_moudle
    (
        .clk(clk),
        .rst_n(rst_n),
        .port_in(sort_in), 
        .port_out(sort_out)
    );

    for(i=0; i<PORT_NUB; i=i+1)begin: loop

        wire    vld;
        wire    [WIDTH_SEL-1 : 0] port;
        wire    [WIDTH_PORT-1 : 0] data;

        assign vld  = wr_en[i];
        assign port = port_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];
        assign data = data_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
        assign sort_in[(i+1)*WIDTH_SORT-1 : i*WIDTH_SORT] = {vld,port,data};

        wire    [WIDTH_PORT-1 : 0]  fifo_data_in;
        wire                        fifo_wr_en;
        wire                        fifo_rd_en;
        wire    [WIDTH_SORT-1 : 0]  sort_out_port;

        assign sort_out_port = sort_out[(i+1)*WIDTH_SORT-1 : i*WIDTH_SORT];
        assign fifo_wr_en = sort_out_port[WIDTH_SEL-1];
        assign fifo_data_in = sort_out_port[WIDTH_PORT-1 : 0];

        reg_fifo 
        #(
            .DATA_WIDTH(WIDTH_PORT),
            .DEPTH(16)
        )
        reg_fifo
        (
            .clk(clk),
            .rst_n(rst_n),
            .wr_en(fifo_wr_en),
            .wr_data(fifo_data_in),
            .rd_en(fifo_rd_en),
            .rd_data(fifo_data_out[i]),
            .full(full[i]),
            .empty(empty[i])
        );
        
        assign fifo_rd_en = (sel == i)? rd_en:1'b0;

    end

    assign data_out = fifo_data_out[sel];
    
endgenerate

endmodule
