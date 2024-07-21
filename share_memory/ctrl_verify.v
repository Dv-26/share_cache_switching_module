`include "../generate_parameter.vh"

module ctrl_verify
(
    input   wire    [WIDTH_DATA-1 : 0]      data_in,
    output  wire                            verify_vld,

    output  wire    [WIDTH_LENGTH-1 : 0]    length,
    output  wire    [WIDTH_CRC-1 : 0]       crc_16bit,
    output  wire    [WIDTH_PRIORITY-1 : 0]  priority
);

localparam  WIDTH_DATA      = `DATA_WIDTH; 
localparam  WIDTH_LENGTH    = $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_SEL       = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT      = WIDTH_SEL + WIDTH_DATA;
localparam  WIDTH_LIST      = WIDTH_SEL + WIDTH_DATA;  
localparam  PORT_NUB        = `PORT_NUB_TOTAL;
localparam  WIDTH_PRIORITY  = $clog2(`PRIORITY);
localparam  WIDTH_CRC       = `CRC32_LENGTH;
localparam  WIDTH_VERIFY    = WIDTH_DATA - WIDTH_CRC - WIDTH_PRIORITY - WIDTH_LENGTH;

wire    [WIDTH_PRIORITY-1 : 0]      length_bar;
wire    [WIDTH_CRC-1 : 0]           crc_16bit;
wire    [WIDTH_PRIORITY-1 : 0]      priority, priority_bar;

assign {length_bar, length, crc_16bit, priority} = data_in;
assign verify_vld = length[WIDTH_PRIORITY-1 : 0] == ~length_bar;

endmodule
