`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/28 12:59:06
// Design Name: 
// Module Name: Input_to_PE_Buffer
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
//Bitparal 8 8 Version

module Input_to_PE_Buffer#(
    parameter WORD_SIZE = 16,
    parameter THREE_WORD_SIZE = 48,
    parameter OFF_TO_ON_ADDRESS_SIZE = 13, // 1156 (Dec) 484(hex) 0100 1000 0100(bin) 
    parameter TILE_SIZE = 34,
    parameter OFF_TO_ON_ADDRESS_NUMBER = 352,
    parameter ON_TO_OFF_ADDRESS_SIZE = 10, 
    parameter ON_TO_OFF_ADDRESS_NUMBER = 900,
    parameter BANK_STATE = 2, // 00 , 01 , 10
    parameter Bank_0 = 0,
    parameter Bank_1 = 1,
    parameter Bank_2 = 2
    )(
    input clk,
    input [OFF_TO_ON_ADDRESS_SIZE-1:0] On_to_PE_addr,
    input [OFF_TO_ON_ADDRESS_SIZE-1:0] operator_length,
    input [1:0] state,
    input ibuf_rd_A,
	input ibuf_rd_B,
	input [1:0] Kernel_Size,
    input [3:0] Bit_serial,
	input [3:0] Bit_serial_wait_counter,
	
	input signed [WORD_SIZE-1:0] q_Buffer_A_Bank_0,
    input signed [WORD_SIZE-1:0] q_Buffer_A_Bank_1,
    input signed [WORD_SIZE-1:0] q_Buffer_A_Bank_2,
    
    input signed [WORD_SIZE-1:0] q_Buffer_B_Bank_0,
    input signed [WORD_SIZE-1:0] q_Buffer_B_Bank_1,
    input signed [WORD_SIZE-1:0] q_Buffer_B_Bank_2,
    
//    output reg signed [WORD_SIZE-1:0] Data_0,
//    output reg signed [WORD_SIZE-1:0] Data_1,
    output reg signed [WORD_SIZE-1:0] Data_2,
//    output reg signed [WORD_SIZE-1:0] Data_3,
//    output reg signed [WORD_SIZE-1:0] Data_4,
    output reg signed [WORD_SIZE-1:0] Data_5,
//    output reg signed [WORD_SIZE-1:0] Data_6,
//    output reg signed [WORD_SIZE-1:0] Data_7,
    output reg signed [WORD_SIZE-1:0] Data_8
    );
    
reg [1:0] state_buffer;
    ////////////////////////////////////////////////////////////////////////////////////// Output  //////////////////////////////////////////////////////////////////////////////////////
always@(posedge clk) begin
    state_buffer <= (Kernel_Size == 2'd3) ? state : 0;
end

always@(posedge clk) begin
    Data_2 <= (ibuf_rd_A == 1 && state_buffer == 2'b00 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_0 : 
              (ibuf_rd_A == 1 && state_buffer == 2'b01 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_1 : 
              (ibuf_rd_A == 1 && state_buffer == 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_2 :
              (ibuf_rd_B == 1 && state_buffer == 2'b00 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_0 :
              (ibuf_rd_B == 1 && state_buffer == 2'b01 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_1 :
              (ibuf_rd_B == 1 && state_buffer == 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_2 : Data_2 ;
             
    Data_5 <= (ibuf_rd_A == 1 && state_buffer == 2'b00 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_1 : 
              (ibuf_rd_A == 1 && state_buffer == 2'b01 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_2 : 
              (ibuf_rd_A == 1 && state_buffer == 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_0 : 
              (ibuf_rd_B == 1 && state_buffer == 2'b00 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_1 :
              (ibuf_rd_B == 1 && state_buffer == 2'b01 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_2 :
              (ibuf_rd_B == 1 && state_buffer == 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_0 :Data_5 ;
   
    Data_8 <= (ibuf_rd_A == 1 && state_buffer == 2'b00 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_2 : 
              (ibuf_rd_A == 1 && state_buffer == 2'b01 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_0 : 
              (ibuf_rd_A == 1 && state_buffer == 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_A_Bank_1 : 
              (ibuf_rd_B == 1 && state_buffer == 2'b00 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_2 :
              (ibuf_rd_B == 1 && state_buffer == 2'b01 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_0 :
              (ibuf_rd_B == 1 && state_buffer == 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) ? q_Buffer_B_Bank_1 :Data_8 ;
end
endmodule
