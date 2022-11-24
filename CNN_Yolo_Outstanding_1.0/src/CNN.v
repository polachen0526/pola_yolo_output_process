`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/15 15:06:24
// Design Name: 
// Module Name: CNN
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
// Bitparal 8 8 Version

module CNN #(
    parameter WORD_SIZE = 16,
    parameter OUT_WORD_SIZE = 36,
    parameter INTEGER = 32,
    parameter EIGHT_WORD_SIZE = 128,
    parameter OFF_TO_ON_ADDRESS_SIZE = 13, // 1156 (Dec) 484(hex) 0100 1000 0100(bin) 
    parameter ON_TO_OFF_ADDRESS_SIZE = 10,
    
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_M_AXI_ID_WIDTH	    = 1,
    parameter C_M_AXI_ADDR_WIDTH	= 32,
    parameter C_M_AXI_DATA_WIDTH	= 128,
    parameter C_M_AXI_AWUSER_WIDTH	= 1,
    parameter C_M_AXI_ARUSER_WIDTH	= 1,
    parameter C_M_AXI_WUSER_WIDTH	= 1,
    parameter C_M_AXI_RUSER_WIDTH	= 1,
    parameter C_M_AXI_BUSER_WIDTH	= 1
) /*(
    input       clk,
    input       rst_A,
    input       rst_B,
    
    output reg  ready_A,
    output reg  ready_B,
    input       start_A,
    input       start_B,
    input start,
    input [2:0] bits,
    output reg Compute_Finish_A,
    output reg Compute_Finish_B,
	//Input Buffer
	output wire ibuf_wr_A,
	output wire ibuf_wr_B,
	input [INTEGER-1:0] first_addr,
	output wire [INTEGER-1:0] off_to_on_ibuf_iaddr,
	
	input [EIGHT_WORD_SIZE-1:0] ibuf_idata,
	input [5:0] tile_size,
	
    input Maxpooling,
    input Accumulate, // 0 : no accumulate with other output buffer 1 : need to accumulate  
    input [1:0] Activation, // 0 : no activation function 1 : relu 2 : lic_relu  else : no activation
    input Batch_Act_Select, // 0 : Batch before Activation 1 : Activation before Batch
    // If don't need batch , just set Batch_weight as 16'h0800 and Batch_bias as 16'h0000
    input signed [WORD_SIZE-1:0] Batch_weight,
    input signed [WORD_SIZE-1:0] Batch_bias,
	input [1:0] Bit_serial
    );*/
(
    input                                    S_AXI_ACLK,    // use M_AXI_ACLK
    output                                   IRQ,

    input                                    s_axi_start,
    input   [C_S_AXI_DATA_WIDTH-1:0]         s_axi_inst_0,
    input   [C_S_AXI_DATA_WIDTH-1:0]         s_axi_inst_1,
    input   [C_S_AXI_DATA_WIDTH-1:0]         s_axi_inst_2,
    input   [C_S_AXI_DATA_WIDTH-1:0]         s_axi_inst_3,
    input   [C_S_AXI_DATA_WIDTH-1:0]         s_axi_inst_4,
        
    output                                   s_axi_Rerror,            //Trigger IRQ if error
    output  [C_S_AXI_DATA_WIDTH-1:0]         s_axi_Rerror_addr,
    output  [1 : 0]                          s_axi_Werror,            //Trigger IRQ if error
    output  [C_S_AXI_DATA_WIDTH-1:0]         s_axi_Werror_addr,
        // M_AXI-Full
    input                                    M_AXI_ACLK,
    input                                    M_AXI_ARESETN,
        //----------------------------------------------------------------------------------
        //  (AW) Channel
        //----------------------------------------------------------------------------------
    input                                    M_AXI_AWREADY,
    output  [C_M_AXI_ID_WIDTH-1 : 0]         M_AXI_AWID,     //Unused
    output  [C_M_AXI_ADDR_WIDTH-1 : 0]       M_AXI_AWADDR,   
    output  [7 : 0]                          M_AXI_AWLEN,
    output  [2 : 0]                          M_AXI_AWSIZE,   //Unused
    output  [1 : 0]                          M_AXI_AWBURST,  //Unused
    output                                   M_AXI_AWLOCK,   //Unused
    output  [3 : 0]                          M_AXI_AWCACHE,  //Unused
    output  [2 : 0]                          M_AXI_AWPROT,   //Unused
    output  [3 : 0]                          M_AXI_AWQOS,    //Unused
    output  [C_M_AXI_AWUSER_WIDTH-1 : 0]     M_AXI_AWUSER,   //Unused
    output                                   M_AXI_AWVALID,

        //----------------------------------------------------------------------------------
        //  (W) Channel
        //----------------------------------------------------------------------------------
    input                                    M_AXI_WREADY,
    output  [C_M_AXI_DATA_WIDTH-1 : 0]       M_AXI_WDATA,
    output  [C_M_AXI_DATA_WIDTH/8-1 : 0]     M_AXI_WSTRB,
    output                                   M_AXI_WLAST,
    output  [C_M_AXI_WUSER_WIDTH-1 : 0]      M_AXI_WUSER,    //Unused
    output                                   M_AXI_WVALID,

        //----------------------------------------------------------------------------------
        //  (B) Channel
        //----------------------------------------------------------------------------------
    input  [C_M_AXI_ID_WIDTH-1 : 0]          M_AXI_BID,      //Unused
    input  [1 : 0]                           M_AXI_BRESP,
    input  [C_M_AXI_BUSER_WIDTH-1 : 0]       M_AXI_BUSER,    //Unused
    input                                    M_AXI_BVALID,
    output                                   M_AXI_BREADY,
        //----------------------------------------------------------------------------------
        //  (AR) Channel
        //----------------------------------------------------------------------------------
    input                                    M_AXI_ARREADY, // ready
    output  [C_M_AXI_ID_WIDTH-1 : 0]         M_AXI_ARID,    //0
    output  wire [C_M_AXI_ADDR_WIDTH-1 : 0]  M_AXI_ARADDR,  // addr
    output  wire [7 : 0]                     M_AXI_ARLEN,   // 128 bits
    output  [2 : 0]                          M_AXI_ARSIZE,
    output  [1 : 0]                          M_AXI_ARBURST,
    output                                   M_AXI_ARLOCK,
    output  [3 : 0]                          M_AXI_ARCACHE,
    output  [2 : 0]                          M_AXI_ARPROT,
    output  [3 : 0]                          M_AXI_ARQOS,
    output  [C_M_AXI_ARUSER_WIDTH-1 : 0]     M_AXI_ARUSER,
    output  wire                             M_AXI_ARVALID, // same as ready, but just for one cycle

        //----------------------------------------------------------------------------------
        //  (R) Channel
        //----------------------------------------------------------------------------------
    input  [C_M_AXI_ID_WIDTH-1 : 0]          M_AXI_RID,     //
    input  [C_M_AXI_DATA_WIDTH-1 : 0]        M_AXI_RDATA,   //Dram -> Sram Data
    input  [1 : 0]                           M_AXI_RRESP,   // feedback good or bad
    input                                    M_AXI_RLAST,   // last value
    input  [C_M_AXI_RUSER_WIDTH-1 : 0]       M_AXI_RUSER,
    input                                    M_AXI_RVALID,  // when valid is High , read data is effective
    output wire                              M_AXI_RREADY,   // ready to start reading

    output      [1:0]                       DEBUG_INPUT_state,
                                            DEBUG_INPUT_start_valid_buffer,
    output      [2:0]                       DEBUG_INPUT_state_input_ctrl,
    output  reg [31:0]                      HARDWARE_VERSION,
    output  reg                             DEBUG_Master_Output_Finish,
                                            DEBUG_Compute_Finish,
                                            DEBUG_For_State_Finish,
                                            DEBUG_Pad_Start_OBUF_FINISH,
                                            DEBUG_CONV_FLAG,
                                            DEBUG_IRQ_TO_MASTER_CTRL,
                                            DEBUG_have_pool_ing,
                                            DEBUG_ready_A,
                                            DEBUG_ready_B,
                                            DEBUG_start_A,
                                            DEBUG_start_B,
    output       [1:0]                      DEBUG_obuf_state,
                                            DEBUG_obuf_pool_s,
                                            DEBUG_obuf_finish_state,
    output  reg                             DEBUG_obuf_rst
    );

wire [OFF_TO_ON_ADDRESS_SIZE-1:0] ibuf_iaddr;
reg ibuf_rd_A,ibuf_rd_B,ibuf_rd_A_buffer,ibuf_rd_B_buffer;
wire [OFF_TO_ON_ADDRESS_SIZE-1:0] On_to_PE_addr;
wire [OFF_TO_ON_ADDRESS_SIZE-1:0] operator_length;
wire [1:0] ibuf_iaddr_bank_sel;

//---------------------------------------- Block space 0
wire signed [WORD_SIZE-1:0] PE_0_Data_0,PE_0_Data_1,PE_0_Data_2;
wire signed [WORD_SIZE-1:0] PE_0_Data_3,PE_0_Data_4,PE_0_Data_5;
wire signed [WORD_SIZE-1:0] PE_0_Data_6,PE_0_Data_7,PE_0_Data_8;

//---------------------------------------- Block space 1
wire signed [WORD_SIZE-1:0] PE_1_Data_0,PE_1_Data_1,PE_1_Data_2;
wire signed [WORD_SIZE-1:0] PE_1_Data_3,PE_1_Data_4,PE_1_Data_5;
wire signed [WORD_SIZE-1:0] PE_1_Data_6,PE_1_Data_7,PE_1_Data_8;

//---------------------------------------- Block space 2
wire signed [WORD_SIZE-1:0] PE_2_Data_0,PE_2_Data_1,PE_2_Data_2;
wire signed [WORD_SIZE-1:0] PE_2_Data_3,PE_2_Data_4,PE_2_Data_5;
wire signed [WORD_SIZE-1:0] PE_2_Data_6,PE_2_Data_7,PE_2_Data_8;

//---------------------------------------- Block space 3
wire signed [WORD_SIZE-1:0] PE_3_Data_0,PE_3_Data_1,PE_3_Data_2;
wire signed [WORD_SIZE-1:0] PE_3_Data_3,PE_3_Data_4,PE_3_Data_5;
wire signed [WORD_SIZE-1:0] PE_3_Data_6,PE_3_Data_7,PE_3_Data_8;

//---------------------------------------- Block space 4
wire signed [WORD_SIZE-1:0] PE_4_Data_0,PE_4_Data_1,PE_4_Data_2;
wire signed [WORD_SIZE-1:0] PE_4_Data_3,PE_4_Data_4,PE_4_Data_5;
wire signed [WORD_SIZE-1:0] PE_4_Data_6,PE_4_Data_7,PE_4_Data_8;

//---------------------------------------- Block space 5
wire signed [WORD_SIZE-1:0] PE_5_Data_0,PE_5_Data_1,PE_5_Data_2;
wire signed [WORD_SIZE-1:0] PE_5_Data_3,PE_5_Data_4,PE_5_Data_5;
wire signed [WORD_SIZE-1:0] PE_5_Data_6,PE_5_Data_7,PE_5_Data_8;

//---------------------------------------- Block space 6
wire signed [WORD_SIZE-1:0] PE_6_Data_0,PE_6_Data_1,PE_6_Data_2;
wire signed [WORD_SIZE-1:0] PE_6_Data_3,PE_6_Data_4,PE_6_Data_5;
wire signed [WORD_SIZE-1:0] PE_6_Data_6,PE_6_Data_7,PE_6_Data_8;

//---------------------------------------- Block space 7
wire signed [WORD_SIZE-1:0] PE_7_Data_0,PE_7_Data_1,PE_7_Data_2;
wire signed [WORD_SIZE-1:0] PE_7_Data_3,PE_7_Data_4,PE_7_Data_5;
wire signed [WORD_SIZE-1:0] PE_7_Data_6,PE_7_Data_7,PE_7_Data_8;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//---------------------------------------- Block  fully_connect_weight
wire signed [WORD_SIZE-1:0] fully_connect_weight_0,fully_connect_weight_1,fully_connect_weight_2;
wire signed [WORD_SIZE-1:0] fully_connect_weight_3,fully_connect_weight_4,fully_connect_weight_5;
wire signed [WORD_SIZE-1:0] fully_connect_weight_6,fully_connect_weight_7;

wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_wr_0,Bank_addr_wr_1,Bank_addr_wr_2;
wire [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_rd_0,Bank_addr_rd_1,Bank_addr_rd_2;
wire [1:0] state,next_state_bank_count,State_Bank_sel,hw_icp_able_cacl_to_input;
wire Maxpooling_buffer;

//////////////////////////////////////////////////////////AB Buffer Control ///////////////////////////////////////////////////////////////////////////
wire rst_A,rst_B;
wire ready_A,ready_B;
wire start_A,start_B;
reg Compute_Finish_A,Compute_Finish_B;
wire For_State_Finish;
//reg Compute_Finish;
wire Compute_Finish;
wire Master_Output_Finish;
wire ibuf_wr_A,ibuf_wr_B;
wire Input_Buffer_to_PE_Ctrl_rst;
wire obuf_ctrl_rst,Choose_Weight_buf;
wire weight_buffer_start;
wire[C_M_AXI_DATA_WIDTH-1:0] weight_buffer_data,Output_data;
wire obuffer_init;
wire [15:0] oc_addr_x, oc_addr_y;
wire On_to_PE_buffer_sel,IRQ_TO_MASTER_CTRL;

wire [C_S_AXI_DATA_WIDTH-1:0] Input_Address;
wire [C_S_AXI_DATA_WIDTH-1:0] Weight_Address;
wire [C_S_AXI_DATA_WIDTH-1:0] Output_Address;
wire [C_S_AXI_DATA_WIDTH-1:0] Pooling_Address;
wire Is_Final_Tile;
wire Have_Accumulate;
wire Is_Last_Channel;
wire Pad_Start_OBUF_FINISH;
wire weight_rst_A,weight_rst_B,off_to_on_valid_A,off_to_on_valid_B;
wire [3:0] type;
wire Reload;


//////////////////////////////////////////////////////////////////////////////////////////////////////LAYER INSTRUCTION//////////////////////////////////////////////////////////////////////////////////////////////////////
// wire [C_S_AXI_DATA_WIDTH-1:0] Instruction_Address = 0;
// wire [7:0] Instruction_Number = 0;
// wire [7:0] Output_Tile_Number = 0;
// wire [5:0] quant_obuf = 11;
// wire [5:0] quant_word_size = 0;
// wire [5:0] quant_batch = 11;
// wire [5:0] quant_finish = 0;
// wire [5:0] quant_batch_bias = 11;
// wire [5:0] Input_Tile_Size = 34;
// wire [5:0] Output_Tile_Size = 0;
// wire [1:0] Kernel_Size = 3;
// wire [1:0] Stride = 2;
// wire [1:0] Padding_Size = 0;
// wire [1:0] Maxpooling_Size = 2;
// wire [1:0] Maxpooling_Stride = 2;
// wire [2:0] Bit_Serial = 0;
// wire Batch_First = 0;
// wire Have_Pooling = 0;
// wire Have_Batch = 0;
// wire Have_ReLU = 0;
// wire Is_LeakyReLU = 0;

wire [C_S_AXI_DATA_WIDTH-1:0] Instruction_Address;
wire [11:0] Instruction_Number;
wire [5:0] quant_obuf ;
wire [5:0] quant_word_size;
wire [5:0] quant_finish;
wire [5:0] pool_quant_finish;
wire [5:0] quant_batch_bias ;
wire [1:0] Kernel_Size;
wire [1:0] Stride;
wire [1:0] Maxpooling_Size;
wire [1:0] Maxpooling_Stride;
wire [3:0] Bit_Serial;
wire [3:0] Bit_Serial_test;
wire [3:0] Bit_serial_wait_counter;
wire [11:0] input_feature_offset;
wire [11:0] output_Feature_offset;
assign Bit_Serial_test = 0 ;
wire Batch_First;
wire Have_maxpooling,have_pool_ing;
wire Have_Batch;
wire Have_ReLU;
wire Is_LeakyReLU;
wire Is_Upsample;
wire [15:0] leaky_constant;
wire start_buffer_to_obuf_chip,padding_start,On_to_PE_finish;
reg s_axi_start_buffer;
wire [1:0] CONV_FLAG;
wire Concat_Output_Control;
wire [5:0] Input_Tile_Size_row,Input_Tile_Size_col;
wire [1:0] hw_icp_able_cacl,hw_ocp_able_cacl;

    
always @ ( posedge M_AXI_ACLK ) begin
    HARDWARE_VERSION <= 32'h2021_10_24;             
    DEBUG_Master_Output_Finish      <= Master_Output_Finish;                 
    DEBUG_Compute_Finish            <= Compute_Finish;             
    DEBUG_For_State_Finish          <= For_State_Finish;             
    DEBUG_Pad_Start_OBUF_FINISH     <= Pad_Start_OBUF_FINISH;       
    DEBUG_CONV_FLAG                 <= CONV_FLAG;     
    DEBUG_IRQ_TO_MASTER_CTRL        <= IRQ_TO_MASTER_CTRL;                 
    DEBUG_have_pool_ing             <= have_pool_ing;         
    DEBUG_ready_A                   <= ready_A;
    DEBUG_ready_B                   <= ready_B;
    DEBUG_start_A                   <= start_A;
    DEBUG_start_B                   <= start_B;
    DEBUG_obuf_rst                  <= obuf_ctrl_rst;
end



always@(posedge S_AXI_ACLK)begin
    if(!M_AXI_ARESETN)
        s_axi_start_buffer <= 1'b0;
    else
        s_axi_start_buffer <= s_axi_start;
end

wire rst = !s_axi_start_buffer || !M_AXI_ARESETN;
//fully_connect_length,fully_connected,
assign {pool_quant_finish,Concat_Output_Control,CONV_FLAG,output_Feature_offset,input_feature_offset,leaky_constant,Is_Upsample,Instruction_Address,Instruction_Number,quant_obuf,quant_word_size
,quant_finish,quant_batch_bias,Kernel_Size,Stride,Maxpooling_Size,Maxpooling_Stride,Bit_Serial,
Batch_First,Have_Batch,Have_ReLU,Is_LeakyReLU} = (rst == 1'b0) ? {s_axi_inst_4,s_axi_inst_3,s_axi_inst_2,s_axi_inst_1,s_axi_inst_0} : 160'd0;


Master_read_control uMaster_read_control(
        .clk(S_AXI_ACLK),
        .rst(rst),
        .IRQ(IRQ),
        .s_axi_start(s_axi_start_buffer),       
        .s_axi_img_size(Instruction_Number),    // number of instruction
        .s_axi_dram_raddr(Instruction_Address),  // first addr
        
        /////////////////////////////////////////////////AR/////////////////////////////////////////////////
        .M_AXI_ARREADY(M_AXI_ARREADY), // ready
        .M_AXI_ARADDR(M_AXI_ARADDR),  // addr
        .M_AXI_ARLEN(M_AXI_ARLEN),   // 128 bits * 256 len
        .M_AXI_ARVALID(M_AXI_ARVALID), // same as ready, but just for one cycle
        
        /////////////////////////////////////////////////R/////////////////////////////////////////////////
        .M_AXI_RDATA(M_AXI_RDATA),   //Dram -> Sram Data
        .M_AXI_RRESP(M_AXI_RRESP),   // feedback good or bad
        .M_AXI_RLAST(M_AXI_RLAST),   // last value
        .M_AXI_RVALID(M_AXI_RVALID),  // when valid is High , read data is effective
        .M_AXI_RREADY(M_AXI_RREADY),   // ready to start reading
        .s_axi_Rerror(s_axi_Rerror),            //Trigger IRQ if error
        .s_axi_Rerror_addr(s_axi_Rerror_addr),
        .rst_A(rst_A),
        .rst_B(rst_B), 
        .ready_A(ready_A),
        .ready_B(ready_B),
        .start_A(start_A),
        .start_B(start_B),
       
        .Kernel_Size(Kernel_Size),
        .On_to_PE_finish(On_to_PE_finish),
        .Input_Address(Input_Address),
        .Weight_Address(Weight_Address),
        .Output_Address(Output_Address),
        .Pooling_Address(Pooling_Address),
        .Is_Final_Tile(Is_Final_Tile),
        .Have_Accumulate(Have_Accumulate),
        .Is_Last_Channel(Is_Last_Channel),
        .Feature_map_size(input_feature_offset),
        .hw_icp_able_cacl(hw_icp_able_cacl),
        .hw_ocp_able_cacl(hw_ocp_able_cacl),
        .hw_icp_able_cacl_to_input(hw_icp_able_cacl_to_input),
        
        .weight_buffer_start(weight_buffer_start),
        .Choose_Weight_buf(Choose_Weight_buf),
        .obuffer_init(obuffer_init),
        .PE_finish(For_State_Finish),
        .On_to_PE_buffer_sel(On_to_PE_buffer_sel),
        .Input_Buffer_to_PE_Ctrl_rst(Input_Buffer_to_PE_Ctrl_rst),
        //.obuf_ctrl_rst(obuf_ctrl_rst),
        .ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
        .ibuf_wr_A(ibuf_wr_A),
        .ibuf_wr_B(ibuf_wr_B),
        .ibuf_iaddr(ibuf_iaddr),
        .On_to_PE_addr(On_to_PE_addr),
        .weight_rst_A(weight_rst_A),
        .weight_rst_B(weight_rst_B),
        .off_to_on_valid_A(off_to_on_valid_A),
        .off_to_on_valid_B(off_to_on_valid_B),
        .padding_start(padding_start),
        .type(type),
        .Reload(Reload),
        .next_state_bank_count(next_state_bank_count),
        .Have_maxpooling(Have_maxpooling),
        .Input_Tile_Size_row(Input_Tile_Size_row),
        .Input_Tile_Size_col(Input_Tile_Size_col),


        .DEBUG_INPUT_state                  (DEBUG_INPUT_state), 
        .DEBUG_INPUT_start_valid_buffer     (DEBUG_INPUT_start_valid_buffer),             
        .DEBUG_INPUT_state_input_ctrl       (DEBUG_INPUT_state_input_ctrl)
    );

//----------------------------------------------------------------------INPUT BUFFER
Input_Buffer_to_PE_Controler uInput_Buffer_to_PE_Controler(
    .clk(M_AXI_ACLK),
    .Input_Buffer_to_PE_Ctrl_rst(Input_Buffer_to_PE_Ctrl_rst),
    .start_A(start_A),
    .start_B(start_B),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .On_to_PE_addr(On_to_PE_addr),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .Kernel_Size(Kernel_Size),
    .On_to_PE_buffer_sel(On_to_PE_buffer_sel),
    //.Kernel_Size(3'd1),
    .state(state),
    .operator_length(operator_length),
    .TILE_SIZE_row(Input_Tile_Size_row),
    .TILE_SIZE_col(Input_Tile_Size_col),
    .type(type),
    .Reload(Reload),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .start_buffer_to_obuf_chip(start_buffer_to_obuf_chip),
    .PE_rst(obuf_ctrl_rst),
    .On_to_PE_finish(On_to_PE_finish)
    );
    
Input_Buffer_AB_and_PE_Total_Block PE_reg_block_0(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[15:0]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_0_Data_2),
    .Data_5(PE_0_Data_5),
    .Data_8(PE_0_Data_8)
);

Input_Buffer_AB_and_PE_Total_Block PE_reg_block_1(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[31:16]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_1_Data_2),
    .Data_5(PE_1_Data_5),
    .Data_8(PE_1_Data_8)
);

Input_Buffer_AB_and_PE_Total_Block PE_reg_block_2(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[47:32]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_2_Data_2),
    .Data_5(PE_2_Data_5),
    .Data_8(PE_2_Data_8)
);

Input_Buffer_AB_and_PE_Total_Block PE_reg_block_3(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[63:48]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_3_Data_2),
    .Data_5(PE_3_Data_5),
    .Data_8(PE_3_Data_8)
);

Input_Buffer_AB_and_PE_Total_Block PE_reg_block_4(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[79:64]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_4_Data_2),
    .Data_5(PE_4_Data_5),
    .Data_8(PE_4_Data_8)
);

Input_Buffer_AB_and_PE_Total_Block PE_reg_block_5(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[95:80]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_5_Data_2),
    .Data_5(PE_5_Data_5),
    .Data_8(PE_5_Data_8)
);

Input_Buffer_AB_and_PE_Total_Block PE_reg_block_6(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[111:96]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_6_Data_2),
    .Data_5(PE_6_Data_5),
    .Data_8(PE_6_Data_8)
);

Input_Buffer_AB_and_PE_Total_Block PE_reg_block_7(
    .clk(M_AXI_ACLK),
    .rst_A(rst_A),
    .rst_B(rst_B),
    .ibuf_wr_A(off_to_on_valid_A),
    .ibuf_wr_B(off_to_on_valid_B),
	.ibuf_idata(M_AXI_RDATA[127:112]), 
	.padding_start(padding_start),
	.ibuf_iaddr_bank_sel(ibuf_iaddr_bank_sel),
	.next_state_bank_count(next_state_bank_count),
	.hw_icp_able_cacl(hw_icp_able_cacl_to_input),
	.Kernel_Size(Kernel_Size),
	/*.ibuf_rd_A(ibuf_rd_A),
	.ibuf_rd_B(ibuf_rd_B),*/
	.ibuf_rd_A(ibuf_rd_A_buffer),
	.ibuf_rd_B(ibuf_rd_B_buffer),
    .Bank_addr_wr(ibuf_iaddr),
    .Bank_addr_rd_0(Bank_addr_rd_0),
    .Bank_addr_rd_1(Bank_addr_rd_1),
    .Bank_addr_rd_2(Bank_addr_rd_2),
    .On_to_PE_addr(On_to_PE_addr),
    .operator_length(operator_length),
    .Bit_serial(Bit_Serial_test),
    .Bit_serial_wait_counter(Bit_serial_wait_counter),
    .state(state),
    .weight_start(weight_buffer_start),
    .Data_2(PE_7_Data_2),
    .Data_5(PE_7_Data_5),
    .Data_8(PE_7_Data_8)
);

OBUF_CHIP uobuf_chip(
        .clk                                (M_AXI_ACLK),
        .obuf_rst                           (obuf_ctrl_rst),
        .wbuf_rst_A                         (weight_rst_A),
        .wbuf_rst_B                         (weight_rst_B),
        .WBUF_RLAST                         (M_AXI_RLAST),
        .WBUF_VALID_FLAG                    (weight_buffer_start), //obuffer_init
        .WBUF_CHOOSE                        (~Choose_Weight_buf),               //0: using A loading B 1: using B loading A
        .pwc_dwc_combine_                   (1'b0),
        .concat_output_control_             (Concat_Output_Control),
        .set_isize_                         (1'b1),
        .set_wsize_                         (1'b1),
        .batch_first_                       (Batch_First),
        .have_batch_                        (Have_Batch),
        .have_batch_dwc_                    (1'b0),
        .have_relu_                         (Have_ReLU),
        .have_relu_dwc_                     (1'b0),
        .have_leaky_                        (Is_LeakyReLU),
        .have_sigmoid_                      (1'b0),
        .have_pool_                         (Have_maxpooling),
        .Is_Upsample_                       (Is_Upsample),
        .ker_size_                          ({2'b00,Kernel_Size}),
        .ker_strd_                          ({2'b00,Stride}),
        .pool_size_                         (Maxpooling_Size),
        .pool_strd_                         (Maxpooling_Stride),
        .Bit_serial_                        (2'b00),
        .obuf_tile_size_x_                  (Input_Tile_Size_row),
        .obuf_tile_size_y_                  (Input_Tile_Size_col),
        .obuf_tile_size_x_aft_pool_         (Input_Tile_Size_row>>1),       //end address of write mode 
        .obuf_tile_size_y_aft_pool_         (Input_Tile_Size_col>>1),       //end address of write mode 
        .quant_pe_                          (quant_obuf),            //quant before data store into obuf and then transf to off chip mem
        .quant_normalization_               (quant_batch_bias),
        .quant_activation_                  (quant_batch_bias),
        .quant_next_layer_                  (quant_finish),
        .quant_pool_next_layer_             (pool_quant_finish),
        .leaky_constant_                    (leaky_constant), ////////////////////put the leaky constant here "must be 16 bits"
        .hw_icp_able_cacl_                  (hw_icp_able_cacl),
        .hw_ocp_able_cacl_                  (hw_ocp_able_cacl),
        .have_accu_                         (Have_Accumulate),
        .have_last_ich_                     (Is_Last_Channel),
        .Is_last_ker_                       (1'b1),
        .Is_Final_Tile_                     (Is_Final_Tile),
        .IBUF_DATA_TRANS_START_             (start_buffer_to_obuf_chip),
        .ibuf_idata                         ({
                                                PE_7_Data_8,PE_6_Data_8,PE_5_Data_8,PE_4_Data_8,PE_3_Data_8,PE_2_Data_8,PE_1_Data_8,PE_0_Data_8,    
                                                PE_7_Data_5,PE_6_Data_5,PE_5_Data_5,PE_4_Data_5,PE_3_Data_5,PE_2_Data_5,PE_1_Data_5,PE_0_Data_5,
                                                PE_7_Data_2,PE_6_Data_2,PE_5_Data_2,PE_4_Data_2,PE_3_Data_2,PE_2_Data_2,PE_1_Data_2,PE_0_Data_2
                                            }),
        .axi_wdata                          (weight_buffer_data), //which is 128 bits , {ich0(16bits),ich1(16bits),ich2....ich7}
        .user_obuf_oaddr_x                  (oc_addr_x),        //Testbench read data address
        .user_obuf_oaddr_y                  (oc_addr_y),
        .user_obuf_oaddr_z                  (State_Bank_sel),
        .Master_Output_Finish               (Master_Output_Finish),
        .OBUF_FINISH_FLAG                   (Compute_Finish),
        .For_State_Finish                   (For_State_Finish),
        .Pad_Start_OBUF_FINISH              (Pad_Start_OBUF_FINISH),
        .OBUF_TO_DRAM_DATA                  (Output_data),
        .CONV_FLAG_                         (CONV_FLAG),
        .IRQ_TO_MASTER_CTRL                 (IRQ_TO_MASTER_CTRL),
        .have_pool_ing                      (have_pool_ing),


    .DEBUG_obuf_state                    (DEBUG_obuf_state), 
    .DEBUG_obuf_pool_s                   (DEBUG_obuf_pool_s), 
    .DEBUG_obuf_finish_state             (DEBUG_obuf_finish_state)
        
    );
    
Pad_v2 Pad_0(
    //General
    .clk(S_AXI_ACLK),
    .rst(rst),
    .irq(IRQ),

    //To CPU Response
    //.s_axi_error(s_axi_error),    //Trigger IRQ if error
    /*.s_axi_error(s_axi_Werror),
    .w_error_addr(s_axi_Werror_addr),*/

    //Tile Info
    .Output_Address(Output_Address),
    //.Output_Address(32'h01102f10),
    .Kernel_Size(Kernel_Size),
    .Pooling_Address(Pooling_Address),
    .Next_Input_Feature_Size_tmp({{4{1'b0}},output_Feature_offset}),
    .Output_Tile_Size_row({{10{1'b0}},Input_Tile_Size_row}),
    .Output_Tile_Size_col({{10{1'b0}},Input_Tile_Size_col}),
    .is_final(Is_Final_Tile),
    .IRQ_TO_MASTER_CTRL(IRQ_TO_MASTER_CTRL),
    .Is_pooling(have_pool_ing),
    .start(Pad_Start_OBUF_FINISH),
    .layer_done(Master_Output_Finish),  //Master output finish
    .Is_Upsample(Is_Upsample),

    //On-Chip Memory
    .inter_data(Output_data),
    //output  [TILE_SIZE_BW-1 : 0]        inter_addr,
    .oc_addr_x(oc_addr_x),
    .oc_addr_y(oc_addr_y),
    .State_Bank_sel(State_Bank_sel),
    .hw_ocp_able_cacl(hw_ocp_able_cacl),

    //AW Channel
    .m_axi_awready(M_AXI_AWREADY),
    .m_axi_awvalid(M_AXI_AWVALID),
    .m_axi_awaddr(M_AXI_AWADDR),
    .m_axi_awlen(M_AXI_AWLEN),
    
    //W Channel
    .m_axi_wready(M_AXI_WREADY),
    .m_axi_wdata(M_AXI_WDATA),
    .m_axi_wstrb(M_AXI_WSTRB),
    .m_axi_wlast(M_AXI_WLAST),
    .m_axi_wvalid(M_AXI_WVALID),/*,

    //B Channel
    .m_axi_bresp(M_AXI_BRESP),*/
    .m_axi_bvalid(M_AXI_BVALID),
    .m_axi_bready(M_AXI_BREADY)
);
assign weight_buffer_data = (weight_buffer_start ) ? M_AXI_RDATA : 128'bx;

always@(posedge M_AXI_ACLK) ibuf_rd_A_buffer <= start_A;
always@(posedge M_AXI_ACLK) ibuf_rd_B_buffer <= start_B;
/*
always@(posedge M_AXI_ACLK) begin
    if(rst)
        ibuf_rd_A <= 0;
    else if(ibuf_rd_A_buffer)
        ibuf_rd_A <= 1;
    else if(Compute_Finish == 1)
        ibuf_rd_A <= 0;
end

always@(posedge M_AXI_ACLK) begin
    if(rst)
        ibuf_rd_B <= 0;
    else if(ibuf_rd_B_buffer)
        ibuf_rd_B <= 1;
    else if(Compute_Finish == 1)
        ibuf_rd_B <= 0;
end*/



//assign Compute_Finish = (On_to_PE_addr == operator_length) ? 1'b1 : 1'b0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    
  //  wire rst = !s_axi_start && !M_AXI_ARESETN;
    
        //  (AW) Channel
    assign M_AXI_AWID       = {C_M_AXI_ID_WIDTH{1'b0}};         //Unused
    assign M_AXI_AWSIZE 	= 3'd4;     //clogb2((C_M_AXI_DATA_WIDTH/8)-1);
    assign M_AXI_AWBURST	= 2'd1;     //INCR Mode
    assign M_AXI_AWCACHE	= 4'd0;     //???
	assign M_AXI_AWPROT	    = 3'd0;     //???
    assign M_AXI_AWLOCK     = 1'd0;     //No need to lock bus
    assign M_AXI_AWQOS	    = 4'd0;     //Let QoS be default
    assign M_AXI_AWUSER	    = {C_M_AXI_AWUSER_WIDTH{1'b0}};     //Unused

    //Unused Write
    //  Set AW_CHANNEL
    // assign M_AXI_AWADDR  = {C_M_AXI_ADDR_WIDTH{1'b0}};
    // assign M_AXI_AWVALID = 1'b0;
    // assign M_AXI_AWLEN   = 7'd0;

    //  (W)  Channel
	//assign M_AXI_WSTRB	    = {(C_M_AXI_DATA_WIDTH/8){1'b1}};   //All bytes are effectual
    assign M_AXI_WUSER	    = {C_M_AXI_WUSER_WIDTH{1'b0}};      //Unused

    //Unused Write
    //  Set W CHANNEL
    // assign M_AXI_WDATA   = {C_M_AXI_DATA_WIDTH{1'b0}};
    // assign M_AXI_WSTRB   = {(C_M_AXI_DATA_WIDTH/8){1'b0}};
    // assign M_AXI_WLAST   = 1'b0;
    // assign M_AXI_WVALID  = 1'b0;

    //  (B)  Channel 
    //assign M_AXI_BREADY  = 1'b0;

    //  (AR) Channel
    assign M_AXI_ARID	    = {C_M_AXI_ID_WIDTH{1'b0}};         //Unused
    assign M_AXI_ARSIZE 	= 3'd4;     //clogb2((C_M_AXI_DATA_WIDTH/8)-1);
	assign M_AXI_ARBURST	= 2'd1;     //INCR Mode
	assign M_AXI_ARLOCK	    = 1'd0;     //No need to lock bus
	assign M_AXI_ARCACHE	= 4'd0;     //???
	assign M_AXI_ARPROT	    = 3'd0;     //???
	assign M_AXI_ARQOS	    = 4'd0;     //Let QoS be default
	assign M_AXI_ARUSER	    = {C_M_AXI_ARUSER_WIDTH{1'b0}};     //Unused

	
endmodule
