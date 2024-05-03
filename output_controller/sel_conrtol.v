`timescale 1ns / 1ps
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
#(
    parameter DATA_WIDTH = 64
)
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

`include "./generate_parameter.vh"

localparam PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam PORT_WIDTH = $clog2(`PORT_NUB_TOTAL);
localparam  PRI_WIDTH_SIG = $clog2(`PRI_NUM_TOTAL); // ÿ����������ȼ�λ��
localparam  PRI_WIDTH = PORT_NUB_TOTAL * PRI_WIDTH_SIG; // ��������������ȼ�λ��
localparam PRI_NUM_BIT = 3;
localparam CRC32_LENGTH = 32;
localparam DATABUF_HIGH_NUM = 7;

// ����״̬
localparam STATE_WAIT = 0;
localparam STATE_SEND = 1;
localparam STATE_WAIT_2 = 2;

// ��ǰ״̬
reg [1:0]current_state;

//reg����
reg [PRI_WIDTH - 1:0] out_priority_bits;
reg [CRC32_LENGTH - 1:0] out_crc [PORT_NUB_TOTAL - 1:0];
reg [DATABUF_HIGH_NUM - 1:0] out_frame_num [PORT_NUB_TOTAL - 1:0];
reg [PORT_NUB_TOTAL - 1:0] out_empty;//��Ӧλ�Ƿ�Ϊ��
reg [PORT_WIDTH - 1:0] cycle_counters;
reg rd_sop_reg;
reg rd_sop_reg_f;
//CRC32��صļĴ���
reg crc_en;
wire [CRC32_LENGTH - 1:0]crc_out;
reg crc_rst;
//���ȼ�������صļĴ���
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
crc32_64bit crc32 (
        .data_in(rd_data), 
        .crc_en(crc_en), 
        .crc_out(crc_out), 
        .rst(crc_rst), 
        .clk(clk)
        );

priority_control_module priority_control(
    .clk(clk), // ʱ���ź�
    .rst_n(rst_n), // ��λ�ź�
    .request_signals(~out_empty), // �����ź�����
    .priorities(out_priority_bits), // �����źŵ����ȼ�����
    .select_scheme(select_scheme), // ���ȼ�ѡ�񷽰���0���̶����ȼ���1����Ȩ��ѯ��
    .grant(grant), // �������Ȩ�ź�
    .grant_vld(grant_vld), // �����Ȩ�źŵ���Ч��־
    .arb_en(arb_en)
);


integer j;
always @(posedge clk or posedge rst_n) begin
    //test <= data_in[PRI_NUM_BIT - 1:0];
    if (rst_n) begin // �첽��λ
        // ��ʼ������
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
        current_state <= STATE_WAIT; // ��ʼ��״̬Ϊ�ȴ�����
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
        if (cycle_counters > PORT_NUB_TOTAL - 1) begin //STATE_WAIT������һ�������ã�
            cycle_counters <= 0;
        end
        
        if (arb_en == 1 && grant_vld == 1) begin//���ڴ��ٲ�ģ���ȡ���µ��ٲ���Ϣ��������STATE_SEND��ת���Ǹ��˿ڵ�����
            arb_en <= 0;
            grant_result <= grant;
            grant_result_vld <= 1;
        end
        
        if (current_state == STATE_WAIT) begin //����������ڿ��������ź�
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
        //״̬���߼�����STATE_WAIT�ȴ�����״̬1�����ڱ��������˿ڡ�STATE_WAIT_2���ڽ��ն˿����ݣ���Ϊrd_en������Ҫ�ȴ�һ�����ڲ������ݣ�������Ӵ�״̬��STATE_SEND�������ݵ��߼�
        case (current_state)
            STATE_WAIT: begin
                if (empty[cycle_counters] != out_empty[cycle_counters] && (error == 0) && (current_state == STATE_WAIT || current_state == STATE_WAIT_2) && rd_eop == 0) begin //��ζ�����µ�����
                    rd_en <= 1; //��������
                    rd_sel <= cycle_counters;
                    out_empty[cycle_counters] <= 0;
                    current_state <= STATE_WAIT_2;
                    wait_data_first <= 1;
                end else begin
                    if ((empty == out_empty) && ready == 1 && ~empty) begin //empty!=0��ζ�����������룬empty==out_empty��ζ�Ŷ�Ӧ�����Ѿ��������
                        // ����״̬
                        is_first <= 1;
                        arb_en <= 1;
                        current_state <= STATE_SEND;
                    end
                    cycle_counters <= cycle_counters + 1;
                end
            end
            STATE_SEND: begin
                // �������ݵ��߼�
                if(is_first == 1 && ready == 1 && grant_result_vld)begin
                    is_first <= 0;
                    rd_sop_reg <= 1;
                    rd_en <= 1;
                end
                if(grant_result_vld == 1 && ready == 1 && is_first == 0 && rd_sop_reg == 0 && out_frame_num[grant_result] >= 1 && empty[grant_result] == 0) begin
                    if(data_is_break == 0 && data_is_break_recovery == 0) begin//�����ж���ָ��жϣ���Ϊ�����ṹ�����⣬����16���˿ھ͵õ�16�����ڲŻ���һ����Ӧ����˿ڵ����ݰ�������ط����ڻָ����
                        //û�з����жϵ����
                        crc_en <= 1;
                        rd_data <= data_in;
                        rd_vld <= 1;
                        out_frame_num[grant_result] <= out_frame_num[grant_result] - 1;
                    end else begin
                        //�����ж�
                        data_is_break <= 0;
                        data_is_break_recovery <= 1;
                    end
                    if(data_is_break_recovery == 1) begin//������Ĵ����ж�ͬ����Ϊ�˶��һ�ģ���Ϊrd_en���ߺ��������һ���ڲŴ���
                        data_is_break_recovery <= 0;
                    end
                end else begin
                    if (empty[grant_result] == 1) begin //����δ�ܼ�ʱ���� �ж������ж��Ƿ������߼�
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
                
                if (out_frame_num[grant_result] == 0 && arb_en == 0) begin//�������Ϊ0ʱ��ֹͣ���
                    // ����������ɣ�����״̬Ϊ�ȴ�����
                    if(out_crc[grant_result] != crc_out && grant_result_vld == 1) begin//�ж���û�д���
                        error <= 1;//���ߴ���������
                    end else begin
                        //û�д�������
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
            STATE_WAIT_2: begin//��������״̬2
                if(wait_data_first == 1) begin//�����Ӧ���λ
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

//�������always������Ϊsop����
always@(posedge clk or negedge rst_n)begin
    if(rst_n)
        rd_sop_reg_f <= 0;
    else
        rd_sop_reg_f <= rd_sop_reg;
end

assign rd_sop = rd_sop_reg_f;
endmodule