module fpga_linear_sigmoid_func_layer#(
        parameter data_bit                        = 16,
        parameter alpga_shift_bit                 = 15,
        parameter bias_shift_bit                  = 999,
        parameter alpha_shift_value               = 2**alpga_shift_bit,
        parameter bias_shift_value                = 2**bias_shift_bit,
        //-------------------------------alpha----------------------------------
        parameter data_negative_8_alpha           = 0.00247 * alpha_shift_value,
        parameter data_negative_4_point_5_alpha   = 0.02415 * alpha_shift_value,
        parameter data_negative_3_alpha           = 0.0639  * alpha_shift_value,
        parameter data_negative_2_point_5_alpha   = 0.0831  * alpha_shift_value,
        parameter data_negative_2_alpha           = 0.12891 * alpha_shift_value,
        parameter data_negative_1_point_5_alpha   = 0.16351 * alpha_shift_value,
        parameter data_negative_1_alpha           = 0.23674 * alpha_shift_value,
        parameter data_positive_1_alpha           = 0.16351 * alpha_shift_value,
        parameter data_positive_1_point_5_alpha   = 0.12891 * alpha_shift_value,
        parameter data_positive_2_alpha           = 0.0831  * alpha_shift_value,
        parameter data_positive_2_point_5_alpha   = 0.0639  * alpha_shift_value,
        parameter data_positive_3_alpha           = 0.02415 * alpha_shift_value,
        parameter data_positive_4_point_5_alpha   = 0.00247 * alpha_shift_value,
        parameter data_positive_8_alpha           = 0       * alpha_shift_value,
        //-------------------------------bias-----------------------------------
        parameter data_negative_8_bias            = 0.01843 * bias_shift_value,
        parameter data_negative_4_point_5_bias    = 0.11599 * bias_shift_value,   
        parameter data_negative_3_bias            = 0.23525 * bias_shift_value,          
        parameter data_negative_2_point_5_bias    = 0.28325 * bias_shift_value,          
        parameter data_negative_2_bias            = 0.37487 * bias_shift_value,          
        parameter data_negative_1_point_5_bias    = 0.42677 * bias_shift_value, 
        parameter data_negative_1_bias            = 0.5     * bias_shift_value,          
        parameter data_positive_1_bias            = 0.57323 * bias_shift_value,              
        parameter data_positive_1_point_5_bias    = 0.62513 * bias_shift_value,          
        parameter data_positive_2_bias            = 0.71675 * bias_shift_value,          
        parameter data_positive_2_point_5_bias    = 0.76475 * bias_shift_value,          
        parameter data_positive_3_bias            = 0.88401 * bias_shift_value,  
        parameter data_positive_4_point_5_bias    = 0.98157 * bias_shift_value,          
        parameter data_positive_8_bias            = 1       * bias_shift_value,
        //-------------------------------ragnge_data-----------------------------------
        parameter range_value_negative_8          = -8      * bias_shift_value,
        parameter range_value_negative_4_point_5  = -4.5    * bias_shift_value,    
        parameter range_value_negative_3          = -3      * bias_shift_value,
        parameter range_value_negative_2_point_5  = -2.5    * bias_shift_value,    
        parameter range_value_negative_2          = -2      * bias_shift_value,
        parameter range_value_negative_1_point_5  = -1.5    * bias_shift_value,    
        parameter range_value_negative_1          = -1      * bias_shift_value,
        parameter range_value_positive_1          = 1       * bias_shift_value,
        parameter range_value_positive_1_point_5  = 1.5     * bias_shift_value,
        parameter range_value_positive_2          = 2       * bias_shift_value,
        parameter range_value_positive_2_point_5  = 2.5     * bias_shift_value,
        parameter range_value_positive_3          = 3       * bias_shift_value,
        parameter range_value_positive_4_point_5  = 4.5     * bias_shift_value,
        parameter range_value_positive_8          = 8       * bias_shift_value
    )(
        input               M_AXI_ACLK,
        input               rst,
        input  signed       [data_bit-1:0] input_data, 
        output reg  signed  [data_bit-1:0] output_alpha,
        output reg  signed  [data_bit-1:0] output_bias
    );
    //------------------sigmoid-------------------
    //1.find the value range
    //2.put the value to reg
    reg [3:0]range_signal;
    reg [data_bit-1:0]output_alpha_wire;
    reg [data_bit-1:0]output_bias_wire;

    always@(posedge M_AXI_ACLK)begin
        if(rst)begin
            output_alpha    <= 0;
            output_bias     <= 0;
        end else begin
            output_alpha    <= output_alpha_wire;
            output_bias     <= output_bias_wire;
        end
    end

    always@(*)begin
        case (range_signal)
            0   :   begin
                output_alpha_wire = 0;
                output_bias_wire  = 0;
            end
            1   :   begin
                output_alpha_wire = data_negative_8_alpha;
                output_bias_wire  = data_negative_8_bias;
            end
            2   :   begin
                output_alpha_wire = data_negative_4_point_5_alpha;
                output_bias_wire  = data_negative_4_point_5_bias;
            end
            3   :   begin
                output_alpha_wire = data_negative_3_alpha;
                output_bias_wire  = data_negative_3_bias;
            end
            4   :   begin
                output_alpha_wire = data_negative_2_point_5_alpha;
                output_bias_wire  = data_negative_2_point_5_bias;
            end
            5   :   begin
                output_alpha_wire = data_negative_2_alpha;
                output_bias_wire  = data_negative_2_bias;
            end
            6   :   begin
                output_alpha_wire = data_negative_1_point_5_alpha;
                output_bias_wire  = data_negative_1_point_5_bias;
            end
            7   :   begin
                output_alpha_wire = data_negative_1_alpha;
                output_bias_wire  = data_negative_1_bias;
            end
            8   :   begin
                output_alpha_wire = data_positive_1_alpha;
                output_bias_wire  = data_positive_1_bias;
            end
            9   :   begin
                output_alpha_wire = data_positive_1_point_5_alpha;
                output_bias_wire  = data_positive_1_point_5_bias;
            end
            10  :   begin
                output_alpha_wire = data_positive_2_alpha;
                output_bias_wire  = data_positive_2_bias;
            end
            11  :   begin
                output_alpha_wire = data_positive_2_point_5_alpha;
                output_bias_wire  = data_positive_2_point_5_bias;
            end
            12  :   begin
                output_alpha_wire = data_positive_3_alpha;
                output_bias_wire  = data_positive_3_bias;
            end
            13  :   begin
                output_alpha_wire = data_positive_4_point_5_alpha;
                output_bias_wire  = data_positive_4_point_5_bias;
            end
            14  :   begin
                output_alpha_wire = data_positive_8_alpha;
                output_bias_wire  = data_positive_8_bias;
            end
            default: begin
                output_alpha_wire = 0;
                output_bias_wire  = 0;
            end
        endcase
    end

    always@(posedge M_AXI_ACLK)begin
        if(input_data<range_value_negative_8)
            range_signal <= 0;
        else if(input_data>range_value_negative_8 && input_data<=range_value_negative_4_point_5)
            range_signal <= 1;
        else if(input_data>range_value_negative_4_point_5 && input_data<=range_value_negative_3)
            range_signal <= 2;
        else if(input_data>range_value_negative_3 && input_data<=range_value_negative_2_point_5)
            range_signal <= 3;
        else if(input_data>range_value_negative_2_point_5 && input_data<=range_value_negative_2)
            range_signal <= 4;
        else if(input_data>range_value_negative_2 && input_data<=range_value_negative_1_point_5)
            range_signal <= 5;
        else if(input_data>range_value_negative_1_point_5 && input_data<=range_value_negative_1)
            range_signal <= 6;
        else if(input_data>range_value_negative_1 && input_data<=range_value_positive_1)
            range_signal <= 7;
        else if(input_data>range_value_positive_1 && input_data<=range_value_positive_1_point_5)
            range_signal <= 8;
        else if(input_data>range_value_positive_1_point_5 && input_data<=range_value_positive_2)
            range_signal <= 9;
        else if(input_data>range_value_positive_2 && input_data<=range_value_positive_2_point_5)
            range_signal <= 10;    
        else if(input_data>range_value_positive_2_point_5 && input_data<=range_value_positive_3)
            range_signal <= 11;    
        else if(input_data>range_value_positive_3 && input_data<=range_value_positive_4_point_5)
            range_signal <= 12; 
        else if(input_data>range_value_positive_4_point_5 && input_data<=range_value_positive_8)
            range_signal <= 13; 
        else if(input_data>range_value_positive_8)
            range_signal <= 14;
        else
            range_signal <= 0;
    end
