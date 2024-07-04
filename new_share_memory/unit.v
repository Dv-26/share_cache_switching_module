`include "../generate_parameter.vh"
 
module unit
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [DATA_WIDTH-1 : 0]  rx,
    input   wire    [DATA_WIDTH-1 : 0]  tx,

    input   wire    [WIDTH_TOTAL-1 : 0] data_in,
    output  wire    [WIDTH_TOTAL-1 : 0] data_out
);

localparam  DATA_WIDTH  = `DATA_WIDTH;
localparam  WIDTH_TOTAL = $clog2(`PORT_NUB_TOTAL) * DATA_WIDTH;

endmodule
