`include "../../generate_parameter.vh"

module package_cnt
(
    input   wire                        clk,
    input   wire                        rst_n,
    input   wire    [PORT_NUB-1 : 0]    cnt_add,
    input   wire    [WIDTH_SEL-1 : 0]   minus_sel,
    input   wire                        cnt_minus,

    output  wire    [PORT_NUB-1 : 0]    cnt_eq_zero
);

localparam  PORT_NUB = `PORT_NUB_TOTAL;
localparam  WIDTH_SEL = $clog2(`PORT_NUB_TOTAL);

generate
    genvar i;
    for(i=0; i<PORT_NUB; i=i+1)begin: counter

        wire        minus;
        reg [8:0]   cnt;

        always @(posedge clk or negedge rst_n)begin 
            if(!rst_n)
                cnt <= 0;
            else begin
                if(cnt_add[i] && ~minus)
                    cnt <= cnt + 1;
                else if(~cnt_add[i] && minus)
                    cnt <= cnt - 1;
            end
        end

        assign minus    = (minus_sel == i) && cnt_minus;
        assign cnt_eq_zero[i] = cnt == 0;
    end
endgenerate

endmodule