endmodule

module fpga_exp_lookuptable_func_layer#(
    parameter data_bit                        = 16,
    parameter alpga_shift_bit                 = 15,
    parameter bias_shift_bit                  = 999,
    parameter alpha_shift_value               = 2**alpga_shift_bit,
    parameter bias_shift_value                = 2**bias_shift_bit,
    //------------------------------------1.125 -> 1-----------------------------------
    parameter data_positive_exp_1_point_125            = 3.080217  * bias_shift_value,
    parameter data_positive_exp_1_point_117188         = 3.0562464 * bias_shift_value,
    parameter data_positive_exp_1_point_101563         = 3.0088637 * bias_shift_value,
    parameter data_positive_exp_1_point_085938         = 2.9622156 * bias_shift_value,
    parameter data_positive_exp_1_point_070313         = 2.9162907 * bias_shift_value,
    parameter data_positive_exp_1_point_054688         = 2.8710778 * bias_shift_value,
    parameter data_positive_exp_1_point_039063         = 2.8265659 * bias_shift_value,
    parameter data_positive_exp_1_point_023438         = 2.782744  * bias_shift_value,
    parameter data_positive_exp_1_point_007813         = 2.7396016 * bias_shift_value,
    //------------------------------------0.125 -> 0-----------------------------------
    parameter data_positive_exp_0_point_125            = 1.133148  * bias_shift_value,
    parameter data_positive_exp_0_point_117188         = 1.1243302 * bias_shift_value,
    parameter data_positive_exp_0_point_101563         = 1.1068991 * bias_shift_value,
    parameter data_positive_exp_0_point_085938         = 1.0897382 * bias_shift_value,
    parameter data_positive_exp_0_point_070313         = 1.0728434 * bias_shift_value,
    parameter data_positive_exp_0_point_054688         = 1.0562105 * bias_shift_value,
    parameter data_positive_exp_0_point_039063         = 1.0398355 * bias_shift_value,
    parameter data_positive_exp_0_point_023438         = 1.0237143 * bias_shift_value,
    parameter data_positive_exp_0_point_007813         = 1.0078431 * bias_shift_value,
    //---------------------------------- -0.875- > -1----------------------------------
    parameter data_negative_exp_0_point_875            = 0.416862  * bias_shift_value,
    parameter data_negative_exp_0_point_88281          = 0.413618  * bias_shift_value,
    parameter data_negative_exp_0_point_89844          = 0.4072054 * bias_shift_value,
    parameter data_negative_exp_0_point_91406          = 0.4008923 * bias_shift_value,
    parameter data_negative_exp_0_point_92969          = 0.394677  * bias_shift_value,
    parameter data_negative_exp_0_point_94531          = 0.3885581 * bias_shift_value,
    parameter data_negative_exp_0_point_96094          = 0.3825341 * bias_shift_value,
    parameter data_negative_exp_0_point_97656          = 0.3766035 * bias_shift_value,
    parameter data_negative_exp_0_point_99219          = 0.3707648 * bias_shift_value,
    //---------------------------------- -1.875- > -2----------------------------------
    parameter data_negative_exp_1_point_875            = 0.153355  * bias_shift_value,
    parameter data_negative_exp_1_point_88281          = 0.1521615 * bias_shift_value,
    parameter data_negative_exp_1_point_89844          = 0.1498025 * bias_shift_value, 
    parameter data_negative_exp_1_point_91406          = 0.14748   * bias_shift_value,
    parameter data_negative_exp_1_point_92969          = 0.1451936 * bias_shift_value,
    parameter data_negative_exp_1_point_94531          = 0.1429425 * bias_shift_value, 
    parameter data_negative_exp_1_point_96094          = 0.1407264 * bias_shift_value,
    parameter data_negative_exp_1_point_97656          = 0.1385447 * bias_shift_value,
    parameter data_negative_exp_1_point_99219          = 0.1363967 * bias_shift_value,
    parameter data_negative_exp_2_point                = 0.135335  * bias_shift_value,
    //-----------------------------------positive range-------------------------------
    parameter range_value_positive_1_point_125          = 1.125     * bias_shift_value,
    parameter range_value_positive_1_point_109375       = 1.109375  * bias_shift_value,
    parameter range_value_positive_1_point_09375        = 1.09375   * bias_shift_value,
    parameter range_value_positive_1_point_078125       = 1.078125  * bias_shift_value,
    parameter range_value_positive_1_point_0625         = 1.0625    * bias_shift_value,
    parameter range_value_positive_1_point_046875       = 1.046875  * bias_shift_value,
    parameter range_value_positive_1_point_03125        = 1.03125   * bias_shift_value,
    parameter range_value_positive_1_point_015625       = 1.015625  * bias_shift_value,
    parameter range_value_positive_1_point              = 1         * bias_shift_value,
    parameter range_value_positive_0_point_125          = 0.125     * bias_shift_value,
    parameter range_value_positive_0_point_109375       = 0.109375  * bias_shift_value,
    parameter range_value_positive_0_point_09375        = 0.09375   * bias_shift_value,
    parameter range_value_positive_0_point_078125       = 0.078125  * bias_shift_value,
    parameter range_value_positive_0_point_0625         = 0.0625    * bias_shift_value,
    parameter range_value_positive_0_point_046875       = 0.046875  * bias_shift_value,
    parameter range_value_positive_0_point_03125        = 0.03125   * bias_shift_value,
    parameter range_value_positive_0_point_015625       = 0.015625  * bias_shift_value,
    parameter range_value_positive_0_point              = 0         * bias_shift_value,
    //-------------------------------------negative range-----------------------------
    parameter range_value_negative_0_point_875          = -0.875    * bias_shift_value,
    parameter range_value_negative_0_point_89063        = -0.89063  * bias_shift_value,
    parameter range_value_negative_0_point_90625        = -0.90625  * bias_shift_value,
    parameter range_value_negative_0_point_92188        = -0.92188  * bias_shift_value,
    parameter range_value_negative_0_point_9375         = -0.9375   * bias_shift_value,
    parameter range_value_negative_0_point_95313        = -0.95313  * bias_shift_value,
    parameter range_value_negative_0_point_96875        = -0.96875  * bias_shift_value,
    parameter range_value_negative_0_point_98438        = -0.98438  * bias_shift_value,
    parameter range_value_negative_1_point              = -1        * bias_shift_value,
    parameter range_value_negative_1_point_875          = -1.875    * bias_shift_value,
    parameter range_value_negative_1_point_89063        = -1.89063  * bias_shift_value,
    parameter range_value_negative_1_point_90625        = -1.90625  * bias_shift_value,
    parameter range_value_negative_1_point_92188        = -1.92188  * bias_shift_value,
    parameter range_value_negative_1_point_9375         = -1.9375   * bias_shift_value,
    parameter range_value_negative_1_point_95313        = -1.95313  * bias_shift_value,
    parameter range_value_negative_1_point_96875        = -1.96875  * bias_shift_value,
    parameter range_value_negative_1_point_98438        = -1.98438  * bias_shift_value,
    parameter range_value_negative_2_point              = -2        * bias_shift_value
)(
    input   M_AXI_ACLK,
    input   rst,
    input   signed [data_bit-1:0] input_data,
    output  reg  signed  [data_bit-1:0] output_alpha,
    output  reg  signed  [data_bit-1:0] output_bias
);

    reg  signed [data_bit-1:0]output_alpha_find;
    reg  signed [data_bit-1:0]output_bias_find;
    wire signed [data_bit-1:0]output_bias_find_output;
    reg        [5:0]         range_signal;

    exp_bias_choose_func_layer#(.bias_shift_bit(bias_shift_bit)) exp_layer(
        .input_data(output_bias_find),
        .output_data(output_bias_find_output)
    );

    always@(posedge M_AXI_ACLK)begin
        if(rst)begin
            output_alpha    <= 0;
            output_bias     <= 0;
        end else begin
            output_alpha    <= output_alpha_find;
            output_bias     <= output_bias_find_output;
        end
    end

    always@(*)begin
        case (range_signal)
            0   :   begin
                output_alpha_find = data_positive_exp_1_point_125;
                output_bias_find  = input_data - range_value_positive_1_point_125;
            end
            1   :   begin
                output_alpha_find = data_positive_exp_1_point_117188;
                output_bias_find  = input_data - range_value_positive_1_point_109375;
            end
            2   :   begin
                output_alpha_find = data_positive_exp_1_point_101563;
                output_bias_find  = input_data - range_value_positive_1_point_09375;
            end
            3   :   begin
                output_alpha_find = data_positive_exp_1_point_085938;
                output_bias_find  = input_data - range_value_positive_1_point_078125; 
            end
            4   :   begin
                output_alpha_find = data_positive_exp_1_point_070313;
                output_bias_find  = input_data - range_value_positive_1_point_0625; 
            end
            5   :   begin
                output_alpha_find = data_positive_exp_1_point_054688;
                output_bias_find  = input_data - range_value_positive_1_point_046875; 
            end
            6   :   begin
                output_alpha_find = data_positive_exp_1_point_039063;
                output_bias_find  = input_data - range_value_positive_1_point_03125; 
            end
            7   :   begin
                output_alpha_find = data_positive_exp_1_point_023438;
                output_bias_find  = input_data - range_value_positive_1_point_015625; 
            end
            8   :   begin
                output_alpha_find = data_positive_exp_1_point_007813;
                output_bias_find  = input_data - range_value_positive_1_point; 
            end
            9   :   begin
                output_alpha_find = data_positive_exp_0_point_125;
                output_bias_find  = input_data - range_value_positive_0_point_125; 
            end
            10  :   begin
                output_alpha_find = data_positive_exp_0_point_117188;
                output_bias_find  = input_data - range_value_positive_0_point_109375;
            end
            11  :   begin
                output_alpha_find = data_positive_exp_0_point_101563;
                output_bias_find  = input_data - range_value_positive_0_point_09375;
            end
            12  :   begin
                output_alpha_find = data_positive_exp_0_point_085938;
                output_bias_find  = input_data - range_value_positive_0_point_078125;
            end
            13  :   begin
                output_alpha_find = data_positive_exp_0_point_070313;
                output_bias_find  = input_data - range_value_positive_0_point_0625;
            end
            14  :   begin
                output_alpha_find = data_positive_exp_0_point_054688;
                output_bias_find  = input_data - range_value_positive_0_point_046875;
            end
            15  :   begin
                output_alpha_find = data_positive_exp_0_point_039063;
                output_bias_find  = input_data - range_value_positive_0_point_03125;
            end
            16  :   begin
                output_alpha_find = data_positive_exp_0_point_023438;
                output_bias_find  = input_data - range_value_positive_0_point_015625;
            end
            17  :   begin
                output_alpha_find = data_positive_exp_0_point_007813;
                output_bias_find  = input_data - range_value_positive_0_point;
            end
            18  :   begin
                output_alpha_find = data_negative_exp_0_point_875;
                output_bias_find  = input_data - range_value_negative_0_point_875;
            end
            19  :   begin
                output_alpha_find = data_negative_exp_0_point_88281;
                output_bias_find  = input_data - range_value_negative_0_point_89063;
            end
            20  :   begin
                output_alpha_find = data_negative_exp_0_point_89844;
                output_bias_find  = input_data - range_value_negative_0_point_90625;
            end
            21  :   begin
                output_alpha_find = data_negative_exp_0_point_91406;
                output_bias_find  = input_data - range_value_negative_0_point_92188;
            end
            22  :   begin
                output_alpha_find = data_negative_exp_0_point_92969;
                output_bias_find  = input_data - range_value_negative_0_point_9375;  
            end
            23  :   begin
                output_alpha_find = data_negative_exp_0_point_94531;
                output_bias_find  = input_data - range_value_negative_0_point_95313;
            end
            24  :   begin
                output_alpha_find = data_negative_exp_0_point_96094;
                output_bias_find  = input_data - range_value_negative_0_point_96875;
            end
            25  :   begin
                output_alpha_find = data_negative_exp_0_point_97656;
                output_bias_find  = input_data - range_value_negative_0_point_98438;
            end
            26  :   begin
                output_alpha_find = data_negative_exp_0_point_99219;
                output_bias_find  = input_data - range_value_negative_1_point;
            end
            27  :   begin
                output_alpha_find = data_negative_exp_1_point_875;
                output_bias_find  = input_data - range_value_negative_1_point_875;
            end
            28  :   begin
                output_alpha_find = data_negative_exp_1_point_88281;
                output_bias_find  = input_data - range_value_negative_1_point_89063;
            end
            29  :   begin
                output_alpha_find = data_negative_exp_1_point_89844;
                output_bias_find  = input_data - range_value_negative_1_point_90625;
            end
            30  :   begin
                output_alpha_find = data_negative_exp_1_point_91406;
                output_bias_find  = input_data - range_value_negative_1_point_92188;
            end
            31  :   begin
                output_alpha_find = data_negative_exp_1_point_92969;
                output_bias_find  = input_data - range_value_negative_1_point_9375;
            end
            32  :   begin
                output_alpha_find = data_negative_exp_1_point_94531;
                output_bias_find  = input_data - range_value_negative_1_point_95313;
            end
            33  :   begin
                output_alpha_find = data_negative_exp_1_point_96094;
                output_bias_find  = input_data - range_value_negative_1_point_96875;
            end
            34  :   begin
                output_alpha_find = data_negative_exp_1_point_97656;
                output_bias_find  = input_data - range_value_negative_1_point_98438;
            end
            35  :   begin
                output_alpha_find = data_negative_exp_1_point_99219;
                output_bias_find  = input_data - range_value_negative_2_point;
            end
            36  :   begin
                output_alpha_find = data_negative_exp_2_point;
                output_bias_find  = 16'h0000;
            end
            default: begin
                output_alpha_find = 16'hxxxx;
                output_bias_find  = 16'hxxxx;
            end
        endcase
    end

    always@(posedge M_AXI_ACLK)begin
        if(input_data > range_value_positive_1_point_125)
            range_signal <= 0;
        else if(input_data > range_value_positive_1_point_109375)
            range_signal <= 1;
        else if(input_data > range_value_positive_1_point_09375)
            range_signal <= 2;
        else if(input_data > range_value_positive_1_point_078125)
            range_signal <= 3;
        else if(input_data > range_value_positive_1_point_0625)
            range_signal <= 4;
        else if(input_data > range_value_positive_1_point_046875)
            range_signal <= 5;
        else if(input_data > range_value_positive_1_point_03125)
            range_signal <= 6;
        else if(input_data > range_value_positive_1_point_015625)
            range_signal <= 7;
        else if(input_data > range_value_positive_1_point)
            range_signal <= 8;
        else if(input_data > range_value_positive_0_point_125)//next range(1 -> 0.125)
            range_signal <= 9;
        else if(input_data > range_value_positive_0_point_109375)
            range_signal <= 10;
        else if(input_data > range_value_positive_0_point_09375)
            range_signal <= 11;
        else if(input_data > range_value_positive_0_point_078125)
            range_signal <= 12;
        else if(input_data > range_value_positive_0_point_0625)
            range_signal <= 13;
        else if(input_data > range_value_positive_0_point_046875)
            range_signal <= 14;
        else if(input_data > range_value_positive_0_point_03125)
            range_signal <= 15;
        else if(input_data > range_value_positive_0_point_015625)
            range_signal <= 16;
        else if(input_data > range_value_positive_0_point)
            range_signal <= 17;
        else if(input_data > range_value_negative_0_point_875)//next range(0 -> -0.875)
            range_signal <= 18;
        else if(input_data > range_value_negative_0_point_89063)
            range_signal <= 19;
        else if(input_data > range_value_negative_0_point_90625)
            range_signal <= 20;
        else if(input_data > range_value_negative_0_point_92188)
            range_signal <= 21;
        else if(input_data > range_value_negative_0_point_9375)
            range_signal <= 22;
        else if(input_data > range_value_negative_0_point_95313)
            range_signal <= 23;
        else if(input_data > range_value_negative_0_point_96875)
            range_signal <= 24;
        else if(input_data > range_value_negative_0_point_98438)
            range_signal <= 25;
        else if(input_data > range_value_negative_1_point)
            range_signal <= 26;
        else if(input_data > range_value_negative_1_point_875)//next range(-1 -> -1.875)
            range_signal <= 27;
        else if(input_data > range_value_negative_1_point_89063)
            range_signal <= 28;
        else if(input_data > range_value_negative_1_point_90625)
            range_signal <= 29;
        else if(input_data > range_value_negative_1_point_92188)
            range_signal <= 30;
        else if(input_data > range_value_negative_1_point_9375)
            range_signal <= 31;
        else if(input_data > range_value_negative_1_point_95313)
            range_signal <= 32;
        else if(input_data > range_value_negative_1_point_96875)
            range_signal <= 33;    
        else if(input_data > range_value_negative_1_point_98438)
            range_signal <= 34;
        else if(input_data > range_value_negative_2_point)
            range_signal <= 35;
        else if(input_data <= range_value_negative_2_point)
            range_signal <= 36;
        else begin
            range_signal <= 37;
        end
    end
