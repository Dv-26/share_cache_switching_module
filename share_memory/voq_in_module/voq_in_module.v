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
    output  wire    [WIDTH_PORT-1 : 0]  data_out,
    output  wire    [PORT_NUB-1 : 0]    done_out

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
wire    [PORT_NUB-1 : 0]      done[PORT_NUB : 0];

reg                         full_reg;
reg     [WIDTH_PORT-1 : 0]  data_reg;
reg     [WIDTH_SEL-1 : 0]   nub_reg;
reg     [PORT_NUB : 0]      valid_reg;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data_reg    <= 0;
        nub_reg     <= 0;
        valid_reg   <= 0;
        full_reg    <= 0;
    end
    else begin
        if(!full_reg)begin
            data_reg    <= data_in;
            nub_reg     <= nub;
            valid_reg   <= valid_in;
        end
        full_reg    <= voq_full_in;
    end
end

assign port_data[0] = data_reg;
assign port_valid[0] = valid_reg;
assign port_nub[0] = nub_reg;

assign data_out = port_data[PORT_NUB];
assign valid_out = port_valid[PORT_NUB];
assign done_out = done[PORT_NUB];

generate
    genvar i; 
    for(i=0; i<PORT_NUB; i=i+1)begin: loop

        tx_manage_fsm
        #(
            .NUB(i)
        )
        tx_manage_fsm
        (
            .clk                (clk),
            .rst_n              (rst_n),
            .keep_in            (full_reg),
            .data_in            (port_data[i]),
            .valid_in           (port_valid[i]),
            .nub_in             (port_nub[i]),
            .done_in            (done[i]),
            .data_out           (port_data[i+1]),
            .nub_out            (port_nub[i+1]),
            .valid_out          (port_valid[i+1]),
            .done_out           (done[i+1])
        );

    end
endgenerate

endmodule



