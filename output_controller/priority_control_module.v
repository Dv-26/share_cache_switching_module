// ����ʱ�䵥λ��ʱ�侫��
`timescale 1ns / 1ps

module priority_control_module(
    input wire clk, // ʱ���ź�
    input wire reset, // ��λ�ź�
    input wire [PORT_NUB_TOTAL - 1:0] request_signals, // �����ź�����
    input wire [PRI_WIDTH - 1:0] priorities, // �����źŵ����ȼ�����
    input wire select_scheme, // ���ȼ�ѡ�񷽰���0���̶����ȼ���1����Ȩ��ѯ��
    output reg [PORT_WIDTH - 1:0] grant, // �������Ȩ�ź�
    output reg grant_vld // �����Ȩ�źŵ���Ч��־
);
// ���ð����˿��������ȼ����Ȳ������ļ�
`include "./generate_parameter.vh"

// ����ֲ�����
localparam  PORT_NUB_TOTAL = `PORT_NUB_TOTAL; // �����ܶ˿���
localparam  PORT_WIDTH = $clog2(`PORT_NUB_TOTAL); // ����˿ڿ��
localparam  PRI_WIDTH_SIG = $clog2(`PRI_NUM_TOTAL); // ÿ����������ȼ�λ��
localparam  PRI_WIDTH = PORT_NUB_TOTAL * PRI_WIDTH_SIG; // ��������������ȼ�λ��

// ����Ĵ���������
reg [PRI_WIDTH_SIG - 1:0] fixed_priority_grant; // �̶����ȼ���Ȩ
reg [PRI_WIDTH_SIG - 1:0] wrr_priority_grant; // ��Ȩ��ѯ��Ȩ
wire [PRI_WIDTH_SIG - 1:0] fixed_priorities [PORT_NUB_TOTAL - 1:0]; // �̶����ȼ�����
reg [PRI_WIDTH_SIG - 1:0] wrr_counters [PORT_NUB_TOTAL - 1:0]; // WRR����������
reg [PORT_WIDTH - 1:0] wrr_current; // ��ǰWRR���������
// ���ȼ��������������ȼ���ȶ����ȼ�������н���
genvar i;
generate
    for (i = 0; i < PORT_NUB_TOTAL; i = i + 1) begin : parse_priority
        assign fixed_priorities[i] = priorities[i * PRI_WIDTH_SIG +: PRI_WIDTH_SIG];
    end
endgenerate

// �̶����ȼ�ѡ���߼�
integer j;
always @(*) begin
    fixed_priority_grant = 0;
    for (j = 0; j < PORT_NUB_TOTAL; j = j + 1) begin
        if (request_signals[j] && (select_scheme == 0)) begin // ��������ź���Ч
            // �Ƚϲ�ѡ�����ȼ���ߣ�������ָ�꣩�����������Ȩ
            fixed_priority_grant = fixed_priorities[j] > fixed_priorities[fixed_priority_grant] ? j[3:0] : fixed_priority_grant;
        end
    end
end

always @(posedge clk or posedge reset) begin
    if ((select_scheme == 0)) begin // ��������ź���Ч
        grant_vld = 1;
    end else begin
        grant_vld = 0;
    end
end
// ��Ȩ��ѯ(WRR)���ȼ�ѡ���߼�
integer g;
always @(posedge clk or posedge reset) begin
    if (reset) begin // �����λ�źű�����
        // ��ʼ��WRR����������Ȩ״̬�͵�ǰ���������
        for (g = 0; g < PORT_NUB_TOTAL; g = g + 1) begin
            wrr_counters[g] = 0;
        end
        grant_vld = 0;
        wrr_current = 0;
        wrr_priority_grant = 0;
    end else begin // ����WRR�߼�
        if (select_scheme) begin // ���ѡ��WRR����
            if (wrr_counters[wrr_current] <= fixed_priorities[wrr_current]) begin
                // �����ǰ����δ�ﵽ��Ȩ������
                if (request_signals[wrr_current]) begin
                    // ��Ȩ��ǰ����
                    wrr_priority_grant = wrr_current;
                    grant_vld = 1; // ������Ȩ��Ч
                    wrr_counters[wrr_current] = wrr_counters[wrr_current] + 1; // ����WRR������
                end else begin
                    // ���δ���յ���ǰ�����ƶ�����һ������
                    grant_vld = 0;
                    wrr_current = wrr_current + 1;
                    wrr_counters[wrr_current] = 0;
                end
            end else begin
                // ��ѯ����һ������
                grant_vld = 0;
                wrr_current = wrr_current + 1;
                wrr_counters[wrr_current] = 0;
            end
            // ����ѭ����ѯ
            if (wrr_current > PORT_NUB_TOTAL - 1) begin
                wrr_current = 0;
            end
        end
    end
end

// �������ȼ����ѡ���߼�
always @(*) begin
    // ����ѡ�񷽰�����̶����ȼ���WRR���ȼ�grant
    grant = select_scheme ? wrr_priority_grant : fixed_priority_grant;
end

endmodule 