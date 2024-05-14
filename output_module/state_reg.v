`include "../generate_parameter.vh"

module ctrol_bit
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire                        en,
    input   wire    [PORT_NUB-1 : 0]    set_zero,
    input   wire    [PORT_NUB-1 : 0]    emtpy_in,

    output  wire    [WIDTH_SEL-1 : 0]   sel_out,
    output  wire    [PORT_NUB-1 : 0]    ctrol_bit,
    output  wire                        done
);

localparam  PORT_NUB            =   `PORT_NUB_TOTAL;
localparam  DATA_WIDTH          =   `DATA_WIDTH;
localparam  WIDTH_SEL           =   $clog2(`PORT_NUB_TOTAL);
localparam  WIDTH_LENGTH        =   $clog2(`DATA_LENGTH_MAX);
localparam  WIDTH_PRIORITY      =   $clog2(`PRIORITY);



generate 
    genvar i;

    wire    [PORT_NUB-1 : 0]    state_bit;

    for(i=0; i<PORT_NUB; i=i+1)begin: loop1

        reg     emtpy_reg,emtpy_reg_n;
        reg     state,state_n;

        always @(posedge clk or negedge rst_n)begin
            if(!rst_n)begin
                emtpy_reg <= 1'b0;
                state <= 1'b0;
            end
            else begin
                emtpy_reg <= emtpy_reg_n;
                state <= state_n;
            end
        end

        reg     state_load;

        always @(*)begin
            state_load = 1'b0;
            emtpy_reg_n = emtpy_reg;
            if(emtpy_reg)begin
                if(set_zero[i])
                    emtpy_reg_n = 1'b0;
            end
            else begin
                if(!emtpy_in[i])begin
                    emtpy_reg_n = 1'b1;
                    state_load = 1'b1;
                end
            end
        end

        always @(*)begin
            state_n = state;
            if(state)begin
                if(state_zero[i])
                    state_n = 0;
            end
            else begin
                if(state_load)
                    state_n = 1;
            end
        end

        assign ctrol_bit[i] = emtpy_reg;
        assign state_bit[i] = state;

    end




    reg [WIDTH_SEL-1 : 0] sel_reg,sel_n;
    reg [PORT_NUB-1 : 0] state_zero,state_zero_n;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            sel_reg <= 0;
            state_zero <= 0;
        end
        else begin
            sel_reg <= sel_n;
            state_zero <= state_zero_n; 
        end
    end

    integer n;

    always @(*)begin
        sel_n = 0;
        state_zero_n = {PORT_NUB{1'b0}};
        for(n=0; n<PORT_NUB; n=n+1)begin: encode
            if(state_bit[n])begin
                sel_n = n;
                if(en)
                    state_zero_n[n] = 1'b1;
                disable encode;
            end
        end
    end


    
    assign sel_out = sel_reg;

    reg     done_reg;
    wire    done_n;

    assign done_n = &(~state_bit);

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            done_reg <= 0;
        else
            done_reg <= done_n;
    end

    assign done = done_reg;




endgenerate



endmodule
