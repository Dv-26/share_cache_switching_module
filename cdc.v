module cdc
#(
    parameter   DATA_WIDTH = 9
)
(
    input   wire                        tx_clk,
    input   wire                        rx_clk,
    input   wire                        rst_n,

    input   wire    [DATA_WIDTH-1 : 0]  in_data,
    output  wire    [DATA_WIDTH-1 : 0]  out_data
);

reg     [DATA_WIDTH-1 : 0]  tx_reg;
reg     [DATA_WIDTH-1 : 0]  rx_reg[3 : 0];
reg     [DATA_WIDTH-1 : 0]  out_reg;

always @(posedge tx_clk or negedge rst_n)begin
    if(!rst_n)
        tx_reg <= 0;
    else
        tx_reg <= in_data;
end

always @(posedge rx_clk or negedge rst_n)begin
    if(!rst_n)begin
        rx_reg[0] <= 0;
        rx_reg[1] <= 0;
        rx_reg[2] <= 0;
        rx_reg[3] <= 0;
    end
    else begin
        rx_reg[0] <= tx_reg;
        rx_reg[1] <= rx_reg[0];
        rx_reg[2] <= rx_reg[1];
        rx_reg[3] <= rx_reg[2];
    end
end

wire    out_reg_load;
assign  out_reg_load = (rx_reg[3] == rx_reg[2]) && (rx_reg[2] == rx_reg[0]);

always @(posedge rx_clk or negedge rst_n)begin
    if(!rst_n)
        out_reg <= 0;
    else
        if(out_reg_load)
            out_reg <= rx_reg[3];
end

assign out_data = out_reg;

endmodule
