`timescale 1ns / 1ps

module voq
#(
    parameter   DATA_WIDTH  =   128,
    parameter   DEPTH       =   100,
    parameter   QUEUE_NUB   =   16
)
(
    input       wire                                clk,
    input       wire                                rst_n,
    
    input       wire    [DATA_WIDTH-1:0]            wr_data,
    input       wire                                wr_en,
    input       wire    [$clog2(QUEUE_NUB)-1:0]     wr_client,

    output      wire    [DATA_WIDTH-1:0]            rd_data,
    input       wire                                rd_en
    input       wire    [$clog2(QUEUE_NUB)-1:0]     rd_client
);



wire                        sram_wr_en;
wire                        sram_wr_addr;
wire    [DATA_WIDTH-1:0]    sram_wr_data;
wire                        sram_rd_en;
wire    [DATA_WIDTH-1:0]    sram_rd_data;
wire                        sram_rd_addr;

ram
#(
    .ADDR_WIDTH($clog2(DEPTH)), 
    .DATA_WIDTH(DATA_WIDTH)
)
sram
(
    .clk(clk),
    .wr_en(sdram_wr_en),
    .wr_addr(sdram_wr_addr),
    .wr_data(sdram_wr_data),
    .rd_en(sdram_rd_en),
    .rd_data(sdram_rd_data),
    .rd_addr(sdram_rd_addr)
);

assign sdram_wr_data = wr_data;
assign rd_data = sdram_rd_data;

wire                            free_ptr_rd;
wire                            free_ptr_wr;
wire    [$clog2(DEPTH)-1:0]     free_ptr_w_data;
wire    [$clog2(DEPTH)-1:0]     free_ptr_r_data;
wire                            free_ptr_empty;
wire                            free_ptr_full;

free_ptr_fifo
#(
    .DATA_BIT($clog2(DEPTH))
free_ptr_fifo
)
(
    .clk(clk),
    .rst_n(rst_n),
    .rd(free_ptr_rd),
    .wr(free_ptr_wr),
    .w_data(free_ptr_w_data),
    .r_data(free_ptr_r_data),
    .empty(free_ptr_empty),
    .full(free_ptr_full)
);

assign sdram_wr_addr = free_ptr_r_data;

wire                            ptrqueue_rd     [QUEUE_NUB-1:0];
wire                            ptrqueue_wr     [QUEUE_NUB-1:0];
wire                            ptrqueue_empty  [QUEUE_NUB-1:0];
wire                            ptrqueue_full   [QUEUE_NUB-1:0];
wire    [$clog2(DEPTH)-1:0]     ptrqueue_in     [QUEUE_NUB-1:0];
wire    [$clog2(DEPTH)-1:0]     ptrqueue_out    [QUEUE_NUB-1:0];

generate
    genvar i;
    for(i=0;i<QUEUE_NUB;i++)begin : loop
        fifo
        #(
            .DATA_BIT($clog2(DEPTH)),
            .W($clog2(DEPTH))
        )
        ptr_fifo
        (
            .clk(clk),
            .rst_n(rst_n),
            .rd(ptrqueue_rd[i]),
            .wr(ptrqueue_wr[i]),
            .w_data(ptrqueue_in[i]),
            .r_data(ptrqueue_out[i]),
            .empty(ptrqueue_empty[i]),
            .full(ptrqueue_full[i])
        );
    end
endgenerate

endmodule
