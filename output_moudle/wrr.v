`include "../generate_parameter.vh"

module wrr
#(
    parameter   NUB = 0
)
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire                        en,
    input   wire    [PORT_NUB-1 : 0]    req_in,
    input   wire    [WIDTH_IN-1 : 0]    wieght_in,
    output  wire    [WIDTH_OUT-1 : 0]   port_out,
    output  wire                        valid_out
);

localparam  WIDTH_WIEGHT    =   $clog2(`PRIORITY);
localparam  PORT_NUB        =   `PORT_NUB_TOTAL;
localparam  WIDTH_OUT       =   $clog2(PORT_NUB); 
localparam  WIDTH_PORT_IN   =   PORT_NUB * WIDTH_OUT;
localparam  WIDTH_IN        =   PORT_NUB * $clog2(`PRIORITY);

reg     [WIDTH_WIEGHT-1 : 0]             wieght_reg[PORT_NUB-1 : 0];

wire    [PORT_NUB-1 : 0]        wieght_minus;
wire    [PORT_NUB-1 : 0]        wieght_eq_zero;
wire                            wieght_rst;

generate 
    genvar i;

    for(i=0; i<PORT_NUB; i=i+1)begin: loop

        wire    [WIDTH_WIEGHT-1 : 0]    wieght;

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                wieght_reg[i] <= wieght;
            else begin
                if(wieght_rst)
                    wieght_reg[i] <= wieght;
                else if(en && wieght_minus[i])
                    wieght_reg[i] <= wieght_reg[i] - 1;
            end
        end


        if(i == NUB)
            assign wieght = 0; //不接收自身发起数据
        else 
            assign wieght = wieght_in[(i+1)*WIDTH_WIEGHT-1 : i*WIDTH_WIEGHT];
        

        assign wieght_eq_zero[i] = wieght_reg[i] == 0;

    end

endgenerate

wire                        higth_is_one;
wire    [PORT_NUB-1 : 0]    mask;
wire    [PORT_NUB-1 : 0]    valid;

assign  valid           =   req_in & ~wieght_eq_zero;
assign  mask            =   {mask[PORT_NUB-2 : 0] | valid[PORT_NUB-2 : 0], 1'b0};
assign  wieght_minus    =   ~mask & valid; 
assign  wieght_rst      =   &(req_in ~^ (req_in & wieght_eq_zero));

encode
#(
    .N(PORT_NUB),
    .PIPELINE(0)
)
encode
(
    .clk(clk),
    .rst_n(rst_n),
    .in(wieght_minus),
    .out(port_out)
);
assign valid_out = |req_in & ~wieght_rst;

endmodule

