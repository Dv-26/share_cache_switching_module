`timescale 1ns/1ns
`include "../generate_parameter.vh"

module cdc_handshake
#(
    parameter DATA_WIDTH = 32
)
(
    input   wire                        rst_n,
    input   wire                        tx_clk,
    input   wire                        rx_clk,
    
    input   wire                        tx_valid,
    input   wire    [DATA_WIDTH-1 : 0]  data_in,
    output  wire                        tx_ready,

    output  wire                        rx_valid,
    input   wire                        rx_ready,
    output  wire    [DATA_WIDTH-1 : 0]  data_out
);

reg             valid_t2r;
reg     [1:0]   valid_t2r_reg;
wire            pulse_t;

always @(posedge rx_clk or negedge rst_n)begin
    if(!rst_n)begin
        valid_t2r <= 1'b0;
        valid_t2r_reg <= 2'b0;
    end
    else begin
        valid_t2r_reg <= {valid_t2r_reg[0], tx_valid};
        valid_t2r <= valid_t2r_reg[1];
    end
end
assign pulse_t = !valid_t2r & valid_t2r_reg[1];

reg [DATA_WIDTH-1 : 0]  data_t2r;
always@(posedge rx_clk or negedge rst_n)begin
    if(!rst_n)
        data_t2r <= 0;
    else begin
        if(pulse_t)
            data_t2r <= data_in;
    end
end
assign data_out = data_t2r;

reg valid_r_reg,valid_r_n;
always@(posedge rx_clk or negedge rst_n)begin
    if(!rst_n)
        valid_r_reg <= 0;
    else begin
        valid_r_reg <= valid_r_n;
    end
end
always @(*)begin
    valid_r_n = valid_r_reg;
    if(pulse_t)
        valid_r_n = 1;
    else if(valid_r_reg & rx_ready)
        valid_r_n = 0;
end
assign rx_valid = valid_r_reg;

wire    pulse_r;
assign  pulse_r = valid_r_reg & rx_ready;

reg pulse_r_f;
wire    pulse_r_up;
always @(posedge rx_clk or negedge rst_n)begin
    if(!rst_n)
        pulse_r_f <= 1'b0;
    else
        pulse_r_f <= pulse_r_f;
end
assign pulse_r_up = !pulse_r_f & pulse_r;

reg level_r;
always @(posedge rx_clk or negedge rst_n)begin
    if(!rst_n)
        level_r <= 0;
    else
        level_r <= level_r ^ pulse_r_up;
end


wire level_r2t;
reg [1:0]   level_r2t_reg;
always@(posedge tx_clk or negedge rst_n)begin
    if(!rst_n)
        level_r2t_reg <= 2'b00;
    else
        level_r2t_reg <= {level_r2t_reg[0], level_r};
end
assign level_r2t = level_r2t_reg[1]; 

reg level_r2t_f;
wire    pulse_r2t;
always@(posedge tx_clk or negedge rst_n)begin
    if(!rst_n)
        level_r2t_f <= 1'b0;
    else
        level_r2t_f <= level_r2t;
end
assign  pulse_r2t = level_r2t_f ^ level_r2t;


assign tx_ready = pulse_r2t;
endmodule
