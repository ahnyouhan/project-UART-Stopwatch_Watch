`timescale 1ns / 1ps

module uart_sw_watch (
    input        clk,
    input        rst,
    input        btn_L,
    input        btn_R,
    input        btn_U,
    input        btn_D,
    input  [1:0] mode,
    input        rx,
    output       tx,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire [7:0] w_rx_fifo_popdata;
    wire       w_rx_trigger;
    wire       w_cmd_runstop;
    wire       w_cmd_clear;
    wire       w_cmd_secup;
    wire       w_cmd_minup;
    wire       w_cmd_hourup;
    wire       w_cmd_mode0;
    wire       w_cmd_mode0_trigger;
    wire       w_cmd_mode1;
    wire       w_cmd_mode1_trigger;


    uart_top U_UART_TOP (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx),
        .rx_fifo_popdata(w_rx_fifo_popdata),
        .rx_trigger(w_rx_trigger)
    );

    command_decoder U_CMD_DEC (
        .clk(clk),
        .rst(rst),
        .rx_fifo_popdata(w_rx_fifo_popdata),
        .rx_trigger(w_rx_trigger),
        .i_mode(mode),
        .o_runstop(w_cmd_runstop),
        .o_clear(w_cmd_clear),
        .o_secup(w_cmd_secup),
        .o_minup(w_cmd_minup),
        .o_hourup(w_cmd_hourup),
        .o_mode0(w_cmd_mode0),
        .o_mode0_trigger(w_cmd_mode0_trigger),
        .o_mode1(w_cmd_mode1),
        .o_mode1_trigger(w_cmd_mode1_trigger)
    );

    stopwatch U_STOPWATCH (
        .clk(clk),
        .rst(rst),
        .btn_L(btn_L),
        .btn_R(btn_R),
        .btn_U(btn_U),
        .btn_D(btn_D),
        .cmd_runstop(w_cmd_runstop),
        .cmd_clear(w_cmd_clear),
        .cmd_secup(w_cmd_secup),
        .cmd_minup(w_cmd_minup),
        .cmd_hourup(w_cmd_hourup),
        .cmd_digit_mode(w_cmd_mode0),
        .cmd_mode0_trigger(w_cmd_mode0_trigger),
        .cmd_watch_mode(w_cmd_mode1),
        .cmd_mode1_trigger(w_cmd_mode1_trigger),
        .mode(mode),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


endmodule

module command_decoder (
    input        clk,
    input        rst,
    input  [7:0] rx_fifo_popdata,
    input        rx_trigger,
    input  [1:0] i_mode,
    output       o_runstop,
    output       o_clear,
    output       o_secup,
    output       o_minup,
    output       o_hourup,
    output       o_mode0,
    output       o_mode0_trigger,
    output       o_mode1,
    output       o_mode1_trigger
);

    reg runstop_reg, runstop_next;
    reg clear_reg, clear_next;
    reg secup_reg, secup_next;
    reg minup_reg, minup_next;
    reg hourup_reg, hourup_next;
    reg mode0_reg, mode0_next;
    reg mode0_trigger_reg, mode0_trigger_next;
    reg mode1_reg, mode1_next;
    reg mode1_trigger_reg, mode1_trigger_next;

    assign o_runstop = runstop_reg;
    assign o_clear = clear_reg;
    assign o_secup = secup_reg;
    assign o_minup = minup_reg;
    assign o_hourup = hourup_reg;
    assign o_mode0 = mode0_reg;
    assign o_mode0_trigger = mode0_trigger_reg;
    assign o_mode1 = mode1_reg;
    assign o_mode1_trigger = mode1_trigger_reg;

    reg  mode0_prev, mode1_prev;
    wire mode0_sw_trigger, mode1_sw_trigger;

    assign mode0_sw_trigger = (i_mode[0] != mode0_prev);
    assign mode1_sw_trigger = (i_mode[1] != mode1_prev);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mode0_prev <= 0;
            mode1_prev <=0;
        end
        else begin
            mode0_prev <= i_mode[0];
            mode1_prev <= i_mode[1];
        end
    end


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            runstop_reg  <= 0;
            clear_reg    <= 0;
            secup_reg    <= 0;
            minup_reg    <= 0;
            hourup_reg   <= 0;
            mode0_reg    <= 0;
            mode0_trigger_reg <=0;
            mode1_reg<=0;
            mode1_trigger_reg <=0;
        end else begin
            runstop_reg <= runstop_next;
            clear_reg <= clear_next;
            secup_reg <= secup_next;
            minup_reg <= minup_next;
            hourup_reg <= hourup_next;
            mode0_reg <= mode0_next;
            mode0_trigger_reg <= mode0_trigger_next;
            mode1_reg <= mode1_next;
            mode1_trigger_reg <= mode1_trigger_next;
        end
    end

    always @(*) begin

        runstop_next = 1'b0;
        clear_next = 1'b0;
        secup_next = 1'b0;
        minup_next = 1'b0;
        hourup_next = 1'b0;
        mode0_next = mode0_reg;
        mode0_trigger_next = mode0_trigger_reg;
        mode1_next = mode1_reg;
        mode1_trigger_next = mode1_trigger_reg;

        if (rx_trigger) begin
            case (rx_fifo_popdata)
                8'h72: runstop_next = 1'b1;  // 'r'
                8'h63: clear_next = 1'b1;  // 'c'
                8'h53: secup_next = 1'b1;  // 'S' sec up
                8'h4D: minup_next = 1'b1;  // 'M' min up
                8'h48: hourup_next = 1'b1;  // 'H' hour up
                8'h6E: begin
                    mode0_trigger_next = 1'b1;
                    mode0_next = ~mode0_reg;  // 'n' digit switch
                end
                8'h6D: begin
                    mode1_trigger_next = 1'b1;
                    mode1_next = ~mode1_reg;
                end
            endcase
        end else if (mode0_sw_trigger) begin
            mode0_trigger_next = 1'b1;
            mode0_next = i_mode[0];
        end else if (mode1_sw_trigger) begin
            mode1_trigger_next = 1'b1;
            mode1_next = i_mode[1];
        end




    end



endmodule

