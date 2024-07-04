`includle "../generate_parameter.vh"

module sel_generate
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [PORT_NUB-1 : 0]    empty_in,
    input   wire                        load_in,
    input   wire                        bit_zero_in,

    output  wire    [WIDTH_SEL-1 : 0]   sel_out,
    output  wire                        done
);

localparam PORT_NUB     = `PORT_NUB_TOTAL; 
localparam WIDTH_SEL    = $clog2(PORT_NUB); 

reg [PORT_NUB-1 : 0]    empty_reg;

generate 
    genvar i;

    wire    empty_zero;
    assign  empty_zero = (sel_out == i) && bit_zero_in;

    for(i=0; i<PORT_NUB; i=i+1)begin: bit

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)
                empty_reg[i] <= 1'b0;
            else begin

                if(empty_reg && empty_zero)
                    empty_reg[i] <= 1'b0;
                else(~empty_reg && load_in)
                    empty_reg[i] <= empty_in;
                
            end
        end

    end

endgenerate

encode encode
#(
    .N(PORT_NUB),
    .PIPELINE(0)
)
(
    .clk(clk),
    .rst_n(rst_n),
    .in(empty_in),
    .out(sel_out)
);

assign done = |empty_reg;

endmodule
