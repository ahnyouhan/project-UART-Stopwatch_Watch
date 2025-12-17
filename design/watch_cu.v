`timescale 1ns / 1ps

// FSM
module watch_cu (
    input  clk,
    input  rst,
    input  i_secup,     // btn_U
    input  i_minup,     // btn_L
    input  i_hourup,    // btn_R
    input  mode,
    output reg o_secup,  
    output reg o_minup,    
    output reg o_hourup    
);

    // state define
    parameter WATCH = 2'b00, SECUP = 2'b01, MINUP = 2'b10, HOURUP = 2'b11;  // 0,1,2,3
    reg [1:0] c_state, n_state;  // 2 bit parameter 


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state     <= WATCH;
        end else begin
            c_state     <= n_state;
        end
    end

    // next combinational logic
    always @(*) begin
        n_state      = c_state;  // Latch X
        o_secup = 1'b0;
        o_minup = 1'b0;
        o_hourup = 1'b0;
        if(mode==1) begin
            case (c_state)
                WATCH: begin
                    if(i_secup) begin
                        n_state = SECUP;
                    end else if(i_minup) begin
                        n_state = MINUP;
                    end else if(i_hourup) begin
                        n_state = HOURUP;
                    end
                end
                SECUP: begin
                    o_secup = 1'b1;
                    n_state = WATCH;
                end
                MINUP: begin
                    o_minup = 1'b1;
                    n_state = WATCH;
                end
                HOURUP: begin
                    o_hourup = 1'b1;
                    n_state = WATCH;
                end
                default:begin
                    n_state = c_state;
                end
            endcase
        end
    end
endmodule
