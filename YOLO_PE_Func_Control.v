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
        parameter Data_bit = 16,
        parameter sigmoid_alpha_shift_bit = 15,
        parameter sigmoid_bias_shift_bit = 10,
        parameter exp_alpha_shift_bit = 10,
        parameter exp_bias_shift_bit = 10,
        parameter layer_shift_bit = 10,
        parameter sigmoid_bias_delay = 3,
        parameter sigmoid_input_delay= 2,
        parameter anchor_max_bit = 5 // 8 == max_anchor=211 8bit  , 3 == exp range -2->2 + 1bit range = 8-3=5
    )(
        input M_AXI_ACLK,
        input rst,
        input [Data_bit-1:0] data_parameter,
        input signed[Data_bit-1:0] data_in_bx0,   // if FSM is box prediction , data_in_bx0 = sigmoid(output_answer_line[0])  else if FSM is IOU , data_in_bx0 = bx0;
        input signed[Data_bit-1:0] data_in_by0,   // if FSM is box prediction , data_in_by0 = sigmoid(output_answer_line[1])  else if FSM is IOU , data_in_by0 = by0;
        input signed[Data_bit-1:0] data_in_bw0,   // if FSM is box prediction , data_in_bw0 = exp(output_answer_line[2])      else if FSM is IOU , data_in_bw0 = bw0;
        input signed[Data_bit-1:0] data_in_bh0,   // if FSM is box prediction , data_in_bh0 = exp(output_answer_line[3])      else if FSM is IOU , data_in_bh0 = bh0;
        input signed[Data_bit-1:0] data_in_bx1,   // if FSM is box prediction , data_in_bx1 = None                            else if FSM is IOU , data_in_bx1 = bx1;
        input signed[Data_bit-1:0] data_in_by1,   // if FSM is box prediction , data_in_by1 = None                            else if FSM is IOU , data_in_by1 = by1;
        input signed[Data_bit-1:0] data_in_bw1,   // if FSM is box prediction , data_in_bw1 = None                            else if FSM is IOU , data_in_bw1 = bw1;
        input signed[Data_bit-1:0] data_in_bh1    // if FSM is box prediction , data_in_by1 = None                            else if FSM is IOU , data_in_by1 = bh1;
    );
    //---------------------------------PE module--------------------------------
        wire       [3:0]repair_bit;
        wire       signed [Data_bit-1:0]n_value; //present the y location
        wire       signed [Data_bit-1:0]m_value; //present the x location
        reg        [Data_bit-1:0]  func_shift_bit;
        reg        [1:0]           func_select_bit;
        wire signed[Data_bit-1 : 0]sigmoid_output_alpha[0:1];
        wire signed[Data_bit-1 : 0]sigmoid_output_bias[0:1];
        wire signed[Data_bit-1 : 0]exp_output_alpha[0:1];
        wire signed[Data_bit-1 : 0]exp_output_bias[0:1]; 
        wire signed[Data_bit-1 : 0]output_data_control_mul[0:5]; 
        wire signed[Data_bit-1 : 0]output_data_control_add[0:7];
        reg  [Data_bit-1 : 0]data_parameter_reg[0:3];
        assign repair_bit = data_parameter[11-:4];//index_register
        assign n_value    = data_parameter[7-:4]<<<layer_shift_bit;
        assign m_value    = data_parameter[3-:4]<<<layer_shift_bit;

        //---------------------------------parameter---------------------------------------
        always@(posedge M_AXI_ACLK)begin
            if(rst) begin
                data_parameter_reg[0] <= 0;
                data_parameter_reg[1] <= 0;
                data_parameter_reg[2] <= 0;
                data_parameter_reg[3] <= 0;
            end else begin
                data_parameter_reg[3]<=data_parameter_reg[2];
                data_parameter_reg[2]<=data_parameter_reg[1];
                data_parameter_reg[1]<=data_parameter_reg[0];
                data_parameter_reg[0]<=data_parameter;
            end
        end

        //----------------------------------2 sigmoid -------------------------------------
        fpga_linear_sigmoid_func_layer #(.bias_shift_bit(layer_shift_bit)) sigmoid_layer_0(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .repair_bit(repair_bit),
            .input_data(data_in_bx0),
            .output_alpha(sigmoid_output_alpha[0]),
            .output_bias(sigmoid_output_bias[0])
        );
        fpga_linear_sigmoid_func_layer #(.bias_shift_bit(layer_shift_bit)) sigmoid_layer_1(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .repair_bit(repair_bit),
            .input_data(data_in_by0),
            .output_alpha(sigmoid_output_alpha[1]),
            .output_bias(sigmoid_output_bias[1])
        );
        //----------------------------------2 exp -------------------------------------
        fpga_exp_lookuptable_func_layer #(.bias_shift_bit(layer_shift_bit)) exp_layer_0(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .repair_bit(repair_bit),
            .input_data(data_in_bw0),
            .output_alpha(exp_output_alpha[0]),
            .output_bias(exp_output_bias[0])
        );
        fpga_exp_lookuptable_func_layer #(.bias_shift_bit(layer_shift_bit)) exp_layer_1(
            .M_AXI_ACLK(M_AXI_ACLK),
            .rst(rst),
            .repair_bit(repair_bit),
            .input_data(data_in_bh0),
            .output_alpha(exp_output_alpha[1]),
            .output_bias(exp_output_bias[1])
        );
        

        //----------------------------------PE control---------------------------------
        //1.contorl 6 mul func_shift_bit , repair bit , input_data , input_alpha , output_data
        wire [Data_bit-1 : 0]      func_shift_mul_bit   [0:5];
        wire [3 : 0]               repair_mul_bit       [0:5];
        wire signed[Data_bit-1 : 0]input_data_mul       [0:5];
        wire signed[Data_bit-1 : 0]input_alpha_mul      [0:5];
        reg  signed[Data_bit-1 : 0]sigmoid_input_reg_0  [0:sigmoid_input_delay-1];//keep 3 pipeline
        reg  signed[Data_bit-1 : 0]sigmoid_input_reg_1  [0:sigmoid_input_delay-1];//keep 3 pipeline
        reg  signed[Data_bit-1 : 0]sigmoid_keep_bias_0; 
        reg  signed[Data_bit-1 : 0]sigmoid_keep_bias_1;  
        integer j;

        assign func_shift_mul_bit[0] = sigmoid_alpha_shift_bit;
        assign func_shift_mul_bit[1] = exp_alpha_shift_bit;
        assign func_shift_mul_bit[2] = anchor_max_bit;
        assign func_shift_mul_bit[3] = sigmoid_alpha_shift_bit;
        assign func_shift_mul_bit[4] = exp_alpha_shift_bit;
        assign func_shift_mul_bit[5] = anchor_max_bit;
        
        assign repair_mul_bit[0]     = data_parameter_reg[3][11-:4];
        assign repair_mul_bit[1]     = data_parameter_reg[3][11-:4];
        assign repair_mul_bit[2]     = data_parameter_reg[3][11-:4];
        assign repair_mul_bit[3]     = data_parameter_reg[3][11-:4];
        assign repair_mul_bit[4]     = data_parameter_reg[3][11-:4];
        assign repair_mul_bit[5]     = data_parameter_reg[3][11-:4];

        assign input_data_mul[0]     = sigmoid_input_reg_0[1];
        assign input_data_mul[1]     = exp_output_alpha[0];
        assign input_data_mul[2]     = output_data_control_mul[1];
        assign input_data_mul[3]     = sigmoid_input_reg_1[1];
        assign input_data_mul[4]     = exp_output_alpha[1];
        assign input_data_mul[5]     = output_data_control_mul[4];

        assign input_alpha_mul[0]    = sigmoid_output_alpha[0];
        assign input_alpha_mul[1]    = exp_output_bias[0];
        assign input_alpha_mul[2]    = 83;
        assign input_alpha_mul[3]    = sigmoid_output_alpha[1];
        assign input_alpha_mul[4]    = exp_output_bias[1];
        assign input_alpha_mul[5]    = 104;

        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                for(j=0;j<3;j=j+1)begin
                    if(j<1)begin
                        sigmoid_input_reg_0[j] <= 0;
                        sigmoid_input_reg_1[j] <= 0;
                        sigmoid_keep_bias_0    <= 0;
                        sigmoid_keep_bias_1    <= 0;
                    end else begin
                        sigmoid_input_reg_0[j] <= 0;
                        sigmoid_input_reg_1[j] <= 0;
                    end
                end        
            end else begin
                sigmoid_input_reg_0[1] <= sigmoid_input_reg_0[0]; sigmoid_input_reg_0[0] <= data_in_bx0;
                sigmoid_input_reg_1[1] <= sigmoid_input_reg_1[0]; sigmoid_input_reg_1[0] <= data_in_by0;
                sigmoid_keep_bias_0    <= sigmoid_output_bias[0];
                sigmoid_keep_bias_1    <= sigmoid_output_bias[1];
            end
        end
        //----------------------------------6 mul -------------------------------------
        //1.sigmoid 2 mul 
        //2.exp     1 mul
        //3.iou     3 mul
        process_mul_element mul_element_1(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_mul_bit[0]) , .repair_bit(repair_mul_bit[0]) , .input_data(input_data_mul[0])   , .input_alpha(input_alpha_mul[0])    , .output_data(output_data_control_mul[0]));
        process_mul_element mul_element_2(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_mul_bit[1]) , .repair_bit(repair_mul_bit[1]) , .input_data(input_data_mul[1])   , .input_alpha(input_alpha_mul[1])    , .output_data(output_data_control_mul[1]));
        process_mul_element mul_element_3(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_mul_bit[2]) , .repair_bit(repair_mul_bit[2]) , .input_data(input_data_mul[2])   , .input_alpha(input_alpha_mul[2])    , .output_data(output_data_control_mul[2]));
        process_mul_element mul_element_4(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_mul_bit[3]) , .repair_bit(repair_mul_bit[3]) , .input_data(input_data_mul[3])   , .input_alpha(input_alpha_mul[3])    , .output_data(output_data_control_mul[3]));
        process_mul_element mul_element_5(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_mul_bit[4]) , .repair_bit(repair_mul_bit[4]) , .input_data(input_data_mul[4])   , .input_alpha(input_alpha_mul[4])    , .output_data(output_data_control_mul[4]));
        process_mul_element mul_element_6(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_mul_bit[5]) , .repair_bit(repair_mul_bit[5]) , .input_data(input_data_mul[5])   , .input_alpha(input_alpha_mul[5])    , .output_data(output_data_control_mul[5]));

        //----------------------------------PE control---------------------------------
        //1.contorl 8 add func_shift_bit , repair bit , input_data , input_bias , output_data
        wire [Data_bit-1 : 0]   func_shift_add_bit  [0:7];
        wire [3 : 0]            repair_add_bit      [0:7];
        wire signed[Data_bit-1 : 0]   input_data_add      [0:5];
        wire signed[Data_bit-1 : 0]   input_bias_add      [0:5];

        assign func_shift_add_bit[0] = sigmoid_bias_shift_bit;
        assign func_shift_add_bit[1] = sigmoid_bias_shift_bit;
        assign func_shift_add_bit[2] = sigmoid_bias_shift_bit;
        assign func_shift_add_bit[3] = sigmoid_bias_shift_bit;
        assign func_shift_add_bit[4] = sigmoid_bias_shift_bit;
        assign func_shift_add_bit[5] = sigmoid_bias_shift_bit;
        assign func_shift_add_bit[6] = sigmoid_bias_shift_bit;
        assign func_shift_add_bit[7] = sigmoid_bias_shift_bit;

        assign repair_add_bit[0]     = data_parameter_reg[3][11-:4];
        assign repair_add_bit[1]     = data_parameter_reg[3][11-:4];
        assign repair_add_bit[2]     = data_parameter_reg[3][11-:4];
        assign repair_add_bit[3]     = data_parameter_reg[3][11-:4];
        assign repair_add_bit[4]     = data_parameter_reg[3][11-:4];
        assign repair_add_bit[5]     = data_parameter_reg[3][11-:4];
        assign repair_add_bit[6]     = data_parameter_reg[3][11-:4];
        assign repair_add_bit[7]     = data_parameter_reg[3][11-:4];

        assign input_data_add[0]     = output_data_control_mul[0];
        assign input_data_add[1]     = output_data_control_mul[3];
        assign input_data_add[2]     = output_data_control_add[0];
        assign input_data_add[3]     = output_data_control_add[1];
        assign input_data_add[4]     = 0;
        assign input_data_add[5]     = 0;
        assign input_data_add[7]     = 0;
        assign input_data_add[8]     = 0;

        assign input_bias_add[0]     = sigmoid_keep_bias_0;
        assign input_bias_add[1]     = sigmoid_keep_bias_1;
        assign input_bias_add[2]     = data_parameter_reg[3][7-:4]<<sigmoid_bias_shift_bit;
        assign input_bias_add[3]     = data_parameter_reg[3][3-:4]<<sigmoid_bias_shift_bit;
        assign input_bias_add[4]     = 0;
        assign input_bias_add[5]     = 0;
        assign input_bias_add[7]     = 0;
        assign input_bias_add[8]     = 0;
        //----------------------------------8 add -------------------------------------
        //1.sigmoid 2 add
        //2.iou     6 add
        process_add_element add_element_1(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[0]) , .repair_bit(repair_add_bit[0]) , .input_data(input_data_add[0]) , .input_bias(input_bias_add[0]) , .output_data(output_data_control_add[0]));
        process_add_element add_element_2(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[1]) , .repair_bit(repair_add_bit[1]) , .input_data(input_data_add[1]) , .input_bias(input_bias_add[1]) , .output_data(output_data_control_add[1]));
        process_add_element add_element_3(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[2]) , .repair_bit(repair_add_bit[2]) , .input_data(input_data_add[2]) , .input_bias(input_bias_add[2]) , .output_data(output_data_control_add[2]));
        process_add_element add_element_4(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[3]) , .repair_bit(repair_add_bit[3]) , .input_data(input_data_add[3]) , .input_bias(input_bias_add[3]) , .output_data(output_data_control_add[3]));
        process_add_element add_element_5(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[4]) , .repair_bit(repair_add_bit[4]) , .input_data(input_data_add[4]) , .input_bias(input_bias_add[4]) , .output_data(output_data_control_add[4]));
        process_add_element add_element_6(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[5]) , .repair_bit(repair_add_bit[5]) , .input_data(input_data_add[5]) , .input_bias(input_bias_add[5]) , .output_data(output_data_control_add[5]));
        process_add_element add_element_7(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[6]) , .repair_bit(repair_add_bit[6]) , .input_data(input_data_add[7]) , .input_bias(input_bias_add[7]) , .output_data(output_data_control_add[6]));
        process_add_element add_element_8(.M_AXI_ACLK(M_AXI_ACLK) , .rst(rst) , .func_shift_bit(func_shift_add_bit[7]) , .repair_bit(repair_add_bit[7]) , .input_data(input_data_add[8]) , .input_bias(input_bias_add[8]) , .output_data(output_data_control_add[7]));
endmodule
