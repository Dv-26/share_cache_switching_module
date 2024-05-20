`include "../../generate_parameter.vh"
module tx_manage_fsm
#(
    parameter   NUB = 0      
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    input   wire    [WIDTH_LENGTH-1 : 0]    length_in,
    input   wire    [WIDTH_SEL-1 : 0]       tx_in,
    input   wire                            top_rd_en_in,
    input   wire    [WIDTH_SEL-1 : 0]       nub_in,
    output  reg                             valid_out,   
    output  reg                             cut_1to2_out
);

localparam  WIDTH_LENGTH    = $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_SEL       = $clog2(`PORT_NUB_TOTAL);
localparam  NUB_0           = NUB;

reg     error_nub_load;
wire    error_eq;
reg     [WIDTH_SEL-1 : 0]   error_nub_cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        error_nub_cnt <= 0;
    else
        if(error_nub_load)
            error_nub_cnt <= nub_in;
end
assign error_eq = error_nub_cnt-1 == nub_in;

reg    cnt_add,cnt_rst,nub_add_cnt;
reg [WIDTH_SEL-1 : 0]   nub_cnt;
wire    nub_eq;

always @(posedge clk or negedge rst_n)begin

    if(!rst_n)begin
        nub_cnt <= NUB;
    end 
    else begin

        if(cnt_rst)begin
            nub_cnt <= NUB;
        end
        else begin

            if(nub_add_cnt)begin
                nub_cnt <=  nub_cnt + add_cnt;
            end
            else begin
                if(cnt_add)
                    nub_cnt <= nub_cnt + 1;
            end

        end

    end

end

reg     add_add,add_rst;
reg [WIDTH_SEL-1 : 0]   add_cnt;

always @(posedge clk or negedge rst_n)begin

    if(!rst_n)begin
        add_cnt <= 0;
    end
    else begin

        if(add_rst)begin
            add_cnt <= 0;
        end
        else begin
            if(add_add)
                add_cnt <= add_cnt + 1;
        end

    end

end

wire    data_valid;

assign  nub_eq = (nub_cnt == nub_in);
assign  data_valid = (tx_in == NUB) && (top_rd_en_in == 1'b1);

reg     length_reg_minus,length_load;
wire    length_eq_zero;   

reg [WIDTH_LENGTH-1 : 0]    length_reg;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        length_reg <= 0;
    end
    else begin
        if(length_load)
            length_reg <= length_in - add_cnt;
        else begin
            if(length_reg_minus && !length_eq_zero)
                length_reg <= length_reg - 1;
        end
    end
end

assign length_eq_zero = length_reg == 0;

localparam IDLE         = 2'b00;
localparam RECEIVE1     = 2'b01;
localparam RECEIVE2     = 2'b10;
localparam RECEIVE3     = 2'b11;


reg [1:0]   state,state_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= state_n;
end


always @(*)begin
    state_n = state;
    length_load = 1'b0;
    cnt_add = 1'b0;
    add_rst = 1'b0;
    cnt_rst = 1'b0;
    add_add = 1'b0;
    error_nub_load = 1'b0;
    length_reg_minus = 1'b0;
    valid_out = 1'b0;
    cut_1to2_out = 1'b0;
    nub_add_cnt = 1'b0;
    case(state)
        IDLE:begin

            if(data_valid)begin
                if(nub_eq)begin

                    length_load = 1'b1;
                    cnt_add = 1'b1;
                    valid_out = 1'b1;
                    state_n = RECEIVE1;

                end
                else begin
                    error_nub_load = 1'b1;
                    state_n = RECEIVE2;
                end
            end

        end
        RECEIVE1:begin

            if(data_valid)begin

                length_reg_minus = 1'b1;

                if(nub_eq)begin
                    cnt_add = 1'b1;
                    valid_out = 1'b1;
                end
                else begin
                    state_n = RECEIVE2;
                    error_nub_load = 1'b1;
                end
                
            end

            if(length_eq_zero)begin
                cnt_rst = 1'b1;
                state_n = IDLE;
            end

        end
        RECEIVE2: begin


            if(data_valid)begin

                length_reg_minus = 1'b1;

                if(nub_eq)begin

                    cnt_add = 1;
                    if(length_eq_zero)begin
                        length_load = 1'b1;
                    end
                    else begin
                        // nub_add_cnt = 1'b1;
                    end
                    add_add = 1;
                    valid_out = 1'b1;
                    state_n = RECEIVE3;
                end
                else 
                    add_add = 1;

            end

        end
        RECEIVE3: begin

            if(data_valid)begin

                length_reg_minus = 1'b1;
                add_add = 1;

                if(nub_eq)begin
                    valid_out = 1'b1;
                    cnt_add = 1'b1;
                    if(error_eq)begin
                        cut_1to2_out = 1'b1;
                        nub_add_cnt = 1'b1;
                        add_rst = 1'b1;
                        state_n = RECEIVE1;
                    end
                end 
                
            end

        end

    endcase
end

endmodule
