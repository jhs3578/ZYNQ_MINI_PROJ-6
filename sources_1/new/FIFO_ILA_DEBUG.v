`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/11 14:42:19
// Design Name: 
// Module Name: FIFO_ILA_DEBUG
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


module FIFO_ILA_DEBUG(
   input wire clk,
   input wire rstn
);
    parameter STATE_IDLE='d0;
    parameter STATE_WRITE='d1;
    parameter STATE_READ='d2;
    
    parameter CLK_FREQ=50_000_000;//input clk 50m
    
    reg [31:0]counter_reg;
    reg [3:0]system_state_reg;
    reg [9:0]state_timeout_reg;
    
    reg [7:0]write_data_reg;
    (* mark_debug = "true", keep = "true" *)
    wire[7:0] read_data;
    (* mark_debug = "true", keep = "true" *)
    wire [7:0]write_data;
    reg read_en_reg;
    reg write_en_reg;
    (* mark_debug = "true", keep = "true" *)
    wire is_write_read_flag;
    (* mark_debug = "true", keep = "true" *)
    wire fifo_full;
    (* mark_debug = "true", keep = "true" *)
    wire fifo_empty;

    //wire [24:0]ila_probe0;
    (* mark_debug = "true", keep = "true" *)
    wire read_en;
    (* mark_debug = "true", keep = "true" *)
    wire write_en;
    (* mark_debug = "true", keep = "true" *)
    wire [3:0]system_state;
    
    assign read_en=read_en_reg;
    assign write_en=write_en_reg;
    assign system_state=system_state_reg;
    assign write_data[7:0]=write_data_reg[7:0];
    assign is_write_read_flag=(system_state[3:0]==STATE_IDLE)?'b0:'b1;   
    
    //always block ,1s triger onece to read write
    always@(posedge clk or negedge rstn)begin
        if(rstn=='b0)begin
            counter_reg<='b0;
        end
        else begin
            if(counter_reg<(CLK_FREQ-'b1))counter_reg<=counter_reg+'b1;
            else counter_reg<='b0; 
        end
    end
   //state machine
    always@(posedge clk or negedge rstn)begin
        if(rstn=='b0)begin
            system_state_reg<='b0;
            state_timeout_reg<='b0;
        end
        else begin
           if(counter_reg==(CLK_FREQ-'b1))begin
                system_state_reg<=STATE_WRITE;
                state_timeout_reg<='b0;
           end
           else begin
                if(system_state_reg==STATE_WRITE)begin//write fifo state
                    if(state_timeout_reg<'d256)state_timeout_reg<=state_timeout_reg+'b1;
                    else begin
                         state_timeout_reg<='b0;
                         system_state_reg<=STATE_READ;
                    end
                end
                else  if(system_state_reg==STATE_READ)begin//read fifo state
                    if(state_timeout_reg<'d256)state_timeout_reg<=state_timeout_reg+'b1;
                    else begin
                         state_timeout_reg<='b0;
                         system_state_reg<=STATE_IDLE;
                    end
                end
           end
        end
    end   
   //write read logic generate
    always@(posedge clk or negedge rstn)begin
        if(rstn=='b0)begin
            write_data_reg<='b0;
        end
        else begin
            if(system_state_reg==STATE_WRITE)begin
                write_data_reg<=write_data_reg+'b1;
                read_en_reg='b0;
                write_en_reg<='b1;
            end
            else  if(system_state_reg==STATE_READ)begin
                write_data_reg<='b0;
                read_en_reg='b1;
                write_en_reg='b0;
            end
            else if(system_state_reg==STATE_IDLE)begin
                write_data_reg<='b0;
                read_en_reg='b0;
                write_en_reg='b0;
            end
        end
    end
    
    fifo_generator_0 fifo_generator_0_inst
    (
    .clk(clk),
    .srst(~rstn),
    .din(write_data),
    .wr_en(write_en),
    .rd_en(read_en),
    .dout(read_data),
    .full(fifo_full),
    .empty(fifo_empty)
    );
endmodule
