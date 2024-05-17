`include "../generate_parameter.vh"

module in_rd_controller_fsm
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire                        start,
    input   wire    [WIDTH_SEL-1 : 0]   rx_in,
    input   wire    [WIDTH_LENGTH-1:0]  data_length,
    input   wire                        ready_in,                

    output  wire    [WIDTH_SEL-1 : 0]   rx_out,
    output  wire                        fifo_rd_en,
    output  reg                         out_valid,
    output  reg                         ready,
    output  reg                         out_sel
);

localparam  DATA_WIDTH      =   `DATA_WIDTH;
localparam  WIDTH_SEL       =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH    =   $clog2(`DATA_LENGTH_MAX);

localparam  IDLE    = 3'b000;
localparam  WAIT    = 3'b001;
localparam  LOAD    = 3'b011;
localparam  RD      = 3'b010;
localparam  DONE    = 3'b111;

reg [WIDTH_LENGTH-1 : 0]    data_length_reg;
wire                        cnt_eq_length;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_length_reg <= 0;
    else begin
        if(data_length_reg_load)
            data_length_reg  <= data_length;
    end
end

reg [WIDTH_LENGTH-1:0]   cnt;

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

assign cnt_eq_length = cnt == data_length_reg;

reg [WIDTH_SEL-1:0]   rx_reg;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rx_reg <= 0;
    else begin
        if(rx_load)
            rx_reg <= rx_in;
    end
end

assign rx_out = rx_reg;

reg         data_length_reg_load,cnt_add,cnt_rst,rx_load,out_sel;
reg [2:0]   state,state_n;

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
    rx_load = 1'b0;
    out_sel = 1'b0;
    ready   = 1'b0;
    out_valid = 1'b0;
    data_length_reg_load = 1'b0;
    case(state)
        IDLE:begin
            if(start)begin
                state_n = LOAD;
                rx_load = 1'b1;
                ready = 1'b1;
                data_length_reg_load = 1'b1;
            end
        end
        // WAIT:begin
        //     if(ready_in)
        //         state_n = LOAD;
        // end
        LOAD:begin
            out_valid = 1'b1;
            out_sel = 1'b1;
            state_n = RD;
        end
        RD:begin
            out_valid = 1'b1;
            cnt_add = 1'b1;
            if(cnt_eq_length)begin
                state_n = DONE;
                out_valid = 1'b0;
            end
        end
        DONE:begin
            cnt_rst = 1'b1;
            state_n = IDLE;
        end
    endcase
end

assign fifo_rd_en = state == RD;

endmodule
