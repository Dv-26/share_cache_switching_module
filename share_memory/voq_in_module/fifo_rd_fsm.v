`include "../../generate_parameter.vh"

module fifo_rd_fsm
(
    input   wire                        clk,
    input   wire                        rst_n,
    
    input   wire                        cut_1to2_in,
    input   wire                        cut_2to1_in,
    input   wire                        voq_full_in,
    input   wire                        fifo_empty_in,

    output  reg                         out_sel_out,
    output  reg                         fifo1_rd_en,
    output  reg                         fifo2_rd_en,
    output  reg                         top_wr_en_out
);

localparam  PORT_NUB        = `PORT_NUB_TOTAL;
localparam  WIDTH_SEL       = $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_PORT      = WIDTH_SEL + `DATA_WIDTH;
localparam  WIDTH_FIFO      = WIDTH_PORT + 1;
localparam  WIDTH_LENGTH    = $clog2(`DATA_LENGTH_MAX);

localparam  IDLE    = 2'b00;
localparam  FIFO1   = 2'b01;
localparam  FIFO2   = 2'b10;

reg         top_wr_en_out_n;
reg [1:0]   state,state_n;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state <= FIFO1;
        top_wr_en_out <= 0;
    end
    else begin
        state <= state_n;
        top_wr_en_out <= top_wr_en_out_n;
    end
end


always @(*)begin
    state_n = state;
    top_wr_en_out_n = 1'b0;
    out_sel_out = 1'b0;
    fifo1_rd_en = 1'b0;
    fifo2_rd_en = 1'b0;

    case(state)

        // IDLE:begin
        //     
        //     if(!fifo_empty_in)begin
        //         fifo1_rd_en = 1'b1;
        //         state_n = FIFO1;
        //     end
        //
        // end
        FIFO1:begin

            out_sel_out = 1'b1;
            // top_wr_en_out = 1'b1;

            if(!voq_full_in && !fifo_empty_in)begin
                top_wr_en_out_n = 1'b1;
                fifo1_rd_en = 1'b1;
            end
            
            
            if(cut_1to2_in)begin
                state_n = FIFO2;
                fifo2_rd_en = 1'b1;
                fifo1_rd_en = 1'b0;
            end
            
        end
        FIFO2:begin

            out_sel_out = 1'b0;

            if(!voq_full_in)begin
                fifo2_rd_en = 1'b1;
                top_wr_en_out_n = 1'b1;
            end
            
            if(cut_2to1_in)begin
                state_n = FIFO1;
                fifo1_rd_en = 1'b1;
                fifo2_rd_en = 1'b0;
            end
        end
    endcase
end


endmodule
