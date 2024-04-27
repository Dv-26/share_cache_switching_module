// 设置时间单位和时间精度
`timescale 1ns / 1ps

module priority_control_module(
    input wire clk, // 时钟信号
    input wire reset, // 复位信号
    input wire [PORT_NUB_TOTAL - 1:0] request_signals, // 请求信号数组
    input wire [PRI_WIDTH - 1:0] priorities, // 请求信号的优先级数组
    input wire select_scheme, // 优先级选择方案（0：固定优先级；1：加权轮询）
    output reg [PORT_WIDTH - 1:0] grant, // 输出的授权信号
    output reg grant_vld // 输出授权信号的有效标志
);
// 引用包含端口数、优先级数等参数的文件
`include "./generate_parameter.vh"

// 定义局部参数
localparam  PORT_NUB_TOTAL = `PORT_NUB_TOTAL; // 定义总端口数
localparam  PORT_WIDTH = $clog2(`PORT_NUB_TOTAL); // 计算端口宽度
localparam  PRI_WIDTH_SIG = $clog2(`PRI_NUM_TOTAL); // 每个请求的优先级位宽
localparam  PRI_WIDTH = PORT_NUB_TOTAL * PRI_WIDTH_SIG; // 所有请求的总优先级位宽

// 定义寄存器和线网
reg [PRI_WIDTH_SIG - 1:0] fixed_priority_grant; // 固定优先级授权
reg [PRI_WIDTH_SIG - 1:0] wrr_priority_grant; // 加权轮询授权
wire [PRI_WIDTH_SIG - 1:0] fixed_priorities [PORT_NUB_TOTAL - 1:0]; // 固定优先级数组
reg [PRI_WIDTH_SIG - 1:0] wrr_counters [PORT_NUB_TOTAL - 1:0]; // WRR计数器数组
reg [PORT_WIDTH - 1:0] wrr_current; // 当前WRR服务的请求
// 优先级解析，根据优先级宽度对优先级数组进行解码
genvar i;
generate
    for (i = 0; i < PORT_NUB_TOTAL; i = i + 1) begin : parse_priority
        assign fixed_priorities[i] = priorities[i * PRI_WIDTH_SIG +: PRI_WIDTH_SIG];
    end
endgenerate

// 固定优先级选择逻辑
integer j;
always @(*) begin
    fixed_priority_grant = 0;
    for (j = 0; j < PORT_NUB_TOTAL; j = j + 1) begin
        if (request_signals[j] && (select_scheme == 0)) begin // 如果请求信号有效
            // 比较并选出优先级最高（或其他指标）的请求进行授权
            fixed_priority_grant = fixed_priorities[j] > fixed_priorities[fixed_priority_grant] ? j[3:0] : fixed_priority_grant;
        end
    end
end

always @(posedge clk or posedge reset) begin
    if ((select_scheme == 0)) begin // 如果请求信号有效
        grant_vld = 1;
    end else begin
        grant_vld = 0;
    end
end
// 加权轮询(WRR)优先级选择逻辑
integer g;
always @(posedge clk or posedge reset) begin
    if (reset) begin // 如果复位信号被激活
        // 初始化WRR计数器，授权状态和当前服务的请求
        for (g = 0; g < PORT_NUB_TOTAL; g = g + 1) begin
            wrr_counters[g] = 0;
        end
        grant_vld = 0;
        wrr_current = 0;
        wrr_priority_grant = 0;
    end else begin // 处理WRR逻辑
        if (select_scheme) begin // 如果选择WRR方案
            if (wrr_counters[wrr_current] <= fixed_priorities[wrr_current]) begin
                // 如果当前请求未达到其权重上限
                if (request_signals[wrr_current]) begin
                    // 授权当前请求
                    wrr_priority_grant = wrr_current;
                    grant_vld = 1; // 设置授权有效
                    wrr_counters[wrr_current] = wrr_counters[wrr_current] + 1; // 更新WRR计数器
                end else begin
                    // 如果未接收到当前请求，移动到下一个请求
                    grant_vld = 0;
                    wrr_current = wrr_current + 1;
                    wrr_counters[wrr_current] = 0;
                end
            end else begin
                // 轮询至下一个请求
                grant_vld = 0;
                wrr_current = wrr_current + 1;
                wrr_counters[wrr_current] = 0;
            end
            // 处理循环轮询
            if (wrr_current > PORT_NUB_TOTAL - 1) begin
                wrr_current = 0;
            end
        end
    end
end

// 最终优先级输出选择逻辑
always @(*) begin
    // 根据选择方案输出固定优先级或WRR优先级grant
    grant = select_scheme ? wrr_priority_grant : fixed_priority_grant;
end

endmodule 