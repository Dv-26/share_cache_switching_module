`timescale 1ns/1ns
`include "../../generate_parameter.vh"

module ctrl_unit 
#(
    parameter dest = 0
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    output  wire    [WIDTH_COUNT-1 : 0]     mux_sel_out,
    output  wire    [WIDTH_COUNT-1 : 0]     shift_out,
    input   wire    [WIDTH_COUNT-1 : 0]     shift_in,

    input   wire                            voq1_full_in,
    output  wire                            voq1_wr_en,
    input   wire    [PORT_NUB_TOTAL-1 : 0]  voq0_empty_in,
    output  wire    [PORT_NUB_TOTAL-1 : 0]  en_out
);

localparam WIDTH_COUNT      = $clog2(`PORT_NUB_TOTAL);
localparam PORT_NUB_TOTAL   = `PORT_NUB_TOTAL;

localparam  STOP    = 1'b0;
localparam  RUN     = 1'b1;

reg     state,state_n;
wire    stop2run,run2stop;
reg     wr_en;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= STOP;
        wr_en <= 0;
    end
    else begin
        state <= state_n;
        wr_en <= wr_en_n;
    end
end

assign voq1_wr_en = wr_en;

wire    empty;
assign empty = voq0_empty_in[cnt];

reg wr_en_n,cnt_load;

always@(*)begin
    wr_en_n = 0;
    cnt_load = 0;
    state_n = state;
    case(state)
        STOP:begin
            if(stop2run)begin
                state_n = RUN;
            end
        end
        RUN:begin
            cnt_load = 1;
            if(!empty)
                wr_en_n = 1;
            if(run2stop)begin
                state_n = STOP;
                wr_en_n = 0;
            end
        end
    endcase
end

assign  stop2run = !voq1_full_in && shift_reg == cnt;
assign  run2stop = voq1_full_in;

reg                     cnt_load;
reg [WIDTH_COUNT-1 : 0] cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= {WIDTH_COUNT{1'b0}};
    else 
        if(cnt_load)
            cnt <= shift_reg;
end

assign mux_sel_out = cnt;

reg [WIDTH_COUNT-1 : 0] shift_reg;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
       shift_reg <= dest;
    else
       shift_reg <= shift_in;
end

assign shift_out = shift_reg;


generate
    genvar i;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop
        assign en_out[i] =  (state != RUN)? 1'b0:
                            (cnt == i)?     !voq1_full_in:
                                            1'b0;
    end
endgenerate

endmodule
