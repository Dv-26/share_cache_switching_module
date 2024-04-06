`include "./define.vh"

module dc_fifo_input_data_info
#(
    parameter   DATA_BIT    = $clog2(`PORT_NUB_TOTAL) + $clog2(`PRI_NUM) + $clog2(`DATABUF_HIGH_LIMIT_NUM) + `CRC32_LENGTH_WIDTH,
    parameter   DATA_DEPTH  = $clog2(`DATABUF_HIGH_LIMIT_NUM / `INPUT_LOW_LIMIT_NUM)
)
(
    input   wire                        rst_n,

    input   wire                        wr_clk,
    input   wire    [DATA_BIT-1:0]      wr_data,
    input   wire                        wr_en,
    output  wire    [DATA_DEPTH-1:0]    wr_cnt,

    input   wire                        rd_clk,
    output  wire    [DATA_BIT-1:0]      rd_data,
    input   wire                        rd_en,
    output  wire    [DATA_DEPTH-1:0]    rd_cnt,

    output  wire                        empty,
    output  wire                        full
);

reg     [DATA_BIT-1:0]      array_reg [2**DATA_DEPTH-1:0];

reg     [DATA_DEPTH:0]      w_prt_reg;
wire    [DATA_DEPTH:0]      w_prt_gray;
reg     [DATA_DEPTH:0]      w_prt_gray_r,w_prt_gray_rr;    
wire    [DATA_DEPTH:0]      w_prt_bin;
reg     [DATA_DEPTH-1:0]    wr_cnt_reg;

reg     [DATA_DEPTH:0]      r_prt_reg; 
wire    [DATA_DEPTH:0]      r_prt_gray;
reg     [DATA_DEPTH:0]      r_prt_gray_r,r_prt_gray_rr;    
wire    [DATA_DEPTH:0]      r_prt_bin;
reg     [DATA_DEPTH-1:0]    rd_cnt_reg;

always @(posedge wr_clk)begin
    if(wr_en && !full_out_n)
        array_reg [w_prt_reg[DATA_DEPTH-1:0]] <= wr_data;
end




assign  rd_data = array_reg[r_prt_reg[DATA_DEPTH-1:0]];
assign w_prt_gray = (w_prt_reg >> 1) ^ w_prt_reg;

always @(posedge wr_clk or negedge rst_n)begin
    if(!rst_n)begin
        r_prt_gray_r    <= {(DATA_DEPTH+1){1'b0}};
        r_prt_gray_rr   <= {(DATA_DEPTH+1){1'b0}};
    end
    else begin
        r_prt_gray_r    <= r_prt_gray;
        r_prt_gray_rr   <= r_prt_gray_r;
    end
end

genvar i;
generate
    for(i=0;i<DATA_DEPTH+1;i=i+1)begin: r_gray2binary
        if(i==DATA_DEPTH) 
            assign r_prt_bin[i] = r_prt_gray_rr[i];
        else 
            assign r_prt_bin[i] = r_prt_bin[i+1] ^ r_prt_gray_rr[i];
    end
endgenerate

always @(posedge wr_clk or negedge rst_n)begin
    if(!rst_n)
        wr_cnt_reg <= {DATA_DEPTH{1'b0}};
    else 
        wr_cnt_reg <= w_prt_reg[DATA_DEPTH-1:0] - r_prt_bin[DATA_DEPTH-1:0];
end

assign wr_cnt = wr_cnt_reg;




reg     full_out;
/* wire    full_out_n; */

assign full_out_n = (w_prt_gray[DATA_DEPTH] != r_prt_gray_rr[DATA_DEPTH]) && (w_prt_gray[DATA_DEPTH - 1] != r_prt_gray_rr[DATA_DEPTH - 1]) && (w_prt_gray[DATA_DEPTH-2:0] == r_prt_gray_rr[DATA_DEPTH-2:0]);

/* always @(posedge wr_clk or negedge rst_n)begin */
/*     if(!rst_n) */
/*         full_out <= 1'b0; */
/*     else */ 
/*         full_out <= full_out_n; */ 
/* end */

assign full = full_out_n;




always @(posedge wr_clk or negedge rst_n)begin
    if(!rst_n)begin
        w_prt_reg   <= {(DATA_DEPTH+1){1'b0}};
    end
    else begin 
        if(wr_en && ~full_out_n)
            w_prt_reg <= w_prt_reg + 1;
    end
end




assign r_prt_gray = (r_prt_reg >> 1) ^ r_prt_reg;

always @(posedge rd_clk or negedge rst_n)begin
    if(!rst_n)begin
        w_prt_gray_r <= {(DATA_DEPTH + 1){1'b0}};
        w_prt_gray_rr <= {(DATA_DEPTH + 1){1'b0}};
    end
    else begin
        w_prt_gray_r <= w_prt_gray;
        w_prt_gray_rr <= w_prt_gray_r;
    end
end



genvar j;
generate
    for(j=0;j<DATA_DEPTH+1;j=j+1)begin: w_gray2binary
        if(j==DATA_DEPTH) 
            assign w_prt_bin[j] = w_prt_gray_rr[j];
        else 
            assign w_prt_bin[j] = w_prt_bin[j+1] ^ w_prt_gray_rr[j];
    end
endgenerate



always @(posedge rd_clk or negedge rst_n)begin
    if(!rst_n)
        rd_cnt_reg <= {DATA_DEPTH{1'b0}};
    else 
        rd_cnt_reg <= w_prt_bin[DATA_DEPTH-1:0] - r_prt_reg[DATA_DEPTH-1:0];
end

assign rd_cnt = rd_cnt_reg;




wire    empty_out_n;
/* reg     empty_out; */

assign empty_out_n = r_prt_gray == w_prt_gray_rr;

/* always @(posedge rd_clk or negedge rst_n)begin */
/*     if(!rst_n) */
/*         empty_out <= 1'b0; */
/*     else */
/*         empty_out <= empty_out_n; */
/* end */

assign empty = empty_out_n;



always @(posedge rd_clk or negedge rst_n)begin
    if(!rst_n)begin
        r_prt_reg   <= {(DATA_DEPTH+1){1'b0}};
    end
    else begin
        if(rd_en && ~empty_out_n)
            r_prt_reg <= r_prt_reg + 1;
    end
end


endmodule
