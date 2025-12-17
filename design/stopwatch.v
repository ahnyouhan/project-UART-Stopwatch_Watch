`timescale 1ns / 1ps

module stopwatch (
    input        clk,
    input        rst,
    input        btn_L,
    input        btn_R,
    input        btn_U,
    input        btn_D,
    input        cmd_runstop,
    input        cmd_clear,
    input        cmd_secup,
    input        cmd_minup,
    input        cmd_hourup,
    input        cmd_digit_mode,
    input        cmd_mode0_trigger,
    input        cmd_watch_mode,
    input        cmd_mode1_trigger,
    input  [1:0] mode,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    wire [6:0] w_watch_msec;
    wire [5:0] w_watch_sec;
    wire [5:0] w_watch_min;
    wire [4:0] w_watch_hour;

    wire w_runstop, w_clear;
    wire w_secup, w_minup, w_hourup;
    wire w_increase;
    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire [23:0] w_time_data;
    wire w_cmd_mode0_trigger, w_cmd_mode1_trigger;
    wire digit_mode, watch_mode;
    

    assign w_cmd_mode0_trigger = cmd_mode0_trigger;
    assign digit_mode = w_cmd_mode0_trigger ? cmd_digit_mode :mode[0];

    assign w_cmd_mode1_trigger = cmd_mode1_trigger;
    assign watch_mode = w_cmd_mode1_trigger ? cmd_watch_mode: mode[1];

    

    button_debounce U_BD_R_RUNSTOP(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_R),
        .o_btn(w_btn_R)
    );

    button_debounce U_BD_L_CLEAR_MINUP(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_L),
        .o_btn(w_btn_L)
    );

    button_debounce U_BD_U_SECUP(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_U),
        .o_btn(w_btn_U)
    );

    button_debounce U_BD_D_HOURUP(
        .clk(clk),
        .rst(rst),
        .i_btn(btn_D),
        .o_btn(w_btn_D)
    );

    stopwatch_dp U_SW_DP (
        .clk (clk),
        .rst (rst),
        .i_runstop(w_runstop & ~mode[1]),
        .i_clear(w_clear),
        .i_secup(1'b0),
        .i_minup(1'b0),
        .i_hourup(1'b0),
        .watch_mode(1'b0),
        .msec(w_msec),
        .sec (w_sec),
        .min (w_min),
        .hour (w_hour)
    );

    stopwatch_cu U_SW_CU (
        .clk(clk),
        .rst(rst),
        .i_runstop(w_btn_R | cmd_runstop),
        .i_clear(w_btn_L | cmd_clear),
        .mode(mode[1]),
        .o_runstop(w_runstop),
        .o_clear(w_clear)
    );


    stopwatch_dp U_WATCH_DP (
        .clk (clk),
        .rst (rst),
        .i_runstop(1'b1),
        .i_clear(1'b0),
        .i_secup(w_secup),
        .i_minup(w_minup),
        .i_hourup(w_hourup),
        .watch_mode(1'b1),
        .msec(w_watch_msec),
        .sec (w_watch_sec),
        .min (w_watch_min),
        .hour (w_watch_hour)
    );

    watch_cu U_WATCH_CU(
        .clk(clk),
        .rst(rst),
        .i_secup(w_btn_U | cmd_secup),     // btn_U
        .i_minup(w_btn_L | cmd_minup),     // btn_L
        .i_hourup(w_btn_D | cmd_hourup),    // btn_D
        .mode(mode[1]),
        .o_secup(w_secup),  
        .o_minup(w_minup),    
        .o_hourup(w_hourup)    
);


    mux_2x1_time U_SW_W_MODE(
        .sel(watch_mode),
        .sw_time({w_hour, w_min, w_sec, w_msec}),
        .watch_time({w_watch_hour, w_watch_min, w_watch_sec, w_watch_msec}),
        .time_data(w_time_data)
    );

    fnd_controller U_FND_CTRL (
        .clk(clk),
        .reset(rst),
        .i_time(w_time_data),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .mode(digit_mode)
    );
endmodule

module mux_2x1_time (
    input   sel,
    input  [23:0] sw_time,
    input  [23:0] watch_time,
    output [23:0] time_data

);
    assign time_data = (sel==0) ? sw_time : watch_time;
    
endmodule

