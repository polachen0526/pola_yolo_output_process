`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/17 17:38:55
// Design Name: 
// Module Name: YOLO_PE_Func_Control
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

module YOLO_PE_Func_Control#(
        parameter Data_bit                  = 16,
        parameter exp_cell                  = 9,            // for EXP module total 9 cell
        parameter layer_shift_bit           = 10,
        parameter repair_bit                = 0,
        parameter sigmoid_exp_add_number    = 6,            // sigmoid use 2 add and exp use 4 add, total = exp_cell * sigmoid_exp_add_number
        parameter exp_anchor_cell           = 8,            // for exp_anchor need how many step to finish , check the most number and div(/) it
        parameter exp_anchor_number         = 2,            // after the EXP module , mul anchor with EXP_module_result
        parameter delay_clock_sigmoid       = 2,
        parameter delay_clock_exp           = 9,
        parameter avoid_overflow_number     = 3,
        parameter stride_module_cell        = 7,
        parameter series_present            = 4
    )(
        input  M_AXI_ACLK,
        input  rst,
        input  over_conf_threshold,
        input  [1:0]Current_state,
        input  [Data_bit-1:0] data_parameter,
        input  signed[Data_bit-1:0] data_in_bx0,   // if FSM is box prediction , data_in_bx0 = sigmoid(output_answer_line[0])  else if FSM is IOU , data_in_bx0 = bx0;
        input  signed[Data_bit-1:0] data_in_by0,   // if FSM is box prediction , data_in_by0 = sigmoid(output_answer_line[1])  else if FSM is IOU , data_in_by0 = by0;
        input  signed[Data_bit-1:0] data_in_bw0,   // if FSM is box prediction , data_in_bw0 = exp(output_answer_line[2])      else if FSM is IOU , data_in_bw0 = bw0;
        input  signed[Data_bit-1:0] data_in_bh0,   // if FSM is box prediction , data_in_bh0 = exp(output_answer_line[3])      else if FSM is IOU , data_in_bh0 = bh0;
        input  signed[Data_bit-1:0] data_in_bx1,   // if FSM is box prediction , data_in_bx1 = conf                            else if FSM is IOU , data_in_bx1 = bx1;
        input  signed[Data_bit-1:0] data_in_by1,   // if FSM is box prediction , data_in_by1 = class                           else if FSM is IOU , data_in_by1 = by1;
        input  signed[Data_bit-1:0] data_in_bw1,   // if FSM is box prediction , data_in_bw1 = None                            else if FSM is IOU , data_in_bw1 = bw1;
        input  signed[Data_bit-1:0] data_in_bh1,   // if FSM is box prediction , data_in_by1 = None                            else if FSM is IOU , data_in_by1 = bh1;
        output signed[Data_bit-1:0] data_out_bx,
        output signed[Data_bit-1:0] data_out_by,
        output signed[Data_bit-1:0] data_out_bw,
        output signed[Data_bit-1:0] data_out_bh,
        output signed[Data_bit-1:0] data_out_conf,
        output signed[Data_bit-1:0] data_out_class,
        output signed[Data_bit-1:0] data_out_index
    );
        //---------------------------anyone please dont fix the coding--------------
        //1.if use the top current_state wire single , this code must broken , not statble
        reg [1:0]Current_state_YOLO_PE_FUNC_CONTROL;
        always@(posedge M_AXI_ACLK)begin
            if(rst)
                Current_state_YOLO_PE_FUNC_CONTROL <= 0;
            else if(Current_state==2'b01)
                Current_state_YOLO_PE_FUNC_CONTROL <= 1;
            else if(Current_state==2'b10)
                Current_state_YOLO_PE_FUNC_CONTROL <= 2;
            else if(Current_state==2'b11)
                Current_state_YOLO_PE_FUNC_CONTROL <= 3;
            else
                Current_state_YOLO_PE_FUNC_CONTROL <= Current_state_YOLO_PE_FUNC_CONTROL;
        end
        //----------------------------------parameter delay--------------------------------
        wire [Data_bit-1 : 0] delay_data_parameter_sigmoid;
        wire [Data_bit-1 : 0] delay_data_parameter_exp;
        pola_yolo_Delay_signed_module #(.delay_clock(delay_clock_sigmoid)) delay_module_data_parameter_alignment_sigmoid(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(over_conf_threshold),
            .input_data         (data_parameter),
            .output_data        (delay_data_parameter_sigmoid)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(delay_clock_exp)) delay_module_data_parameter_alignment_exp(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(over_conf_threshold),
            .input_data         (data_parameter),
            .output_data        (delay_data_parameter_exp)
        );
        //----------------------------------2 sigmoid -------------------------------------
        wire signed[Data_bit-1:0] sigmoid_output_alpha_0 , sigmoid_output_beta_0;
        wire signed[Data_bit-1:0] sigmoid_output_alpha_1 , sigmoid_output_beta_1;
        wire       [8:0]          sigmoid_output_add_signal_0 , sigmoid_output_add_signal_1;
        wire [4:0]debug_line_0,debug_line_1;

        fpga_linear_sigmoid_func_layer_PLAN #(.bias_shift_bit(layer_shift_bit)) sigmoid_layer_total_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .repair_bit         (repair_bit),
            .input_data         (data_in_bx0),
            .output_data_alpha  (sigmoid_output_alpha_0),
            .output_data_beta   (sigmoid_output_beta_0),
            .debug_line         (debug_line_0),
            .output_add_signal  (sigmoid_output_add_signal_0)
        );
        fpga_linear_sigmoid_func_layer_PLAN #(.bias_shift_bit(layer_shift_bit)) sigmoid_layer_total_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .repair_bit         (repair_bit),
            .input_data         (data_in_by0),
            .output_data_alpha  (sigmoid_output_alpha_1),
            .output_data_beta   (sigmoid_output_beta_1),
            .debug_line         (debug_line_1),
            .output_add_signal  (sigmoid_output_add_signal_1)
        );

        //----------------------------------2 exp -------------------------------------
        wire signed[Data_bit-1:0]EXP_initial_value_0    = 1<<<layer_shift_bit;
        wire signed[Data_bit-1:0]EXP_initial_value_1    = 1<<<layer_shift_bit;
        wire signed[Data_bit-1:0]ORG_input_data_0       = data_in_bw0;
        wire signed[Data_bit-1:0]ORG_input_data_1       = data_in_bh0;
        wire signed[(exp_cell-1)*(Data_bit)-1:0]        EXP_input_data_0;
        wire signed[(exp_cell-1)*(Data_bit)-1:0]        EXP_input_data_1;
        wire signed[(exp_cell-1)*(Data_bit)-1:0]        EXP_input_K_data_0;   
        wire signed[(exp_cell-1)*(Data_bit)-1:0]        EXP_input_K_data_1;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_alpha_0;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_alpha_1;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_beta_0;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_beta_1;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_K_alpha_0;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_K_alpha_1;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_K_beta_0;
        wire signed[exp_cell*(Data_bit)-1:0]            output_data_K_beta_1;
        wire       [exp_cell*2-1:0]exp_output_add_signal_0 , exp_output_add_signal_1;

        fpga_exp_lookuptable_func_layer_total #(.bias_shift_bit(layer_shift_bit)) exp_layer_total_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .repair_bit         (repair_bit),
            .EXP_initial_value  (EXP_initial_value_0),
            .ORG_input_data     (ORG_input_data_0),
            .EXP_input_data     (EXP_input_data_0),
            .EXP_input_K_data   (EXP_input_K_data_0),
            .output_data_alpha  (output_data_alpha_0),
            .output_data_beta   (output_data_beta_0),
            .output_data_K_alpha(output_data_K_alpha_0),
            .output_data_K_beta (output_data_K_beta_0),
            .output_add_signal  (exp_output_add_signal_0)
        );
        fpga_exp_lookuptable_func_layer_total #(.bias_shift_bit(layer_shift_bit)) exp_layer_total_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .repair_bit         (repair_bit),
            .EXP_initial_value  (EXP_initial_value_1),
            .ORG_input_data     (ORG_input_data_1),
            .EXP_input_data     (EXP_input_data_1),   
            .EXP_input_K_data   (EXP_input_K_data_1),
            .output_data_alpha  (output_data_alpha_1),
            .output_data_beta   (output_data_beta_1),
            .output_data_K_alpha(output_data_K_alpha_1),
            .output_data_K_beta (output_data_K_beta_1),
            .output_add_signal  (exp_output_add_signal_1)
        );

        //--------------------------------output_add_signal_conbine---------------------
        wire [9*sigmoid_exp_add_number-1:0]add_signal_all_output_data_control;
        assign add_signal_all_output_data_control = {
            exp_output_add_signal_1[18-1-:2] , exp_output_add_signal_0[18-1-:2] , sigmoid_output_add_signal_1[9-1-:1] , sigmoid_output_add_signal_0[9-1-:1] ,
            exp_output_add_signal_1[16-1-:2] , exp_output_add_signal_0[16-1-:2] , sigmoid_output_add_signal_1[8-1-:1] , sigmoid_output_add_signal_0[8-1-:1] ,
            exp_output_add_signal_1[14-1-:2] , exp_output_add_signal_0[14-1-:2] , sigmoid_output_add_signal_1[7-1-:1] , sigmoid_output_add_signal_0[7-1-:1] ,
            exp_output_add_signal_1[12-1-:2] , exp_output_add_signal_0[12-1-:2] , sigmoid_output_add_signal_1[6-1-:1] , sigmoid_output_add_signal_0[6-1-:1] ,
            exp_output_add_signal_1[10-1-:2] , exp_output_add_signal_0[10-1-:2] , sigmoid_output_add_signal_1[5-1-:1] , sigmoid_output_add_signal_0[5-1-:1] ,
            exp_output_add_signal_1[8-1-: 2] , exp_output_add_signal_0[8-1-: 2] , sigmoid_output_add_signal_1[4-1-:1] , sigmoid_output_add_signal_0[4-1-:1] ,
            exp_output_add_signal_1[6-1-: 2] , exp_output_add_signal_0[6-1-: 2] , sigmoid_output_add_signal_1[3-1-:1] , sigmoid_output_add_signal_0[3-1-:1] ,
            exp_output_add_signal_1[4-1-: 2] , exp_output_add_signal_0[4-1-: 2] , sigmoid_output_add_signal_1[2-1-:1] , sigmoid_output_add_signal_0[2-1-:1] ,
            exp_output_add_signal_1[2-1-: 2] , exp_output_add_signal_0[2-1-: 2] , sigmoid_output_add_signal_1[1-1-:1] , sigmoid_output_add_signal_0[1-1-:1]
        };
        //--------------------------------data_path_control-----------------------------
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_1_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_2_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_3_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_4_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_5_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_6_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_7_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_8_output_data_control;
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_9_output_data_control;
        wire signed[9*sigmoid_exp_add_number*Data_bit-1:0]add_element_all_output_data_control;
        
        //--------------------------------sigmoid_stride_module-------------------------
        wire  signed  [stride_module_cell * Data_bit-1:0] sigmoid_stride_output_data_0 , sigmoid_stride_output_data_1;
        stride_func_layer_total sigmoid_stride_func_layer_0(
            .rst            (rst),
            .M_AXI_ACLK     (M_AXI_ACLK),
            .data_parameter (data_parameter),
            .input_data     (add_element_2_output_data_control[(Data_bit-1)-:16]>>>avoid_overflow_number),
            .output_data    (sigmoid_stride_output_data_0)
        );
        stride_func_layer_total sigmoid_stride_func_layer_1(
            .rst            (rst),
            .M_AXI_ACLK     (M_AXI_ACLK),
            .data_parameter (data_parameter),
            .input_data     (add_element_2_output_data_control[(2*Data_bit-1)-:16]>>>avoid_overflow_number),
            .output_data    (sigmoid_stride_output_data_1)
        );

        //----------------------------------generate after----------------------------------------------
        wire [Data_bit-1:0]add_sigmoid_stride_output_2_0 = sigmoid_stride_output_data_0[(1 * Data_bit-1)-:16];
        wire [Data_bit-1:0]add_sigmoid_stride_output_2_1 = sigmoid_stride_output_data_1[(1 * Data_bit-1)-:16];
        wire [Data_bit-1:0]add_sigmoid_stride_output_3_0 , add_sigmoid_stride_output_3_1;
        wire [Data_bit-1:0]add_sigmoid_stride_output_4_0 , add_sigmoid_stride_output_4_1;
        wire [Data_bit-1:0]add_sigmoid_stride_output_5_0 , add_sigmoid_stride_output_5_1;
        wire [Data_bit-1:0]add_sigmoid_stride_output_6_0 , add_sigmoid_stride_output_6_1;
        wire [Data_bit-1:0]add_sigmoid_stride_output_7_0 , add_sigmoid_stride_output_7_1;
        wire [Data_bit-1:0]add_sigmoid_stride_output_8_0 , add_sigmoid_stride_output_8_1;
        wire [Data_bit-1:0]add_sigmoid_stride_output_9_0 , add_sigmoid_stride_output_9_1;
        /*
        pola_yolo_Delay_signed_module #(.delay_clock(0)) delay_module_sigmoid_stride_func_layer_0_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(1 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_2_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(0)) delay_module_sigmoid_stride_func_layer_0_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(1 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_2_1)
        );
        */
        pola_yolo_Delay_signed_module #(.delay_clock(1)) delay_module_sigmoid_stride_func_layer_1_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(2 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_3_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(1)) delay_module_sigmoid_stride_func_layer_1_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(2 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_3_1)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(2)) delay_module_sigmoid_stride_func_layer_2_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(3 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_4_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(2)) delay_module_sigmoid_stride_func_layer_2_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(3 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_4_1)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(3)) delay_module_sigmoid_stride_func_layer_3_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(4 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_5_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(3)) delay_module_sigmoid_stride_func_layer_3_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(4 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_5_1)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(4)) delay_module_sigmoid_stride_func_layer_4_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(5 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_6_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(4)) delay_module_sigmoid_stride_func_layer_4_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(5 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_6_1)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(5)) delay_module_sigmoid_stride_func_layer_5_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(6 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_7_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(5)) delay_module_sigmoid_stride_func_layer_5_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(6 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_7_1)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(6)) delay_module_sigmoid_stride_func_layer_6_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(7 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_8_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(6)) delay_module_sigmoid_stride_func_layer_6_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(7 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_8_1)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(7)) delay_module_sigmoid_stride_func_layer_7_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_0[(8 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_9_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(7)) delay_module_sigmoid_stride_func_layer_7_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (sigmoid_stride_output_data_1[(8 * Data_bit-1)-:16]),
            .output_data        (add_sigmoid_stride_output_9_1)
        );
        assign{
                add_element_9_output_data_control,add_element_8_output_data_control,add_element_7_output_data_control,
                add_element_6_output_data_control,add_element_5_output_data_control,add_element_4_output_data_control,
                add_element_3_output_data_control,add_element_2_output_data_control,add_element_1_output_data_control
            } = add_element_all_output_data_control;

        assign EXP_input_data_0   = {add_element_9_output_data_control[3*Data_bit-1-:16],add_element_8_output_data_control[3*Data_bit-1-:16],add_element_7_output_data_control[3*Data_bit-1-:16],add_element_6_output_data_control[3*Data_bit-1-:16],add_element_5_output_data_control[3*Data_bit-1-:16],add_element_4_output_data_control[3*Data_bit-1-:16],add_element_3_output_data_control[3*Data_bit-1-:16],add_element_2_output_data_control[3*Data_bit-1-:16],add_element_1_output_data_control[3*Data_bit-1-:16]};
        assign EXP_input_K_data_0 = {add_element_9_output_data_control[4*Data_bit-1-:16],add_element_8_output_data_control[4*Data_bit-1-:16],add_element_7_output_data_control[4*Data_bit-1-:16],add_element_6_output_data_control[4*Data_bit-1-:16],add_element_5_output_data_control[4*Data_bit-1-:16],add_element_4_output_data_control[4*Data_bit-1-:16],add_element_3_output_data_control[4*Data_bit-1-:16],add_element_2_output_data_control[4*Data_bit-1-:16],add_element_1_output_data_control[4*Data_bit-1-:16]};
        assign EXP_input_data_1   = {add_element_9_output_data_control[5*Data_bit-1-:16],add_element_8_output_data_control[5*Data_bit-1-:16],add_element_7_output_data_control[5*Data_bit-1-:16],add_element_6_output_data_control[5*Data_bit-1-:16],add_element_5_output_data_control[5*Data_bit-1-:16],add_element_4_output_data_control[5*Data_bit-1-:16],add_element_3_output_data_control[5*Data_bit-1-:16],add_element_2_output_data_control[5*Data_bit-1-:16],add_element_1_output_data_control[5*Data_bit-1-:16]};
        assign EXP_input_K_data_1 = {add_element_9_output_data_control[6*Data_bit-1-:16],add_element_8_output_data_control[6*Data_bit-1-:16],add_element_7_output_data_control[6*Data_bit-1-:16],add_element_6_output_data_control[6*Data_bit-1-:16],add_element_5_output_data_control[6*Data_bit-1-:16],add_element_4_output_data_control[6*Data_bit-1-:16],add_element_3_output_data_control[6*Data_bit-1-:16],add_element_2_output_data_control[6*Data_bit-1-:16],add_element_1_output_data_control[6*Data_bit-1-:16]};
        
        wire signed[Data_bit-1:0]add_element_1_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? sigmoid_output_alpha_0                     : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? sigmoid_output_alpha_1                     : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(Data_bit-1)-:16]    : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(Data_bit-1)-:16]    : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(Data_bit-1)-:16]    : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(Data_bit-1)-:16]    : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? sigmoid_output_beta_0                      : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? sigmoid_output_beta_1                      : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(Data_bit-1)-:16]     : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(Data_bit-1)-:16]     : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(Data_bit-1)-:16]     : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_1_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(Data_bit-1)-:16]     : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_1_total_alpha_data_control = {
            add_element_1_6_alpha_data_control,
            add_element_1_5_alpha_data_control,
            add_element_1_4_alpha_data_control,
            add_element_1_3_alpha_data_control,
            add_element_1_2_alpha_data_control,
            add_element_1_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_1_total_beta_data_control = {
            add_element_1_6_beta_data_control,
            add_element_1_5_beta_data_control,
            add_element_1_4_beta_data_control,
            add_element_1_3_beta_data_control,
            add_element_1_2_beta_data_control,
            add_element_1_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_2_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_1_output_data_control[(Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_1_output_data_control[(2*Data_bit-1)-:16] : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(2*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(2*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(2*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(2*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? delay_data_parameter_sigmoid[3-:4]<<<layer_shift_bit: 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? delay_data_parameter_sigmoid[7-:4]<<<layer_shift_bit: 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(2*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(2*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(2*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_2_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(2*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_2_total_alpha_data_control = {
            add_element_2_6_alpha_data_control,
            add_element_2_5_alpha_data_control,
            add_element_2_4_alpha_data_control,
            add_element_2_3_alpha_data_control,
            add_element_2_2_alpha_data_control,
            add_element_2_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_2_total_beta_data_control = {
            add_element_2_6_beta_data_control,
            add_element_2_5_beta_data_control,
            add_element_2_4_beta_data_control,
            add_element_2_3_beta_data_control,
            add_element_2_2_beta_data_control,
            add_element_2_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_3_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_2_output_data_control[(Data_bit-1)-:16]   >>>avoid_overflow_number : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_2_output_data_control[(2*Data_bit-1)-:16] >>>avoid_overflow_number : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(3*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(3*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(3*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(3*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_2_0              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_2_1              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(3*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(3*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(3*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_3_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(3*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_3_total_alpha_data_control = {
            add_element_3_6_alpha_data_control,
            add_element_3_5_alpha_data_control,
            add_element_3_4_alpha_data_control,
            add_element_3_3_alpha_data_control,
            add_element_3_2_alpha_data_control,
            add_element_3_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_3_total_beta_data_control = {
            add_element_3_6_beta_data_control,
            add_element_3_5_beta_data_control,
            add_element_3_4_beta_data_control,
            add_element_3_3_beta_data_control,
            add_element_3_2_beta_data_control,
            add_element_3_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_4_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_3_output_data_control[(Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_3_output_data_control[(2*Data_bit-1)-:16] : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(4*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(4*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(4*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(4*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_3_0              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_3_1              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(4*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(4*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(4*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_4_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(4*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_4_total_alpha_data_control = {
            add_element_4_6_alpha_data_control,
            add_element_4_5_alpha_data_control,
            add_element_4_4_alpha_data_control,
            add_element_4_3_alpha_data_control,
            add_element_4_2_alpha_data_control,
            add_element_4_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_4_total_beta_data_control = {
            add_element_4_6_beta_data_control,
            add_element_4_5_beta_data_control,
            add_element_4_4_beta_data_control,
            add_element_4_3_beta_data_control,
            add_element_4_2_beta_data_control,
            add_element_4_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_5_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_4_output_data_control[(Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_4_output_data_control[(2*Data_bit-1)-:16] : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(5*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(5*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(5*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(5*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_4_0              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_4_1              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(5*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(5*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(5*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_5_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(5*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_5_total_alpha_data_control = {
            add_element_5_6_alpha_data_control,
            add_element_5_5_alpha_data_control,
            add_element_5_4_alpha_data_control,
            add_element_5_3_alpha_data_control,
            add_element_5_2_alpha_data_control,
            add_element_5_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_5_total_beta_data_control = {
            add_element_5_6_beta_data_control,
            add_element_5_5_beta_data_control,
            add_element_5_4_beta_data_control,
            add_element_5_3_beta_data_control,
            add_element_5_2_beta_data_control,
            add_element_5_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_6_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_5_output_data_control[(Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_5_output_data_control[(2*Data_bit-1)-:16] : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(6*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(6*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(6*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(6*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_5_0              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_5_1              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(6*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(6*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(6*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_6_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(6*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_6_total_alpha_data_control = {
            add_element_6_6_alpha_data_control,
            add_element_6_5_alpha_data_control,
            add_element_6_4_alpha_data_control,
            add_element_6_3_alpha_data_control,
            add_element_6_2_alpha_data_control,
            add_element_6_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_6_total_beta_data_control = {
            add_element_6_6_beta_data_control,
            add_element_6_5_beta_data_control,
            add_element_6_4_beta_data_control,
            add_element_6_3_beta_data_control,
            add_element_6_2_beta_data_control,
            add_element_6_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_7_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_6_output_data_control[(Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_6_output_data_control[(2*Data_bit-1)-:16] : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(7*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(7*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(7*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(7*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_6_0              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_6_1              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(7*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(7*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(7*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_7_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(7*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_7_total_alpha_data_control = {
            add_element_7_6_alpha_data_control,
            add_element_7_5_alpha_data_control,
            add_element_7_4_alpha_data_control,
            add_element_7_3_alpha_data_control,
            add_element_7_2_alpha_data_control,
            add_element_7_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_7_total_beta_data_control = {
            add_element_7_6_beta_data_control,
            add_element_7_5_beta_data_control,
            add_element_7_4_beta_data_control,
            add_element_7_3_beta_data_control,
            add_element_7_2_beta_data_control,
            add_element_7_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_8_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_7_output_data_control[(Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_7_output_data_control[(2*Data_bit-1)-:16] : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(8*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(8*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(8*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(8*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_7_0              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_7_1              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(8*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(8*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(8*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_8_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(8*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_8_total_alpha_data_control = {
            add_element_8_6_alpha_data_control,
            add_element_8_5_alpha_data_control,
            add_element_8_4_alpha_data_control,
            add_element_8_3_alpha_data_control,
            add_element_8_2_alpha_data_control,
            add_element_8_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_8_total_beta_data_control = {
            add_element_8_6_beta_data_control,
            add_element_8_5_beta_data_control,
            add_element_8_4_beta_data_control,
            add_element_8_3_beta_data_control,
            add_element_8_2_beta_data_control,
            add_element_8_1_beta_data_control
        };
        wire signed[Data_bit-1:0]add_element_9_1_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_8_output_data_control[(Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_2_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_element_8_output_data_control[(2*Data_bit-1)-:16] : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_3_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_0  [(9*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_4_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_0[(9*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_5_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_alpha_1  [(9*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_6_alpha_data_control  = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_alpha_1[(9*Data_bit-1)-:16]  : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_1_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_8_0              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_2_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? add_sigmoid_stride_output_8_1              : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_3_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_0  [(9*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_4_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_0[(9*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_5_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_beta_1  [(9*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[Data_bit-1:0]add_element_9_6_beta_data_control   = (Current_state_YOLO_PE_FUNC_CONTROL==2'b01) ? output_data_K_beta_1[(9*Data_bit-1)-:16]   : 0/* replace the zero number after finish the box prediction */; //if Current_state_YOLO_PE_FUNC_CONTROL ==2'b01 mean doing box prediction now else if Current_state_YOLO_PE_FUNC_CONTROL==2'b10 mean IOU state
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_9_total_alpha_data_control = {
            add_element_9_6_alpha_data_control,
            add_element_9_5_alpha_data_control,
            add_element_9_4_alpha_data_control,
            add_element_9_3_alpha_data_control,
            add_element_9_2_alpha_data_control,
            add_element_9_1_alpha_data_control
        };
        wire signed[sigmoid_exp_add_number*Data_bit-1:0]add_element_9_total_beta_data_control = {
            add_element_9_6_beta_data_control,
            add_element_9_5_beta_data_control,
            add_element_9_4_beta_data_control,
            add_element_9_3_beta_data_control,
            add_element_9_2_beta_data_control,
            add_element_9_1_beta_data_control
        };
        //--------------------------------total singal-----------------------------
        //top------------>down sort~~
        //1.add_element_all_alpha_data_control              (16*6*9bit)
        //2.add_element_(number)_total_beta_data_control    (16*6bit)
        //3.add_element_(number)_(number)_beta_data_control (16bit)
        wire signed[9*sigmoid_exp_add_number*Data_bit-1:0] add_element_all_alpha_data_control , add_element_all_beta_data_control;
        assign add_element_all_alpha_data_control = {
            add_element_9_total_alpha_data_control,
            add_element_8_total_alpha_data_control,
            add_element_7_total_alpha_data_control,
            add_element_6_total_alpha_data_control,
            add_element_5_total_alpha_data_control,
            add_element_4_total_alpha_data_control,
            add_element_3_total_alpha_data_control,
            add_element_2_total_alpha_data_control,
            add_element_1_total_alpha_data_control
        };
        assign add_element_all_beta_data_control = {
            add_element_9_total_beta_data_control,
            add_element_8_total_beta_data_control,
            add_element_7_total_beta_data_control,
            add_element_6_total_beta_data_control,
            add_element_5_total_beta_data_control,
            add_element_4_total_beta_data_control,
            add_element_3_total_beta_data_control,
            add_element_2_total_beta_data_control,
            add_element_1_total_beta_data_control
        };
        //--------------------------------sigmoid and exp add---------------------------------------
        genvar idx;
        generate
            for(idx=0;idx<exp_cell*sigmoid_exp_add_number;idx=idx+1)begin
                process_add_element add_element_sigmoid_exp(
                    .M_AXI_ACLK(M_AXI_ACLK) , 
                    .rst(rst) , 
                    .input_data_alpha(add_element_all_alpha_data_control[((Data_bit * (idx+1))-1)-:16]) ,
                    .input_data_beta(add_element_all_beta_data_control[((Data_bit * (idx+1))-1)-:16]) ,
                    .output_data(add_element_all_output_data_control[((Data_bit * (idx+1))-1)-:16]),
                    .output_add_signal(add_signal_all_output_data_control[idx])
                );
            end
        endgenerate

        //--------------------------------exp anchor box add---------------------------------------
        wire signed [(exp_anchor_cell-1) * exp_anchor_number * Data_bit-1:0] exp_anchor_add_output_data;//get line from adder
        wire signed [exp_anchor_cell  * Data_bit-1:0] exp_anchor_output_data_alpha , exp_anchor_output_data_beta; // get line from exp_anchor_layer
        wire signed [(exp_anchor_cell + exp_anchor_cell - 1) * Data_bit-1:0] exp_input_data_alpha = {
                exp_anchor_add_output_data[(13 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(11 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(9 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(7 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(5 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(3 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(1 * Data_bit-1)-:16],
                exp_anchor_output_data_alpha
            };
        wire signed [(exp_anchor_cell + exp_anchor_cell - 1) * Data_bit-1:0] exp_input_data_beta  = {
                exp_anchor_add_output_data[(14 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(12 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(10 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(8 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(6 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(4 * Data_bit-1)-:16],
                exp_anchor_add_output_data[(2 * Data_bit-1)-:16],
                exp_anchor_output_data_beta
            };
        wire signed [(2*Data_bit-1):0]exp_anchor_box_all_input_data  = {
                {avoid_overflow_number{add_element_9_output_data_control[(5*Data_bit-1)-:1]}},add_element_9_output_data_control[(5*Data_bit-1)-:13],
                {avoid_overflow_number{add_element_9_output_data_control[(3*Data_bit-1)-:1]}},add_element_9_output_data_control[(3*Data_bit-1)-:13]
            };

        exp_anchor_parameter_func_layer_total exp_anchor_layer(
            .rst(rst),
            .M_AXI_ACLK(M_AXI_ACLK),
            .input_data(exp_anchor_box_all_input_data),
            .data_parameter(delay_data_parameter_exp),
            .output_data({exp_anchor_output_data_beta , exp_anchor_output_data_alpha})
        );

        genvar idj;
        generate
            for(idj=0;idj<exp_anchor_number*(exp_anchor_cell-1);idj=idj+1)begin
                process_add_element add_element_exp_anchor(
                    .M_AXI_ACLK(M_AXI_ACLK) , 
                    .rst(rst) , 
                    .input_data_alpha(exp_input_data_alpha[((Data_bit * (idj+1))-1)-:16]) ,
                    .input_data_beta(exp_input_data_beta[((Data_bit * (idj+1))-1)-:16]) ,
                    .output_data(exp_anchor_add_output_data[((Data_bit * (idj+1))-1)-:16]),
                    .output_add_signal(0)
                );
            end
        endgenerate

        //--------------------------------output_data------------------------------------
        //TODO write the output_data rule......................
        wire signed [Data_bit-1:0] sigmoid_output_data_0 , sigmoid_output_data_1;
        pola_yolo_Delay_signed_module #(.delay_clock(2)) delay_module_sigmoid_to_alignment_exp_0(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (add_element_9_output_data_control[(1 * Data_bit-1)-:16]),
            .output_data        (sigmoid_output_data_0)
        );
        pola_yolo_Delay_signed_module #(.delay_clock(2)) delay_module_sigmoid_to_alignment_exp_1(
            .M_AXI_ACLK         (M_AXI_ACLK),
            .rst                (rst),
            .over_conf_threshold(1),
            .input_data         (add_element_9_output_data_control[(2 * Data_bit-1)-:16]),
            .output_data        (sigmoid_output_data_1)
        );
        assign data_out_bx       = sigmoid_output_data_0;
        assign data_out_by       = sigmoid_output_data_1;
        assign data_out_bw       = exp_anchor_add_output_data[(13 * Data_bit-1)-:16];
        assign data_out_bh       = exp_anchor_add_output_data[(14 * Data_bit-1)-:16];
        assign data_out_conf     = 0;//xxxx
        assign data_out_class    = 0;//xxxx
        assign data_out_index    = 0;//xxxx

        /*        
        always@(*)begin
            if(data_parameter_reg[3][11-:4]==4'b0100)begin
                input_alpha_mul[2]  = 49;   //32,16,1,0,0
                input_alpha_mul[5]  = 50;   //32,16,2,0,0
            end else if(data_parameter_reg[3][11-:4]==4'b1000)begin
                input_alpha_mul[2]  = 83;   //64,16,2,1,0
                input_alpha_mul[5]  = 104;  //64,32,8,0,0
            end else if(data_parameter_reg[3][11-:4]==4'b1100)begin
                input_alpha_mul[2]  = 211;  //128,64,16,2,1
                input_alpha_mul[5]  = 196;  //128,64,4,0,0,0
            end else if(data_parameter_reg[3][11-:4]==4'b0101)begin
                input_alpha_mul[2]  = 6;    //4,2,0,0,0
                input_alpha_mul[5]  = 8;    //8,0,0,0,0
            end else if(data_parameter_reg[3][11-:4]==4'b1001)begin
                input_alpha_mul[2]  = 14;   //8,4,2,0,0
                input_alpha_mul[5]  = 16;   //16,0,0,0,0
            end else if(data_parameter_reg[3][11-:4]==4'b1101)begin
                input_alpha_mul[2]  = 22;   //16,4,2,0,0
                input_alpha_mul[5]  = 35;   //32,2,1,0,0
            end else begin
                input_alpha_mul[2]  = 0;
                input_alpha_mul[5]  = 0;
            end
        end
*/

endmodule
