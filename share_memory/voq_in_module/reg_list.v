
module reg_list
#(
    parameter   DEPTH       = 8,
    parameter   DATA_WIDTH  = 4,
    parameter   INDEX_WIDTH = 4
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire    [INDEX_WIDTH-1 : 0]     index_in,
    input   wire    [DATA_WIDTH-1 : 0]      wr_data,
    input   wire                            wr_en,
    input   wire    [INDEX_WIDTH-1 : 0]     search_in,
    output  wire    [DATA_WIDTH-1 : 0]      rd_data,
    input   wire                            rd_en,
    output  wire                            search_valid,
    output  wire                            full,
    output  wire                            empty
);

localparam  WIDTH_SEL = $clog2(DEPTH);

reg [INDEX_WIDTH-1 : 0] index_reg   [DEPTH-1 : 0];
reg [DATA_WIDTH-1 : 0]  data_reg    [DEPTH-1 : 0];
reg [DEPTH-1 : 0]       bitmap;

reg     [WIDTH_SEL-1 : 0]   wr_sel;
reg     [WIDTH_SEL-1 : 0]   rd_sel;

integer n;
always @(*)begin
    wr_sel = 0;
    rd_sel = 0;
    for(n=DEPTH-1; n >= 0; n=n-1)begin
        if(!bitmap[n])
            wr_sel = n;
        if(search_bitmap[n])
            rd_sel = n;
    end
end

assign rd_data = data_reg[rd_sel];

assign full     = &bitmap;
assign empty    = ~|bitmap;  

wire    [DEPTH-1 : 0]   search_bitmap;

generate
    genvar i;
    for(i=0; i<DEPTH; i=i+1)begin: loop

        wire    wr,rd;
        reg [INDEX_WIDTH-1 : 0] index_reg_n;
        reg [DATA_WIDTH-1 : 0]  data_reg_n;
        reg                     bitmap_n;
        
        assign wr = wr_en && wr_sel == i;
        assign rd = rd_en && rd_sel == i;

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                bitmap[i] <= 0;
                index_reg[i] <= 0;
                data_reg[i] <= 0;
            end
            else begin
                index_reg[i] <= index_reg_n;
                data_reg[i] <= data_reg_n;
                bitmap[i] <= bitmap_n;
            end
        end

        always @(*)begin
            index_reg_n = index_reg[i];
            data_reg_n = data_reg[i];
            bitmap_n = bitmap[i];

            case({wr, rd})
                2'b01:begin
                    bitmap_n = 0;
                    data_reg_n = 0;
                    index_reg_n = 0;
                end
                2'b10:begin
                    bitmap_n = 1;
                    data_reg_n = wr_data;
                    index_reg_n = index_in;
                end
                2'b11:begin
                    bitmap_n = 1;
                    data_reg_n = wr_data;
                    index_reg_n = index_in;
                end
            endcase
        end

        assign search_bitmap[i] = bitmap[i] && (search_in == index_reg[i]);
    end
endgenerate

assign search_valid = |search_bitmap;



endmodule
