`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/25 17:24:20
// Design Name: 
// Module Name: YOLO_output_spilt_process
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


module YOLO_output_spilt_process#(
        parameter C_S_AXI_DATA_WIDTH        = 32,
        parameter C_M_AXI_ID_WIDTH	        = 1,
        parameter C_M_AXI_ADDR_WIDTH	    = 32,
        parameter C_M_AXI_DATA_WIDTH	    = 128,
        parameter C_M_AXI_AWUSER_WIDTH	    = 1,
        parameter C_M_AXI_ARUSER_WIDTH	    = 1,
        parameter C_M_AXI_WUSER_WIDTH	    = 1,
        parameter C_M_AXI_RUSER_WIDTH	    = 1,
        parameter C_M_AXI_BUSER_WIDTH	    = 1,
        //-----------MAIN FSM-----------------
        parameter IDLE_state                = 2'b00,
        parameter PROCESS_inst_state        = 2'b01,
        parameter PROCESS_state             = 2'b10,
        parameter PROCESS_write_state       = 2'b11,
        parameter MAIN_finish_state         = 2'b11,
        parameter READ_state                = 2'b01,
        parameter WRITE_state               = 2'b01,
        parameter four_K_boundary           = 16'h1000,
        parameter Data_bit                  = 16,
        //-----------Read FSM-----------------
        parameter SET_layer_0               = 3'b000,
        parameter INST_layer_0              = 3'b001,
        parameter SET_layer_1               = 3'b010,
        parameter INST_layer_1              = 3'b011,
        parameter READ_data_finish          = 3'b100,
        //-----------Process FSM-----------------
        parameter PROCESS_idle_state        = 3'b000,
        parameter PROCESS_find_state        = 3'b001,
        parameter PROCESS_calc_state        = 3'b010,
        parameter PROCESS_finish_state      = 3'b011,
        //-----------Data_fix_FSM-----------------
        parameter keep_go                   = 2'b00,
        parameter fill_up_0                 = 2'b01,
        parameter fill_up_1                 = 2'b10,
        //-----------Data_fix_AXI_FSM-------------
        parameter keep_go_axi               =3'b000,
        parameter reset_sram_0_axi          =3'b001,
        parameter fill_up_0_axi             =3'b010,
        parameter reset_sram_1_axi          =3'b011,
        parameter fill_up_1_axi             =3'b100,
        //-----------------------------------------
        parameter address_to_arlen              = 4, //2**4 = 16
        parameter num_classes                   = 1,
        parameter CH_round_total                = 3,
        parameter layer_0_address_pointer_bit   = 9,
        parameter layer_1_address_pointer_bit   = 11,
        parameter lyr_ch                        = (5 + num_classes),
        parameter layer_0_border_size           = 8,
        parameter layer_1_border_size           = 16,
        parameter layer_0_x_mul_y_total         = 64 - 1,
        parameter layer_1_x_mul_y_total         = 256 - 1
    )(
        input   S_AXI_ACLK,
        input   s_axi_start,
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_0,       //input_address_0
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_1,       //input_address_1
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_2,       //input_number_0 , input_number_1
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_3,       //conf_0 , conf_1;
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_4,       //output_address
        output                              s_axi_Rerror,       //Trigger IRQ if error
        output  [C_S_AXI_DATA_WIDTH-1:0]    s_axi_Rerror_addr,
        output  [1:0]                       s_axi_Werror,       //Trigger IRQ if error
        output  [C_S_AXI_DATA_WIDTH-1:0]    s_axi_Werror_addr,
        output  IRQ,
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
        output wire                              M_AXI_RREADY   // ready to start reading

        //--------------------dispaly the signal to ila--------------------
        //
        //
        //
    );
        //--------------------test_line-----------------------------
        //wire    signed [15:0] float_number_reg;
        //assign float_number_reg = float_number;

        //--------------------if you want make a ip use this!!------------------
        /*wire rst = M_AXI_ARESETN;*/
        
        //--------------------if you want sim use this!!------------------------
        reg s_axi_start_buffer;

        always@(posedge S_AXI_ACLK)begin
            if(!M_AXI_ARESETN)
                s_axi_start_buffer <= 1'b0;
            else
                s_axi_start_buffer <= s_axi_start;
        end

        wire rst = !s_axi_start_buffer || !M_AXI_ARESETN;

        //----------------------FSM_line_define-------------------\\
        reg [1:0] Current_state , Next_state;
        reg [1:0] CREAD_state   , NREAD_state;
        reg [1:0] CWRITE_state  , NWRITE_state;
        reg en_axi_arvalid      , en_axi_awvalid;

        //----------------------state_condition------------------\\
        wire   signed           [15:0] conf_0  , conf_1;
        assign conf_0               = s_axi_inst_3[15:0];
        assign conf_1               = s_axi_inst_3[31:16];

        //---------------------AR and R condition------------------\\
        integer j , pointer_index , index_0 , index_1;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Layer_0_need_arlen;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Layer_1_need_arlen;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Layer_0_total_arlen;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Layer_1_total_arlen;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Next_M_AXI_ARADDR;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Next_TO_boundary_ARLEN;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Pre_M_AXI_ARADDR;
        reg  [C_M_AXI_ADDR_WIDTH-1 : 0]      Pre_Pre_M_AXI_ARADDR;
        reg  [7:0]                           Pre_M_AXI_ARLEN;
        reg  [7:0]                           Pre_Pre_M_AXI_ARLEN;
        reg  [5:0]                           Pre_node_count_0;
        reg  [5:0]                           Pre_Pre_node_count_0;
        reg  [7:0]                           Pre_node_count_1;
        reg  [7:0]                           Pre_Pre_node_count_1;
        reg  [2:0]                           C_AB_set_FSM , N_AB_set_FSM;
        reg  [1:0]                           C_Data_fix_FSM , N_Data_fix_FSM;           //until single is raise
        reg  [2:0]                           C_Data_fix_AXI_FSM , N_Data_fix_AXI_FSM;   //keep the state change with axi
        reg  [9:0]                           Next_ARLEN;
        wire signed[127:0]                   INPUT_DATA;
        wire signed[15:0]                    output_answer_line[0:6];
        wire                                 fill_up_arrive_value_index_0;
        wire                                 fill_up_arrive_value_index_1;
        reg  signed[15:0]                    Sram_data_input[0:6];
        reg                                  over_conf_threshold;
        reg  [2:0]                           CH_round_count;
        reg  [2:0]  layer_0_x_count , layer_0_y_count;
        reg  [3:0]  layer_1_x_count , layer_1_y_count;
        reg  [5:0]  layer_0_x_mul_y_count; // 8*8
        reg  [7:0]  layer_1_x_mul_y_count; // 16*16
        reg  [layer_0_address_pointer_bit-1:0] layer_0_address_pointer [0:C_S_AXI_DATA_WIDTH-1];
        reg  [layer_1_address_pointer_bit-1:0] layer_1_address_pointer [0:C_S_AXI_DATA_WIDTH-1];
        reg  [4:0]  Sram_addr;
        reg         Sram_write_en [0:6];
        assign INPUT_DATA               =    M_AXI_RDATA;
        assign M_AXI_ARVALID            =   (en_axi_arvalid && M_AXI_ARREADY);
        assign M_AXI_ARADDR             =    Next_M_AXI_ARADDR;
        assign M_AXI_ARLEN              =   (Next_ARLEN - 1);
        assign M_AXI_RREADY             =   (M_AXI_RVALID);
        assign fill_up_arrive_value_index_0    =    (CH_round_count==layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-1)-:3]-1 && layer_0_x_mul_y_count==layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-4)-:6]-Pre_Pre_node_count_0);
        assign fill_up_arrive_value_index_1    =    (CH_round_count==layer_1_address_pointer[pointer_index][(layer_1_address_pointer_bit-1)-:3]-1 && layer_1_x_mul_y_count==layer_1_address_pointer[pointer_index][(layer_1_address_pointer_bit-4)-:8]-Pre_Pre_node_count_1);

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Pre_M_AXI_ARADDR        <= 0;
                Pre_Pre_M_AXI_ARADDR    <= 0;
                Pre_node_count_0        <= 0;
                Pre_Pre_node_count_0    <= 0;
            end else if(M_AXI_ARVALID)begin
                Pre_node_count_0        <= layer_0_x_mul_y_count;
                Pre_Pre_node_count_0    <= Pre_node_count_0;
                Pre_node_count_1        <= layer_1_x_mul_y_count;
                Pre_Pre_node_count_1    <= Pre_node_count_1;
                Pre_M_AXI_ARADDR        <= M_AXI_ARADDR;
                Pre_Pre_M_AXI_ARADDR    <= Pre_M_AXI_ARADDR;
            end else begin
                Pre_node_count_0        <= Pre_node_count_0;
                Pre_Pre_node_count_0    <= Pre_Pre_node_count_0;
                Pre_node_count_1        <= Pre_node_count_1;
                Pre_Pre_node_count_1    <= Pre_Pre_node_count_1;
                Pre_M_AXI_ARADDR        <= Pre_M_AXI_ARADDR;
                Pre_Pre_M_AXI_ARADDR    <= Pre_Pre_M_AXI_ARADDR;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Pre_M_AXI_ARLEN         <= 0;
                Pre_Pre_M_AXI_ARLEN     <= 0;
            end else if(M_AXI_ARVALID)begin
                Pre_M_AXI_ARLEN         <= M_AXI_ARLEN + 1;
                Pre_Pre_M_AXI_ARLEN     <= Pre_M_AXI_ARLEN;
            end else begin
                Pre_M_AXI_ARLEN         <= Pre_M_AXI_ARLEN;
                Pre_Pre_M_AXI_ARLEN     <= Pre_Pre_M_AXI_ARLEN;
            end
        end
        
        always@(*)begin
            if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==0)begin
                Sram_write_en[0] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[1] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[2] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[3] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[4] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[5] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[6] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==1)begin
                Sram_write_en[0] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold) ? 0 : 0;
                Sram_write_en[1] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold) ? 0 : 0;
                Sram_write_en[2] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[3] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[4] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[5] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[6] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==2)begin
                Sram_write_en[0] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 0 : 0;
                Sram_write_en[1] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 0 : 0;
                Sram_write_en[2] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 0 : 0;
                Sram_write_en[3] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 0 : 0;
                Sram_write_en[4] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[5] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
                Sram_write_en[6] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold) ? 1 : 0;
            end else begin
                Sram_write_en[0] = 0;
                Sram_write_en[1] = 0;
                Sram_write_en[2] = 0;
                Sram_write_en[3] = 0;
                Sram_write_en[4] = 0;
                Sram_write_en[5] = 0;
                Sram_write_en[6] = 0;
            end
        end

        always@(*)begin
            if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==0)begin
                Sram_data_input[0] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? M_AXI_RDATA[111:96]  : (over_conf_threshold) ? M_AXI_RDATA[15:0]  : 0;
                Sram_data_input[1] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? M_AXI_RDATA[127:112] : (over_conf_threshold) ? M_AXI_RDATA[31:16] : 0;
                Sram_data_input[2] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[47:32] : 0;
                Sram_data_input[3] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[63:48] : 0;
                Sram_data_input[4] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[79:64] : 0;
                Sram_data_input[5] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[95:80] : 0;
                Sram_data_input[6] = over_conf_threshold ? (C_AB_set_FSM==INST_layer_0 ? {4'b0000 , {1'b0,layer_0_x_count} , {1'b0,layer_0_y_count}} : (C_AB_set_FSM==INST_layer_1 ? {4'b0001 , layer_1_x_count , layer_1_y_count} : 0)) : 0;
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==1)begin
                Sram_data_input[0] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? M_AXI_RDATA[79:64]   : (over_conf_threshold) ? 0                  : 0; 
                Sram_data_input[1] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? M_AXI_RDATA[95:80]   : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[2] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? M_AXI_RDATA[111:96]  : (over_conf_threshold) ? M_AXI_RDATA[15:0]  : 0;
                Sram_data_input[3] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? M_AXI_RDATA[127:112] : (over_conf_threshold) ? M_AXI_RDATA[31:16] : 0;
                Sram_data_input[4] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[47:32] : 0;
                Sram_data_input[5] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[63:48] : 0;
                Sram_data_input[6] = over_conf_threshold ? (C_AB_set_FSM==INST_layer_0 ? {4'b0000 , {1'b0,layer_0_x_count} , {1'b0,layer_0_y_count}} : (C_AB_set_FSM==INST_layer_1 ? {4'b0001 , layer_1_x_count , layer_1_y_count} : 0)) : 0;
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==2)begin
                Sram_data_input[0] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[1] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[2] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[3] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[4] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[15:0]  : 0;
                Sram_data_input[5] = ((C_Data_fix_AXI_FSM==fill_up_0_axi && fill_up_arrive_value_index_0) || (C_Data_fix_AXI_FSM==fill_up_1_axi && fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? M_AXI_RDATA[31:16] : 0;
                Sram_data_input[6] = over_conf_threshold ? (C_AB_set_FSM==INST_layer_0 ? {4'b0000 , {1'b0,layer_0_x_count} , {1'b0,layer_0_y_count}} : (C_AB_set_FSM==INST_layer_1 ? {4'b0001 , layer_1_x_count , layer_1_y_count} : 0)) : 0;
            end else begin
                Sram_data_input[0] = 0;
                Sram_data_input[1] = 0;
                Sram_data_input[2] = 0;
                Sram_data_input[3] = 0;
                Sram_data_input[4] = 0;
                Sram_data_input[5] = 0;
                Sram_data_input[6] = 0;
            end
        end

        always@(*)begin
            if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_0)begin
                if(CH_round_count==0 && ($signed (INPUT_DATA[79:64]) > conf_0))begin
                    over_conf_threshold = 1;
                end else if (CH_round_count==1 && (($signed (INPUT_DATA[47:32]) > conf_0)))begin
                    over_conf_threshold = 1;
                end else if (CH_round_count==2 && (($signed (INPUT_DATA[15:0])  > conf_0)))begin
                    over_conf_threshold = 1;
                end else begin
                    over_conf_threshold = 0;
                end
            end else if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_1)begin
                if(CH_round_count==0 && (($signed(INPUT_DATA[79:64])) > conf_1))begin
                    over_conf_threshold = 1;
                end else if (CH_round_count==1 && (($signed(INPUT_DATA[47:32]) > conf_1)))begin
                    over_conf_threshold = 1;
                end else if (CH_round_count==2 && (($signed(INPUT_DATA[15:0])  > conf_1)))begin
                    over_conf_threshold = 1;
                end else begin
                    over_conf_threshold = 0;
                end
            end else begin
                over_conf_threshold = 0;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                C_Data_fix_AXI_FSM <= 0;
            else
                C_Data_fix_AXI_FSM <= N_Data_fix_AXI_FSM;
        end

        always@(*)begin
            case (C_Data_fix_AXI_FSM)
                keep_go_axi : begin
                    if(N_Data_fix_FSM==fill_up_0 && M_AXI_RLAST)        N_Data_fix_AXI_FSM = reset_sram_0_axi;
                    else if(N_Data_fix_FSM==fill_up_1 && M_AXI_RLAST)   N_Data_fix_AXI_FSM = reset_sram_1_axi;
                    else                                                N_Data_fix_AXI_FSM = keep_go_axi;
                end
                reset_sram_0_axi : begin
                    if(s_axi_start)                                     N_Data_fix_AXI_FSM = fill_up_0_axi;
                    else                                                N_Data_fix_AXI_FSM = reset_sram_0_axi;
                end
                fill_up_0_axi : begin
                    if(N_Data_fix_FSM!=fill_up_0 && M_AXI_RLAST)        N_Data_fix_AXI_FSM = keep_go_axi;
                    else                                                N_Data_fix_AXI_FSM = fill_up_0_axi;
                end
                reset_sram_1_axi : begin
                    if(s_axi_start)                                     N_Data_fix_AXI_FSM = fill_up_1_axi;
                    else                                                N_Data_fix_AXI_FSM = reset_sram_1_axi;
                end
                fill_up_1_axi : begin
                    if(N_Data_fix_FSM!=fill_up_1 && M_AXI_RLAST)        N_Data_fix_AXI_FSM = keep_go_axi;
                    else                                                N_Data_fix_AXI_FSM = fill_up_1_axi;
                end
                default: begin
                    N_Data_fix_AXI_FSM = keep_go_axi;
                end
            endcase
        end

        wire [2:0] output_asnwer_ch_round_count_0 = layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-1)-:3];
        wire [5:0] output_asnwer_layer_0_x_mul_y_count = layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-4)-:6];
        wire [2:0] output_asnwer_ch_round_count_1 = layer_1_address_pointer[pointer_index][(layer_1_address_pointer_bit-1)-:3];
        wire [8:0] output_asnwer_layer_1_x_mul_y_count = layer_1_address_pointer[pointer_index][(layer_1_address_pointer_bit-4)-:8];
        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_0 || C_AB_set_FSM==SET_layer_1)
                pointer_index <= 0;
            else if(C_AB_set_FSM==INST_layer_0 && fill_up_arrive_value_index_0)
                pointer_index <= pointer_index + 1;
            else if(C_AB_set_FSM==INST_layer_1 && fill_up_arrive_value_index_1)
                pointer_index <= pointer_index + 1;
            else 
                pointer_index <= pointer_index;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                index_0 <= 0;
                index_1 <= 0;
            end else if(over_conf_threshold && C_AB_set_FSM==INST_layer_0)begin
                index_0 <= index_0 + 1;
            end else if(over_conf_threshold && C_AB_set_FSM==INST_layer_1)begin
                index_1 <= index_1 + 1;
            end else begin
                index_0 <= index_0;
                index_1 <= index_1;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                for(j=0;j<32;j=j+1)begin
                    layer_0_address_pointer[j] <= 0;
                    layer_1_address_pointer[j] <= 0;
                end
            end else if(over_conf_threshold && C_AB_set_FSM==INST_layer_0)begin
                layer_0_address_pointer[index_0] <= {CH_round_count , layer_0_x_mul_y_count};
            end else if(over_conf_threshold && C_AB_set_FSM==INST_layer_1)begin
                layer_1_address_pointer[index_1] <= {CH_round_count , layer_1_x_mul_y_count};
            end else begin
                for(j=0;j<32;j=j+1)begin
                    layer_0_address_pointer[j] <= layer_0_address_pointer[j];
                    layer_1_address_pointer[j] <= layer_1_address_pointer[j];
                end
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                C_Data_fix_FSM <= keep_go;
            else
                C_Data_fix_FSM <= N_Data_fix_FSM;
        end

        always@(*)begin
            case (C_Data_fix_FSM)
                keep_go :   begin
                   if(C_AB_set_FSM==INST_layer_0 && pointer_index!=index_0)      N_Data_fix_FSM = fill_up_0;
                   else if(C_AB_set_FSM==INST_layer_1 && pointer_index!=index_1) N_Data_fix_FSM = fill_up_1;
                   else                                                          N_Data_fix_FSM = keep_go;
                end
                fill_up_0 :   begin
                    if(pointer_index==index_0 && M_AXI_RLAST)begin
                        N_Data_fix_FSM = keep_go;
                    end else begin
                        N_Data_fix_FSM = fill_up_0;
                    end
                end
                fill_up_1 :   begin
                    if(pointer_index==index_1 && M_AXI_RLAST)begin
                        N_Data_fix_FSM = keep_go;
                    end else begin
                        N_Data_fix_FSM = fill_up_1;
                    end
                end
                default: begin
                    N_Data_fix_FSM = keep_go;
                end
            endcase
        end

        wire [2:0]output_asnwer = layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-1)-:3];//test line

        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_0 || C_AB_set_FSM==SET_layer_1 || Current_state!=Next_state)begin
                CH_round_count <= 0;
            end else if(C_AB_set_FSM==INST_layer_0 && layer_0_x_mul_y_count==layer_0_x_mul_y_total)begin
                if(index_0!=0 && C_Data_fix_FSM==fill_up_0 && M_AXI_RLAST)begin
                    CH_round_count <= layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-1)-:3] - 1;
                end else begin
                    CH_round_count <= CH_round_count + 1;
                end
            end else if(C_AB_set_FSM==INST_layer_1 && layer_1_x_mul_y_count==layer_1_x_mul_y_total)
                if(index_1!=0 && C_Data_fix_FSM==fill_up_1 && M_AXI_RLAST)begin
                    CH_round_count <= layer_1_address_pointer[pointer_index][(layer_1_address_pointer_bit-1)-:3] - 1;
                end else begin
                    CH_round_count <= CH_round_count + 1;
                end
            else
                CH_round_count <= CH_round_count;
        end
        //----------------------------layer_0_x_mul_y_count----------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_1 || Current_state!=Next_state)
                layer_0_x_count <= 0;
            else if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_0)
                layer_0_x_count <= layer_0_x_count + 1;
            else
                layer_0_x_count <= layer_0_x_count;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_1 || Current_state!=Next_state)
                layer_0_y_count <= 0;
            else if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_0 && layer_0_x_count==layer_0_border_size-1)
                layer_0_y_count <= layer_0_y_count + 1;
            else
                layer_0_y_count <= layer_0_y_count;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_1 || Current_state!=Next_state)
                layer_0_x_mul_y_count <= 0;
            else if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_0)
                layer_0_x_mul_y_count <= layer_0_x_mul_y_count + 1;
            else
                layer_0_x_mul_y_count <= layer_0_x_mul_y_count;
        end

        //----------------------------layer_1_x_mul_y_count----------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_0 || Current_state!=Next_state)
                layer_1_x_count <= 0;
            else if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_1)
                layer_1_x_count <= layer_1_x_count + 1;
            else
                layer_1_x_count <= layer_1_x_count;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_0 || Current_state!=Next_state)
                layer_1_y_count <= 0;
            else if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_1 && layer_1_x_count==layer_1_border_size-1)
                layer_1_y_count <= layer_1_y_count + 1;
            else
                layer_1_y_count <= layer_1_y_count;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst || C_AB_set_FSM==SET_layer_0 || Current_state!=Next_state)
                layer_1_x_mul_y_count <= 0;
            else if(M_AXI_RVALID && M_AXI_RREADY && C_AB_set_FSM==INST_layer_1)
                layer_1_x_mul_y_count <= layer_1_x_mul_y_count + 1;
            else
                layer_1_x_mul_y_count <= layer_1_x_mul_y_count;
        end

        //----------------------------SET FSM----------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                C_AB_set_FSM <= SET_layer_0;
            else
                C_AB_set_FSM <= N_AB_set_FSM;
        end

        always@(*)begin
            case (C_AB_set_FSM)
                SET_layer_0 : begin
                    if(M_AXI_ARVALID)   N_AB_set_FSM = INST_layer_0;
                    else                N_AB_set_FSM = SET_layer_0;
                end
                INST_layer_0 : begin
                    if(C_Data_fix_FSM == fill_up_0 && pointer_index!=index_0)       N_AB_set_FSM = INST_layer_0;
                    else if(M_AXI_ARVALID && Layer_0_need_arlen==0)                 N_AB_set_FSM = SET_layer_1;
                    else                                                            N_AB_set_FSM = INST_layer_0;
                end
                SET_layer_1 : begin
                    if(M_AXI_ARVALID)   N_AB_set_FSM = INST_layer_1;
                    else                N_AB_set_FSM = SET_layer_1;
                end
                INST_layer_1 : begin
                    if(C_Data_fix_FSM == fill_up_1 && pointer_index!=index_1)       N_AB_set_FSM = INST_layer_1;
                    else if(M_AXI_ARVALID && Layer_1_need_arlen==0)                 N_AB_set_FSM = READ_data_finish;
                    else                                                            N_AB_set_FSM = INST_layer_1;
                end
                READ_data_finish : begin
                    N_AB_set_FSM = READ_data_finish;
                end
                default: begin
                    N_AB_set_FSM = SET_layer_0;
                end
            endcase
        end

        always@(posedge M_AXI_ACLK)begin
            if(N_Data_fix_FSM==fill_up_0 || N_Data_fix_FSM==fill_up_1)
                Next_M_AXI_ARADDR = Pre_Pre_M_AXI_ARADDR;
            else if(N_AB_set_FSM==SET_layer_0)
                Next_M_AXI_ARADDR <= s_axi_inst_0;
            else if(M_AXI_ARVALID && N_AB_set_FSM==INST_layer_0)
                Next_M_AXI_ARADDR <= s_axi_inst_0 + ((Layer_0_total_arlen+Next_ARLEN) << address_to_arlen);
            else if(N_AB_set_FSM==SET_layer_1)
                Next_M_AXI_ARADDR <= s_axi_inst_1;
            else if(M_AXI_ARVALID && N_AB_set_FSM==INST_layer_1)
                Next_M_AXI_ARADDR <= s_axi_inst_1 + ((Layer_1_total_arlen+Next_ARLEN) << address_to_arlen);
            else
                Next_M_AXI_ARADDR <= Next_M_AXI_ARADDR;
        end
        
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Layer_0_total_arlen <= 0;
                Layer_1_total_arlen <= 0;
            end else if(N_AB_set_FSM==INST_layer_0 && M_AXI_ARVALID && Layer_0_need_arlen!=0)begin
                Layer_0_total_arlen <= Layer_0_total_arlen + Next_ARLEN;
            end else if(N_AB_set_FSM==INST_layer_1 && M_AXI_ARVALID && Layer_1_need_arlen!=0)begin
                Layer_1_total_arlen <= Layer_1_total_arlen + Next_ARLEN;
            end else begin
                Layer_0_total_arlen <= Layer_0_total_arlen;
                Layer_1_total_arlen <= Layer_1_total_arlen;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                Next_TO_boundary_ARLEN <= 0;
            else if(s_axi_start)
                Next_TO_boundary_ARLEN <= (four_K_boundary - M_AXI_ARADDR[11:0]) >> address_to_arlen;
            else 
                Next_TO_boundary_ARLEN <= Next_TO_boundary_ARLEN;
        end
        
        always@(*)begin
            if(N_Data_fix_FSM==fill_up_0)
                Next_ARLEN = Pre_Pre_M_AXI_ARLEN - Pre_Pre_node_count_0;
            else if(N_Data_fix_FSM==fill_up_1)
                Next_ARLEN = Pre_Pre_M_AXI_ARLEN - Pre_Pre_node_count_1;
            else if(M_AXI_ARVALID && Layer_0_need_arlen!=0 && (Next_TO_boundary_ARLEN >= Layer_0_need_arlen))
                Next_ARLEN = (N_AB_set_FSM==SET_layer_1) ? 1 : Layer_0_need_arlen;
            else if(M_AXI_ARVALID && Layer_0_need_arlen!=0 && (Next_TO_boundary_ARLEN < Layer_0_need_arlen))
                Next_ARLEN = (N_AB_set_FSM==SET_layer_1) ? 1 : Next_TO_boundary_ARLEN;
            else if(M_AXI_ARVALID && Layer_1_need_arlen!=0 && (Next_TO_boundary_ARLEN >= Layer_1_need_arlen))
                Next_ARLEN = (N_AB_set_FSM==SET_layer_1) ? 1 : Layer_1_need_arlen;
            else if(M_AXI_ARVALID && Layer_1_need_arlen!=0 && (Next_TO_boundary_ARLEN < Layer_1_need_arlen))
                Next_ARLEN = (N_AB_set_FSM==SET_layer_1) ? 1 : Next_TO_boundary_ARLEN;
            else
                Next_ARLEN = 1;
        end
        
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Layer_0_need_arlen <= s_axi_inst_2[15:0];
            end else if(N_AB_set_FSM==INST_layer_0 && M_AXI_ARVALID && (Next_TO_boundary_ARLEN >= Layer_0_need_arlen))begin
                Layer_0_need_arlen <= 0;
            end else if (N_AB_set_FSM==INST_layer_0 && M_AXI_ARVALID && (Next_TO_boundary_ARLEN < Layer_0_need_arlen))begin
                Layer_0_need_arlen <= Layer_0_need_arlen - Next_TO_boundary_ARLEN;
            end else begin
                Layer_0_need_arlen <= Layer_0_need_arlen;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Layer_1_need_arlen <= s_axi_inst_2[31:16];
            end else if(N_AB_set_FSM==INST_layer_1 && M_AXI_ARVALID && (Next_TO_boundary_ARLEN >= Layer_1_need_arlen))begin
                Layer_1_need_arlen <= 0;
            end else if (N_AB_set_FSM==INST_layer_1 && M_AXI_ARVALID && (Next_TO_boundary_ARLEN < Layer_1_need_arlen))begin
                Layer_1_need_arlen <= Layer_1_need_arlen - Next_TO_boundary_ARLEN;
            end else begin
                Layer_1_need_arlen <= Layer_1_need_arlen;
            end
        end
        
        //---------------------PUT YOUR SRAM IN HERE----------------\\
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_1(.clka(M_AXI_ACLK) , .wea(Sram_write_en[0]) , .addra(Sram_addr)  , .dina(Sram_data_input[0])  , .douta(output_answer_line[0]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_2(.clka(M_AXI_ACLK) , .wea(Sram_write_en[1]) , .addra(Sram_addr)  , .dina(Sram_data_input[1])  , .douta(output_answer_line[1]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_3(.clka(M_AXI_ACLK) , .wea(Sram_write_en[2]) , .addra(Sram_addr)  , .dina(Sram_data_input[2])  , .douta(output_answer_line[2]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_4(.clka(M_AXI_ACLK) , .wea(Sram_write_en[3]) , .addra(Sram_addr)  , .dina(Sram_data_input[3])  , .douta(output_answer_line[3]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_5(.clka(M_AXI_ACLK) , .wea(Sram_write_en[4]) , .addra(Sram_addr)  , .dina(Sram_data_input[4])  , .douta(output_answer_line[4]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_6(.clka(M_AXI_ACLK) , .wea(Sram_write_en[5]) , .addra(Sram_addr)  , .dina(Sram_data_input[5])  , .douta(output_answer_line[5]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_7(.clka(M_AXI_ACLK) , .wea(Sram_write_en[6]) , .addra(Sram_addr)  , .dina(Sram_data_input[6])  , .douta(output_answer_line[6]));

        

        //---------------------AW and W condition------------------\\
        reg [C_M_AXI_ADDR_WIDTH-1 : 0]      Next_M_AXI_AWADDR;
        assign M_AXI_AWVALID            = (en_axi_awvalid && M_AXI_AWREADY);

        

        //----------------------Process_FSM------------------------------------
        //1. in process fsm put data in sigmoid func and exp func
        reg [2:0]C_process_state , N_process_state;
        reg [2:0]C_process_six_state , N_process_six_state;
        reg [3:0]class_count;
        wire PROCESS_calc_state_finish;
        wire tx_sigmoid_tw_exp_func_finish;
        wire ty_sigmoid_th_exp_func_finish;
        wire class_sigmoid_func_finish;
        reg  [1:0] sigmoid_exp_func_count;
        assign tx_sigmoid_tw_exp_func_finish = (C_process_six_state==1 && sigmoid_exp_func_count==2) ? 1 : 0;
        assign ty_sigmoid_th_exp_func_finish = (C_process_six_state==1 && sigmoid_exp_func_count==2) ? 1 : 0;
        assign class_sigmoid_func_finish     = (C_process_six_state==1 && sigmoid_exp_func_count==2) ? 1 : 0;


        always@(posedge M_AXI_ACLK)begin
            if(rst)
                sigmoid_exp_func_count <= 0;
            else if(sigmoid_exp_func_count==2)
                sigmoid_exp_func_count <= 0;
            else if(sigmoid_exp_func_count<2)
                sigmoid_exp_func_count <= sigmoid_exp_func_count + 1;
            else 
                sigmoid_exp_func_count <= sigmoid_exp_func_count;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst || C_process_six_state)
                class_count <= 0;
            else if(class_sigmoid_func_finish)
                class_count <= class_count + 1;
            else
                class_count <= class_count;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                C_process_six_state <= 0;
            else
                C_process_six_state <= N_process_six_state;
        end

        always@(*)begin
            case (C_process_six_state)
                0   :   begin
                    if(C_process_state==PROCESS_calc_state)                           N_process_six_state = 1;
                    else                                                              N_process_six_state = 0;
                end
                1   :   begin
                    if(tx_sigmoid_tw_exp_func_finish)                                 N_process_six_state = 2;
                    else                                                              N_process_six_state = 1;
                end
                2   :   begin
                    if(ty_sigmoid_th_exp_func_finish)                                 N_process_six_state = 3;
                    else                                                              N_process_six_state = 2;
                end
                3   :   begin
                    if(class_sigmoid_func_finish && class_count==num_classes)         N_process_six_state = 0;
                    else                                                              N_process_six_state = 3;
                end
                default: begin
                    N_process_six_state = 0;
                end
            endcase
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                C_process_state <= PROCESS_idle_state;
            else
                C_process_state <= N_process_state;
        end

        always@(*)begin
            case (C_process_state)
                PROCESS_idle_state : begin
                    if(Current_state==PROCESS_state)        N_process_state = PROCESS_find_state;
                    else                                    N_process_state = PROCESS_idle_state;
                end
                PROCESS_find_state : begin
                    if(Sram_addr==index_0 + index_1)        N_process_state = PROCESS_finish_state;
                    else if(Current_state==PROCESS_state)   N_process_state = PROCESS_calc_state;
                    else                                    N_process_state = PROCESS_find_state;
                end
                PROCESS_calc_state : begin
                    if(PROCESS_calc_state_finish)           N_process_state = PROCESS_find_state;
                    else                                    N_process_state = PROCESS_calc_state;
                end
                PROCESS_finish_state : begin
                    N_process_state = PROCESS_finish_state;
                end
                default: begin
                    N_process_state = PROCESS_idle_state;
                end
            endcase
        end
        
        //---------------------------------PE module--------------------------------
        wire [Data_bit-1 : 0]sigmoid_output_alpha , sigmoid_output_bias;
        wire [Data_bit-1 : 0]exp_output_alpha; 
        wire [Data_bit-1 : 0]exp_output_bias ;
        wire [3:0]repair_bit;
        reg  [Data_bit-1 : 0]input_data_control_sigmoid,input_data_control_exp;
        assign repair_bit = output_answer_line[6][11-:4];//index_register

        always@(*)begin
            if(C_process_six_state == 1)begin
                input_data_control_sigmoid  = output_answer_line[0];
                input_data_control_exp      = output_answer_line[2];
            end else if(C_process_six_state == 2)begin
                input_data_control_sigmoid  = output_answer_line[1];
                input_data_control_exp      = output_answer_line[3];
            end else if(C_process_six_state == 3)begin
                input_data_control_sigmoid  = output_answer_line[5];
                input_data_control_exp      = 0;
            end else begin
                input_data_control_sigmoid  = 0;
                input_data_control_exp      = 0;
            end
        end
        
        fpga_linear_sigmoid_func_layer #(.bias_shift_bit(10)) sigmoid_layer(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .repair_bit(repair_bit),
            .input_data(input_data_control_sigmoid),
            .output_alpha(sigmoid_output_alpha),
            .output_bias(sigmoid_output_bias)
        );
        fpga_exp_lookuptable_func_layer #(.bias_shift_bit(10)) exp_layer(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .repair_bit(repair_bit),
            .input_data(input_data_control_exp),
            .output_alpha(exp_output_alpha),
            .output_bias(exp_output_bias)
        );
        process_mul_element mul_element(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .input_data(),
            .input_alpha(),
            .output_data()
        );
        process_add_element add_element(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .input_data(),
            .input_bias(),
            .output_data()
        );

        //----------------------latch_count_define-----------------------------
        reg en_axi_rcount       , en_axi_wcount;

        //----------------------main state control----------------------------
        wire   INST_state_finish;
        wire   PROCESS_state_finish;
        wire   PROCESS_write_state_finish;
        assign IRQ                  =   (Current_state==MAIN_finish_state) ? 1 : 0;
        assign INST_state_finish    =   (C_AB_set_FSM==READ_data_finish) ? 1 : 0;

        //----------------------main-FSM---------------------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                Current_state <= IDLE_state;
            else
                Current_state <= Next_state;
        end

        always@( * )begin : main_state_combination
            case (Current_state)
                IDLE_state      :   begin
                    if(s_axi_start) Next_state = PROCESS_inst_state;
                    else            Next_state = IDLE_state;
                end
                PROCESS_inst_state      :   begin
                    if(INST_state_finish)    Next_state = PROCESS_state;
                    else                     Next_state = PROCESS_inst_state;
                end
                PROCESS_state   :   begin
                    if(PROCESS_state_finish) Next_state = PROCESS_write_state;
                    else                     Next_state = PROCESS_state;
                end
                PROCESS_write_state     :   begin
                    if(PROCESS_write_state_finish)  Next_state = MAIN_finish_state;
                    else                            Next_state = PROCESS_write_state;
                end
                MAIN_finish_state      :   begin
                    Next_state = IDLE_state;
                end
                default: 
                    Next_state = IDLE_state;
            endcase
        end
        //----------------------READ-FSM---------------------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                CREAD_state <= IDLE_state;
            else
                CREAD_state <= NREAD_state;
        end

        always@(*)begin : read_state_combination
            case (CREAD_state)
                IDLE_state  :   begin
                    if(Current_state==PROCESS_inst_state && !IRQ)   NREAD_state = READ_state;
                    else                                            NREAD_state = IDLE_state;
                end
                READ_state  :   begin
                    if(M_AXI_RLAST && M_AXI_RVALID && M_AXI_RREADY) NREAD_state = IDLE_state;
                    else                                            NREAD_state = READ_state;
                end
                default: begin
                    NREAD_state = IDLE_state;
                end
            endcase
        end

        //----------------------WRITE-FSM--------------------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                CWRITE_state <= IDLE_state;
            else
                CWRITE_state <= NWRITE_state;
        end

        always@(*)begin : write_state_combination
            case (CWRITE_state)
            IDLE_state  :   begin
                if(Current_state==PROCESS_write_state && !IRQ)      NWRITE_state = WRITE_state;
                else                                                NWRITE_state = IDLE_state;
            end
            WRITE_state :   begin
                if(M_AXI_WLAST && M_AXI_WVALID && M_AXI_WREADY)     NWRITE_state = IDLE_state;
                else                                                NWRITE_state = WRITE_state;
            end
                default: begin
                    NWRITE_state = IDLE_state;
                end
            endcase                
        end

        //--------------------AR_valid_latch---------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                en_axi_arvalid <= 1'b0;
            else
                en_axi_arvalid <= (en_axi_arvalid) ? 1'b0 : ((CREAD_state==READ_state) && (en_axi_rcount < 1) && M_AXI_ARREADY==1);
        end

        always@(posedge M_AXI_ACLK)begin
            if(CREAD_state==IDLE_state)
                en_axi_rcount <= 0;
            else if(M_AXI_ARVALID && M_AXI_ARREADY)
                en_axi_rcount <= en_axi_rcount + 1;
            else
                en_axi_rcount <= en_axi_rcount;
        end

        //--------------------AW_valid_latch---------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                en_axi_awvalid <= 1'b0;
            else
                en_axi_awvalid <= (en_axi_awvalid) ? 1'b0 : ((CWRITE_state==WRITE_state) && (en_axi_wcount<1) && M_AXI_AWREADY==1);
        end

        always@(posedge M_AXI_ACLK)begin
            if(CWRITE_state==IDLE_state)
                en_axi_wcount <= 0;
            else if(M_AXI_AWVALID && M_AXI_AWREADY)
                en_axi_wcount <= en_axi_wcount + 1;
            else
                en_axi_wcount <= en_axi_wcount;
        end

        //--------------------------------SRAM ADDR CONTROL-----------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Sram_addr <= 0;
            end else if(Current_state==PROCESS_inst_state)begin
                if(C_Data_fix_AXI_FSM==keep_go_axi && over_conf_threshold)begin
                    Sram_addr <= Sram_addr + 1;
                end else if(C_Data_fix_AXI_FSM==reset_sram_0_axi)begin
                    Sram_addr <= 0;
                end else if(C_Data_fix_AXI_FSM==reset_sram_1_axi)begin
                    Sram_addr <= index_0;
                end else if(C_Data_fix_AXI_FSM==fill_up_0_axi || C_Data_fix_AXI_FSM==fill_up_1_axi)begin
                    if(C_AB_set_FSM==INST_layer_0 && fill_up_arrive_value_index_0)
                        Sram_addr <= Sram_addr + 1;
                    else if(C_AB_set_FSM==INST_layer_1 && fill_up_arrive_value_index_1)
                        Sram_addr <= Sram_addr + 1;    
                    else
                        Sram_addr <= Sram_addr;
                end else begin
                    Sram_addr <= Sram_addr;    
                end
            end else if (Current_state==PROCESS_state)begin
                if(C_process_state==PROCESS_idle_state)begin
                    Sram_addr <= 0;
                end else if(C_process_state==PROCESS_calc_state && PROCESS_calc_state_finish)begin
                    Sram_addr <= Sram_addr + 1;
                end else begin
                    Sram_addr <= Sram_addr;    
                end
            end else begin
                Sram_addr <= Sram_addr;
            end
        end

endmodule
