`include "../generate_parameter.vh"

module send_module
#(
    parameter tx_port = 0
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    output  reg                             done,
    output  wire                            ready,

    input   wire                            start,
    input   wire                            single,
    input   wire    [19 : 0]                send_cycle,
    input   wire    [WIDTH_SEL-1 : 0]       dest,
    input   wire    [WIDTH_PRIORITY-1 : 0]  priority,
    input   wire    [WIDTH_LENGTH-1 : 0]    length,

    output  reg                             wr_sop,
    output  reg                             wr_eop,
    output  reg                             wr_vld,
    output  reg     [DATA_WIDTH-1 : 0]      wr_data
);

localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  WIDTH_SEL           =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY      =   $clog2(`PRIORITY);

localparam  IDLE = 3'b001;
localparam  CTRL = 3'b011;     
localparam  SEND = 3'b010;
localparam  DONE = 3'b100;
localparam  WAIT = 3'b101;

reg             time_cnt_add,time_cnt_zero;
reg [19 : 0]    time_cnt;
wire            time_cnt_end;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        time_cnt <= 0;
    end
    else begin
        if(time_cnt_zero)
            time_cnt <= 0;
        else if(time_cnt_add)
            time_cnt <= time_cnt + 1;
    end
end

assign time_cnt_end = time_cnt >= send_cycle;

reg [DATA_WIDTH-1:0]   cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= (tx_port << 28) + (dest << 24);
    end
    else begin
        if(cnt_rst)begin
            cnt <= (tx_port << 28) + (dest << 24);
        end
        else begin
            if(cnt_add)
                cnt <= cnt + 1;
        end
    end
end

reg [WIDTH_LENGTH-1 : 0]   data_length_reg;
wire        cnt_eq_length;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_length_reg <= 0;
    else begin
        if(data_length_reg_load)
            data_length_reg  <= length;
    end
end
assign cnt_eq_length = cnt[WIDTH_LENGTH-1 : 0] >= data_length_reg-1;

reg [2:0]   state,state_n;
reg         data_length_reg_load,cnt_add,cnt_rst,out_sel;

reg         wr_eop_n,wr_sop_n;
wire        wr_vld_n;
wire    [DATA_WIDTH-1 : 0]  wr_data_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= IDLE;
        wr_sop <= 0;
        wr_eop <= 0;
        wr_vld <= 0;
        wr_data <= 0;
    end
    else begin
        state <= state_n;
        wr_sop <= wr_sop_n;
        wr_eop <= wr_eop_n;
        wr_vld <= wr_vld_n;
        wr_data <= wr_data_n;
    end
end

always @(*)begin
    state_n = state;
    cnt_add = 1'b0;
    cnt_rst = 1'b0;
    wr_sop_n  = 1'b0;
    wr_eop_n  = 1'b0;
    data_length_reg_load  = 1'b0;
    time_cnt_add = 1'b0;
    time_cnt_zero = 1'b0;
    done = 0;
    case(state)
        IDLE:begin
            cnt_rst = 1'b1;
            if(start)begin
                state_n = CTRL;
                wr_sop_n = 1'b1;
                data_length_reg_load = 1'b1;
            end
        end
        CTRL:begin
            time_cnt_add = 1;
            state_n = SEND;
        end
        SEND:begin
            time_cnt_add = 1;
            cnt_add = 1;
            if(cnt_eq_length)
                state_n = DONE;
        end
        DONE:begin
            time_cnt_add = 1;
            wr_eop_n  = 1;
            cnt_rst = 1;
            state_n = WAIT;
        end
        WAIT:begin
            if(time_cnt_end)begin
                if(!(single && start))begin
                    done = 1;
                    state_n = IDLE;
                    time_cnt_zero = 1;
                end
            end
            else
                time_cnt_add = 1;
        end
        default:begin
            state_n = IDLE;
        end
    endcase
end

assign wr_data_n =      (state == CTRL)?    {dest,priority,length}:
                        (state == SEND)?    cnt:
                                        {DATA_WIDTH{1'b0}};

assign wr_vld_n = (state == CTRL) || (state == SEND);

assign ready = (state == IDLE && !start);



endmodule
