`include "../generate_parameter.vh"

module send_module
#(
    parameter tx_port = 0
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire                            start,
    output  wire                            done,
    output  wire                            ready,

    input   wire    [WIDTH_SEL-1 : 0]       dest,
    input   wire    [WIDTH_PRIORITY-1 : 0]  priority,
    input   wire    [WIDTH_LENGTH-1 : 0]    length,

    output  reg                             wr_sop,
    output  reg                             wr_eop,
    output  wire                            wr_vld,
    output  wire    [DATA_WIDTH-1 : 0]      wr_data
);

localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  WIDTH_SEL           =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY      =   $clog2(`PRIORITY);

localparam  IDLE = 3'b001;
localparam  CTRL = 3'b011;     
localparam  SEND = 3'b010;
localparam  DONE = 3'b100;


reg [DATA_WIDTH-1:0]   cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= tx_port << 28;
    end
    else begin
        if(cnt_rst)begin
            cnt <= tx_port << 28;
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
assign cnt_eq_length = cnt[WIDTH_LENGTH-1 : 0] == data_length_reg-1;

reg [2:0]   state,state_n;
reg         data_length_reg_load,cnt_add,cnt_rst,out_sel;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= state_n;
end

always @(*)begin
    state_n = state;
    cnt_add = 1'b0;
    cnt_rst = 1'b0;
    wr_sop  = 1'b0;
    wr_eop  = 1'b0;
    data_length_reg_load  = 1'b0;
    case(state)
        IDLE:begin
            if(start)begin
                state_n = CTRL;
                wr_sop = 1'b1;
                data_length_reg_load = 1'b1;
            end
        end
        CTRL:begin
            state_n = SEND;
        end
        SEND:begin
            cnt_add = 1;
            if(cnt_eq_length)
                state_n = DONE;
        end
        DONE:begin
            state_n = IDLE;
            wr_eop  = 1;
            cnt_rst = 1;
        end
    endcase
end

assign wr_data =    (state == CTRL)?    {dest,priority,length}:
                    (state == SEND)?    cnt:
                                        {DATA_WIDTH{1'b0}};
assign wr_vld = (state == CTRL) || (state == SEND);

assign done = wr_eop;
assign ready = state == IDLE;



endmodule
