`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/14 18:39:40
// Design Name: 
// Module Name: fifo
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


module free_ptr_fifo
#(
    parameter DEPTH = 8                 //存储深度
)
(
    input   wire                    clk,
    input   wire                    rst_n,

    input   wire                    rd,
    input   wire                    wr,

    input   wire    [WIDTH-1:0]     w_data,
    output  wire    [WIDTH-1:0]     r_data,

    output  wire                    empty,
    output  wire                    full,
    output  wire    [WIDTH-1:0]     count
);

localparam  WIDTH = $clog2(DEPTH);

(*ram_style="block"*)reg [WIDTH-1:0] array_reg [DEPTH-1:0];
reg [WIDTH-1:0]w_prt_reg,w_prt_n,w_prt_succ;
reg [WIDTH-1:0]r_prt_reg,r_prt_n,r_prt_succ;
reg [WIDTH-1:0]count_reg,count_reg_n;
reg full_reg,full_reg_n,empty_reg,empty_reg_n;
wire wr_en;

integer i;

initial begin
    for(i=0;i<DEPTH;i=i+1)begin
        array_reg[i] = i;
    end
end

always @(posedge clk) begin
    if(wr_en)
        array_reg[w_prt_reg] <= w_data; 
end

assign r_data = array_reg[r_prt_reg];

assign wr_en = wr & ~full_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        w_prt_reg <= {WIDTH{1'b0}};
        r_prt_reg <= {WIDTH{1'b0}};
        full_reg  <= 1'b1;
        empty_reg <= 1'b0;
        count_reg <= DEPTH;
    end 
    else begin
        w_prt_reg <= w_prt_n;
        r_prt_reg <= r_prt_n;
        full_reg  <= full_reg_n;
        empty_reg <= empty_reg_n;
        count_reg <= count_reg_n;
    end
end

always @(*) begin

    if(w_prt_reg < DEPTH-1)
        w_prt_succ = w_prt_reg + 1;
    else
        w_prt_succ = 0;

    if(r_prt_reg < DEPTH-1)
        r_prt_succ = r_prt_reg + 1;
    else
        r_prt_succ = 0;

    w_prt_n = w_prt_reg;
    r_prt_n = r_prt_reg;

    full_reg_n = full_reg;
    empty_reg_n = empty_reg;
    count_reg_n = count_reg;

    case({rd,wr})
       // 2'b00:      //无操作
        2'b01:begin
            if(~full_reg)begin
                w_prt_n = w_prt_succ;
                count_reg_n = count_reg + 1;
                empty_reg_n = 1'b0;
                if(w_prt_succ == r_prt_reg)
                    full_reg_n = 1'b1;
            end
        end
        2'b10:begin
            if(~empty_reg)begin
                r_prt_n = r_prt_succ;
                count_reg_n = count_reg - 1;
                full_reg_n = 1'b0;
                if(r_prt_succ == w_prt_reg)
                    empty_reg_n = 1'b1;
            end
        end
        2'b11:begin
            w_prt_n = w_prt_succ;
            r_prt_n = r_prt_succ;
        end
    endcase
end

assign full = full_reg;
assign empty = empty_reg;
assign count = count_reg;

endmodule
