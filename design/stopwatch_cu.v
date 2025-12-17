`timescale 1ns / 1ps

// FSM
module stopwatch_cu (
    input  clk,
    input  rst,
    input  i_runstop,  // btn_R
    input  i_clear,    // btn_L
    input  mode, //mode[1]
    output o_runstop,
    output o_clear
);

    // state define
    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;  // 0,1,2
    reg [1:0] c_state, n_state;  // 2 bit parameter 
    reg runstop_reg, runstop_next;
    reg clear_reg, clear_next;

    assign o_runstop = runstop_reg;
    assign o_clear   = clear_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state     <= STOP;
            runstop_reg <= 1'b0;
            clear_reg   <= 1'b0;
        end else begin
            c_state     <= n_state;
            runstop_reg <= runstop_next;
            clear_reg   <= clear_next;
        end
    end

    // next combinational logic
    always @(*) begin
        n_state      = c_state;  // Latch X
        runstop_next = runstop_reg;
        clear_next   = clear_reg;
        
        if(mode==0) begin
            case (c_state)
                STOP: begin
                    // moore output
                    runstop_next = 1'b0;
                    clear_next   = 1'b0;
                    // next state
                    if (i_runstop) begin
                        n_state = RUN;
                    end else if (i_clear) begin
                        n_state = CLEAR;
                    end
                end
                RUN: begin
                    runstop_next = 1'b1;
                    if (i_runstop) begin
                        n_state = STOP;
                    end
                end
                CLEAR: begin
                    clear_next = 1'b1;
                    n_state = STOP;
                end
            endcase
        end
    end

    // output logic


endmodule
