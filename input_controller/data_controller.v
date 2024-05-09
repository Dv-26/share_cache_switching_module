`timescale 1ns / 1ps
`include "./define.vh"

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.03.2024 20:43:39
// Design Name: 
// Module Name: data_controller
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

`include "CRC32_D64.v"

module data_controller 
#(
    parameter   INPUT_DATA_BIT    = `INPUT_DATA_WIDTH,
    parameter   OUTPUT_DATA_BIT   = `OUTPUT_DATA_WIDTH, 
    parameter   PORT_NUM_BIT      = $clog2(`PORT_NUB_TOTAL), //2**几个端口
    parameter   PRI_NUM_BIT       = $clog2(`PRI_NUM),
    parameter   DATABUF_HIGH_NUM  = $clog2(`DATABUF_HIGH_LIMIT_NUM), //2**几个数据包 支持多少个数据包
    parameter   CRC32_LENGTH      = `CRC32_LENGTH_WIDTH, //CRC32校验长度
    parameter   INPUT_HIGH_LIMIT  = `INPUT_HIGH_LIMIT_NUM,
    parameter   INPUT_LOW_LIMIT   = `INPUT_LOW_LIMIT_NUM
)
(
    input wire clk,
    input wire rst,
    input wire wr_sop,
    input wire wr_eop,
    input wire wr_vld,
    input wire [INPUT_DATA_BIT - 1:0] wr_data,
    input wire [PORT_NUM_BIT - 1:0] local_port_info,
    output reg IP_full,
    output reg almost_full,
    output reg [OUTPUT_DATA_BIT - 1:0] data,
    output reg rr_vld,
    output reg data_valid,
    output reg error
);
    //状态机基本变量信息
    localparam WAIT_DATA     = 2'd0;//等待数据包
    localparam RECEIVING = 2'd1;//开始接收
    localparam VALIDATE = 2'd2;//数据验证
    localparam local_port = 4'd0;//表示这是端口0
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // 用于存储数据长度和端口信息的寄存器
    reg [PORT_NUM_BIT - 1:0] port_info;//4bit
    reg [PRI_NUM_BIT - 1:0] priority_bits;//3bit
    //reg [10:0] frame_length; // 假设帧长度最大1024，需要11位表示
    reg [DATABUF_HIGH_NUM - 1:0] frame_num; //数据帧块数
    
    //中间相关变量
    reg [PORT_NUM_BIT - 1:0] out_port_info;//4bit
    reg [PRI_NUM_BIT - 1:0] out_priority_bits;//3bit
    reg [CRC32_LENGTH - 1:0] out_crc;
    reg [DATABUF_HIGH_NUM - 1:0] out_frame_num; //输出数据帧块数
    reg out_isfirst;//来判断该数据帧是否第一帧
    
    //crc32相关变量
    reg crc_en;
    reg crc_rst;
    wire [CRC32_LENGTH - 1:0] crc_out;
    wire [INPUT_DATA_BIT - 1:0] data_in;
    reg vld_isfinish;
    reg [INPUT_DATA_BIT - 1:0] wr_crc_data;
    
    //fifo相关变量
    wire [INPUT_DATA_BIT - 1:0] fifo_data_out;
    reg fifo_rst;
    reg fifo_wr_en;
    reg [INPUT_DATA_BIT - 1:0] fifo_input_data;
    reg fifo_rd_en;
    
    wire [PORT_NUM_BIT + PRI_NUM_BIT + DATABUF_HIGH_NUM + CRC32_LENGTH - 1:0] fifo_data_info_out;
    reg fifo_wr_info_en;
    reg [PORT_NUM_BIT + PRI_NUM_BIT + DATABUF_HIGH_NUM + CRC32_LENGTH - 1:0] fifo_input_data_info;
    reg fifo_rd_info_en;
    wire fifo_rd_info_empty;
    
    //CRC32模块
    crc32_64bit crc32 (
        .data_in(wr_crc_data), 
        .crc_en(crc_en), 
        .crc_out(crc_out), 
        .rst(crc_rst), 
        .clk(clk)
        );
    //fifo模块
    dc_fifo_input fifo_data (
      .rst_n(~fifo_rst),                  // input wire rst
      .wr_clk(clk),            // input wire wr_clk
      .rd_clk(~clk),            // 取反时钟，错开读写
      .wr_data(fifo_input_data),                  // input wire [63 : 0] din
      .wr_en(fifo_wr_en),              // input wire wr_en
      .rd_en(fifo_rd_en),              // input wire rd_en
      .rd_data(fifo_data_out)                 // output wire [63 : 0] dout
    );
    
    dc_fifo_input_data_info fifo_data_info (
      .rst_n(~fifo_rst),                  // input wire rst
      .wr_clk(clk),            // input wire wr_clk
      .rd_clk(~clk),            // 取反时钟，错开读写
      .wr_data(fifo_input_data_info),                  // input wire [63 : 0] din
      .wr_en(fifo_wr_info_en),              // input wire wr_en
      .rd_en(fifo_rd_info_en),              // input wire rd_en
      .rd_data(fifo_data_info_out),                 // output wire [63 : 0] dout
      .empty(fifo_rd_info_empty)
    );

    // 状态机初始状态设置
    initial begin
        current_state <= WAIT_DATA;//等待数据
        //为ip核初始化赋值，避免高阻态
        IP_full <= 0;
        almost_full <= 0;
        data_valid <= 0;
        error <= 0;
        data <=0;
        //crc32相关变量
        crc_en <= 0;
        crc_rst <= 1;
        //fifo变量
        fifo_wr_en <= 0;
        fifo_rd_en <= 0;
        fifo_rst <=0;
        //状态机内部变量
        frame_num <= 0;
        out_frame_num <= 0;
        out_isfirst <= 0;
        out_priority_bits <= 0;
        priority_bits <=0;
        port_info <=0;
        
    end

    // 状态机转换逻辑
    always @(posedge clk) begin
        if (!rst) begin//重置信号处理逻辑
            current_state <= WAIT_DATA;//等待数据
            //为ip核初始化赋值，避免高阻态
            IP_full <= 0;
            almost_full <= 0;
            data_valid <= 0;
            error <= 0;
            data <=0;
            //crc32相关变量
            crc_en <= 0;
            crc_rst <= 1;
            //fifo变量
            fifo_wr_en <= 0;
            fifo_rd_en <= 0;
            fifo_rst <=0;
            //状态机内部变量
            frame_num <= 0;
            fifo_rst <= 1;//重置fifo
        end else begin
            fifo_rst <= 0;
            current_state <= next_state; //状态机切换状态
        end
        
        
        if (wr_sop == 0 && wr_vld == 1 && error == 0) begin//数据开始传输，启用CRC32模块
            crc_rst <= 0;
            crc_en <= 1;
            wr_crc_data <= wr_data;
            frame_num <= frame_num + 1;
            if (frame_num == 0) begin
                port_info <= wr_data[PORT_NUM_BIT - 1:0];
                priority_bits <= wr_data[PORT_NUM_BIT + PRI_NUM_BIT - 1:PORT_NUM_BIT];
            end else begin
                fifo_wr_en <= 1;//打开fifo
                fifo_input_data <= wr_data;
            end
        end
        
        if (current_state == RECEIVING && wr_eop && error == 0) begin //判断数据发送是否结束
            data_valid <= (frame_num >= INPUT_LOW_LIMIT && frame_num <= INPUT_HIGH_LIMIT);
            vld_isfinish <= 0;//该位用于判断模块是否发出控制帧给交换单元模块
            fifo_input_data <= 0;
            fifo_wr_en <= 0;//当数据包传输完成时，关闭fifo的写入
        end
        
        if (current_state == VALIDATE && wr_eop == 0 && error == 0) begin
            crc_rst <= 1;
            crc_en <= 0;
        end
    end
    
    // 状态机下一个状态和相关逻辑
    always @(*) begin
        case (current_state)
            WAIT_DATA: begin
                port_info <= 0;
                priority_bits <= 0;
                fifo_wr_info_en <= 0;
                fifo_input_data_info <= PORT_NUM_BIT + PRI_NUM_BIT + DATABUF_HIGH_NUM + CRC32_LENGTH - 1'd0;
                data_valid <= 0;
                frame_num<=0;//接收数据帧个数
                if (wr_sop  && error == 0) begin
                    next_state <= RECEIVING;
                end
            end
            RECEIVING: begin
                if (wr_eop  && error == 0) begin //判断数据发送是否结束
                    next_state <= VALIDATE;
                end else begin
                    next_state <= RECEIVING;
                end
            end
            VALIDATE: begin
                if(wr_eop == 0 && error == 0) begin
                    if (data_valid == 0) begin //超出数据帧接收限制
                        error <= 1;//错误位拉高
                    end else begin 
                        fifo_input_data_info[PORT_NUM_BIT - 1:0] <= port_info;
                        fifo_input_data_info[PORT_NUM_BIT + PRI_NUM_BIT - 1:PORT_NUM_BIT] <= priority_bits;
                        fifo_input_data_info[PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH - 1:PORT_NUM_BIT + PRI_NUM_BIT] <= crc_out;
                        fifo_input_data_info[PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH + DATABUF_HIGH_NUM - 1:PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH] <= frame_num;//要输出的数据帧数
                        fifo_wr_info_en <= 1;//启用FIFO_DATA_INFO
                    end
                end
                next_state <= WAIT_DATA;
            end
            default: begin
                next_state <= WAIT_DATA;
            end
        endcase
    end
    
    always @(posedge clk) begin //这个部分来输出数据
        if (out_frame_num > 0) begin//不等于0时，代表有需要输出的数据
            if (out_isfirst == 1 && local_port_info != out_port_info) begin//第一次输出 将控制帧传输给交换单元
                out_isfirst <= 0;
                rr_vld <= 1;//拉高表示输出的数据有效
                data[0] <= 1;//交换单元中的有效位
                data[PORT_NUM_BIT:1] <= out_port_info;//输出的目标端口
                data[PORT_NUM_BIT + PORT_NUM_BIT:PORT_NUM_BIT + 1] <= local_port;//本地端口的标识符
                data[PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT:PORT_NUM_BIT + PORT_NUM_BIT + 1] <= out_priority_bits;//优先级
                data[PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH:PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT + 1] <= out_crc;//crc32
                //data[OUTPUT_DATA_BIT - 1:PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH + 1] <= OUTPUT_DATA_BIT - PORT_NUM_BIT - PORT_NUM_BIT - PRI_NUM_BIT - CRC32_LENGTH'd0;
            end else begin
                out_frame_num <= out_frame_num - 1;
                out_isfirst <= 0;
                if(out_frame_num > 1 && local_port_info != out_port_info) begin
                    fifo_rd_en <= 1;
                    data[0] <= 1;
                    data[PORT_NUM_BIT:1] <= out_port_info;//输出的目标端口
                    data[PORT_NUM_BIT + PORT_NUM_BIT:PORT_NUM_BIT + 1] <= local_port;//本地端口的标识符
                    data[OUTPUT_DATA_BIT - 1:PORT_NUM_BIT + PORT_NUM_BIT + 1] <= fifo_data_out;
                    rr_vld <= 1;
                end
                
                if(out_frame_num <= 1) begin
                    fifo_rd_en <= 0;
                    data <= 0;
                    rr_vld <= 0;
                end
            end
        end else begin
            fifo_rd_en <= 0;//fifo停止读
            data <= 0;
            rr_vld <= 0;
        end
    end
    
    always @(posedge clk) begin
        if (out_frame_num == 0 && fifo_rd_info_empty == 0) begin
            fifo_rd_info_en <= 1;
            out_isfirst <= 1;
            out_port_info <= fifo_data_info_out[PORT_NUM_BIT - 1:0];
            out_priority_bits <= fifo_data_info_out[PORT_NUM_BIT + PRI_NUM_BIT - 1:PORT_NUM_BIT];
            out_crc <= fifo_data_info_out[PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH - 1:PORT_NUM_BIT + PRI_NUM_BIT];
            out_frame_num <= fifo_data_info_out[PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH + DATABUF_HIGH_NUM - 1:PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH];
        end
        if(fifo_rd_info_en == 1 && fifo_rd_info_empty == 1) begin
            fifo_rd_info_en <= 0;
        end
    end
endmodule