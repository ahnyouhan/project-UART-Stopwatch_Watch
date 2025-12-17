`timescale 1ns / 1ps


module fnd_controller (
    input         clk,
    input         reset,
    input  [23:0] i_time, // i_time[6:0], msec 7 , sec 6, min 6, hour 5
    input         mode,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data
);
    wire [3:0] w_bcd, w_dot_data;
    wire [3:0] w_msec_sec, w_min_hour; // { msec,sec / min, hour }
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [2:0] w_sel;
    wire w_clk_1khz;
    

    clk_div_1khz U_CLK_DIV_1KHZ (
        .clk(clk),
        .reset(reset),
        .o_clk_1khz(w_clk_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk(w_clk_1khz),  // clock
        .reset(reset),  // reset
        .sel(w_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .sel(w_sel[1:0]),
        .fnd_com(fnd_com)
    );


    digit_splitter #(
        .BIT_WIDTH(5)
    ) U_HOUR_DS(
        .count_data(i_time[23:19]),
        .digit_1(w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_MIN_DS(
        .count_data(i_time[18:13]),
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10)
    );


    digit_splitter #(
        .BIT_WIDTH(6)
    ) U_SEC_DS(
        .count_data(i_time[12:7]),
        .digit_1(w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

     digit_splitter #(
        .BIT_WIDTH(7)
    ) U_MSEC_DS(
        .count_data(i_time[6:0]),
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    mux_2x1 U_Mux_2x1(
        .sel(mode),
        .bcd_1(w_msec_sec), // msec,sec
        .bcd_2(w_min_hour), // min, hour
        .bcd(w_bcd)
    );



    comparator_msec U_COMP_DOT(
        .msec(i_time[6:0]),
        .dot_data(w_dot_data)
    );

    mux_8x1 U_Mux_8x1_MIN_HOUR(
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10),
        .digit_100(w_hour_digit_1),
        .digit_1000(w_hour_digit_10),
        .digit_5(4'hf),
        .digit_6(4'hf),
        .digit_7(w_dot_data),  // digit dot display
        .digit_8(4'hf),
        .sel(w_sel),
        .bcd(w_min_hour)
    );

    mux_8x1 U_Mux_8x1_MSEC_SEC(
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10),
        .digit_100(w_sec_digit_1),
        .digit_1000(w_sec_digit_10),
        .digit_5(4'hf),
        .digit_6(4'hf),
        .digit_7(w_dot_data),  // digit dot display
        .digit_8(4'hf),
        .sel(w_sel),
        .bcd(w_msec_sec)
    );
    bcd_decoder U_BCD_DECODER (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );
endmodule

module clk_div_1khz (
    input  clk,
    input  reset,
    output o_clk_1khz
);
    //counter 100_000
    // $clog2 는 system 에서 제공하는 task
    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk_1khz;
    assign o_clk_1khz = r_clk_1khz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter  <= 0;
            r_clk_1khz <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter  <= 0;
                r_clk_1khz <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk_1khz <= 1'b0;
            end

        end

    end

endmodule


module counter_8 (
    input        clk,    // clock
    input        reset,  // reset
    output [2:0] sel
);
    reg [2:0] counter;
    assign sel = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            // initial
            counter <= 0;
        end else begin
            // operation
            counter <= counter + 1;
        end
    end

endmodule

module decoder_2x4 (
    input  [1:0] sel,
    output [3:0] fnd_com
);

    assign fnd_com = (sel==2'b00) ? 4'b1110:
                    (sel==2'b01) ? 4'b1101:
                    (sel==2'b10) ? 4'b1011:
                    (sel==2'b11) ? 4'b0111:4'b1111;

endmodule

module comparator_msec (
    input  [6:0] msec,
    output [3:0] dot_data
);

    assign dot_data = (msec < 50) ? 4'hf : 4'he;
    
endmodule


module mux_2x1(
    input  sel,
    input  [3:0] bcd_1, // msec,min 
    input  [3:0] bcd_2, // min, hour
    output [3:0] bcd

);
    assign bcd = sel? bcd_1:bcd_2;
    
endmodule



module mux_8x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [3:0] digit_5,
    input  [3:0] digit_6,
    input  [3:0] digit_7,  // digit dot display
    input  [3:0] digit_8,
    input  [2:0] sel,
    output [3:0] bcd
);
    reg [3:0] r_bcd;
    assign bcd = r_bcd;
    always @(*) begin
        case (sel)
            3'b000:   r_bcd = digit_1;
            3'b001:   r_bcd = digit_10;
            3'b010:   r_bcd = digit_100;
            3'b011:   r_bcd = digit_1000;
            3'b100:   r_bcd = digit_5;
            3'b101:   r_bcd = digit_6;
            3'b110:   r_bcd = digit_7;
            3'b111:   r_bcd = digit_8;
            default: r_bcd = digit_1;
        endcase
    end

endmodule

    

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] count_data,
    output [          3:0] digit_1,
    output [          3:0] digit_10

);
    assign digit_1  = count_data % 10;
    assign digit_10 = (count_data / 10) % 10;

endmodule

module bcd_decoder (
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);

    always @(bcd) begin
        case (bcd)
            4'b0000: fnd_data = 8'hc0;
            4'b0001: fnd_data = 8'hF9;
            4'b0010: fnd_data = 8'hA4;
            4'b0011: fnd_data = 8'hB0;
            4'b0100: fnd_data = 8'h99;
            4'b0101: fnd_data = 8'h92;
            4'b0110: fnd_data = 8'h82;
            4'b0111: fnd_data = 8'hF8;
            4'b1000: fnd_data = 8'h80;
            4'b1001: fnd_data = 8'h90;

            4'b1010: fnd_data = 8'h88;
            4'b1011: fnd_data = 8'h83;
            4'b1100: fnd_data = 8'hc6;
            4'b1101: fnd_data = 8'ha1;

            4'b1110: fnd_data = 8'h7f;  // only dot display
            4'b1111: fnd_data = 8'hff;  // all off

            default: fnd_data = 8'hff;
        endcase

    end

endmodule
