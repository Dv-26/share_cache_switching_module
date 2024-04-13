`timescale 1ns/1ns
`include "../generate_parameter.vh"

module multi_channel_fifo
#(
    parameter   PORT_NUB    = 4,
    parameter   DEPTH       = 100
)
(
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [WIDTH_PORT-1 : 0]  wr_data,
    input   wire                        wr_en,
    input   wire    [WIDTH_SEL-1 : 0]   wr_sel,

    output  wire    [WIDTH_PORT-1 : 0]  rd_data,
    input   wire                        rd_en,
    input   wire    [WIDTH_SEL-1 : 0]   rd_sel,

    output  wire    [PORT_NUB-1 : 0]    empty,
    output  wire    [PORT_NUB-1 : 0]    full

);

localparam  WIDTH_PORT  = $clog2(DEPTH);
localparam  WIDTH_TOTAL = PORT_NUB * WIDTH_PORT;
localparam  WIDTH_SEL   = $clog2(PORT_NUB);
localparam  WIDTH_PRT   = $clog2(PORT_NUB*DEPTH);

reg [WIDTH_PORT-1 : 0]  sram    [PORT_NUB*DEPTH-1 : 0];


wire    [WIDTH_PRT-1 : 0]  r_addr,w_addr;
reg     [WIDTH_PRT-1 : 0]  r_addr_reg,w_addr_reg;

assign rd_data = sram[r_addr];

always @(posedge clk)begin
    if(wr_en)
        sram[w_addr] <= wr_data;
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        r_addr_reg <= {WIDTH_PRT{1'b0}};
        w_addr_reg <= {WIDTH_PRT{1'b0}};
    end
    else begin
        r_addr_reg <= r_addr;
        w_addr_reg <= w_addr;
    end
end

reg     [WIDTH_PRT-1 : 0]   rd_prt_reg[PORT_NUB-1 : 0];
reg     [WIDTH_PRT-1 : 0]   wr_prt_reg[PORT_NUB-1 : 0];
reg     [PORT_NUB-1 : 0]    empty_reg;
reg     [PORT_NUB-1 : 0]    full_reg;

assign empty = empty_reg;
assign full = full_reg; 

generate
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin: loop

        reg     [WIDTH_PRT-1 : 0]   w_prt_reg_n,r_prt_reg_n;
        reg     [WIDTH_PRT-1 : 0]   w_prt_succ,r_prt_succ;
        reg                         full_n,empty_n;
        wire                        rd,en;

        assign rd = (rd_sel == i) && rd_en;
        assign wr = (wr_sel == i) && wr_en;

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                rd_prt_reg[i] <= i;
                wr_prt_reg[i] <= i;
                empty_reg[i] <= 1'b0;
                full_reg[i] <= 1'b0;
            end
            else begin
                rd_prt_reg[i] <= r_prt_reg_n;
                wr_prt_reg[i] <= w_prt_reg_n;
                empty_reg[i] <= empty_n;
                full_reg[i] <= full_n;
            end
        end

        always@(*)begin
            empty_n = empty_reg[i];
            full_n = full_reg[i];

            w_prt_succ = wr_prt_reg[i] + PORT_NUB;
            r_prt_succ = rd_prt_reg[i] + PORT_NUB;

            r_prt_reg_n = rd_prt_reg[i];
            w_prt_reg_n = wr_prt_reg[i];


            case({rd,wr})
                2'b01:begin
                    if(~full_reg[i])begin
                        w_prt_reg_n = w_prt_succ;
                        empty_n = 1'b0; 
                        if(w_prt_succ == rd_prt_reg[i])
                            full_n = 1'b1;
                    end
                end
                2'b10:begin
                    if(~empty_reg[i])begin
                        r_prt_reg_n = r_prt_succ;
                        full_n = 1'b0; 
                        if(r_prt_succ == wr_prt_reg[i])
                            empty_n = 1'b1;
                    end
                end
                2'b11:begin
                    w_prt_reg_n = w_prt_succ;
                    r_prt_reg_n = r_prt_succ;
                end
            endcase
            
        end

    end

endgenerate

assign  w_addr = wr_prt_reg[wr_sel];
assign  r_addr = rd_prt_reg[rd_sel];




endmodule
