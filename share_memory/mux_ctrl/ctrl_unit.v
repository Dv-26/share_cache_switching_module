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

    input   wire                            voq_full_in,
    output  wire    [PORT_NUB_TOTAL-1 : 0]  en_out
);

localparam WIDTH_COUNT      = $clog2(`PORT_NUB_TOTAL);
localparam PORT_NUB_TOTAL   = `PORT_NUB_TOTAL;

localparam  STOP    = 1'b0;
localparam  RUN     = 1'b1;

reg     state,state_n;
wire    stop2run,run2stop;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= STOP;
    else
        state <= state_n;
end

always@(*)begin
    state_n = state;
    case(state)
        STOP:begin
            if(stop2run)
                state_n = RUN;
        end
        RUN:begin
            if(run2stop)
                state_n = STOP;
        end
    endcase
end

assign  stop2run = !voq_full_in && shift_reg == cnt;
assign  run2stop = voq_full_in;

reg [WIDTH_COUNT-1 : 0] cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt <= {WIDTH_COUNT{1'b0}};
    else 
        if(state == RUN)
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
                            (cnt == i)? !voq_full_in:
                                        1'b0;
    end
endgenerate

endmodule
