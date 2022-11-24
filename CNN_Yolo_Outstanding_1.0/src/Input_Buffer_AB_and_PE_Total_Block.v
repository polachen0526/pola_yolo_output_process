`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/31 13:37:27
// Design Name: 
// Module Name: Input_Buffer_AB_and_PE_Total_Block
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

module Input_Buffer_AB_and_PE_Total_Block #(
    parameter WORD_SIZE = 16,
    parameter OFF_TO_ON_ADDRESS_SIZE = 13 // 1156 (Dec) 484(hex) 0100 1000 0100(bin) 
    )(
    input clk,
    input rst_A,
    input rst_B,
    input ibuf_wr_A,
    input ibuf_wr_B,
	input signed [WORD_SIZE-1:0] ibuf_idata, 
	input padding_start,
	input [1:0] hw_icp_able_cacl,
	input [1:0] ibuf_iaddr_bank_sel,
	input ibuf_rd_A,
	input ibuf_rd_B,
	input [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_wr,
    input [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_rd_0,
	input [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_rd_1,
	input [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_rd_2,
    input [OFF_TO_ON_ADDRESS_SIZE-1:0] On_to_PE_addr,
    input [OFF_TO_ON_ADDRESS_SIZE-1:0] operator_length,
    input [1:0] state,
    input [1:0] next_state_bank_count,
    input [1:0] Kernel_Size,
    input weight_start,
    input [3:0] Bit_serial,
    input [3:0] Bit_serial_wait_counter,
//    output wire signed [WORD_SIZE-1:0] Data_0,
//    output wire signed [WORD_SIZE-1:0] Data_1,
    output wire signed [WORD_SIZE-1:0] Data_2,
//    output wire signed [WORD_SIZE-1:0] Data_3,
//    output wire signed [WORD_SIZE-1:0] Data_4,
    output wire signed [WORD_SIZE-1:0] Data_5,
//    output wire signed [WORD_SIZE-1:0] Data_6,
//    output wire signed [WORD_SIZE-1:0] Data_7,
    output wire signed [WORD_SIZE-1:0] Data_8
    );
    
wire signed [WORD_SIZE-1:0] q_Buffer_A_Bank_0;
wire signed [WORD_SIZE-1:0] q_Buffer_A_Bank_1;
wire signed [WORD_SIZE-1:0] q_Buffer_A_Bank_2;
wire signed [WORD_SIZE-1:0] q_Buffer_B_Bank_0;
wire signed [WORD_SIZE-1:0] q_Buffer_B_Bank_1;
wire signed [WORD_SIZE-1:0] q_Buffer_B_Bank_2;

wire signed [WORD_SIZE-1:0] choose_data_A;
wire signed [WORD_SIZE-1:0] choose_data_B;

wire [1:0] off_to_on_bank_sel;
reg  [1:0] state_bank_count;

wire signed [WORD_SIZE-1:0] fully_connect_weight_A;
wire signed [WORD_SIZE-1:0] fully_connect_weight_B;

wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_A_0;
wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_A_1;
wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_A_2;

wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_B_0;
wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_B_1;
wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_B_2;
    
Input_Buffer Input_Buffer_A(
    .clk(clk),
    .rst(rst_A),
    .wr(ibuf_wr_A),
    .Bank_addr_0(Bank_addr_A_0),
    .Bank_addr_1(Bank_addr_A_1),
    .Bank_addr_2(Bank_addr_A_2),
    .data(choose_data_A),
    .ibuf_iaddr_bank_sel(off_to_on_bank_sel),
    .rd(ibuf_rd_A),
    .q_Bank_0(q_Buffer_A_Bank_0),
    .q_Bank_1(q_Buffer_A_Bank_1),
    .q_Bank_2(q_Buffer_A_Bank_2)
    );
    
Input_Buffer Input_Buffer_B(
    .clk(clk),
    .rst(rst_B),
    .wr(ibuf_wr_B),
    .Bank_addr_0(Bank_addr_B_0),
    .Bank_addr_1(Bank_addr_B_1),
    .Bank_addr_2(Bank_addr_B_2),
    .data(choose_data_B),
    .ibuf_iaddr_bank_sel(off_to_on_bank_sel),
    .rd(ibuf_rd_B),
    .q_Bank_0(q_Buffer_B_Bank_0),
    .q_Bank_1(q_Buffer_B_Bank_1),
    .q_Bank_2(q_Buffer_B_Bank_2)
    );
    
Input_to_PE_Buffer uInput_to_PE_Buffer(
    .clk(clk),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .state(state),
    .ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),
	.Kernel_Size(Kernel_Size),
	.Bit_serial(Bit_serial),
	.Bit_serial_wait_counter(Bit_serial_wait_counter),
	.q_Buffer_A_Bank_0(q_Buffer_A_Bank_0),
    .q_Buffer_A_Bank_1(q_Buffer_A_Bank_1),
    .q_Buffer_A_Bank_2(q_Buffer_A_Bank_2),
    .q_Buffer_B_Bank_0(q_Buffer_B_Bank_0),
    .q_Buffer_B_Bank_1(q_Buffer_B_Bank_1),
    .q_Buffer_B_Bank_2(q_Buffer_B_Bank_2),
//    .Data_0(Data_0),
//    .Data_1(Data_1),
    .Data_2(Data_2),
//    .Data_3(Data_3),
//    .Data_4(Data_4),
    .Data_5(Data_5),
//    .Data_6(Data_6),
//    .Data_7(Data_7),
    .Data_8(Data_8)
);

assign choose_data_A = ((padding_start && ~ibuf_rd_A) || (Kernel_Size == 2'd1 && state_bank_count >= hw_icp_able_cacl)) ? 0 : ibuf_idata;
assign choose_data_B = ((padding_start && ~ibuf_rd_B) || (Kernel_Size == 2'd1 && state_bank_count >= hw_icp_able_cacl)) ? 0 : ibuf_idata;

always@(posedge clk) state_bank_count <= next_state_bank_count;
assign off_to_on_bank_sel = (Kernel_Size == 2'd3) ? ibuf_iaddr_bank_sel : state_bank_count;

assign Bank_addr_A_0 = (ibuf_rd_A) ? Bank_addr_rd_0 : Bank_addr_wr;
assign Bank_addr_A_1 = (ibuf_rd_A) ? Bank_addr_rd_1 : Bank_addr_wr;
assign Bank_addr_A_2 = (ibuf_rd_A) ? Bank_addr_rd_2 : Bank_addr_wr;

assign Bank_addr_B_0 = (ibuf_rd_B) ? Bank_addr_rd_0 : Bank_addr_wr;
assign Bank_addr_B_1 = (ibuf_rd_B) ? Bank_addr_rd_1 : Bank_addr_wr;
assign Bank_addr_B_2 = (ibuf_rd_B) ? Bank_addr_rd_2 : Bank_addr_wr;

endmodule
