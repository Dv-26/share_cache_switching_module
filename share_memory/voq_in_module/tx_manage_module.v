`include "../../generate_parameter.vh"
module tx_manage_fsm
#(
    parameter   NUB = 0      
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire                            keep_in,
    input   wire    [PORT_NUB-1 : 0]        done_in,
    output  reg     [PORT_NUB-1 : 0]        done_out,

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
localparam  WIDTH_PORT      = WIDTH_SEL + WIDTH_DATA;
localparam  WIDTH_LIST      = WIDTH_SEL + WIDTH_DATA;  
localparam  PORT_NUB        = `PORT_NUB_TOTAL;
localparam  WIDTH_PRIORITY  = $clog2(`PRIORITY);
localparam  WIDTH_CRC       = `CRC32_LENGTH;

wire    [WIDTH_SEL-1 : 0]   data_in_tx;
reg                         out_sel;

assign  data_in_tx = data_in[WIDTH_PORT-1 : WIDTH_PORT-WIDTH_SEL];

reg                         list_wr_en;
reg                         list_rd_en;
wire                        list_full;
wire                        list_empty;
wire    [WIDTH_LIST-1 : 0]  list_data_in;
wire    [WIDTH_LIST-1 : 0]  list_data_out;
wire                        nub_eq_list_out;

reg_list
#(
    .DEPTH(2*PORT_NUB),
    .DATA_WIDTH(WIDTH_LIST),
    .INDEX_WIDTH(WIDTH_SEL)
)
reg_list
(
    .clk            (clk),
    .rst_n          (rst_n),
    .index_in       (nub_in),
    .wr_data        (list_data_in),
    .wr_en          (list_wr_en),
    .search_in      (nub_reg),
    .rd_data        (list_data_out),
    .rd_en          (list_rd_en),
    .search_valid   (nub_eq_list_out),
    .full           (list_full),
    .empty          (list_empty)
);

assign list_data_in = (out_sel)? data_in:list_data_out;

reg                         out_valid;
reg     [WIDTH_LIST+WIDTH_SEL : 0]    out_reg;
wire    [WIDTH_LIST+WIDTH_SEL : 0]    out_reg_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        out_reg <= 0;
    else
        out_reg <= out_reg_n;
end

assign out_reg_n =  (keep_in)?  out_reg:
                    (out_sel)?  {out_valid, nub_reg, list_data_out}:
                                {out_valid, nub_in, data_in};

assign {valid_out,nub_out,data_out} = out_reg;

reg     [WIDTH_SEL-1 : 0]   nub_reg;
reg                         nub_add,nub_rst;
wire                        nub_eq_in;

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

localparam IDLE =   1'b0;
localparam RUN  =   1'b1;

reg state,state_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= state_n;
end

reg done;

always @(*)begin

    state_n             = state;
    list_wr_en          = 1'b0;
    list_rd_en          = 1'b0;
    out_sel             = 1'b0;
    nub_add             = 1'b0;
    nub_rst             = 1'b0;
    length_reg_minus    = 1'b0;
    length_reg_load     = 1'b0;
    out_valid           = 1'b0;  
    done                = 1'b0;

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
                            list_wr_en = 1;
                            out_sel = 1'b1;
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
                    done = 1;
                    if(valid_in)
                        out_valid = 1;
                end
                else begin

                    if(valid_in)begin

                        if(tx_valid)begin


                            case({nub_eq_in,nub_eq_list_out})
                                2'b00:begin
                                    out_sel = 1'b1;
                                    list_wr_en = 1'b1;
                                end
                                2'b01:begin
                                    out_sel = 1'b1;
                                    length_reg_minus = 1'b1;
                                    list_wr_en = 1'b1;
                                    list_rd_en = 1'b1;
                                    nub_add = 1'b1;
                                    out_valid = 1'b1;
                                end
                                2'b10:begin
                                    out_valid = 1'b1;
                                    length_reg_minus = 1'b1;
                                    nub_add = 1'b1;
                                end
                                2'b11:begin
                                    out_sel = 1'b1;
                                    length_reg_minus = 1'b1;
                                    list_wr_en = 1'b1;
                                    list_rd_en = 1'b1;
                                    nub_add = 1'b1;
                                    out_valid = 1'b1;
                                end
                            endcase


                        end
                        else
                            out_valid = 1'b1;

                    end
                    else begin

                        if(nub_eq_list_out)begin
                            out_sel = 1'b1;
                            length_reg_minus = 1'b1;
                            list_rd_en = 1'b1;
                            nub_add = 1'b1;
                            out_valid = 1'b1;
                        end

                    end

                end
            end
        endcase
        
    end

end

reg    [PORT_NUB-1 : 0]    done_out_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        done_out <= 0;
    else
        done_out <= done_out_n;
end

always @(*)begin
    done_out_n = done_in;
    done_out_n[NUB] = done;
end


endmodule
