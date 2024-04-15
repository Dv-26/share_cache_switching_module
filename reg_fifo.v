`timescale 1ns/1ns

module reg_fifo
#(
    parameter   DATA_WIDTH = 8,
    parameter   DEPTH = 16
)
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire                        wr_en,
    input   wire    [DATA_WIDTH-1 : 0]  wr_data,
    input   wire                        rd_en,
    output  wire    [DATA_WIDTH-1 : 0]  rd_data,
    output  wire                        full,
    output  wire                        empty
);

reg [DATA_WIDTH-1 : 0]      shift_reg[DEPTH-1 : 0];
reg [$clog2(DEPTH)-1 : 0]   count,count_n;

assign full = &count;
assign empty = !(|count);

wire    rd,wr;
assign rd = rd_en & ~empty;
assign wr = wr_en & ~full;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        count <= 0;
    else
        count <= count_n;
end

always@(*)begin
    count_n = count;
    case(wr,rd)
        2'b01:  count_n = count - 1;
        2'b10:  count_n = count + 1;
    endcase
end

assign rd_data = shift_reg[count];

generate
    genvar i;

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) 
            shift_reg[0] <= {DATA_WIDTH{1'b0}};
        else begin
            if(wr)
                shift_reg[0] <= wr_data;
        end
    end

    for(i=1; i<DEPTH; i=i+1)begin
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                shift_reg[i] <= {DATA_WIDTH{1'b0}};
            end
            else begin
                if(wr)
                    shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

endgenerate


endmodule
