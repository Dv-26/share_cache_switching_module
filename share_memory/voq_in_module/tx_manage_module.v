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
assign tx_valid    = data_in_tx == NUB; 

reg                         list_wr_en;
reg                         list_rd_en;
wire                        list_full;
wire                        list_empty;
wire                        list_full_total;
wire                        list_empty_total;
wire    [WIDTH_LIST-1 : 0]  list_data_in;
wire    [WIDTH_LIST-1 : 0]  list_data_out;
wire                        nub_eq_list_out;

reg_list
#(
    .DEPTH(16),
    .DATA_WIDTH(WIDTH_LIST),
    .NUB(PORT_NUB)
)
reg_list
(
    .clk            (clk),
    .rst_n          (rst_n),
    .wr_sel         (nub_in),
    .wr_data        (list_data_in),
    .wr_en          (list_wr_en),
    .rd_sel         (nub_reg),
    .rd_data        (list_data_out),
    .rd_en          (list_rd_en),
    .full           (list_full),
    .empty          (list_empty),
    .full_total     (list_full_total),
    .empty_total    (list_empty_total)
);

assign nub_eq_list_out  = ~list_empty;
assign list_data_in     = (out_sel)? data_in:list_data_out;

reg                                     out_valid;
reg     [WIDTH_LIST+WIDTH_SEL : 0]      out_reg;
wire    [WIDTH_LIST+WIDTH_SEL : 0]      out_reg_n;

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
wire                        nub_eq_ctrl;

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

assign nub_eq_in        = nub_in == nub_reg;
assign nub_eq_ctrl      = nub_reg == NUB;

reg     [WIDTH_LENGTH-1 : 0]    length_reg;
reg                             length_reg_minus,length_reg_load;
wire                            length_eq_zero;
wire    [WIDTH_LENGTH-1 : 0]    data_length_in;
reg                             length_sel;
wire                            ctrl_verify;
wire    [WIDTH_DATA-1 : 0]      ctrl_verify_in;

ctrl_verify ctrl_verify_module
(
    .data_in    (ctrl_verify_in),
    .verify_en  (ctrl_verify),
    .length     (data_length_in)
);

assign ctrl_verify_in = (nub_eq_list_out)? list_data_out:data_in;

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

assign length_eq_zero   = length_reg == 0;

reg     ctrl_flag,ctrl_flag_flip;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        ctrl_flag <= 0;
    else
        if(ctrl_flag_flip)
            ctrl_flag <= ~ctrl_flag;
end

localparam IDLE =   3'b001;
localparam RUN1 =   3'b010;
localparam RUN2 =   3'b100;

reg [2:0]   state,state_n;

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
    ctrl_flag_flip      = 1'b0;

    if(!keep_in)begin
        if(valid_in && !tx_valid)
            out_valid = 1'b1;
        else begin
            case(state)
                IDLE:begin
                    if(valid_in)begin
                        if(nub_eq_in && ctrl_verify && !nub_eq_list_out)begin
                            state_n = RUN1;
                            length_reg_load = 1;
                            out_valid = 1;
                            nub_add = 1;
                        end
                        else begin
                            out_sel = 1;
                            list_wr_en = 1;
                        end
                    end

                    if(nub_eq_list_out)begin
                        state_n = RUN1;
                        length_reg_load = 1;
                        out_valid = 1;
                        nub_add = 1;
                        out_sel = 1;
                        list_rd_en = 1;
                    end
                end
                RUN1:begin

                    if(length_eq_zero)begin
                        done = 1;
                        nub_rst = 1;
                        state_n = IDLE;
                    end

                    if(valid_in)begin
                        if(nub_eq_in && !nub_eq_list_out && !length_eq_zero)begin
                            out_valid = 1;
                            length_reg_minus = 1;
                            nub_add = 1;
                        end
                        else begin
                            out_sel = 1;
                            list_wr_en = 1;
                        end
                    end

                    if(nub_eq_list_out && !length_eq_zero)begin
                        out_sel = 1;
                        length_reg_minus = 1;
                        nub_add = 1;
                        out_valid = 1;
                        if(ctrl_verify && nub_eq_ctrl)
                            state_n = RUN2;
                        else
                            list_rd_en = 1;
                    end

                end
                RUN2:begin

                    if(length_eq_zero)begin
                        done = 1;
                        nub_rst = 1;
                        state_n = IDLE;
                    end
                    else begin
                        out_valid = 1;
                        length_reg_minus = 1;
                    end

                    if(valid_in)begin
                        out_sel = 1;
                        list_wr_en = 1;
                    end

                end
            endcase
        end
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
