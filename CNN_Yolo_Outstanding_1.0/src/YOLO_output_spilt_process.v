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
        parameter IDLE_state                = 3'b000,
        parameter PROCESS_inst_state        = 3'b001,
        parameter PROCESS_point_state       = 3'b010,
        parameter PROCESS_iou_state         = 3'b011,
        parameter PROCESS_write_state       = 3'b100,
        parameter MAIN_finish_state         = 3'b101,
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
        //-----------Process FSM point-----------------
        parameter PROCESS_idle_state        = 3'b000,
        parameter PROCESS_find_state        = 3'b001,
        parameter PROCESS_wait_state        = 3'b010,
        parameter PROCESS_calc_state        = 3'b011,
        parameter PROCESS_result_state      = 3'b100,
        parameter PROCESS_finish_state      = 3'b101,
        //-----------Process FSM iou-----------------
        parameter PROCESS_iou_idle_state    = 3'b000,
        parameter PROCESS_iou_find_state    = 3'b001,
        parameter PROCESS_iou_wait_value_state    = 3'b010,
        parameter PROCESS_iou_wait_finish_state  = 3'b011,
        parameter PROCESS_iou_finish_state  = 3'b100,
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
        parameter address_to_awlen              = 4, //2**4 = 16
        parameter CH_round_total                = 3,
        parameter layer_0_address_pointer_bit   = 9,
        parameter layer_1_address_pointer_bit   = 11,
        parameter layer_0_border_size           = 8,
        parameter layer_1_border_size           = 16,
        parameter layer_0_x_mul_y_total         = 64 - 1,
        parameter layer_1_x_mul_y_total         = 256 - 1,
        parameter layer_alignment_number        = 1,
        parameter sram_need_awlen               = 32
    )(
        input   S_AXI_ACLK,
        input   s_axi_start,
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_0,       //input_address_0
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_1,       //input_address_1
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_2,       //input_number_0 , input_number_1
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_3,       //conf_0 , conf_1;
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_4,       //total feature map input_address
        input   [C_S_AXI_DATA_WIDTH-1:0]    s_axi_inst_5,       //output_address
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
        output wire                              M_AXI_RREADY,   // ready to start reading

        //--------------------dispaly the signal to ila--------------------
        output reg  [2:0] Current_state , Next_state,
        output reg  [1:0] CREAD_state   , NREAD_state,
        output reg  [1:0] CWRITE_state  , NWRITE_state,
        output reg  [2:0] C_process_iou_state , N_process_iou_state,
        output reg  [2:0] C_AB_set_FSM , N_AB_set_FSM,
        output reg  [1:0] C_Data_fix_FSM , N_Data_fix_FSM,
        output reg  [Data_bit-1:0] total_sram_count,
        output reg  [Data_bit-1:0] check_iou_if_already_use_count,
        output reg  [Data_bit-1:0] Sram_addr,
        output      [Data_bit-1:0] Sram_addr_delay_for_max_value_cmp,
        output PROCESS_point_state_finish,
        output PROCESS_iou_state_finish  ,
        output PROCESS_write_state_finish,
        output INST_state_finish,
        output wire rst,
        output reg already_finish_lock
    );
        //  (AW) Channel---------------------------------------------------------------------
        assign M_AXI_AWID       = {C_M_AXI_ID_WIDTH{1'b0}};         //Unused
        assign M_AXI_AWSIZE 	= 3'd4;     //clogb2((C_M_AXI_DATA_WIDTH/8)-1);
        assign M_AXI_AWBURST	= 2'd1;     //INCR Mode
        assign M_AXI_AWCACHE	= 4'd0;     //???
	    assign M_AXI_AWPROT	    = 3'd0;     //???
        assign M_AXI_AWLOCK     = 1'd0;     //No need to lock bus
        assign M_AXI_AWQOS	    = 4'd0;     //Let QoS be default
        assign M_AXI_AWUSER	    = {C_M_AXI_AWUSER_WIDTH{1'b0}};     //Unused

        //  (W)  Channel---------------------------------------------------------------------
	    assign M_AXI_WSTRB	    = {(C_M_AXI_DATA_WIDTH/8){1'b1}};   //All bytes are effectual
        assign M_AXI_WUSER	    = {C_M_AXI_WUSER_WIDTH{1'b0}};      //Unused

        //  (AR) Channel---------------------------------------------------------------------
        assign M_AXI_ARID	    = {C_M_AXI_ID_WIDTH{1'b0}};         //Unused
        assign M_AXI_ARSIZE 	= 3'd4;     //clogb2((C_M_AXI_DATA_WIDTH/8)-1);
	    assign M_AXI_ARBURST	= 2'd1;     //INCR Mode
	    assign M_AXI_ARLOCK	    = 1'd0;     //No need to lock bus
	    assign M_AXI_ARCACHE	= 4'd0;     //???
	    assign M_AXI_ARPROT	    = 3'd0;     //???
	    assign M_AXI_ARQOS	    = 4'd0;     //Let QoS be default
	    assign M_AXI_ARUSER	    = {C_M_AXI_ARUSER_WIDTH{1'b0}};     //Unused
	    
        assign s_axi_Rerror = 0;            //Trigger IRQ if error
        assign s_axi_Rerror_addr = 0;
        assign s_axi_Werror = 0;            //Trigger IRQ if error
        assign s_axi_Werror_addr = 0;
        assign M_AXI_BREADY  = (Current_state==PROCESS_write_state || Current_state==PROCESS_finish_state) ? 1 : 0;

        //--------------------test_line-----------------------------
        //wire    signed [15:0] float_number_reg;
        //assign float_number_reg = float_number;

        //--------------------if you want make a ip use this!!------------------
        //wire rst = M_AXI_ARESETN;
        
        //--------------------if you want sim use this!!------------------------
        reg s_axi_start_buffer;

        always@(posedge S_AXI_ACLK)begin
            if(!M_AXI_ARESETN)
                s_axi_start_buffer <= 1'b0;
            else
                s_axi_start_buffer <= s_axi_start;
        end

        assign rst = !s_axi_start_buffer || !M_AXI_ARESETN;
        
        //----------------------FSM_line_define-------------------\\
        //reg [2:0] Current_state , Next_state;
        //reg [1:0] CREAD_state   , NREAD_state;
        //reg [1:0] CWRITE_state  , NWRITE_state;
        reg en_axi_arvalid      , en_axi_awvalid;

        //----------------------state_condition------------------\\
        wire   signed           [15:0] conf_0  , conf_1;
        assign conf_0               = s_axi_inst_3[15:0];
        assign conf_1               = s_axi_inst_3[31:16];

        //---------------------AR and R condition------------------\\
        integer j , i ,pointer_index , index_0 , index_1 , inst_already_finish;
        //reg  [Data_bit-1:0]                  total_sram_count;
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
        //reg  [2:0]                           C_AB_set_FSM , N_AB_set_FSM;
        //reg  [1:0]                           C_Data_fix_FSM , N_Data_fix_FSM;           //until single is raise
        reg  [2:0]                           C_Data_fix_AXI_FSM , N_Data_fix_AXI_FSM;   //keep the state change with axi
        reg  [9:0]                           Next_ARLEN;
        wire signed[127:0]                   INPUT_DATA;
        wire signed[15:0]                    output_answer_line[0:7];
        wire                                 fill_up_arrive_value_index_0;
        wire                                 fill_up_arrive_value_index_1;
        wire                                 fill_up_arrive_value_index_0_delay;
        wire                                 fill_up_arrive_value_index_1_delay;
        reg  signed[15:0]                    Sram_data_input[0:6];
        reg                                  over_conf_threshold;
        wire                                 over_conf_threshold_delay;
        reg  [2:0]                           CH_round_count;
        reg  [2:0]  layer_0_x_count , layer_0_y_count;
        reg  [3:0]  layer_1_x_count , layer_1_y_count;
        reg  [5:0]  layer_0_x_mul_y_count; // 8*8
        reg  [7:0]  layer_1_x_mul_y_count; // 16*16
        reg  [layer_0_address_pointer_bit-1:0] layer_0_address_pointer [0:C_S_AXI_DATA_WIDTH-1];
        reg  [layer_1_address_pointer_bit-1:0] layer_1_address_pointer [0:C_S_AXI_DATA_WIDTH-1];
        reg  signed[Data_bit-1 : 0]Max_value_cmp[0:5];
        reg  [C_M_AXI_ADDR_WIDTH-1:0]check_iou_if_keep_or_not;
        reg  [C_M_AXI_ADDR_WIDTH-1:0]check_iou_if_already_use_or_not;
        //reg  [C_M_AXI_ADDR_WIDTH-1:0]check_iou_if_already_use_count;
        reg  ALL_MAX_conf_check_signal;
        reg  [9:0]max_index_pointer;
        reg  [9:0]max_index_pointer_pre;
        //reg  [Data_bit-1:0]  Sram_addr;
        reg         Sram_write_en  [0:6];
        wire        Sram_write_en_delay[0:4]; // bx.by,bw,bh
        wire signed[Data_bit-1 : 0]data_out_bx   ;
        wire signed[Data_bit-1 : 0]data_out_by   ;
        wire signed[Data_bit-1 : 0]data_out_bw   ;
        wire signed[Data_bit-1 : 0]data_out_bh   ;
        wire signed[Data_bit-1 : 0]data_out_conf ;
        wire signed[Data_bit-1 : 0]data_out_class;
        wire signed[Data_bit-1 : 0]data_out_index;
        wire signed[Data_bit-1 : 0]data_out_add_bw_bh;
        wire is_delete_singal;
        wire signed[8*Data_bit-1:0]sram_output_data_conbine_delay;
        wire [Data_bit-1:0]Sram_addr_delay_for_keep_or_not_and_already_use;
        //wire [Data_bit-1:0]Sram_addr_delay_for_max_value_cmp;
        wire C_Data_fix_AXI_FSM_in_fill_up = (C_Data_fix_AXI_FSM==fill_up_0_axi || C_Data_fix_AXI_FSM==fill_up_1_axi);
        assign INPUT_DATA               =    M_AXI_RDATA;
        assign M_AXI_ARVALID            =   (en_axi_arvalid && M_AXI_ARREADY);
        assign M_AXI_ARADDR             =    Next_M_AXI_ARADDR;
        assign M_AXI_ARLEN              =   (Next_ARLEN - 1);
        assign M_AXI_RREADY             =   (M_AXI_RVALID);
        assign fill_up_arrive_value_index_0    =    (CH_round_count==layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-1)-:3]-1 && layer_0_x_mul_y_count==layer_0_address_pointer[pointer_index][(layer_0_address_pointer_bit-4)-:6]-Pre_Pre_node_count_0);
        assign fill_up_arrive_value_index_1    =    (CH_round_count==layer_1_address_pointer[pointer_index][(layer_1_address_pointer_bit-1)-:3]-1 && layer_1_x_mul_y_count==layer_1_address_pointer[pointer_index][(layer_1_address_pointer_bit-4)-:8]-Pre_Pre_node_count_1);

        //----------------------test----------------------------
        //wire  signed [15:0] a = ~(-10) +1;
        //wire  signed [15:0] b = ~10 +1;
        //-------------------------------------------------------

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
                Sram_write_en[0] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[1] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[2] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[3] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[4] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[5] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[6] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==1)begin
                Sram_write_en[0] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 0 : 0;
                Sram_write_en[1] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 0 : 0;
                Sram_write_en[2] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[3] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 1 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[4] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[5] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[6] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==2)begin
                Sram_write_en[0] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 0 : 0;
                Sram_write_en[1] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 0 : 0;
                Sram_write_en[2] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 0 : 0;
                Sram_write_en[3] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 0 : 0;
                Sram_write_en[4] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[5] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
                Sram_write_en[6] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0 : (over_conf_threshold && !C_Data_fix_AXI_FSM_in_fill_up) ? 1 : 0;
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
        
        //--------------------------------SRAM_DELAY_WRITE_EN------------------------------------
        genvar sram_en_delay;
        generate
            for(sram_en_delay=0;sram_en_delay<5;sram_en_delay=sram_en_delay+1)begin
                pola_yolo_Delay_1bit_module #(.delay_clock(12)) delay_module_en_SRAM(
                    .M_AXI_ACLK         (M_AXI_ACLK),
                    .rst                (rst),
                    .over_conf_threshold(1),
                    .input_data         (Sram_write_en[sram_en_delay]),
                    .output_data        (Sram_write_en_delay[sram_en_delay])
                );
            end
        endgenerate
        
        //---------------------------------------------------------------------------------------
        always@(*)begin
            if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==0)begin
                Sram_data_input[0] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? M_AXI_RDATA[111:96]  : (over_conf_threshold ) ? M_AXI_RDATA[15:0]  : 0;
                Sram_data_input[1] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? M_AXI_RDATA[127:112] : (over_conf_threshold ) ? M_AXI_RDATA[31:16] : 0;
                Sram_data_input[2] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold ) ? M_AXI_RDATA[47:32] : 0;
                Sram_data_input[3] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold ) ? M_AXI_RDATA[63:48] : 0;
                Sram_data_input[4] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold ) ? (C_AB_set_FSM==INST_layer_1) ? M_AXI_RDATA[79:64]<<<layer_alignment_number  : M_AXI_RDATA[79:64] : 0;
                Sram_data_input[5] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold ) ? (C_AB_set_FSM==INST_layer_1) ? M_AXI_RDATA[95:80]<<<layer_alignment_number  : M_AXI_RDATA[95:80] : 0;
                Sram_data_input[6] = C_AB_set_FSM==INST_layer_0 ? {4'b0100 , {1'b0,layer_0_y_count} , {1'b0,layer_0_x_count}} : (C_AB_set_FSM==INST_layer_1 ? {4'b0101 , layer_1_y_count , layer_1_x_count} : 0);
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==1)begin
                Sram_data_input[0] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? M_AXI_RDATA[79:64]   : (over_conf_threshold) ? 0                  : 0; 
                Sram_data_input[1] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? M_AXI_RDATA[95:80]   : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[2] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? M_AXI_RDATA[111:96]  : (over_conf_threshold) ? M_AXI_RDATA[15:0]  : 0;
                Sram_data_input[3] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? M_AXI_RDATA[127:112] : (over_conf_threshold) ? M_AXI_RDATA[31:16] : 0;
                Sram_data_input[4] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? (C_AB_set_FSM==INST_layer_1) ? M_AXI_RDATA[47:32]<<<layer_alignment_number  : M_AXI_RDATA[47:32] : 0;
                Sram_data_input[5] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? (C_AB_set_FSM==INST_layer_1) ? M_AXI_RDATA[63:48]<<<layer_alignment_number  : M_AXI_RDATA[63:48] : 0;
                Sram_data_input[6] = C_AB_set_FSM==INST_layer_0 ? {4'b1000 , {1'b0,layer_0_y_count} , {1'b0,layer_0_x_count}} : (C_AB_set_FSM==INST_layer_1 ? {4'b1001 , layer_1_y_count , layer_1_x_count} : 0);
            end else if(Current_state==PROCESS_inst_state && M_AXI_RVALID && M_AXI_RREADY && CH_round_count==2)begin
                Sram_data_input[0] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[1] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[2] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[3] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? 0                  : 0;
                Sram_data_input[4] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? (C_AB_set_FSM==INST_layer_1) ? M_AXI_RDATA[15:0] <<<layer_alignment_number  : M_AXI_RDATA[15:0]  : 0;
                Sram_data_input[5] = ((fill_up_arrive_value_index_0) || (fill_up_arrive_value_index_1)) ? 0                    : (over_conf_threshold) ? (C_AB_set_FSM==INST_layer_1) ? M_AXI_RDATA[31:16]<<<layer_alignment_number  : M_AXI_RDATA[31:16] : 0;
                Sram_data_input[6] = C_AB_set_FSM==INST_layer_0 ? {4'b1100 , {1'b0,layer_0_y_count} , {1'b0,layer_0_x_count}} : (C_AB_set_FSM==INST_layer_1 ? {4'b1101 , layer_1_y_count , layer_1_x_count} : 0);
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

        //------------------------------------Delay fill_up_arrive_value--------------------
        //this parameter can control sram_addr ,if fill_up_arrive the sram_addr will be add 1
        pola_yolo_Delay_unsigned_module #(.delay_clock(12)) delay_module_over_conf_threshold(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (over_conf_threshold),
            .output_data        (over_conf_threshold_delay)
        );
        pola_yolo_Delay_unsigned_module #(.delay_clock(12)) delay_module_fill_up_arrive_value_index_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (fill_up_arrive_value_index_0),
            .output_data        (fill_up_arrive_value_index_0_delay)
        );
        pola_yolo_Delay_unsigned_module #(.delay_clock(12)) delay_module_fill_up_arrive_value_index_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (fill_up_arrive_value_index_1),
            .output_data        (fill_up_arrive_value_index_1_delay)
        );

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
                if(CH_round_count!=0)
                    index_0 <= index_0 + 1;
                else 
                    index_0 <= index_0;
            end else if(over_conf_threshold && C_AB_set_FSM==INST_layer_1)begin
                if(CH_round_count!=0)
                    index_1 <= index_1 + 1;
                else
                    index_1 <= index_1;
            end else begin
                index_0 <= index_0;
                index_1 <= index_1;
            end
        end
        
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                inst_already_finish <= 0;
            else if(over_conf_threshold && C_AB_set_FSM==INST_layer_0 && CH_round_count==0 && C_Data_fix_AXI_FSM_in_fill_up!=1)
                inst_already_finish <= inst_already_finish + 1;
            else if(over_conf_threshold && C_AB_set_FSM==INST_layer_1 && CH_round_count==0 && C_Data_fix_AXI_FSM_in_fill_up!=1)
                inst_already_finish <= inst_already_finish + 1;
            else if(C_AB_set_FSM==INST_layer_0 && fill_up_arrive_value_index_0_delay)
                inst_already_finish <= inst_already_finish + 1;
            else if(C_AB_set_FSM==INST_layer_1 && fill_up_arrive_value_index_1_delay)
                inst_already_finish <= inst_already_finish + 1;
            else
                inst_already_finish <= inst_already_finish;
        end

        always@(*)begin
            total_sram_count = inst_already_finish;
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
        reg [31:0]Next_M_AXI_ARADDR_check;
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Next_M_AXI_ARADDR <= 0;
                Next_M_AXI_ARADDR_check <=0;
            end
            else if(N_Data_fix_FSM==fill_up_0 || N_Data_fix_FSM==fill_up_1)begin
                Next_M_AXI_ARADDR <= Pre_Pre_M_AXI_ARADDR;
                Next_M_AXI_ARADDR_check<=1;
            end
            else if(N_AB_set_FSM==SET_layer_0)begin
                Next_M_AXI_ARADDR <= s_axi_inst_0;
                Next_M_AXI_ARADDR_check<=2;
            end
            else if(M_AXI_ARVALID && N_AB_set_FSM==INST_layer_0)begin
                Next_M_AXI_ARADDR <= s_axi_inst_0 + ((Layer_0_total_arlen+Next_ARLEN) << address_to_arlen);
                Next_M_AXI_ARADDR_check<=3;
            end
            else if(N_AB_set_FSM==SET_layer_1)begin
                Next_M_AXI_ARADDR <= s_axi_inst_1;
                Next_M_AXI_ARADDR_check<=4;
            end
            else if(M_AXI_ARVALID && N_AB_set_FSM==INST_layer_1)begin
                Next_M_AXI_ARADDR <= s_axi_inst_1 + ((Layer_1_total_arlen+Next_ARLEN) << address_to_arlen);
                Next_M_AXI_ARADDR_check<=5;
            end
            else begin
                Next_M_AXI_ARADDR <= Next_M_AXI_ARADDR;
                Next_M_AXI_ARADDR_check<=0;
            end
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
        
        //----------------------Process_FSM------------------------------------
        //1. in process fsm put data in sigmoid func and exp func
        reg [2:0]C_process_point_state , N_process_point_state; //for four point (left down right top)
        //reg [2:0]C_process_iou_state , N_process_iou_state;
        wire PROCESS_calc_state_finish;
        wire PROCESS_iou_calc_state_finish;

        //---------------------PUT YOUR SRAM IN HERE----------------\\
        wire Sram_en_select[0:7];
        assign Sram_en_select[0] = Current_state==3'b001 ? Sram_write_en_delay[0]:Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 1 : 0) : 0; 
        assign Sram_en_select[1] = Current_state==3'b001 ? Sram_write_en_delay[1]:Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 1 : 0) : 0;
        assign Sram_en_select[2] = Current_state==3'b001 ? Sram_write_en_delay[2]:Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 1 : 0) : 0;
        assign Sram_en_select[3] = Current_state==3'b001 ? Sram_write_en_delay[3]:Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 1 : 0) : 0;
        assign Sram_en_select[4] = Current_state==3'b001 ? Sram_write_en_delay[4]:Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 1 : 0) : 0;
        assign Sram_en_select[5] = Current_state==3'b001 ? Sram_write_en[4]      :Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 0 : 0) : 0;
        assign Sram_en_select[6] = Current_state==3'b001 ? Sram_write_en[5]      :Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 0 : 0) : 0;
        assign Sram_en_select[7] = Current_state==3'b001 ? Sram_write_en[6]      :Current_state==3'b010 ? (C_process_point_state==PROCESS_result_state ? 0 : 0) : 0;

        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_1(.clka(M_AXI_ACLK) , .wea(Sram_en_select[0]) , .addra(Sram_addr)  , .dina(data_out_bx)        , .douta(output_answer_line[0]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_2(.clka(M_AXI_ACLK) , .wea(Sram_en_select[1]) , .addra(Sram_addr)  , .dina(data_out_by)        , .douta(output_answer_line[1]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_3(.clka(M_AXI_ACLK) , .wea(Sram_en_select[2]) , .addra(Sram_addr)  , .dina(data_out_bw)        , .douta(output_answer_line[2]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_4(.clka(M_AXI_ACLK) , .wea(Sram_en_select[3]) , .addra(Sram_addr)  , .dina(data_out_bh)        , .douta(output_answer_line[3]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_8(.clka(M_AXI_ACLK) , .wea(Sram_en_select[4]) , .addra(Sram_addr)  , .dina(data_out_add_bw_bh) , .douta(output_answer_line[7]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_5(.clka(M_AXI_ACLK) , .wea(Sram_en_select[5]) , .addra(Sram_addr)  , .dina(Sram_data_input[4]) , .douta(output_answer_line[4]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_6(.clka(M_AXI_ACLK) , .wea(Sram_en_select[6]) , .addra(Sram_addr)  , .dina(Sram_data_input[5]) , .douta(output_answer_line[5]));
        POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_7(.clka(M_AXI_ACLK) , .wea(Sram_en_select[7]) , .addra(Sram_addr)  , .dina(Sram_data_input[6]) , .douta(output_answer_line[6]));
        //POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_1(.clka(M_AXI_ACLK) , .wea(Sram_write_en[0]) , .addra(Sram_addr)  , .dina(Sram_data_input[0]) , .douta(output_answer_line[0]));
        //POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_2(.clka(M_AXI_ACLK) , .wea(Sram_write_en[1]) , .addra(Sram_addr)  , .dina(Sram_data_input[1]) , .douta(output_answer_line[1]));
        //POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_3(.clka(M_AXI_ACLK) , .wea(Sram_write_en[2]) , .addra(Sram_addr)  , .dina(Sram_data_input[2]) , .douta(output_answer_line[2]));
        //POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_4(.clka(M_AXI_ACLK) , .wea(Sram_write_en[3]) , .addra(Sram_addr)  , .dina(Sram_data_input[3]) , .douta(output_answer_line[3]));
        //POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_5(.clka(M_AXI_ACLK) , .wea(Sram_write_en[4]) , .addra(Sram_addr)  , .dina(Sram_data_input[4]) , .douta(output_answer_line[4]));
        //POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_6(.clka(M_AXI_ACLK) , .wea(Sram_write_en[5]) , .addra(Sram_addr)  , .dina(Sram_data_input[5]) , .douta(output_answer_line[5]));
        //POLA_YOLO_INPUT_SRAM_SINGLE_LRY_CHX100 M_7(.clka(M_AXI_ACLK) , .wea(Sram_write_en[6]) , .addra(Sram_addr)  , .dina(Sram_data_input[6]) , .douta(output_answer_line[6]));
        

        //---------------------AW and W condition------------------\\
        reg [C_M_AXI_ADDR_WIDTH-1 : 0]      Next_M_AXI_AWADDR;
        reg [C_M_AXI_ADDR_WIDTH-1 : 0]      Next_TO_boundary_AWLEN;
        reg [C_M_AXI_ADDR_WIDTH-1 : 0]      total_output_need_awlen;
        reg [9 : 0]                         Next_AWLEN;
        wire   check_iou_if_keep_or_not_delay;
        wire   M_AXI_WVALID_pre;
        wire   M_AXI_WLAST_pre;
        assign M_AXI_AWVALID            =   (en_axi_awvalid && M_AXI_AWREADY);
        assign M_AXI_AWADDR             =   Next_M_AXI_AWADDR;//(s_axi_inst_4);
        assign M_AXI_AWLEN              =   Next_AWLEN - 1;
        assign M_AXI_WLAST              =   M_AXI_WLAST_pre;
        assign M_AXI_WVALID             =   M_AXI_WVALID_pre;
        assign M_AXI_WDATA              =   check_iou_if_keep_or_not_delay ? {16'h0001 , sram_output_data_conbine_delay[7*Data_bit-1:0]} : {16'h0000 , sram_output_data_conbine_delay[7*Data_bit-1:0]};

        pola_yolo_Delay_1bit_module #(.delay_clock(2)) delay_signal_keep_or_not(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (CWRITE_state==WRITE_state && check_iou_if_keep_or_not[Sram_addr]==1'b1),
            .output_data        (check_iou_if_keep_or_not_delay)
        );
        pola_yolo_Delay_1bit_module #(.delay_clock(2)) delay_signal_M_AXI_WVALID_pre(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (CWRITE_state==WRITE_state && Sram_addr<sram_need_awlen),
            .output_data        (M_AXI_WVALID_pre)
        );
        pola_yolo_Delay_1bit_module #(.delay_clock(2)) delay_signal_M_AXI_WLAST_pre(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (CWRITE_state==WRITE_state && Sram_addr==sram_need_awlen-1),
            .output_data        (M_AXI_WLAST_pre)
        );

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                total_output_need_awlen <= sram_need_awlen;
            else if(M_AXI_AWVALID && Next_TO_boundary_AWLEN > total_output_need_awlen)
                total_output_need_awlen <= 0;
            else if(M_AXI_AWVALID && Next_TO_boundary_AWLEN < total_output_need_awlen)
                total_output_need_awlen <= total_output_need_awlen - Next_TO_boundary_AWLEN;
            else
                total_output_need_awlen <= total_output_need_awlen;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                Next_TO_boundary_AWLEN <= 0;
            else if(s_axi_start)
                Next_TO_boundary_AWLEN <= (four_K_boundary - M_AXI_AWADDR[11:0]) >> address_to_awlen;
            else 
                Next_TO_boundary_AWLEN <= Next_TO_boundary_AWLEN;
        end

        always@(*)begin
            if(M_AXI_AWVALID && total_output_need_awlen!=0 && Next_TO_boundary_AWLEN >= total_output_need_awlen)
                Next_AWLEN = total_output_need_awlen;
            else if(M_AXI_AWVALID && total_output_need_awlen!=0 && Next_TO_boundary_AWLEN < total_output_need_awlen)
                Next_AWLEN = Next_TO_boundary_AWLEN;
            else
                Next_AWLEN = 1;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                Next_M_AXI_AWADDR <= s_axi_inst_4;
            else
                Next_M_AXI_AWADDR <= Next_M_AXI_AWADDR + (M_AXI_AWLEN << address_to_awlen);
        end
           
        //-------------------------iou-------------------------------------------
        wire iou_finish_signal = (C_process_iou_state==PROCESS_iou_wait_value_state && Sram_addr_delay_for_max_value_cmp==total_sram_count-1) ? 1 : 0;
        pola_yolo_Delay_1bit_module #(.delay_clock(4)) delay_module_iou_finish(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (iou_finish_signal),
            .output_data        (PROCESS_iou_calc_state_finish)
        );

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                C_process_iou_state <= PROCESS_iou_idle_state;
            else
                C_process_iou_state <= N_process_iou_state;
        end

        always@(*)begin
            case (C_process_iou_state)
                PROCESS_iou_idle_state  :   begin
                    if(Current_state==PROCESS_iou_state)        N_process_iou_state = PROCESS_iou_find_state;
                    else                                        N_process_iou_state = PROCESS_iou_idle_state;
                end
                PROCESS_iou_find_state  :   begin
                    if(total_sram_count==0 || total_sram_count==check_iou_if_already_use_count) N_process_iou_state = PROCESS_iou_finish_state;
                    else if(Sram_addr==total_sram_count-1)      N_process_iou_state = PROCESS_iou_wait_value_state;
                    else                                        N_process_iou_state = PROCESS_iou_find_state;
                end
                PROCESS_iou_wait_value_state  :   begin
                    if(Sram_addr_delay_for_max_value_cmp==total_sram_count-1) N_process_iou_state = PROCESS_iou_wait_finish_state;
                    else                                                      N_process_iou_state = PROCESS_iou_wait_value_state;
                end
                PROCESS_iou_wait_finish_state  :   begin
                    //------------------second round--------------\\
                    if(PROCESS_iou_calc_state_finish)           N_process_iou_state = PROCESS_iou_idle_state;
                    else                                        N_process_iou_state = PROCESS_iou_wait_finish_state;
                end
                PROCESS_iou_finish_state  :   begin
                    if(Current_state!=Next_state)               N_process_iou_state = PROCESS_iou_idle_state;
                    else                                        N_process_iou_state = PROCESS_iou_finish_state;
                end
            endcase
        end

        //-----------------------------------------how many box need process--------------------------------------
        assign PROCESS_calc_state_finish = C_process_point_state==PROCESS_result_state ? 1 : 0;
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                C_process_point_state <= PROCESS_idle_state;
            else
                C_process_point_state <= N_process_point_state;
        end

        always@(*)begin
            case (C_process_point_state)
                PROCESS_idle_state : begin
                    if(Current_state==PROCESS_point_state)      N_process_point_state = PROCESS_find_state;
                    else                                        N_process_point_state = PROCESS_idle_state;
                end
                PROCESS_find_state : begin
                    if(total_sram_count==0)                     N_process_point_state = PROCESS_finish_state;
                    else if(Current_state==PROCESS_point_state) N_process_point_state = PROCESS_wait_state;
                    else                                        N_process_point_state = PROCESS_find_state;
                end
                PROCESS_wait_state : begin
                    if(Current_state==PROCESS_point_state)      N_process_point_state = PROCESS_calc_state;
                    else                                        N_process_point_state = PROCESS_wait_state;
                end
                PROCESS_calc_state : begin
                    if(Current_state==PROCESS_point_state)      N_process_point_state = PROCESS_result_state;
                    else                                        N_process_point_state = PROCESS_calc_state;
                end
                PROCESS_result_state : begin
                    if(Sram_addr==total_sram_count-1 && PROCESS_calc_state_finish)  N_process_point_state = PROCESS_finish_state;
                    else if(PROCESS_calc_state_finish)                              N_process_point_state = PROCESS_find_state;
                    else                                                            N_process_point_state = PROCESS_result_state;
                end
                PROCESS_finish_state : begin
                    if(Current_state!=Next_state)           N_process_point_state = PROCESS_idle_state;
                    else                                    N_process_point_state = PROCESS_finish_state;
                end
                default: begin
                    N_process_point_state = PROCESS_idle_state;
                end
            endcase
        end

        //----------------------latch_count_define-----------------------------
        reg en_axi_rcount       , en_axi_wcount;

        //----------------------main state control----------------------------
        //wire   INST_state_finish;
        assign  PROCESS_point_state_finish   =   (C_process_point_state==PROCESS_finish_state)          ? 1 : 0;
        assign  PROCESS_iou_state_finish     =   (C_process_iou_state==PROCESS_iou_finish_state)        ? 1 : 0;
        assign  PROCESS_write_state_finish   =    M_AXI_WLAST;
        assign  IRQ                          =   (Current_state==IDLE_state && already_finish_lock)     ? 1 : 0;
        assign  INST_state_finish            =   (C_AB_set_FSM==READ_data_finish)                       ? 1 : 0;
        //---------------------already_finish_lock----------------------------
        //reg already_finish_lock;
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                already_finish_lock <= 0;
            else if(M_AXI_BVALID)
                already_finish_lock <= 1;
            else
                already_finish_lock <= already_finish_lock;
        end
        //----------------------main-FSM---------------------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst || already_finish_lock)
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
                    if(INST_state_finish)    Next_state = PROCESS_point_state;
                    else                     Next_state = PROCESS_inst_state;
                end
                PROCESS_point_state   :   begin
                    if(PROCESS_point_state_finish)  Next_state = PROCESS_iou_state;
                    else                            Next_state = PROCESS_point_state;
                end
                PROCESS_iou_state   :   begin
                    if(PROCESS_iou_state_finish)    Next_state = PROCESS_write_state;
                    else                            Next_state = PROCESS_iou_state;
                end
                PROCESS_write_state     :   begin
                    if(PROCESS_write_state_finish)  Next_state = MAIN_finish_state;
                    else                            Next_state = PROCESS_write_state;
                end
                MAIN_finish_state      :   begin
                    if(M_AXI_BVALID)                Next_state = IDLE_state;
                    else                            Next_state = MAIN_finish_state;
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
            if(rst)
                en_axi_rcount <= 0;
            else if(CREAD_state==IDLE_state)
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
            if(rst)
                en_axi_wcount <= 0;
            else if(CWRITE_state==IDLE_state)
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
                if(C_Data_fix_AXI_FSM==keep_go_axi && over_conf_threshold_delay)begin
                    Sram_addr <= Sram_addr + 1;
                end else if(C_Data_fix_AXI_FSM==reset_sram_0_axi)begin
                    Sram_addr <= inst_already_finish;//0;
                end else if(C_Data_fix_AXI_FSM==reset_sram_1_axi)begin
                    Sram_addr <= inst_already_finish;//index_0;
                end else if(fill_up_arrive_value_index_0_delay||fill_up_arrive_value_index_1_delay)begin
                    Sram_addr <= Sram_addr + 1;    
                end else begin
                    Sram_addr <= Sram_addr;    
                end
            end else if (Current_state==PROCESS_point_state)begin
                if(C_process_point_state==PROCESS_idle_state)begin
                    Sram_addr <= 0;
                end else if(C_process_point_state==PROCESS_result_state && PROCESS_calc_state_finish)begin
                    Sram_addr <= Sram_addr + 1;
                end else begin
                    Sram_addr <= Sram_addr;    
                end
            end else if(Current_state==PROCESS_iou_state)begin
                if(C_process_iou_state == PROCESS_iou_idle_state)begin
                    Sram_addr <= 0;
                end else if(C_process_iou_state == PROCESS_iou_find_state)begin
                    Sram_addr <= Sram_addr + 1;
                end else begin
                    Sram_addr <= Sram_addr;    
                end
            end else if(Current_state==PROCESS_write_state)begin
                if(CWRITE_state==IDLE_state)begin
                    Sram_addr <= 0;
                end else if(CWRITE_state==WRITE_state)begin
                    Sram_addr <= Sram_addr + 1;
                end else begin
                    Sram_addr <= Sram_addr;
                end
            end else begin
                Sram_addr <= Sram_addr;
            end
        end
        //----------------------------------sram_addr delay-------------------------------
        //delay 6 clk , find -> wait -> value -> add -> mul -> result
        pola_yolo_Delay_signed_module #(.delay_clock(6)) delay_module_SRAM_ADDR_for_keep_or_not_and_already_use(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (Sram_addr),
            .output_data        (Sram_addr_delay_for_keep_or_not_and_already_use)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(2)) delay_module_SRAM_ADDR_for_max_value_cmp(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (Sram_addr),
            .output_data        (Sram_addr_delay_for_max_value_cmp)
        );
        //----------------------------------parameter delay--------------------------------
        //1.Current_state==3'b001 find and insert the value to sram module
        wire [Data_bit-1 : 0] delay_data_parameter , delay_data_sigmoid_0 , delay_data_sigmoid_1;
        pola_yolo_Delay_signed_module #(.delay_clock(1)) delay_module_data_parameter_SRAM(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (output_answer_line[6]),
            .output_data        (delay_data_parameter)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(1)) delay_module_data_exp_0_SRAM(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (output_answer_line[2]),
            .output_data        (delay_data_sigmoid_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(1)) delay_module_data_exp_1_SRAM(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (output_answer_line[3]),
            .output_data        (delay_data_sigmoid_1)
        );
        //2.Current_state==3'b010 take out the sram value and trans the value to left right top down ponint
        wire signed[8*Data_bit-1:0]sram_output_data_conbine = {
                output_answer_line[6],
                output_answer_line[7],
                output_answer_line[5],
                output_answer_line[4],
                output_answer_line[3],
                output_answer_line[2],
                output_answer_line[1],
                output_answer_line[0]
            };
        
        genvar idq;
        generate
            for(idq=0;idq<8;idq=idq+1)begin
                pola_yolo_Delay_signed_module#(.delay_clock(1)) delay_module_data_sram_output(
                    .M_AXI_ACLK         (M_AXI_ACLK),
                    .rst                (rst),
                    .over_conf_threshold(1),
                    .input_data         (sram_output_data_conbine[((Data_bit * (idq+1))-1)-:16]),
                    .output_data        (sram_output_data_conbine_delay[((Data_bit * (idq+1))-1)-:16])
                );
            end
        endgenerate

        //-------------i need use it but first mission we need to find out pointer 
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                check_iou_if_keep_or_not <=  0;
            end else if(Current_state==PROCESS_iou_state && max_index_pointer==Sram_addr_delay_for_keep_or_not_and_already_use)begin
                check_iou_if_keep_or_not[Sram_addr_delay_for_keep_or_not_and_already_use] <= 1'b1;
            end else if(Current_state==PROCESS_iou_state && is_delete_singal) begin
                check_iou_if_keep_or_not[Sram_addr_delay_for_keep_or_not_and_already_use] <= 1'b0;
            end else begin
                check_iou_if_keep_or_not    <=  check_iou_if_keep_or_not;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                check_iou_if_already_use_or_not <= 0;
            end else if(Current_state==PROCESS_point_state && C_process_point_state==PROCESS_finish_state)begin
                check_iou_if_already_use_or_not[max_index_pointer] <= 1;
            end else if(Current_state==PROCESS_iou_state && is_delete_singal)begin
                check_iou_if_already_use_or_not[Sram_addr_delay_for_keep_or_not_and_already_use] <= 1;
            end else begin
                check_iou_if_already_use_or_not <= check_iou_if_already_use_or_not;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                check_iou_if_already_use_count <= 0;
            end /*else if(Current_state==PROCESS_point_state && C_process_point_state==PROCESS_finish_state)begin
                check_iou_if_already_use_count <= check_iou_if_already_use_count + 1;
            end */else if(Current_state==PROCESS_iou_state && PROCESS_iou_calc_state_finish)begin
                check_iou_if_already_use_count <= check_iou_if_already_use_count + 1;
            end else if(Current_state==PROCESS_iou_state && is_delete_singal && max_index_pointer!=Sram_addr_delay_for_keep_or_not_and_already_use)begin
                check_iou_if_already_use_count <= check_iou_if_already_use_count + 1;
            end else begin
                check_iou_if_already_use_count <= check_iou_if_already_use_count;
            end
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                max_index_pointer_pre <= 0;
            else if((Current_state==PROCESS_iou_state && C_process_iou_state==PROCESS_iou_wait_value_state) && Max_value_cmp[5]< $signed(sram_output_data_conbine_delay[((Data_bit * 5)-1)-:16]) && Sram_addr_delay_for_max_value_cmp!=max_index_pointer)
                max_index_pointer_pre <= Sram_addr_delay_for_max_value_cmp;
            else
                max_index_pointer_pre <= max_index_pointer_pre;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst)
                max_index_pointer <= 0;
            else if(C_process_point_state==PROCESS_result_state && Max_value_cmp[5]<data_out_conf)
                max_index_pointer <= Sram_addr;
            else if(Current_state==PROCESS_iou_state && PROCESS_iou_calc_state_finish)
                max_index_pointer <= max_index_pointer_pre;
            else
                max_index_pointer <= max_index_pointer;
        end

        always@(posedge M_AXI_ACLK)begin
            if(rst || (Current_state==PROCESS_iou_state && C_process_iou_state==PROCESS_iou_idle_state))begin
                Max_value_cmp[0] <= 0;
                Max_value_cmp[1] <= 0;
                Max_value_cmp[2] <= 0;
                Max_value_cmp[3] <= 0;
                Max_value_cmp[4] <= 0;
                Max_value_cmp[5] <= -1024; //speical number , because the value must pass sigmoid and the sigmoid lease value is -1
            end else if(C_process_point_state==PROCESS_result_state && Max_value_cmp[5]<data_out_conf)begin
                Max_value_cmp[0] <= data_out_bx;
                Max_value_cmp[1] <= data_out_by;
                Max_value_cmp[2] <= data_out_bw;
                Max_value_cmp[3] <= data_out_bh;
                Max_value_cmp[4] <= data_out_add_bw_bh;
                Max_value_cmp[5] <= data_out_conf;
            end else if((Current_state==PROCESS_iou_state && C_process_iou_state==PROCESS_iou_wait_value_state) && Max_value_cmp[5]< $signed(sram_output_data_conbine_delay[((Data_bit * 5)-1)-:16]) && Sram_addr_delay_for_max_value_cmp!=max_index_pointer)begin
                Max_value_cmp[0] <= sram_output_data_conbine_delay[((Data_bit * 1)-1)-:16];
                Max_value_cmp[1] <= sram_output_data_conbine_delay[((Data_bit * 2)-1)-:16];
                Max_value_cmp[2] <= sram_output_data_conbine_delay[((Data_bit * 3)-1)-:16];
                Max_value_cmp[3] <= sram_output_data_conbine_delay[((Data_bit * 4)-1)-:16];
                Max_value_cmp[4] <= sram_output_data_conbine_delay[((Data_bit * 7)-1)-:16];
                Max_value_cmp[5] <= sram_output_data_conbine_delay[((Data_bit * 5)-1)-:16];
            end else begin
                Max_value_cmp[0] <= Max_value_cmp[0];
                Max_value_cmp[1] <= Max_value_cmp[1];
                Max_value_cmp[2] <= Max_value_cmp[2];
                Max_value_cmp[3] <= Max_value_cmp[3];
                Max_value_cmp[4] <= Max_value_cmp[4];
                Max_value_cmp[5] <= Max_value_cmp[5];
            end
        end        
        
        reg signed[Data_bit-1:0]Max_value_cmp_left;
        reg signed[Data_bit-1:0]Max_value_cmp_down;
        reg signed[Data_bit-1:0]Max_value_cmp_right;
        reg signed[Data_bit-1:0]Max_value_cmp_top;
        reg signed[Data_bit-1:0]Max_value_cmp_w_add_h;
        reg signed[Data_bit-1:0]Max_value_cmp_conf;
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                Max_value_cmp_left      <= 0;
                Max_value_cmp_down      <= 0;
                Max_value_cmp_right     <= 0;
                Max_value_cmp_top       <= 0;
                Max_value_cmp_w_add_h   <= 0;
                Max_value_cmp_conf      <= 0;
            end else if(Current_state==PROCESS_iou_state && C_process_iou_state==PROCESS_iou_idle_state)begin
                Max_value_cmp_left      <= Max_value_cmp[0];
                Max_value_cmp_down      <= Max_value_cmp[1];
                Max_value_cmp_right     <= Max_value_cmp[2];
                Max_value_cmp_top       <= Max_value_cmp[3];
                Max_value_cmp_w_add_h   <= Max_value_cmp[4];
                Max_value_cmp_conf      <= Max_value_cmp[5];
            end else begin
                Max_value_cmp_left      <= Max_value_cmp_left;
                Max_value_cmp_down      <= Max_value_cmp_down;
                Max_value_cmp_right     <= Max_value_cmp_right;
                Max_value_cmp_top       <= Max_value_cmp_top;
                Max_value_cmp_w_add_h   <= Max_value_cmp_w_add_h;
                Max_value_cmp_conf      <= Max_value_cmp_conf;
            end
        end
        //-----------------------------------PE module---------------------------------------
        wire YOLO_PE_Func_Control_TOP_over_conf_threshold = (C_Data_fix_AXI_FSM_in_fill_up && (fill_up_arrive_value_index_0||fill_up_arrive_value_index_1)) ? C_Data_fix_AXI_FSM_in_fill_up : over_conf_threshold;
        wire [Data_bit-1 : 0]data_parameter = (C_Data_fix_AXI_FSM_in_fill_up) ? delay_data_parameter : Sram_data_input[6]; //use parameter delay for sram delay one clk
        wire signed[Data_bit-1 : 0]data_in_bx0    = Current_state==3'b001 ? ((C_AB_set_FSM==INST_layer_1) ? Sram_data_input[0]<<<layer_alignment_number : Sram_data_input[0]) : Current_state==3'b010 ? (sram_output_data_conbine_delay[((Data_bit * 1)-1)-:16]) : Current_state==3'b011 ? (sram_output_data_conbine_delay[((Data_bit * 1)-1)-:16]) : 0;
        wire signed[Data_bit-1 : 0]data_in_by0    = Current_state==3'b001 ? ((C_AB_set_FSM==INST_layer_1) ? Sram_data_input[1]<<<layer_alignment_number : Sram_data_input[1]) : Current_state==3'b010 ? (sram_output_data_conbine_delay[((Data_bit * 2)-1)-:16]) : Current_state==3'b011 ? (sram_output_data_conbine_delay[((Data_bit * 2)-1)-:16]) : 0;
        wire signed[Data_bit-1 : 0]data_in_bw0    = Current_state==3'b001 ? ((C_AB_set_FSM==INST_layer_1) ? Sram_data_input[2]<<<layer_alignment_number : Sram_data_input[2]) : Current_state==3'b010 ? (sram_output_data_conbine_delay[((Data_bit * 3)-1)-:16]) : Current_state==3'b011 ? (sram_output_data_conbine_delay[((Data_bit * 3)-1)-:16]) : 0;
        wire signed[Data_bit-1 : 0]data_in_bh0    = Current_state==3'b001 ? ((C_AB_set_FSM==INST_layer_1) ? Sram_data_input[3]<<<layer_alignment_number : Sram_data_input[3]) : Current_state==3'b010 ? (sram_output_data_conbine_delay[((Data_bit * 4)-1)-:16]) : Current_state==3'b011 ? (sram_output_data_conbine_delay[((Data_bit * 4)-1)-:16]) : 0;
        wire signed[Data_bit-1 : 0]data_in_bx1    = Current_state==3'b001 ? ((C_AB_set_FSM==INST_layer_1) ? Sram_data_input[4]<<<layer_alignment_number : Sram_data_input[4]) : Current_state==3'b010 ? (sram_output_data_conbine_delay[((Data_bit * 5)-1)-:16]) : Current_state==3'b011 ? (sram_output_data_conbine_delay[((Data_bit * 5)-1)-:16]) : 0;
        wire signed[Data_bit-1 : 0]data_in_by1    = Current_state==3'b001 ? ((C_AB_set_FSM==INST_layer_1) ? Sram_data_input[5]<<<layer_alignment_number : Sram_data_input[5]) : Current_state==3'b010 ? (sram_output_data_conbine_delay[((Data_bit * 6)-1)-:16]) : Current_state==3'b011 ? (sram_output_data_conbine_delay[((Data_bit * 6)-1)-:16]) : 0;
        wire signed[Data_bit-1 : 0]data_in_bw1    = Current_state==3'b001 ? ((C_AB_set_FSM==INST_layer_1) ? delay_data_sigmoid_0 : 0)                                         : Current_state==3'b010 ? 0                                                        : Current_state==3'b011 ? (sram_output_data_conbine_delay[((Data_bit * 7)-1)-:16]) : 0;
        wire signed[Data_bit-1 : 0]data_in_bh1    = Current_state==3'b001 ? delay_data_sigmoid_1 : 0;
        YOLO_PE_Func_Control YOLO_PE_Func_Control_TOP(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .over_conf_threshold(YOLO_PE_Func_Control_TOP_over_conf_threshold),//with two condition , first is in the normal state ,  second is fill_up state
            .Current_state(Current_state),
            .data_parameter(data_parameter),
            .Max_value_cmp_left(Max_value_cmp_left),
            .Max_value_cmp_down(Max_value_cmp_down),
            .Max_value_cmp_right(Max_value_cmp_right),
            .Max_value_cmp_top(Max_value_cmp_top),
            .Max_value_cmp_w_add_h(Max_value_cmp_w_add_h),
            .Max_value_cmp_conf(Max_value_cmp_conf),
            .data_in_bx0(data_in_bx0),
            .data_in_by0(data_in_by0),
            .data_in_bw0(data_in_bw0),
            .data_in_bh0(data_in_bh0),
            .data_in_bx1(data_in_bx1),
            .data_in_by1(data_in_by1),
            .data_in_bw1(data_in_bw1),
            .data_in_bh1(data_in_bh1),
            .data_out_bx(data_out_bx),
            .data_out_by(data_out_by),
            .data_out_bw(data_out_bw),
            .data_out_bh(data_out_bh),
            .data_out_conf(data_out_conf),
            .data_out_class(data_out_class),
            .data_out_index(data_out_index),
            .data_out_add_bw_bh(data_out_add_bw_bh),
            .is_delete_singal(is_delete_singal)
        );
endmodule
