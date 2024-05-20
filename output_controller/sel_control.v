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
    input qos_controll,
    output reg [DATA_WIDTH - 1:0] rd_data,
    output wire rd_sop,
    output reg rd_eop,
    output reg rd_vld,
    output reg [PORT_WIDTH - 1:0] rd_sel,
    output wire rd_en,
    output reg error
);

localparam DATA_WIDTH = `DATA_WIDTH;
localparam PORT_NUB_TOTAL = `PORT_NUB_TOTAL;
localparam PORT_WIDTH = $clog2(`PORT_NUB_TOTAL);
localparam  PRI_WIDTH_SIG = $clog2(`PRI_NUM_TOTAL); // 姣忎釜璇锋眰鐨勪紭鍏堢骇浣嶅
localparam  PRI_WIDTH = PORT_NUB_TOTAL * PRI_WIDTH_SIG; // 鎵?鏈夎姹傜殑鎬讳紭鍏堢骇浣嶅
localparam PRI_NUM_BIT = $clog2(`PRI_NUM_TOTAL);
localparam CRC32_LENGTH = `CRC32_LENGTH;
localparam DATABUF_HIGH_NUM = `DATABUF_HIGH_NUM;

// 瀹氫箟鐘舵??
localparam STATE_WAIT = 0;
localparam STATE_SEND = 1;
localparam STATE_WAIT_2 = 2;

// 褰撳墠鐘舵??
reg [1:0]current_state;


//reg澹版槑
reg [PRI_WIDTH - 1:0] out_priority_bits;
reg [CRC32_LENGTH - 1:0] out_crc [PORT_NUB_TOTAL - 1:0];
reg [DATABUF_HIGH_NUM - 1:0] out_frame_num [PORT_NUB_TOTAL - 1:0];
reg [PORT_NUB_TOTAL - 1:0] out_empty;//瀵瑰簲浣嶆槸鍚︿负绌?
reg [PORT_WIDTH - 1:0] cycle_counters;
reg rd_sop_reg;
reg rd_sop_reg_f;
reg rd_en_reg;
//CRC32鐩稿叧鐨勫瘎瀛樺櫒
reg crc_en;
wire [CRC32_LENGTH - 1:0]crc_out;
reg crc_rst;
//浼樺厛绾ф帶鍒剁浉鍏崇殑瀵勫瓨鍣?
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
reg data_is_break_recovery_1;
reg data_is_break_recovery_2;
reg is_end;
crc16_32bit crc32 (
        .data_in(rd_data), 
        .crc_en(crc_en), 
        .crc_out(crc_out), 
        .rst_n(!crc_rst), 
        .clk(clk)
        );

priority_control_module priority_control(
    .clk(clk), // 鏃堕挓淇″彿
    .rst_n(~rst_n), // 澶嶄綅淇″彿
    .request_signals(~out_empty), // 璇锋眰淇″彿鏁扮粍
    .priorities(out_priority_bits), // 璇锋眰淇″彿鐨勪紭鍏堢骇鏁扮粍
    .select_scheme(qos_controll), // 浼樺厛绾ч?夋嫨鏂规锛?0锛氬浐瀹氫紭鍏堢骇锛?1锛氬姞鏉冭疆璇級
    .grant(grant), // 杈撳嚭鐨勬巿鏉冧俊鍙?
    .grant_vld(grant_vld), // 杈撳嚭鎺堟潈淇″彿鐨勬湁鏁堟爣蹇?
    .arb_en(arb_en)
);


integer j;
always @(posedge clk or posedge rst_n) begin
    //test <= data_in[PRI_NUM_BIT - 1:0];
    if (!rst_n) begin // 寮傛澶嶄綅
        // 鍒濆鍖栧彉閲?
        is_end <= 0;
        rd_sop_reg <= 0;
        rd_eop <= 0;
        rd_vld <= 0;
        rd_sel <= 0;
        rd_en_reg  <= 0;
        rd_data <= 0;
        is_first <= 0;
        arb_en <= 0;
        grant_result <= 0;
        grant_result_vld <= 0;
        data_is_break <= 0;
        current_state <= STATE_WAIT; // 鍒濆鍖栫姸鎬佷负绛夊緟鏁版嵁
        cycle_counters <= 0;
        select_scheme <= 1;
        error <= 0;
        out_priority_bits <= 0;
        wait_data_first <= 0;
        data_is_break_recovery_1 <= 0;
        data_is_break_recovery_2 <= 0;
        for (j = 0; j < PORT_NUB_TOTAL; j = j + 1) begin
            out_frame_num[j] <= 0;
            out_empty[j] <= 1;
            out_crc[j] <= 0;
        end
        
    end else begin
        if (cycle_counters > PORT_NUB_TOTAL - 1) begin //STATE_WAIT閬嶅巻瀹屼竴涓懆鏈熺敤锛?
            cycle_counters <= 0;
        end
        
        if (arb_en == 1 && grant_vld == 1) begin//鐢ㄤ簬浠庝徊瑁佹ā鍧楄鍙栨渶鏂扮殑浠茶淇℃伅锛屽苟鍐冲畾STATE_SEND灏嗚浆鍙戦偅涓鍙ｇ殑鏁版嵁
            arb_en <= 0;
            grant_result <= grant;
            grant_result_vld <= 1;
        end
        
        if (current_state == STATE_WAIT) begin //杩欎釜閮ㄥ垎鐢ㄤ簬鎺у埗鍏朵粬淇″彿
            rd_eop <= 0;
            rd_sop_reg <= 0;
            rd_en_reg <= 0;
            rd_sel <= 0;
            crc_en <= 0;
            crc_rst <= 1;
            arb_en <= 0;
        end else begin
            if(ready && grant_result_vld && out_frame_num[grant_result] > 2)begin  
                rd_eop <= 0;
                rd_sop_reg <= 0;
                rd_en_reg <= 1;  
                rd_sel <= grant_result;
                crc_rst <= 0;
            end else begin
                rd_eop <= 0;
                rd_sop_reg <= 0;
                rd_en_reg <= 0;
                rd_sel <= 0;
                rd_vld <= 0;
                crc_en <= 0;
                crc_rst <= 0;
            end
        end
        //鐘舵?佹満閫昏緫澶勭悊锛孲TATE_WAIT绛夊緟鏁版嵁鐘舵??1锛岀敤浜庨亶鍘嗗悇涓鍙ｃ?係TATE_WAIT_2鐢ㄤ簬鎺ユ敹绔彛鏁版嵁锛屽洜涓簉d_en鎷夐珮闇?瑕佺瓑寰呬竴涓懆鏈熸墠鏈夋暟鎹紝鎵?浠ユ坊鍔犳鐘舵?併?係TATE_SEND鍙戦?佹暟鎹殑閫昏緫
        case (current_state)
            STATE_WAIT: begin
                if (empty[cycle_counters] != out_empty[cycle_counters] && (error == 0) && (current_state == STATE_WAIT || current_state == STATE_WAIT_2) && rd_eop == 0) begin //鎰忓懗鐫?鏈夋柊鐨勬暟鎹?
                    rd_en_reg <= 1; //鎷夐珮鏁版嵁
                    rd_sel <= cycle_counters;
                    out_empty[cycle_counters] <= 0;
                    current_state <= STATE_WAIT_2;
                    wait_data_first <= 1;
                end else begin
                    if ((empty == out_empty) && ready == 1 && ~empty) begin //empty!=0鎰忓懗鐫?鏈夋暟鎹緭鍏ワ紝empty==out_empty鎰忓懗鐫?瀵瑰簲鏁版嵁宸茬粡杈撳叆瀹屾垚
                        // 鏇存柊鐘舵??
                        is_first <= 1;
                        arb_en <= 1;
                        current_state <= STATE_SEND;
                    end
                    cycle_counters <= cycle_counters + 1;
                end
            end
            STATE_SEND: begin
                // 鍙戦?佹暟鎹殑閫昏緫
                if(is_first == 1 && ready == 1 && grant_result_vld)begin
                    is_first <= 0;
                    rd_sop_reg <= 1;
                    rd_en_reg <= 1;
                end
                if(is_first != 1 && grant_result_vld == 1 && ready == 1 && is_first == 0 && rd_sop_reg == 0 && out_frame_num[grant_result] >= 1) begin
                    if(data_is_break == 0 && data_is_break_recovery_1 == 0 && data_is_break_recovery_2 == 0 && data_is_break_recovery_2 == 0) begin//鏁版嵁涓柇涓庢仮澶嶅垽鏂紝鍥犱负浜ゆ崲缁撴瀯鐨勯棶棰橈紝濡傛湁16涓鍙ｅ氨寰楃瓑16涓懆鏈熸墠浼氭湁涓?涓搴旇緭鍏ョ鍙ｇ殑鏁版嵁鍖咃紝杩欎釜鍦版柟鐢ㄤ簬鎭㈠杈撳嚭
                        //娌℃湁鍙戠敓涓柇鐨勬儏鍐?
                        crc_en <= 1;
                        rd_data <= data_in;
                        rd_vld <= 1;
                        //rd_en_reg <= 1;
                        out_frame_num[grant_result] <= out_frame_num[grant_result] - 1;
                    end
                    if(data_is_break_recovery_1 == 1 && empty[grant_result] == 0) begin//绛塭mpty鍐嶆鎷変綆鍦ㄦ竻闄ゆ仮澶嶆暟鎹紶杈?
                        rd_en_reg <= 1;
                        rd_sel <= grant_result;
                        data_is_break_recovery_1 <= 0;
                        data_is_break_recovery_2 <= 1;
                    end
                    
                    if(data_is_break_recovery_2 == 1) begin
                        data_is_break_recovery_2 <= 0;
                    end
                    
                    if (empty[grant_result] == 1 && out_frame_num[grant_result] > 1) begin //鏁版嵁鏈兘鍙婃椂浼犺緭 鍒ゆ柇鏁版嵁涓柇鏄惁鍙戠敓鐨勯?昏緫
                        data_is_break <= 1;//鏁版嵁鍙戠敓涓柇浼犺緭鏈?鍚庝竴涓暟鎹寘鍦ㄦ媺璧凤紝鍥犱负璇荤殑閫熷害姣旇緭鍑虹殑閫熷害蹇?2涓椂閽?
                    end 
                    if (data_is_break == 1) begin
                        data_is_break <= 0;
                        rd_en_reg <= 0;
                        rd_data <= 0;
                        crc_en <= 0;
                        rd_vld <= 0;
                        data_is_break_recovery_1 <= 1;//绛夊緟鏁版嵁鎭㈠
                    end
                end 
                if(ready && grant_result_vld && out_frame_num[grant_result] > 2)begin  
                    rd_en_reg <= 1;  
                    rd_sel <= grant_result;
                end else begin
                    rd_en_reg <= 0;
                    rd_sel <= 0;
                end
                
                if (out_frame_num[grant_result] == 0 && arb_en == 0 && grant_result_vld == 1) begin//杈撳嚭鍧楁暟涓?0鏃讹紝鍋滄杈撳嚭
                    // 鍙戦?佹暟鎹畬鎴愶紝鏇存柊鐘舵?佷负绛夊緟鏁版嵁
                    if(is_end == 0) begin
                        is_end <= 1;
                    end else begin
                        is_end <= 0;
                        if(out_crc[grant_result] != crc_out && grant_result_vld == 1) begin//鍒ゆ柇鏈夋病鏈夐敊璇?
                            error <= 1;//鎷夐珮浠ｈ〃鍙戠敓閿欒
                        end else begin
                            //娌℃湁閿欒鐨勬儏鍐?
                            rd_eop <= 1;
                            rd_en_reg <= 0;
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
            end
            STATE_WAIT_2: begin//鎺ユ敹鏁版嵁鐘舵??2
                if(wait_data_first == 1) begin//娓呴浂瀵瑰簲鏍囪浣?
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

//涓嬮潰杩欎釜always鍧楃敤浜庝负sop鎵撴媿
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        rd_sop_reg_f <= 0;
    else
        rd_sop_reg_f <= rd_sop_reg;
end

assign rd_en   = current_state == STATE_WAIT ? rd_en_reg : current_state == STATE_SEND ? empty[grant_result] == 0 ? rd_en_reg : 0 : rd_en_reg;
//assign rd_en   = empty[grant_result] == 0 ? rd_en_reg : 0;
assign rd_sop = rd_sop_reg_f;
endmodule
