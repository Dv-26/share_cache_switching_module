
module reg_list
#(
    parameter   DEPTH       = 8,
    parameter   DATA_WIDTH  = 4,
    parameter   NUB         = 4
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire    [WIDTH_SEL-1 : 0]       wr_sel,
    input   wire    [DATA_WIDTH-1 : 0]      wr_data,
    input   wire                            wr_en,
    input   wire    [WIDTH_SEL-1 : 0]       rd_sel,
    output  wire    [DATA_WIDTH-1 : 0]      rd_data,
    input   wire                            rd_en,
    output  wire                            full,
    output  wire                            empty,
    output  wire                            full_total,
    output  wire                            empty_total
);

localparam  WIDTH_SEL = $clog2(NUB);

wire    [DATA_WIDTH-1 : 0]  fifo_rd_data[NUB-1 : 0];
wire    [NUB-1 : 0]         fifo_full,fifo_empty;

assign  full        = fifo_full[wr_sel];
assign  empty       = fifo_empty[rd_sel];
assign  rd_data     = fifo_rd_data[rd_sel];
assign  full_total  = &fifo_full;
assign  empty_total = &fifo_empty;

generate
    genvar i;
    for(i=0; i<NUB; i=i+1)begin

        wire    fifo_wr_en,fifo_rd_en;

        reg_fifo
        #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEPTH(DEPTH)
        )
        reg_fifo
        (
            .clk        (clk),
            .rst_n      (rst_n),
            .wr_en      (fifo_wr_en),
            .wr_data    (wr_data),
            .rd_en      (fifo_rd_en),
            .rd_data    (fifo_rd_data[i]),
            .full       (fifo_full[i]),
            .empty      (fifo_empty[i])
        );

        assign fifo_wr_en = (wr_sel == i)? wr_en:0;
        assign fifo_rd_en = (rd_sel == i)? rd_en:0;

    end
endgenerate

endmodule
