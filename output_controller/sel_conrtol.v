`timescale 1ns / 1ps

`include "../generate_parameter.vh"

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2024 16:50:30
// Design Name: 
// Module Name: sel_conrtol
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sel_control
(
    input clk,
    input rst_n,
    input [DATA_WIDTH - 1:0] data_in,
    input ready,
    input [PORT_NUB_TOTAL - 1:0] empty,
    output reg [DATA_WIDTH - 1:0] rd_data,
    output wire rd_sop,
    output reg rd_eop,
    output reg rd_vld,
    output reg [PORT_WIDTH - 1:0] rd_sel,
    output reg rd_en,
    output reg error
);

localparam DATA_WIDTH = `DATA_WIDTH;
localparam PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam PORT_WIDTH = $clog2(`PORT_NUB_TOTAL);
localparam  PRI_WIDTH_SIG = $clog2(`PRI_NUM_TOTAL); // 每个请求的优先级位宽
localparam  PRI_WIDTH = PORT_NUB_TOTAL * PRI_WIDTH_SIG; // 所有请求的总优先级位宽
localparam PRI_NUM_BIT = $clog2(`PRI_NUM_TOTAL);
localparam CRC32_LENGTH = `CRC32_LENGTH;
localparam DATABUF_HIGH_NUM = `DATABUF_HIGH_NUM;

// 定义状态
localparam STATE_WAIT = 0;
localparam STATE_SEND = 1;
localparam STATE_WAIT_2 = 2;

// 当前状态
reg [1:0]current_state;

//reg声明
reg [PRI_WIDTH - 1:0] out_priority_bits;
reg [CRC32_LENGTH - 1:0] out_crc [PORT_NUB_TOTAL - 1:0];
reg [DATABUF_HIGH_NUM - 1:0] out_frame_num [PORT_NUB_TOTAL - 1:0];
reg [PORT_NUB_TOTAL - 1:0] out_empty;//对应位是否为空
reg [PORT_WIDTH - 1:0] cycle_counters;
reg rd_sop_reg;
reg rd_sop_reg_f;
//CRC32相关的寄存器
reg crc_en;
wire [CRC32_LENGTH - 1:0]crc_out;
reg crc_rst;
//优先级控制相关的寄存器
reg select_scheme;
reg arb_en;
wire [PORT_WIDTH - 1:0]grant;
wire grant_vld;
reg is_first;
reg [PORT_WIDTH - 1:0]grant_result;
reg grant_result_vld;
reg [PRI_NUM_BIT - 1:0]test;
reg wait_data_first;
reg data_is_break;
reg data_is_break_recovery;
crc16_32bit crc32 (
        .data_in(rd_data), 
        .crc_en(crc_en), 
        .crc_out(crc_out), 
        .rst(crc_rst), 
        .clk(clk)
        );

priority_control_module priority_control(
    .clk(clk), // 时钟信号
    .rst_n(~rst_n), // 复位信号
    .request_signals(~out_empty), // 请求信号数组
    .priorities(out_priority_bits), // 请求信号的优先级数组
    .select_scheme(select_scheme), // 优先级选择方案（0：固定优先级；1：加权轮询）
    .grant(grant), // 输出的授权信号
    .grant_vld(grant_vld), // 输出授权信号的有效标志
    .arb_en(arb_en)
);


