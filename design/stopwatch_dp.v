`timescale 1ns / 1ps


module stopwatch_dp (
    input clk,
    input rst,
    input i_runstop,
    input i_clear,

    input i_secup,
    input i_minup,
    input i_hourup,

    input watch_mode,
    
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;
    wire w_watch_tick, w_w_sec_tick, w_w_min_tick, w_w_hour_tick;
    
    wire runstop_for_tick;
    assign runstop_for_tick = watch_mode ? 1'b1: i_runstop;
    wire clear_for_counter;
    assign clear_for_counter = watch_mode ? 1'b0: i_clear;

    time_counter #(
        .BIT_WIDTH (7),
        .TIME_COUNT(100)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_clear(clear_for_counter),
        .i_increase(1'b0),
        .o_time(msec),
        .o_tick(w_sec_tick)
    );

    time_counter #(
        .BIT_WIDTH (6),
        .TIME_COUNT(60)
    ) U_SEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .i_clear(clear_for_counter),
        .i_increase(i_secup & watch_mode),
        .o_time(sec),
        .o_tick(w_min_tick)
    );

    time_counter #(
        .BIT_WIDTH (6),
        .TIME_COUNT(60)
    ) U_MIN_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .i_clear(clear_for_counter),
        .i_increase(i_minup & watch_mode),
        .o_time(min),
        .o_tick(w_hour_tick)
    );

    time_counter #(
        .BIT_WIDTH (5),
        .TIME_COUNT(24)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .i_clear(clear_for_counter),
        .i_increase(i_hourup & watch_mode),
        .o_time(hour),
        .o_tick()
    );

 

    tick_gen_100hz U_TICK_GEN_100HZ (
        .clk(clk),
        .rst(rst),
        .i_runstop(runstop_for_tick),
        .o_tick_100hz(w_tick_100hz)
    );
endmodule

module time_counter #(
    parameter BIT_WIDTH = 7,
    TIME_COUNT = 100
) (
    input                  clk,
    input                  rst,
    input                  i_tick,
    input                  i_clear,
    input                  i_increase,
    output [BIT_WIDTH-1:0] o_time,
    output                 o_tick
);
    reg [$clog2(TIME_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign o_time = count_reg;
    assign o_tick = tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst || i_clear) begin
            count_reg <= 0;
            tick_reg  <= 1'b0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next = 1'b0;  //1'b0;

        if(i_increase) begin
            if (count_reg == TIME_COUNT - 1) begin
                count_next = 0;
            end else begin
                count_next = count_reg + 1;
            end 
            tick_next  = 1'b0;   
        end

        else if (i_tick) begin
            if (count_reg == TIME_COUNT - 1) begin
                count_next = 0;
                tick_next  = 1'b1;
            end else begin
                count_next = count_reg + 1;
                tick_next  = 1'b0;
            end

        end

        
    end

endmodule


module tick_gen_100hz (
    input  clk,
    input  rst,
    input i_runstop,
    output o_tick_100hz
);
    parameter FCOUNT = 100_000_000 / 100; //100_000_000 / 100
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_tick;

    assign o_tick_100hz = r_tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            r_tick    <=1'b0;
        end else begin
            if(i_runstop == 1'b1) begin
                //true
                if (r_counter == FCOUNT - 1) begin
                    r_counter <= 0;
                    r_tick    <=1'b1;
                end else begin
                    r_counter <= r_counter + 1;
                    r_tick    <=1'b0;
                end
            end else begin
                r_counter <= r_counter;
            end
        end
    end
endmodule