endmodule

module exp_bias_choose_func_layer#(
        parameter data_bit                              = 16,
        parameter alpga_shift_bit                       = 15,
        parameter bias_shift_bit                        = 999,
        parameter alpha_shift_value                     = 2**alpga_shift_bit,
        parameter bias_shift_value                      = 2**bias_shift_bit,
        parameter range_value_positive_0_point_8125     = 0.8125 * bias_shift_value,
        parameter range_value_positive_0_point_6875     = 0.6875 * bias_shift_value,
        parameter range_value_positive_0_point_5625     = 0.5625 * bias_shift_value,
        parameter range_value_positive_0_point_4375     = 0.4375 * bias_shift_value,
        parameter range_value_positive_0_point_3125     = 0.3125 * bias_shift_value,
        parameter range_value_positive_0_point_1875     = 0.1875 * bias_shift_value,
        parameter range_value_positive_0_point_0625     = 0.0625 * bias_shift_value,
        parameter data_positive_exp_0_point_875         = 2.398875 * bias_shift_value,
        parameter data_positive_exp_0_point_75          = 2.117    * bias_shift_value,
        parameter data_positive_exp_0_point_625         = 1.868246 * bias_shift_value,
        parameter data_positive_exp_0_point_5           = 1.648721 * bias_shift_value,
        parameter data_positive_exp_0_point_375         = 1.454991 * bias_shift_value,
        parameter data_positive_exp_0_point_250         = 1.284025 * bias_shift_value,
        parameter data_positive_exp_0_point_125         = 1.133148 * bias_shift_value,
        parameter data_positive_exp_0_point             = 1        * bias_shift_value
    )(
        input   signed [data_bit-1:0] input_data,
        output  reg signed [data_bit-1:0] output_data
    );
    always@(*)begin
        if(input_data>range_value_positive_0_point_8125)begin
            output_data = data_positive_exp_0_point_875;
        end else if(input_data>range_value_positive_0_point_6875)begin
            output_data = data_positive_exp_0_point_75;
        end else if(input_data>range_value_positive_0_point_5625)begin
            output_data = data_positive_exp_0_point_625;
        end else if(input_data>range_value_positive_0_point_4375)begin
            output_data = data_positive_exp_0_point_5;
        end else if(input_data>range_value_positive_0_point_3125)begin
            output_data = data_positive_exp_0_point_375;
        end else if(input_data>range_value_positive_0_point_1875)begin
            output_data = data_positive_exp_0_point_250;
        end else if(input_data>range_value_positive_0_point_0625)begin
            output_data = data_positive_exp_0_point_125;
        end else if(input_data<=range_value_positive_0_point_0625)begin
            output_data = data_positive_exp_0_point;
        end else begin
            output_data = 16'hxxxx;
        end
    end
endmodule

module process_mul_element#(
        parameter data_bit = 16,
        parameter data_shift = 15
    )(
        input               rst,
        input               M_AXI_ACLK,
        input   signed      [data_bit-1:0] input_data,
        input   signed      [data_bit-1:0] input_alpha,
        output  reg   signed[data_bit-1:0] output_data
    );

        reg     signed      [15:0]MUL_answer;
        
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                MUL_answer <= 0;
            end else begin
                MUL_answer <= (input_alpha * input_data)>>data_shift;
            end
        end
endmodule

module process_add_element#(
        parameter data_bit = 16,
        parameter data_shift = 15
    )(
        input               rst,
        input               M_AXI_ACLK,
        input   signed      [data_bit-1:0] input_data, 
        input   signed      [data_bit-1:0] input_bias,
        output  reg   signed[data_bit-1:0] output_data
    );
        always@(posedge M_AXI_ACLK)begin
            output_data <= (input_data + input_bias)>>1;
        end
endmodule
