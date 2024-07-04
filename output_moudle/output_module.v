`include "../generate_parameter.vh"

module output_module
#(
    parameter  NUB = 0
)
(
    input   wire                                internal_clk, 
    input   wire                                external_clk,
    input   wire                                rst_n, 

    input   wire    [PORT_NUB_TOTAL-1 : 0]      empty_in,
    input   wire    [DATA_WIDTH-1 : 0]          port_in,
    output  reg     [WIDTH_SEL-1 : 0]           rd_sel,
    output  reg                                 rd_en,
    output  reg                                 rd_done,

    input   wire                                ready_in,
    output  wire                                rd_sop,
    output  wire                                rd_eop,
    output  wire                                rd_vld,
    output  wire    [DATA_WIDTH-1 : 0]          rd_data
);

localparam  PORT_NUB_TOTAL      =   `PORT_NUB_TOTAL;
localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  WIDTH_SEL           =   $clog2(PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY      =   $clog2(`PRIORITY);
localparam  WIDTH_CRC           =   `CRC32_LENGTH;

//--------------------------------internal_clk_domain--------------------------

reg     [WIDTH_SEL-1 : 0]   times_cnt; 
reg                         times_cnt_add;
wire                        times_cnt_end;

always @(posedge internal_clk or negedge rst_n)begin
    if(!rst_n)begin
        times_cnt <= 0;
    end
    else begin
        if(times_cnt_add)
            times_cnt <= times_cnt + 1;
    end
end

assign times_cnt_end = times_cnt == PORT_NUB_TOTAL-1;

reg     [DATA_WIDTH-1 : 0]                      ctrl_data[PORT_NUB_TOTAL-1 : 0];
wire    [WIDTH_LENGTH-1 : 0]                    package_length[PORT_NUB_TOTAL-1 : 0];
wire    [WIDTH_CRC-1 : 0]                       crc[PORT_NUB_TOTAL-1 : 0];
wire    [WIDTH_PRIORITY-1 : 0]                  priority[PORT_NUB_TOTAL-1 : 0];
wire    [PORT_NUB_TOTAL*WIDTH_PRIORITY-1 : 0]   priority_total;

reg     [PORT_NUB_TOTAL-1 : 0]                  ctrl_flag;
reg     [PORT_NUB_TOTAL-1 : 0]                  ctrl_data_load;
wire    [PORT_NUB_TOTAL-1 : 0]                  ctrl_data_empty;
reg     [PORT_NUB_TOTAL-1 : 0]                  ctrl_data_rst;


generate
    genvar i;
    for(i=0; i<PORT_NUB_TOTAL; i=i+1)begin: ctrl_reg

        always @(posedge internal_clk or negedge rst_n)begin
            if(!rst_n)begin
               ctrl_data[i] <= 0; 
               ctrl_flag[i] <= 0;
           end
           else begin
               if(ctrl_data_load[i])begin
                   ctrl_data[i] <= port_in;
                   ctrl_flag[i] <= 1'b1;
               end
               else if(ctrl_data_rst[i])
                   ctrl_flag[i] <= 1'b0;
            end
        end

        assign  {package_length[i], crc[i], priority[i]} = ctrl_data[i];
        assign  ctrl_data_empty[i]  = ~empty_in[i] && ~ctrl_flag[i];

        assign  priority_total[(i+1)*WIDTH_PRIORITY-1 : i*WIDTH_PRIORITY] = priority[i];
    end
endgenerate

wire                        compare_tree_valid;
wire    [WIDTH_SEL-1 : 0]   compare_port_out;
reg     [WIDTH_SEL-1 : 0]   compare_reg;
reg                         compare_reg_load;

compare_tree 
#(
    .PORT_NUB(PORT_NUB_TOTAL),
    .WIDTH_WIEGHT(`PRIORITY)
)
compare_tree 
(
    .clk        (internal_clk),
    .rst_n      (rst_n),
    .valid_in   (ctrl_flag),
    .wieght_in  (priority_total),
    .port_out   (compare_port_out),
    .valid_out  (compare_tree_valid)
);

always @(posedge internal_clk or negedge rst_n)begin
    if(!rst_n)
        compare_reg <= 0;
    else begin
        if(compare_reg_load)
            compare_reg <= compare_port_out;
    end
end

reg                         length_add,length_zero;
reg     [WIDTH_CRC-1 : 0]   length_cnt;
wire                        length_eq;

always @(posedge internal_clk or negedge rst_n)begin
    if(!rst_n)
        length_cnt <= 0;
    else begin
        if(length_zero)
            length_cnt <= 0;
        else if(length_add)
            length_cnt <= length_cnt + 1;
    end
end

assign length_eq = length_cnt == package_length[compare_reg];

wire    [WIDTH_CRC-1:0]     crc_out;
wire                        verify; 
wire                        crc_rst_n;
reg                         crc_rst;

crc16_32bit crc_module 
(
    .clk(internal_clk),
    .rst_n(crc_rst_n),
    .data_in(port_in),
    .crc_out(crc_out),
    .crc_en(fifo_wr_en)
);

assign crc_rst_n = rst_n && ~crc_rst;
assign verify = crc_out == crc[compare_reg];

//-------------------------------- FSM -------------------------

localparam  SCAN        = 3'b000;
localparam  GET_CTRL    = 3'b001;        
localparam  RULING      = 3'b010;
localparam  RD          = 3'b011;
localparam  RD_DONE     = 3'b111;
localparam  WAIT        = 3'b110;

reg [2:0]   state,state_n;
reg         fifo_wr_en_n;

always @(posedge internal_clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= SCAN;
        fifo_wr_en <= 0;
        fifo_rst_f <= 0;
    end
    else begin
        state <= state_n;
        fifo_wr_en <= fifo_wr_en_n;
        fifo_rst_f <= fifo_rst;
    end
end

always @(*)begin
    state_n = state;
    rd_sel = 0;
    rd_en = 0;
    times_cnt_add = 0;
    ctrl_data_load = 0;
    ctrl_data_rst = 0;
    compare_reg_load = 0;
    length_add = 0;
    fifo_wr_en_n = 0;
    fifo_rst = 0;
    length_zero = 0;
    tx_valid = 0;
    rd_done = 0;
    crc_rst = 0;
    case(state)
        SCAN:begin
            if(ctrl_data_empty[times_cnt])begin
                state_n = GET_CTRL;
                rd_sel = times_cnt;
                rd_en = 1;
            end
            else begin
                times_cnt_add = 1;
                if(times_cnt_end)
                    state_n = RULING;
            end
        end
        GET_CTRL:begin
            ctrl_data_load[times_cnt] = 1;
            state_n = SCAN;
        end
        RULING:begin
            if(compare_tree_valid)begin
                compare_reg_load = 1;
                state_n = RD;
            end
            else begin
                state_n = SCAN;
            end
        end
        RD:begin
            length_add = 1;
            rd_sel = compare_reg;
            rd_en = 1;
            fifo_wr_en_n = 1;
            if(length_eq)begin
                state_n = RD_DONE;
                fifo_wr_en_n = 0;
            end
        end
        RD_DONE:begin
            rd_sel = compare_reg;
            rd_done = 1;
            length_zero = 1;
            crc_rst = 1;
            if(verify)begin
                state_n = WAIT;
            end
            else begin
                fifo_rst = 1;
                state_n = SCAN;
                ctrl_data_rst[compare_reg] = 1;
            end
        end
        WAIT:begin
            tx_valid = 1;
            if(tx_ready)begin
                state_n = SCAN;
                ctrl_data_rst[compare_reg] = 1;
            end
        end
    endcase
end

//--------------------------------------------------------------

reg     fifo_wr_en,fifo_rst,fifo_rst_f;
wire    fifo_rst_n;
wire    [DATA_WIDTH-1 : 0]  fifo_rd_data;
wire    fifo_rd_en;

dc_fifo 
#(
    .DATA_BIT(DATA_WIDTH),
    .DATA_DEPTH(256)
)
dc_fifo
(
    .rst_n(fifo_rst_n),
    .wr_clk(internal_clk),
    .wr_data(port_in),
    .wr_en(fifo_wr_en),
    .rd_clk(external_clk),
    .rd_data(fifo_rd_data),
    .rd_en(fifo_rd_en)
);

assign fifo_rst_n = rst_n && ~fifo_rst_f;

reg     tx_valid;
wire    tx_ready,rx_valid,rx_ready;

wire    [WIDTH_PRIORITY+WIDTH_LENGTH-1 : 0] handshake_out,handshake_in; 
reg     [WIDTH_PRIORITY+WIDTH_LENGTH-1 : 0] handshake_out_reg;
wire    [WIDTH_PRIORITY-1 : 0]  priority_out;
wire    [WIDTH_LENGTH-1 : 0]    package_length_out;

cdc_handshake 
#(
    .DATA_WIDTH(WIDTH_PRIORITY+WIDTH_LENGTH)
)
cdc_handshake
(
    .rst_n(rst_n),
    .tx_clk(internal_clk),
    .rx_clk(external_clk),
    .tx_valid(tx_valid),
    .data_in(handshake_in),
    .tx_ready(tx_ready),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),
    .data_out(handshake_out)
);

assign handshake_in = {priority[compare_reg], package_length[compare_reg]};
assign {priority_out, package_length_out} = handshake_out;

//--------------------------------external_clk_domain--------------------------

wire out_sel;
assign rd_data = (out_sel)? {NUB, priority_reg, package_length_reg}:fifo_rd_data;

reg     [WIDTH_PRIORITY-1 : 0]  priority_reg;
reg     [WIDTH_LENGTH-1 : 0]    package_length_reg;

wire    reg_load; 

always @(posedge external_clk or negedge rst_n)begin
    if(!rst_n)begin
        priority_reg <= 0;
        package_length_reg <= 0;
    end
    else begin
        if(reg_load)begin
            priority_reg <= priority_out;
            package_length_reg <= package_length_out; 
        end
    end
end

out_rd_controller out_rd_controller
(
    .clk(external_clk),
    .rst_n(rst_n),
    .ready_in(ready_in),
    .rx_valid(rx_valid),
    .rx_ready(rx_ready),
    .load(reg_load),
    .fifo_rd_en(fifo_rd_en),
    .length_in(package_length_reg),
    .rd_sop(rd_sop),
    .rd_eop(rd_eop),
    .rd_vld(rd_vld),
    .out_sel(out_sel)
);

endmodule