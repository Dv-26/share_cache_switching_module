`include "../generate_parameter.vh"

module ready_generate
(
    input   wire                                clk,
    input   wire                                rst_n,

    input   wire    [WIDTH_SEL-1 : 0 ]          cnt_in,
    input   wire    [PORT_NUB-1 : 0]            vld_in, 

    output  wire    [PORT_NUB-1 : 0]            ready_out
);

localparam  PORT_NUB        =   `PORT_NUB_TOTAL;
localparam  WIDTH_SEL       =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_SEL_TOTAL =   `PORT_NUB_TOTAL * WIDTH_SEL;


reg     [WIDTH_SEL-1 : 0]   cnt_reg[PORT_NUB-1 : 0];
reg     [WIDTH_SEL-1 : 0]   cnt_f;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt_f <= 0;
    else
        cnt_f <= cnt_in;
end

generate 
    genvar i,j; 

    wire    [PORT_NUB-1 : 0]    vld_down_out[PORT_NUB-1 : 0];

    for(i=0; i<PORT_NUB; i=i+1)begin: loop0

        reg                         vld_f;    
        wire                        vld_down;
        wire    [WIDTH_SEL-1 : 0]   rx;

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                vld_f <= 1'b0;
            else
                vld_f <= vld_in[i];
        end

        assign vld_down = !vld_in[i] & vld_f; 

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                cnt_reg[i] <= PORT_NUB-1;
            else
                if(vld_down)
                    cnt_reg[i] <= cnt_f;
        end

        assign ready_out[i] = cnt_in == cnt_reg[i];

    end


endgenerate

endmodule
