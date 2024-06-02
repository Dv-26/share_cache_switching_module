`include "../../generate_parameter.vh"

module voq_in_module
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire                        voq_full_in,
    input   wire    [WIDTH_PORT-1 : 0]  data_in,
    input   wire    [WIDTH_SEL-1 : 0]   nub,
    input   wire                        valid_in,

    output  wire                        valid_out,
    output  wire    [WIDTH_PORT-1 : 0]  data_out

);

localparam  PORT_NUB        = `PORT_NUB_TOTAL;
localparam  WIDTH_SEL       = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT      = WIDTH_SEL + `DATA_WIDTH;
localparam  WIDTH_FIFO      = WIDTH_PORT + 1;
localparam  WIDTH_LENGTH    = $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_CRC       =`CRC32_LENGTH;
localparam  WIDTH_PRIORITY  = $clog2(`PRIORITY);

wire    [WIDTH_PORT-1 : 0]  port_data[PORT_NUB : 0];
wire    [WIDTH_SEL-1 : 0]   port_nub[PORT_NUB : 0];
wire    [PORT_NUB : 0]      port_valid;

assign port_data[0] = data_in;
assign port_valid[0] = valid_in;
assign port_nub[0] = nub;

assign data_out = port_data[PORT_NUB];
assign valid_out = port_valid[PORT_NUB];

generate
    genvar i; 
    for(i=0; i<PORT_NUB; i=i+1)begin: loop

        tx_manage_fsm
        #(
            .NUB(i)
        )
        tx_manage_fsm
        (
            .clk(clk),
            .rst_n(rst_n),
            .keep_in(voq_full_in),
            .data_in(port_data[i]),
            .valid_in(port_valid[i]),
            .nub_in(port_nub[i]),
            .data_out(port_data[i+1]),
            .nub_out(port_nub[i+1]),
            .valid_out(port_valid[i+1])
        );

    end
endgenerate

endmodule



