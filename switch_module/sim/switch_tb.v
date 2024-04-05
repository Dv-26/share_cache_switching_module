`timescale 1ns/1ns
`include "../defind.vh"
`define CLK_TIME 2


module switch_tb();

reg                                     clk,rst_n;

always #(`CLK_TIME/2) clk = !clk;

localparam  PORT_NUB = `PORT_NUB_TOTAL;
localparam  PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam  DATA_WIDTH  =   `DATA_WIDTH;
localparam  WIDTH_PORT  =   1 + 2 * $clog2(`PORT_NUB_TOTAL) + `DATA_WIDTH;
localparam  WIDTH_TOTAL =   PORT_NUB * WIDTH_PORT; 

reg                                     clk,rst_n;
wire    [WIDTH_TOTAL-1:0]               sort_port_in;
wire    [WIDTH_TOTAL-1:0]               sort_port_out;

reg                                     port_valid_in[PORT_NUB_TOTAL-1:0];
reg     [$clog2(PORT_NUB_TOTAL)-1 :0]   rx_port_in[PORT_NUB_TOTAL-1:0];
reg     [$clog2(PORT_NUB_TOTAL)-1 :0]   tx_port_in[PORT_NUB_TOTAL-1:0];
reg     [DATA_WIDTH-1:0]                data_in[PORT_NUB_TOTAL-1:0];

wire                                    port_valid_out[PORT_NUB_TOTAL-1:0];
wire    [$clog2(PORT_NUB_TOTAL)-1 :0]   rx_port_out[PORT_NUB_TOTAL-1:0];
wire    [$clog2(PORT_NUB_TOTAL)-1 :0]   tx_port_out[PORT_NUB_TOTAL-1:0];
wire    [DATA_WIDTH-1:0]                data_out[PORT_NUB_TOTAL-1:0];

generate 
    genvar i;
    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin :loop
        assign {port_valid_out[i],rx_port_out[i],tx_port_out[i],data_out[i]} = sort_port_out[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT];
        assign sort_port_in[(i+1)*WIDTH_PORT-1 : i*WIDTH_PORT] = {port_valid_in[i],rx_port_in[i],tx_port_in[i],data_in[i]};
    end
endgenerate

sort_module
#(
    .PORT_NUB(`PORT_NUB_TOTAL)
)
sort_module
(
    .clk(clk),
    .rst_n(rst_n),
    .port_in(sort_port_in), 
    .port_out(sort_port_out)
);

localparam  CONTROL_WIDTH_IN            = $clog2(PORT_NUB_TOTAL) + 1;
localparam  CONTROL_WIDTH_IN_TOTAL      = CONTROL_WIDTH_IN*PORT_NUB_TOTAL ;
localparam  CONTROL_WIDTH_OUT           = $clog2(PORT_NUB_TOTAL);
localparam  CONTROL_WIDTH_OUT_TOTAL     = CONTROL_WIDTH_OUT*PORT_NUB_TOTAL;

wire    [CONTROL_WIDTH_IN_TOTAL-1 : 0]      control_port_in;
wire    [CONTROL_WIDTH_OUT_TOTAL-1 : 0]     control_port_out; 

generate
    genvar j;
    for(j=0; j<`PORT_NUB_TOTAL; j=j+1)begin :loop2
        assign control_port_in[(j+1)*CONTROL_WIDTH_IN-1 : j*CONTROL_WIDTH_IN] = {port_valid_in[j],rx_port_in[j]}; 
        
    end
endgenerate

shift_control shift_control
(
    .clk(clk),
    .rst_n(rst_n),
    .port_in(control_port_in), 
    .port_out(control_port_out)
);

wire    [CONTROL_WIDTH_OUT-1 :0]    shift_nub[PORT_NUB_TOTAL-1 : 0];
wire    [WIDTH_TOTAL-1 : 0]         filter_out[`PORT_NUB_TOTAL-1 : 0];
wire    [`PORT_NUB_TOTAL-1 : 0]     filter_vaild[`PORT_NUB_TOTAL-1 : 0];

localparam N = $clog2(`PORT_NUB_TOTAL)*($clog2(`PORT_NUB_TOTAL)+1)/2 - 2*$clog2(`PORT_NUB_TOTAL) - 1;
;

generate
    // genvar n,i;
    wire    [WIDTH_TOTAL-1 : 0]         barrel_shift_in;
    wire    [CONTROL_WIDTH_OUT_TOTAL-1 : 0]   barrel_shift_sel_in;
    if(N > 0)begin
        shift_reg
        #(
            .DELAY(N),
            .WIDTH(CONTROL_WIDTH_OUT),
            .NUB(`PORT_NUB_TOTAL)
        )
        shift_reg
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(control_port_out), 
            .port_out(barrel_shift_sel_in)
        );
        assign barrel_shift_in = sort_port_out;
    end
    else if(N < 0)begin
        shift_reg
        #(
            .DELAY(-1*N),
            .WIDTH(WIDTH_PORT),
            .NUB(`PORT_NUB_TOTAL)
        )
        shift_reg
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(sort_port_out), 
            .port_out(barrel_shift_in)
        );
        assign barrel_shift_sel_in = control_port_out;
    end
    else begin
        assign barrel_shift_in = sort_port_out;
        assign barrel_shift_sel_in = control_port_out;
    end
    
    for(i=0; i<`PORT_NUB_TOTAL; i=i+1)begin: barrel
        wire    [WIDTH_TOTAL-1 : 0]         filter_in;
        wire    [CONTROL_WIDTH_OUT-1 : 0]   select_in;     
        assign select_in = barrel_shift_sel_in[(i+1)*CONTROL_WIDTH_OUT-1 : i*CONTROL_WIDTH_OUT];
        barrel_shift barrel_shift
        (
            .clk(clk),
            .rst_n(rst_n),
            .select(select_in),
            .port_in(barrel_shift_in), 
            .port_out(filter_in)
        );

        filter
        #(
            .dest(i)
        )
        filter
        (
            .clk(clk),
            .rst_n(rst_n),
            .port_in(filter_in), 
            .port_out(filter_out[i]),
            .port_vaild(filter_vaild[i])
        );

    end

endgenerate

task init;
    integer j;        
    begin
        for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
            port_valid_in[j] = 0;
            rx_port_in[j] = 0;
            tx_port_in[j] = 0;
        end
    end
endtask

task update;
    integer j;
    begin
        @(posedge clk)begin

            for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
                port_valid_in[j] = 1;
                // rx_port_in[j] = $random % PORT_NUB_TOTAL;
                rx_port_in[j] = PORT_NUB_TOTAL-1 - j;
                tx_port_in[j] = j;
                data_in[j] = 0;
            end
            #`CLK_TIME;
            for(j=0; j<PORT_NUB_TOTAL; j=j+1)begin
                port_valid_in[j] = 0;
            end
        end
    end
endtask


initial 
begin

    init();
    clk = 1;
    rst_n = 0;
    #(5*`CLK_TIME);
    rst_n = 1;
    #(5*`CLK_TIME);

    repeat(20)begin
        update();
        // tx_port_in[0] = 4;
        // tx_port_in[1] = 1;
        // tx_port_in[2] = 3;
        // tx_port_in[3] = 2;
    end

    #(20*`CLK_TIME);
    $stop();

end

endmodule

