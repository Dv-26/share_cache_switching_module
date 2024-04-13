`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/12 21:37:05
// Design Name: 
// Module Name: ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ram
#(
    parameter   ADDR_WIDTH  =   6 , 
    parameter   DATA_WIDTH  =   8
)
(
    input   wire                        clk,

    input   wire                        wr_en,
    input   wire    [ADDR_WIDTH - 1:0]  wr_addr,
    input   wire    [DATA_WIDTH - 1:0]  wr_data,

    input   wire                        rd_en,
    output  reg     [DATA_WIDTH - 1:0]  rd_data,
    input   wire    [ADDR_WIDTH - 1:0]  rd_addr

);

reg [DATA_WIDTH - 1:0]  ram[2 ** ADDR_WIDTH - 1:0];



always @(posedge clk ) begin
    if(wr_en)
        ram[wr_addr] <= wr_data;
end

always @(posedge clk)begin
    if(rd_en)
        rd_data <= ram[rd_addr];
end

endmodule
