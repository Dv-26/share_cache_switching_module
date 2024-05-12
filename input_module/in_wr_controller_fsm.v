`include "../generate_parameter.vh"

module in_wr_controller_fsm
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire                        eop,
    input   wire                        valid,
    input   wire                        sop,
    input   wire                        ready,
    input   wire    [DATA_WIDTH-1 : 0]  ctrl_data_in,

    output  reg                         wr_en,
    output  wire                        fifo_rst_n,
    output  wire                        crc_rst_n,
    output  reg     [DATA_WIDTH-1 : 0]  ctrl_data_reg,

    output  reg                         done
);
localparam  DATA_WIDTH = `DATA_WIDTH;
localparam  WIDTH_LENGTH    =   $clog2(`DATA_LENGTH_MAX);

localparam  IDLE        =   3'b110;
localparam  LOAD        =   3'b001;
localparam  WR          =   3'b011;
localparam  WAIT        =   3'b010;
localparam  ERROR       =   3'b111;

reg [2:0]   state,state_n;

reg [WIDTH_LENGTH-1 : 0]   cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 0;
    end
    else begin
        if(cnt_rst)begin
            cnt <= 0;
        end
        else begin
            if(cnt_add)
                cnt <= cnt + 1;
        end
    end
end

wire    [9:0]               data_length;
wire                        cnt_eq_length;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        ctrl_data_reg <= 0;
    else begin
        if(ctrl_reg_load)
            ctrl_data_reg  <= ctrl_data_in;
    end
end

assign data_length = ctrl_data_reg[WIDTH_LENGTH-1 : 0];
assign cnt_eq_length = cnt == data_length;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= IDLE;
    end
    else begin
        state <= state_n;
    end
end

reg cnt_add,cnt_rst,ctrl_reg_load,crc_rst;

always @(*)begin
    state_n = state;
    cnt_add = 1'b0;
    cnt_rst = 1'b0;
    ctrl_reg_load = 1'b0;
    done = 1'b0;
    crc_rst = 1'b0;
    wr_en = 1'b0;
    case(state)
        IDLE:begin
            if(sop)
                state_n = LOAD;
        end
        LOAD:begin
            ctrl_reg_load = 1;
            state_n = WR;
        end
        WR:begin
            wr_en = 1;
            if(valid)
                cnt_add = 1;
            if(eop)begin
                wr_en = 0;
                if(cnt_eq_length)
                    state_n = WAIT;
                else
                    state_n = ERROR;
            end
        end
        WAIT:begin
            cnt_rst = 1;
            done = 1;
            if(ready)begin
                state_n = IDLE;
                crc_rst = 1;
            end
        end
        ERROR:begin
            crc_rst = 1;
            cnt_rst = 1;
            state_n = IDLE;
        end
    endcase
end

assign  error = state == ERROR;
assign  fifo_rst_n = rst_n & !error;
assign  crc_rst_n   = rst_n & !crc_rst;

endmodule
