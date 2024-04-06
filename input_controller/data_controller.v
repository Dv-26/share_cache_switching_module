`timescale 1ns / 1ps
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

`include "crc32_64bit.v"

module data_controller 
#(
    parameter   INPUT_DATA_BIT    = 64,
    parameter   OUTPUT_DATA_BIT   = 73, 
    parameter   PORT_NUM_BIT      = 4, //2**�����˿�
    parameter   PRI_NUM_BIT       = 3,
    parameter   DATABUF_HIGH_NUM  = 8, //2**�������ݰ� ֧�ֶ��ٸ����ݰ�
    parameter   CRC32_LENGTH      = 32, //CRC32У�鳤��
    parameter   INPUT_HIGH_LIMIT  = 128,
    parameter   INPUT_LOW_LIMIT   = 8
)
(
    input wire clk,
    input wire rst,
    input wire wr_sop,
    input wire wr_eop,
    input wire wr_vld,
    input wire [INPUT_DATA_BIT - 1:0] wr_data,
    output reg IP_full,
    output reg almost_full,
    output reg [OUTPUT_DATA_BIT - 1:0] data,
    output reg rr_vld,
    output reg data_valid,
    output reg error
);
    //״̬������������Ϣ
    localparam WAIT_DATA     = 2'd0;//�ȴ����ݰ�
    localparam RECEIVING = 2'd1;//��ʼ����
    localparam VALIDATE = 2'd2;//������֤
    localparam local_port = 4'd0;//��ʾ���Ƕ˿�0
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // ���ڴ洢���ݳ��ȺͶ˿���Ϣ�ļĴ���
    reg [PORT_NUM_BIT - 1:0] port_info;//4bit
    reg [PRI_NUM_BIT - 1:0] priority_bits;//3bit
    //reg [10:0] frame_length; // ����֡�������1024����Ҫ11λ��ʾ
    reg [DATABUF_HIGH_NUM - 1:0] frame_num; //����֡����
    
    //�м���ر���
    reg [PORT_NUM_BIT - 1:0] out_port_info;//4bit
    reg [PRI_NUM_BIT - 1:0] out_priority_bits;//3bit
    reg [CRC32_LENGTH - 1:0] out_crc;
    reg [DATABUF_HIGH_NUM - 1:0] out_frame_num; //�������֡����
    reg out_isfirst;//���жϸ�����֡�Ƿ��һ֡
    
    //crc32��ر���
    reg crc_en;
    reg crc_rst;
    wire [CRC32_LENGTH - 1:0] crc_out;
    wire [INPUT_DATA_BIT - 1:0] data_in;
    reg vld_isfinish;
    reg [INPUT_DATA_BIT - 1:0] wr_crc_data;
    
    //fifo��ر���
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
    
    //CRC32ģ��
    crc32_64bit crc32 (
        .data_in(wr_crc_data), 
        .crc_en(crc_en), 
        .crc_out(crc_out), 
        .rst(crc_rst), 
        .clk(clk)
        );
    //fifoģ��
    dc_fifo_input fifo_data (
      .rst_n(~fifo_rst),                  // input wire rst
      .wr_clk(clk),            // input wire wr_clk
      .rd_clk(~clk),            // ȡ��ʱ�ӣ�����д
      .wr_data(fifo_input_data),                  // input wire [63 : 0] din
      .wr_en(fifo_wr_en),              // input wire wr_en
      .rd_en(fifo_rd_en),              // input wire rd_en
      .rd_data(fifo_data_out)                 // output wire [63 : 0] dout
    );
    
    dc_fifo_input_data_info fifo_data_info (
      .rst_n(~fifo_rst),                  // input wire rst
      .wr_clk(clk),            // input wire wr_clk
      .rd_clk(~clk),            // ȡ��ʱ�ӣ�����д
      .wr_data(fifo_input_data_info),                  // input wire [63 : 0] din
      .wr_en(fifo_wr_info_en),              // input wire wr_en
      .rd_en(fifo_rd_info_en),              // input wire rd_en
      .rd_data(fifo_data_info_out),                 // output wire [63 : 0] dout
      .empty(fifo_rd_info_empty)
    );

    // ״̬����ʼ״̬����
    initial begin
        current_state <= WAIT_DATA;//�ȴ�����
        //Ϊip�˳�ʼ����ֵ���������̬
        IP_full <= 0;
        almost_full <= 0;
        data_valid <= 0;
        error <= 0;
        data <=0;
        //crc32��ر���
        crc_en <= 0;
        crc_rst <= 1;
        //fifo����
        fifo_wr_en <= 0;
        fifo_rd_en <= 0;
        fifo_rst <=0;
        //״̬���ڲ�����
        frame_num <= 0;
        out_frame_num <= 0;
        out_isfirst <= 0;
        out_priority_bits <= 0;
        priority_bits <=0;
        port_info <=0;
        
    end

    // ״̬��ת���߼�
    always @(posedge clk) begin
        if (rst) begin//�����źŴ����߼�
            current_state <= WAIT_DATA;//�ȴ�����
            //Ϊip�˳�ʼ����ֵ���������̬
            IP_full <= 0;
            almost_full <= 0;
            data_valid <= 0;
            error <= 0;
            data <=0;
            //crc32��ر���
            crc_en <= 0;
            crc_rst <= 1;
            //fifo����
            fifo_wr_en <= 0;
            fifo_rd_en <= 0;
            fifo_rst <=0;
            //״̬���ڲ�����
            frame_num <= 0;
            fifo_rst <= 1;//����fifo
        end else begin
            fifo_rst <= 0;
            current_state <= next_state; //״̬���л�״̬
        end
        
        
        if (wr_sop == 0 && wr_vld == 1 && error == 0) begin//���ݿ�ʼ���䣬����CRC32ģ��
            crc_rst <= 0;
            crc_en <= 1;
            wr_crc_data <= wr_data;
            frame_num <= frame_num + 1;
            if (frame_num == 0) begin
                port_info <= wr_data[PORT_NUM_BIT - 1:0];
                priority_bits <= wr_data[PORT_NUM_BIT + PRI_NUM_BIT - 1:PORT_NUM_BIT];
            end else begin
                fifo_wr_en <= 1;//��fifo
                fifo_input_data <= wr_data;
            end
        end
        
        if (current_state == RECEIVING && wr_eop && error == 0) begin //�ж����ݷ����Ƿ����
            data_valid <= (frame_num >= INPUT_LOW_LIMIT && frame_num <= INPUT_HIGH_LIMIT);
            vld_isfinish <= 0;//��λ�����ж�ģ���Ƿ񷢳�����֡��������Ԫģ��
            fifo_input_data <= 0;
            fifo_wr_en <= 0;//�����ݰ��������ʱ���ر�fifo��д��
        end
        
        if (current_state == VALIDATE && wr_eop == 0 && error == 0) begin
            crc_rst <= 1;
            crc_en <= 0;
        end
    end
    
    // ״̬����һ��״̬������߼�
    always @(*) begin
        case (current_state)
            WAIT_DATA: begin
                port_info <= 0;
                priority_bits <= 0;
                fifo_wr_info_en <= 0;
                fifo_input_data_info <= PORT_NUM_BIT + PRI_NUM_BIT + DATABUF_HIGH_NUM + CRC32_LENGTH - 1'd0;
                data_valid <= 0;
                frame_num<=0;//��������֡����
                if (wr_sop  && error == 0) begin
                    next_state <= RECEIVING;
                end
            end
            RECEIVING: begin
                if (wr_eop  && error == 0) begin //�ж����ݷ����Ƿ����
                    next_state <= VALIDATE;
                end else begin
                    next_state <= RECEIVING;
                end
            end
            VALIDATE: begin
                if(wr_eop == 0 && error == 0) begin
                    if (data_valid == 0) begin //��������֡��������
                        error <= 1;//����λ����
                    end else begin 
                        fifo_input_data_info[PORT_NUM_BIT - 1:0] <= port_info;
                        fifo_input_data_info[PORT_NUM_BIT + PRI_NUM_BIT - 1:PORT_NUM_BIT] <= priority_bits;
                        fifo_input_data_info[PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH - 1:PORT_NUM_BIT + PRI_NUM_BIT] <= crc_out;
                        fifo_input_data_info[PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH + DATABUF_HIGH_NUM - 1:PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH] <= frame_num;//Ҫ���������֡��
                        fifo_wr_info_en <= 1;//����FIFO_DATA_INFO
                    end
                end
                next_state <= WAIT_DATA;
            end
            default: begin
                next_state <= WAIT_DATA;
            end
        endcase
    end
    
    always @(posedge clk) begin //����������������
        if (out_frame_num > 0) begin//������0ʱ����������Ҫ���������
            if (out_isfirst == 1) begin//��һ����� ������֡�����������Ԫ
                out_isfirst <= 0;
                rr_vld <= 1;//���߱�ʾ�����������Ч
                data[0] <= 1;//������Ԫ�е���Чλ
                data[PORT_NUM_BIT:1] <= out_port_info;//�����Ŀ��˿�
                data[PORT_NUM_BIT + PORT_NUM_BIT:PORT_NUM_BIT + 1] <= local_port;//���ض˿ڵı�ʶ��
                data[PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT:PORT_NUM_BIT + PORT_NUM_BIT + 1] <= out_priority_bits;//���ȼ�
                data[PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH:PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT + 1] <= out_crc;//crc32
                //data[OUTPUT_DATA_BIT - 1:PORT_NUM_BIT + PORT_NUM_BIT + PRI_NUM_BIT + CRC32_LENGTH + 1] <= OUTPUT_DATA_BIT - PORT_NUM_BIT - PORT_NUM_BIT - PRI_NUM_BIT - CRC32_LENGTH'd0;
            end else begin
                out_frame_num <= out_frame_num - 1;
                if(out_frame_num > 1) begin
                    fifo_rd_en <= 1;
                    data[0] <= 1;
                    data[PORT_NUM_BIT:1] <= out_port_info;//�����Ŀ��˿�
                    data[PORT_NUM_BIT + PORT_NUM_BIT:PORT_NUM_BIT + 1] <= local_port;//���ض˿ڵı�ʶ��
                    data[OUTPUT_DATA_BIT - 1:PORT_NUM_BIT + PORT_NUM_BIT + 1] <= fifo_data_out;
                    rr_vld <= 1;
                end else begin
                    fifo_rd_en <= 0;
                    data <= 0;
                    rr_vld <= 0;
                end
            end
        end else begin
            fifo_rd_en <= 0;//fifoֹͣ��
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