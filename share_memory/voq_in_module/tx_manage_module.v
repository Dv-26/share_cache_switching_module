`include "../../generate_parameter.vh"
module tx_manage_fsm
#(
    parameter   NUB = 0      
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire                            keep_in,

    input   wire    [WIDTH_PORT-1 : 0]      data_in,
    input   wire                            valid_in,
    input   wire    [WIDTH_SEL-1 : 0]       nub_in,

    output  wire    [WIDTH_PORT-1 : 0]      data_out,
    output  wire    [WIDTH_SEL-1 : 0]       nub_out,
    output  wire                            valid_out
);

localparam  WIDTH_DATA      = `DATA_WIDTH; 
localparam  WIDTH_LENGTH    = $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_SEL       = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT      = WIDTH_SEL +  WIDTH_DATA;
localparam  WIDTH_FIFO      = WIDTH_SEL + WIDTH_PORT;  
localparam  PORT_NUB        = `PORT_NUB_TOTAL;
localparam  WIDTH_PRIORITY  = $clog2(`PRIORITY);
localparam  WIDTH_CRC       = `CRC32_LENGTH;

wire    [WIDTH_SEL-1 : 0]   data_in_tx;
reg                         out_sel;
assign  data_in_tx = data_in[WIDTH_PORT-1 : WIDTH_PORT-WIDTH_SEL];

reg     fifo_wr_en;
reg     fifo_rd_en;
wire    fifo_full;
wire    fifo_empty;
wire    empty;

wire    [WIDTH_SEL-1 : 0]   fifo_out_tx;
wire    [WIDTH_SEL-1 : 0]   fifo_out_nub;
wire    [WIDTH_FIFO-1 : 0]  fifo_data_in;
wire    [WIDTH_FIFO-1 : 0]  fifo_data_out;

assign  {fifo_out_nub, fifo_out_tx} = fifo_data_out[WIDTH_FIFO-1 : WIDTH_FIFO - 2*WIDTH_SEL];

reg_fifo
#(
    .DATA_WIDTH(WIDTH_FIFO),
    .DEPTH(PORT_NUB)
)
fifo 
(
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(fifo_wr_en),
    .wr_data(fifo_data_in),
    .rd_en(fifo_rd_en),
    .rd_data(fifo_data_out),
    .full(fifo_full),
    .empty(fifo_empty)
);

assign fifo_data_in = (out_sel)? data_in:fifo_data_out;

reg                         out_valid;
reg     [WIDTH_FIFO : 0]    out_reg;
wire    [WIDTH_FIFO : 0]    out_reg_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        out_reg <= 0;
    else
        out_reg <= out_reg_n;
end

assign out_reg_n =  (keep_in)?  out_reg:
                    (out_sel)?  {out_valid, fifo_data_out}:
                                {out_valid, nub_in, data_in};

assign {valid_out,nub_out,data_out} = out_reg;

reg     [WIDTH_SEL-1 : 0]   nub_reg;
reg                         nub_add,nub_rst;
wire                        nub_eq_in;
wire                        nub_eq_fifo_out;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        nub_reg <= NUB;
    else begin
        if(nub_rst)
            nub_reg <= NUB;
        else
            if(nub_add)
                nub_reg <= nub_reg + 1;
    end
end

reg     [WIDTH_LENGTH-1 : 0]    length_reg;
reg                             length_reg_minus,length_reg_load;
wire                            length_eq_zero;
wire    [WIDTH_LENGTH-1 : 0]    data_length_in;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        length_reg <= 0;
    else begin
        if(length_reg_load)
            length_reg <= length_reg + data_length_in;
        else if(length_reg_minus)
            length_reg <= length_reg - 1;
    end
end

assign data_length_in = data_in[WIDTH_LENGTH+WIDTH_CRC+WIDTH_PRIORITY-1:WIDTH_CRC+WIDTH_PRIORITY];
assign length_eq_zero = length_reg == 0;

assign tx_valid         = data_in_tx == NUB; 
assign nub_eq_in        = nub_in == nub_reg;
assign nub_eq_fifo_out  = (nub_in == fifo_out_nub) & !fifo_empty;

localparam IDLE =   1'b0;
localparam RUN  =   1'b1;

reg state,state_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= state_n;
end

always @(*)begin

    state_n             = state;
    fifo_wr_en          = 1'b0;
    fifo_rd_en          = 1'b0;
    out_sel             = 1'b0;
    nub_add             = 1'b0;
    nub_rst             = 1'b0;
    length_reg_minus    = 1'b0;
    length_reg_load     = 1'b0;
    out_valid           = 1'b0;  

    if(!keep_in)begin

        case(state)
            IDLE:begin
                if(valid_in)begin

                    if(tx_valid)begin

                        if(nub_eq_in)begin
                            state_n = RUN;
                            length_reg_load = 1;
                            out_valid = 1;
                            nub_add = 1;
                        end
                        else begin
                            fifo_wr_en = 1;
                            length_reg_minus = 1;
                        end

                    end
                    else
                        out_valid = 1;
                end
            end
            RUN:begin
                if(length_eq_zero)begin
                    state_n = IDLE;
                    nub_rst = 1;
                end
                else begin

                    if(valid_in)begin

                        if(tx_valid)begin

                            length_reg_minus = 1'b1;

                            case({nub_eq_in,nub_eq_fifo_out})
                                2'b00:begin
                                    out_sel = 1'b1;
                                    fifo_wr_en = 1'b1;
                                end
                                2'b01:begin
                                    out_sel = 1'b1;
                                    fifo_rd_en = 1'b1;
                                    nub_add = 1'b1;
                                    out_valid = 1'b1;
                                end
                                2'b10:begin
                                    out_valid = 1'b1;
                                    nub_add = 1'b1;
                                end
                                2'b11:begin
                                    out_sel = 1'b1;
                                    fifo_wr_en = 1'b1;
                                    fifo_rd_en = 1'b1;
                                    nub_add = 1'b1;
                                    out_valid = 1'b1;
                                end
                            endcase

                        end
                        else
                            out_valid = 1'b1;

                    end
                    else begin

                        if(nub_eq_fifo_out)begin
                            out_sel = 1'b1;
                            fifo_rd_en = 1'b1;
                            nub_add = 1'b1;
                        end

                    end

                end
            end
        endcase
        
    end

end

endmodule
