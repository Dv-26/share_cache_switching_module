`include "../generate_parameter.vh"

module ready_generate
(
    input   wire                                clk,
    input   wire                                rst_n,

    input   wire    [WIDTH_SEL-1 : 0 ]          cnt_in,
    input   wire    [PORT_NUB-1 : 0]            vld_in, 
    input   wire    [WIDTH_SEL_TOTAL-1 : 0]     rx_in,

    output  wire    [PORT_NUB-1 : 0]            ready_out
);

localparam  PORT_NUB        =   `PORT_NUB_TOTAL;
localparam  WIDTH_SEL       =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_SEL_TOTAL = `PORT_NUB_TOTAL * WIDTH_SEL;


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

        wire                        vld;
        reg                         vld_f;    
        wire                        vld_down;
        wire    [WIDTH_SEL-1 : 0]   rx;

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                vld_f <= 1'b0;
            else
                vld_f <= vld;
        end
        assign vld      = vld_in[i];
        assign vld_down = !vld & vld_f; 
        assign rx       = rx_in[(i+1)*WIDTH_SEL-1 : i*WIDTH_SEL];

        for(j=0; j<PORT_NUB; j=j+1)begin: loop1
            assign vld_down_out[i][j] = (j == rx)? vld_down:1'b0;
        end

        assign ready_out[i] = cnt_reg[rx] == cnt_in;

    end

    for(i=0; i<PORT_NUB; i=i+1)begin: loop2

        wire [PORT_NUB-1 : 0]   down_rx;
        for(j=0; j<PORT_NUB; j=j+1)begin: loop3 
            assign down_rx[j] = vld_down_out[j][i];
        end

        wire cnt_load;

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                cnt_reg[i] <= i + 2;
            else begin
                if(cnt_load)
                    cnt_reg[i] <= cnt_f;
            end
        end

        assign cnt_load = |down_rx;

    end


endgenerate

endmodule
