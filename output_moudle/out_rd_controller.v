`include "../generate_parameter.vh"

module out_rd_controller
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire                            ready_in,
    input   wire                            rx_valid,
    output  reg                             rx_ready,
    output  reg                             load,
    output  reg                             fifo_rd_en,
    input   wire    [WIDTH_LENGTH-1 : 0]    length_in,

    output  reg                             rd_sop,
    output  reg                             rd_eop,
    output  reg                             rd_vld,
    output  reg                             out_sel
);

localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);

reg                         length_add,length_zero;
reg [WIDTH_LENGTH-1 : 0]    length_cnt;
wire                        length_eq;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        length_cnt <= 0;
    else begin
        if(length_zero)
            length_cnt <= 0;
        else if(length_add)
            length_cnt <= length_cnt + 1;
    end
end

assign length_eq = length_cnt == length_in;    

localparam  IDLE    =   3'b000; 
localparam  WAIT    =   3'b001; 
localparam  CTRL    =   3'b011;
localparam  RD      =   3'b010;
localparam  DONE    =   3'b110;

reg [2:0]   state,state_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= state_n;
end

always @(*)begin
    state_n = state;
    rx_ready = 0;
    load = 0;
    out_sel = 0;
    fifo_rd_en = 0;
    length_add = 0;
    length_zero = 0;
    rd_sop = 0;
    rd_vld = 0;
    rd_eop = 0;
    case(state)
        IDLE:begin
            if(ready_in)
                state_n = WAIT;
        end
        WAIT:begin
            if(ready_in)begin
                if(rx_valid)begin
                    rx_ready = 1;
                    load = 1;
                    rd_sop = 1;
                    state_n = CTRL;
                end
            end
            else
                state_n = IDLE;
        end
        CTRL:begin
            rd_vld = 1;
            out_sel = 1;
            state_n = RD;
            length_add = 1;
        end
        RD:begin
            rd_vld = 1;
            fifo_rd_en = 1;
            length_add = 1;
            if(length_eq)begin
                state_n = DONE;
            end
        end
        DONE:begin
            rd_eop = 1;
            length_zero = 1;
            if(ready_in)
                state_n = WAIT;
            else
                state_n = IDLE;
        end
    endcase
end

endmodule