integer j;
always @(posedge clk or posedge rst_n) begin
    //test <= data_in[PRI_NUM_BIT - 1:0];
    if (!rst_n) begin // 异步复位
        // 初始化变量
        rd_sop_reg <= 0;
        rd_eop <= 0;
        rd_vld <= 0;
        rd_sel <= 0;
        rd_en  <= 0;
        rd_data <= 0;
        is_first <= 0;
        arb_en <= 0;
        grant_result <= 0;
        grant_result_vld <= 0;
        data_is_break <= 0;
        current_state <= STATE_WAIT; // 初始化状态为等待数据
        cycle_counters <= 0;
        select_scheme <= 1;
        error <= 0;
        out_priority_bits <= 0;
        wait_data_first <= 0;
        data_is_break_recovery <= 0;
        for (j = 0; j < PORT_NUB_TOTAL; j = j + 1) begin
            out_frame_num[j] <= 0;
            out_empty[j] <= 1;
            out_crc[j] <= 0;
        end
        
    end else begin
        if (cycle_counters > PORT_NUB_TOTAL - 1) begin //STATE_WAIT遍历完一个周期用，
            cycle_counters <= 0;
        end
        
        if (arb_en == 1 && grant_vld == 1) begin//用于从仲裁模块读取最新的仲裁信息，并决定STATE_SEND将转发那个端口的数据
            arb_en <= 0;
            grant_result <= grant;
            grant_result_vld <= 1;
        end
        
        if (current_state == STATE_WAIT) begin //这个部分用于控制其他信号
            rd_eop <= 0;
            rd_sop_reg <= 0;
            rd_en <= 0;
            rd_sel <= 0;
            crc_en <= 0;
            crc_rst <= 1;
            arb_en <= 0;
        end else begin
            if(ready && grant_result_vld && out_frame_num[grant_result] > 2)begin  
                rd_eop <= 0;
                rd_sop_reg <= 0;
                rd_en <= 1;  
                rd_sel <= grant_result;
                crc_rst <= 0;
            end else begin
                rd_eop <= 0;
                rd_sop_reg <= 0;
                rd_en <= 0;
                rd_sel <= 0;
                rd_vld <= 0;
                crc_en <= 0;
                crc_rst <= 0;
            end
        end
        //状态机逻辑处理，STATE_WAIT等待数据状态1，用于遍历各个端口。STATE_WAIT_2用于接收端口数据，因为rd_en拉高需要等待一个周期才有数据，所以添加此状态。STATE_SEND发送数据的逻辑
        case (current_state)
            STATE_WAIT: begin
                if (empty[cycle_counters] != out_empty[cycle_counters] && (error == 0) && (current_state == STATE_WAIT || current_state == STATE_WAIT_2) && rd_eop == 0) begin //意味着有新的数据
                    rd_en <= 1; //拉高数据
                    rd_sel <= cycle_counters;
                    out_empty[cycle_counters] <= 0;
                    current_state <= STATE_WAIT_2;
                    wait_data_first <= 1;
                end else begin
                    if ((empty == out_empty) && ready == 1 && ~empty) begin //empty!=0意味着有数据输入，empty==out_empty意味着对应数据已经输入完成
                        // 更新状态
                        is_first <= 1;
                        arb_en <= 1;
                        current_state <= STATE_SEND;
                    end
                    cycle_counters <= cycle_counters + 1;
                end
            end
            STATE_SEND: begin
                // 发送数据的逻辑
                if(is_first == 1 && ready == 1 && grant_result_vld)begin
                    is_first <= 0;
                    rd_sop_reg <= 1;
                    rd_en <= 1;
                end
                if(grant_result_vld == 1 && ready == 1 && is_first == 0 && rd_sop_reg == 0 && out_frame_num[grant_result] >= 1 && empty[grant_result] == 0) begin
                    if(data_is_break == 0 && data_is_break_recovery == 0) begin//数据中断与恢复判断，因为交换结构的问题，如有16个端口就得等16个周期才会有一个对应输入端口的数据包，这个地方用于恢复输出
                        //没有发生中断的情况
                        crc_en <= 1;
                        rd_data <= data_in;
                        rd_vld <= 1;
                        out_frame_num[grant_result] <= out_frame_num[grant_result] - 1;
                    end else begin
                        //发生中断
                        data_is_break <= 0;
                        data_is_break_recovery <= 1;
                    end
                    if(data_is_break_recovery == 1) begin//加这个寄存器判断同样是为了多打一拍，因为rd_en拉高后，数据需等一周期才传输
                        data_is_break_recovery <= 0;
                    end
                end else begin
                    if (empty[grant_result] == 1) begin //数据未能及时传输 判断数据中断是否发生的逻辑
                        data_is_break <= 1;
                        rd_data <= 0;
                        crc_en <= 0;
                        rd_vld <= 0;
                        rd_en <= 0;
                    end 
                    if (data_is_break == 1) begin
                        rd_en <= 0;
                        rd_data <= 0;
                        crc_en <= 0;
                        rd_vld <= 0;
                    end
                end
                
                if (out_frame_num[grant_result] == 0 && arb_en == 0) begin//输出块数为0时，停止输出
                    // 发送数据完成，更新状态为等待数据
                    if(out_crc[grant_result] != crc_out && grant_result_vld == 1) begin//判断有没有错误
                        error <= 1;//拉高代表发生错误
                    end else begin
                        //没有错误的情况
                        rd_eop <= 1;
                        rd_en <= 0;
                        rd_vld <= 0;
                        rd_data <= 0;
                        
                        out_crc[grant_result] <= 0;
                        out_empty[grant_result] <= 1;
                        grant_result_vld <= 0;
                        out_priority_bits[grant_result * PRI_WIDTH_SIG +: PRI_WIDTH_SIG] <= 0;
                        
                        current_state <= STATE_WAIT;
                    end
                end
            end
            STATE_WAIT_2: begin//接收数据状态2
                if(wait_data_first == 1) begin//清零对应标记位
                    wait_data_first <= 0;
                end else begin
                    out_priority_bits[cycle_counters * PRI_WIDTH_SIG +: PRI_WIDTH_SIG] <= data_in[PRI_NUM_BIT - 1:0];
                    out_crc[cycle_counters]           <= data_in[CRC32_LENGTH + PRI_NUM_BIT - 1:PRI_NUM_BIT];
                    out_frame_num[cycle_counters]     <= data_in[DATABUF_HIGH_NUM + CRC32_LENGTH + PRI_NUM_BIT - 1:CRC32_LENGTH + PRI_NUM_BIT];
                    current_state <= STATE_WAIT;
                    cycle_counters <= cycle_counters + 1;
                end
            end
            default: begin
                current_state <= STATE_WAIT;
            end
        endcase
    end
end

//下面这个always块用于为sop打拍
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rd_sop_reg_f <= 0;
    else
        rd_sop_reg_f <= rd_sop_reg;
end

assign rd_sop = rd_sop_reg_f;
endmodule