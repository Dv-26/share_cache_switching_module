`timescale 1ns/1ns
`include "../generate_parameter.vh"

module ctrl_unit 
#(
    parameter dest = 0
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    output  wire    [WIDTH_COUNT-1 : 0]     shift_out,
    input   wire    [WIDTH_COUNT-1 : 0]     shift_in,
    input   wire                            voq_full_in,
    output  wire    [PORT_NUB_TOTAL-1 : 0]  en_out
);

localparam WIDTH_COUNT      = $clog2(`PORT_NUB_TOTAL);
localparam PORT_NUB_TOTAL   = `PORT_NUB_TOTAL;

localparam  STOP = 1'b0;
localparam  RUN = 1'b1;

reg state,state_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= RUN;
    else
        state <= state_n;
end

always @(*)begin
    state_n = state;
    case(state)
        RUN:begin
            if(!voq_full_in)
                state_n <= STOP;
        end
        STOP:begin
            if(voq_full_in && shift_in == count-1)
                state_n <= RUN;
        end
    endcase
end

reg [WIDTH_COUNT-1 : 0] count;
wire                    count_add;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        count <= dest;
    else
        if(count_add)
            count <= shift_in + 1;
end

assign  count_add   =   state == RUN;
assign  shift_out   =   (count_add)? count:shift_in; 

generate
    genvar i;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: loop
        assign en_out[i] = (i == count)? voq_full_in:1'b0;
    end
endgenerate

endmodule
