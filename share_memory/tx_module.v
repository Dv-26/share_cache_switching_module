`timescale 1ns/1ns
`include "./generate_parameter.vh"

//激励信号生成模块，并不是电路模块
module tx_module
#(
    parameter dest = 0
)
(
    input       wire                            clk,
    input       wire                            rst_n,
    input       wire                            start,

    output      reg     [WIDTH_SEL-1 : 0]       rx_port,
    output      reg     [WIDTH_SEL-1 : 0]       tx_port,
    output      reg     [DATA_WIDTH-1 : 0]      data_port,
    output      wire                            vaild,
    output      wire                            done
);

localparam PORT_NUB         =   `PORT_NUB_TOTAL;
localparam WIDTH_SEL        =   $clog2(`PORT_NUB_TOTAL);
localparam DATA_WIDTH       =   `DATA_WIDTH;
localparam IDLE = 3'd0;
localparam RUN  = 3'd1;
localparam DONE = 3'd2;
reg [2:0]   state,state_n;

reg [3:0]   cnt,cnt_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 0;
        state <= IDLE;
    end
    else begin
        cnt <= cnt_n;
        state <= state_n;
    end
end

always @(*)begin
    cnt_n = cnt;
    if(cnt_minus)
        cnt_n = cnt - 1;
    if(cnt_load)
        cnt_n = $random()%10;
end

assign cnt_eq = cnt == 0;

wire    cnt_eq;
reg     cnt_load,cnt_minus;


always @(*)begin
    state_n = state;
    cnt_load = 0;
    cnt_minus = 0;
    case(state)
        IDLE:begin
            if(start)begin
                state_n = RUN;
                cnt_load = 1;
            end
        end
        RUN:begin
            cnt_minus = 1;
            if(cnt_eq)
                state_n = DONE;
        end
        DONE:begin
            state_n = IDLE;
        end
    endcase
end

reg [WIDTH_SEL-1 : 0]rx;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rx_port <= 0;
        tx_port <= 0;
        data_port <= 0;
    end
    else begin
        if(cnt_minus)
            data_port <= data_port + 1;
        if(cnt_load)begin
            rx = $random % PORT_NUB;
            rx_port <= rx;
            tx_port <= dest;
            data_port <= dest*16;
        end
        if(cnt_eq)begin
            rx_port <= 0;
            tx_port <= 0;
            data_port <= 0;
        end
    end
end

assign done = state == DONE;
assign vaild = state == RUN;

endmodule
