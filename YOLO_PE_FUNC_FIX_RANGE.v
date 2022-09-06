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
        input   [2:0]repair_bit,
        input  signed       [data_bit-1:0] input_data, 
        output reg  signed  [data_bit-1:0] output_alpha,
        output reg  signed  [data_bit-1:0] output_bias
    );
    wire signed [data_bit-1:0]data_negative_8_alpha_reg         = data_negative_8_alpha        ;
    wire signed [data_bit-1:0]data_negative_4_point_5_alpha_reg = data_negative_4_point_5_alpha;
    wire signed [data_bit-1:0]data_negative_3_alpha_reg         = data_negative_3_alpha        ;
    wire signed [data_bit-1:0]data_negative_2_point_5_alpha_reg = data_negative_2_point_5_alpha;
    wire signed [data_bit-1:0]data_negative_2_alpha_reg         = data_negative_2_alpha        ;
    wire signed [data_bit-1:0]data_negative_1_point_5_alpha_reg = data_negative_1_point_5_alpha;
    wire signed [data_bit-1:0]data_negative_1_alpha_reg         = data_negative_1_alpha        ;
    wire signed [data_bit-1:0]data_positive_1_alpha_reg         = data_positive_1_alpha        ;
    wire signed [data_bit-1:0]data_positive_1_point_5_alpha_reg = data_positive_1_point_5_alpha;
    wire signed [data_bit-1:0]data_positive_2_alpha_reg         = data_positive_2_alpha        ;
    wire signed [data_bit-1:0]data_positive_2_point_5_alpha_reg = data_positive_2_point_5_alpha;
    wire signed [data_bit-1:0]data_positive_3_alpha_reg         = data_positive_3_alpha        ;
    wire signed [data_bit-1:0]data_positive_4_point_5_alpha_reg = data_positive_4_point_5_alpha;
    wire signed [data_bit-1:0]data_positive_8_alpha_reg         = data_positive_8_alpha        ;
    wire signed [data_bit-1:0]data_negative_8_bias_reg          = data_negative_8_bias        ;
    wire signed [data_bit-1:0]data_negative_4_point_5_bias_reg  = data_negative_4_point_5_bias;
    wire signed [data_bit-1:0]data_negative_3_bias_reg          = data_negative_3_bias        ;
    wire signed [data_bit-1:0]data_negative_2_point_5_bias_reg  = data_negative_2_point_5_bias;
    wire signed [data_bit-1:0]data_negative_2_bias_reg          = data_negative_2_bias        ;
    wire signed [data_bit-1:0]data_negative_1_point_5_bias_reg  = data_negative_1_point_5_bias;
    wire signed [data_bit-1:0]data_negative_1_bias_reg          = data_negative_1_bias        ;
    wire signed [data_bit-1:0]data_positive_1_bias_reg          = data_positive_1_bias        ;
    wire signed [data_bit-1:0]data_positive_1_point_5_bias_reg  = data_positive_1_point_5_bias;
    wire signed [data_bit-1:0]data_positive_2_bias_reg          = data_positive_2_bias        ;
    wire signed [data_bit-1:0]data_positive_2_point_5_bias_reg  = data_positive_2_point_5_bias;
    wire signed [data_bit-1:0]data_positive_3_bias_reg          = data_positive_3_bias        ;
    wire signed [data_bit-1:0]data_positive_4_point_5_bias_reg  = data_positive_4_point_5_bias;
    wire signed [data_bit-1:0]data_positive_8_bias_reg          = data_positive_8_bias        ;
    wire signed [data_bit-1:0]range_value_negative_8_reg        = range_value_negative_8        ;
    wire signed [data_bit-1:0]range_value_negative_4_point_5_reg = range_value_negative_4_point_5;
    wire signed [data_bit-1:0]range_value_negative_3_reg         = range_value_negative_3        ;
    wire signed [data_bit-1:0]range_value_negative_2_point_5_reg = range_value_negative_2_point_5;
    wire signed [data_bit-1:0]range_value_negative_2_reg         = range_value_negative_2        ;
    wire signed [data_bit-1:0]range_value_negative_1_point_5_reg = range_value_negative_1_point_5;
    wire signed [data_bit-1:0]range_value_negative_1_reg         = range_value_negative_1        ;
    wire signed [data_bit-1:0]range_value_positive_1_reg         = range_value_positive_1        ;
    wire signed [data_bit-1:0]range_value_positive_1_point_5_reg = range_value_positive_1_point_5;
    wire signed [data_bit-1:0]range_value_positive_2_reg         = range_value_positive_2        ;
    wire signed [data_bit-1:0]range_value_positive_2_point_5_reg = range_value_positive_2_point_5;
    wire signed [data_bit-1:0]range_value_positive_3_reg         = range_value_positive_3        ;
    wire signed [data_bit-1:0]range_value_positive_4_point_5_reg = range_value_positive_4_point_5;
    wire signed [data_bit-1:0]range_value_positive_8_reg         = range_value_positive_8        ;

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
                output_alpha_wire = (data_negative_8_alpha_reg>>repair_bit);
                output_bias_wire  = (data_negative_8_bias_reg>>repair_bit);
            end
            2   :   begin
                output_alpha_wire = (data_negative_4_point_5_alpha_reg>>repair_bit);
                output_bias_wire  = (data_negative_4_point_5_bias_reg>>repair_bit);
            end
            3   :   begin
                output_alpha_wire = (data_negative_3_alpha_reg>>repair_bit);
                output_bias_wire  = (data_negative_3_bias_reg>>repair_bit);
            end
            4   :   begin
                output_alpha_wire = (data_negative_2_point_5_alpha_reg>>repair_bit);
                output_bias_wire  = (data_negative_2_point_5_bias_reg>>repair_bit);
            end
            5   :   begin
                output_alpha_wire = (data_negative_2_alpha_reg>>repair_bit);
                output_bias_wire  = (data_negative_2_bias_reg>>repair_bit);
            end
            6   :   begin
                output_alpha_wire = (data_negative_1_point_5_alpha_reg>>repair_bit);
                output_bias_wire  = (data_negative_1_point_5_bias_reg>>repair_bit);
            end
            7   :   begin
                output_alpha_wire = (data_negative_1_alpha_reg>>repair_bit);
                output_bias_wire  = (data_negative_1_bias_reg>>repair_bit);
            end
            8   :   begin
                output_alpha_wire = (data_positive_1_alpha_reg>>repair_bit);
                output_bias_wire  = (data_positive_1_bias_reg>>repair_bit);
            end
            9   :   begin
                output_alpha_wire = (data_positive_1_point_5_alpha_reg>>repair_bit);
                output_bias_wire  = (data_positive_1_point_5_bias_reg>>repair_bit);
            end
            10  :   begin
                output_alpha_wire = (data_positive_2_alpha_reg>>repair_bit);
                output_bias_wire  = (data_positive_2_bias_reg>>repair_bit);
            end
            11  :   begin
                output_alpha_wire = (data_positive_2_point_5_alpha_reg>>repair_bit);
                output_bias_wire  = (data_positive_2_point_5_bias_reg>>repair_bit);
            end
            12  :   begin
                output_alpha_wire = (data_positive_3_alpha_reg>>repair_bit);
                output_bias_wire  = (data_positive_3_bias_reg>>repair_bit);
            end
            13  :   begin
                output_alpha_wire = (data_positive_4_point_5_alpha_reg>>repair_bit);
                output_bias_wire  = (data_positive_4_point_5_bias_reg>>repair_bit);
            end
            14  :   begin
                output_alpha_wire = (data_positive_8_alpha_reg>>repair_bit);
                output_bias_wire  = (data_positive_8_bias_reg>>repair_bit);
            end
            default: begin
                output_alpha_wire = 0;
                output_bias_wire  = 0;
            end
        endcase
    end

    always@(posedge M_AXI_ACLK)begin
        if(input_data<=(range_value_negative_8_reg>>repair_bit))
            range_signal <= 0;
        else if(input_data>(range_value_negative_8_reg>>repair_bit) && input_data<=(range_value_negative_4_point_5_reg>>repair_bit))
            range_signal <= 1;
        else if(input_data>(range_value_negative_4_point_5_reg>>repair_bit) && input_data<=(range_value_negative_3_reg>>repair_bit))
            range_signal <= 2;
        else if(input_data>(range_value_negative_3_reg>>repair_bit) && input_data<=(range_value_negative_2_point_5_reg>>repair_bit))
            range_signal <= 3;
        else if(input_data>(range_value_negative_2_point_5_reg>>repair_bit) && input_data<=(range_value_negative_2_reg>>repair_bit))
            range_signal <= 4;
        else if(input_data>(range_value_negative_2_reg>>repair_bit) && input_data<=(range_value_negative_1_point_5_reg>>repair_bit))
            range_signal <= 5;
        else if(input_data>(range_value_negative_1_point_5_reg>>repair_bit) && input_data<=(range_value_negative_1_reg>>repair_bit))
            range_signal <= 6;
        else if(input_data>(range_value_negative_1_reg>>repair_bit) && input_data<=(range_value_positive_1_reg>>repair_bit))
            range_signal <= 7;
        else if(input_data>(range_value_positive_1_reg>>repair_bit) && input_data<=(range_value_positive_1_point_5_reg>>repair_bit))
            range_signal <= 8;
        else if(input_data>(range_value_positive_1_point_5_reg>>repair_bit) && input_data<=(range_value_positive_2_reg>>repair_bit))
            range_signal <= 9;
        else if(input_data>(range_value_positive_2_reg>>repair_bit) && input_data<=(range_value_positive_2_point_5_reg>>repair_bit))
            range_signal <= 10;    
        else if(input_data>(range_value_positive_2_point_5_reg>>repair_bit) && input_data<=(range_value_positive_3_reg>>repair_bit))
            range_signal <= 11;    
        else if(input_data>(range_value_positive_3_reg>>repair_bit) && input_data<=(range_value_positive_4_point_5_reg>>repair_bit))
            range_signal <= 12; 
        else if(input_data>(range_value_positive_4_point_5_reg>>repair_bit) && input_data<=(range_value_positive_8_reg>>repair_bit))
            range_signal <= 13; 
        else if(input_data>(range_value_positive_8_reg>>repair_bit))
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
    input   [2:0]repair_bit,
    input   signed [data_bit-1:0] input_data,
    output  reg  signed  [data_bit-1:0] output_alpha,
    output  reg  signed  [data_bit-1:0] output_bias
);
    wire signed  [data_bit-1:0]data_positive_exp_1_point_125_reg     = data_positive_exp_1_point_125   ;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_117188_reg  = data_positive_exp_1_point_117188;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_101563_reg  = data_positive_exp_1_point_101563;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_085938_reg  = data_positive_exp_1_point_085938;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_070313_reg  = data_positive_exp_1_point_070313;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_054688_reg  = data_positive_exp_1_point_054688;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_039063_reg  = data_positive_exp_1_point_039063;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_023438_reg  = data_positive_exp_1_point_023438;
    wire signed  [data_bit-1:0]data_positive_exp_1_point_007813_reg  = data_positive_exp_1_point_007813;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_125_reg     = data_positive_exp_0_point_125   ;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_117188_reg  = data_positive_exp_0_point_117188;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_101563_reg  = data_positive_exp_0_point_101563;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_085938_reg  = data_positive_exp_0_point_085938;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_070313_reg  = data_positive_exp_0_point_070313;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_054688_reg  = data_positive_exp_0_point_054688;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_039063_reg  = data_positive_exp_0_point_039063;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_023438_reg  = data_positive_exp_0_point_023438;
    wire signed  [data_bit-1:0]data_positive_exp_0_point_007813_reg  = data_positive_exp_0_point_007813;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_875_reg     = data_negative_exp_0_point_875  ;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_88281_reg   = data_negative_exp_0_point_88281;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_89844_reg   = data_negative_exp_0_point_89844;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_91406_reg   = data_negative_exp_0_point_91406;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_92969_reg   = data_negative_exp_0_point_92969;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_94531_reg   = data_negative_exp_0_point_94531;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_96094_reg   = data_negative_exp_0_point_96094;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_97656_reg   = data_negative_exp_0_point_97656;
    wire signed  [data_bit-1:0]data_negative_exp_0_point_99219_reg   = data_negative_exp_0_point_99219;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_875_reg     = data_negative_exp_1_point_875  ;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_88281_reg   = data_negative_exp_1_point_88281;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_89844_reg   = data_negative_exp_1_point_89844;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_91406_reg   = data_negative_exp_1_point_91406;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_92969_reg   = data_negative_exp_1_point_92969;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_94531_reg   = data_negative_exp_1_point_94531;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_96094_reg   = data_negative_exp_1_point_96094;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_97656_reg   = data_negative_exp_1_point_97656;
    wire signed  [data_bit-1:0]data_negative_exp_1_point_99219_reg   = data_negative_exp_1_point_99219;
    wire signed  [data_bit-1:0]data_negative_exp_2_point_reg         = data_negative_exp_2_point      ;
    wire signed  [data_bit-1:0]range_value_positive_1_point_125_reg    = range_value_positive_1_point_125   ;
    wire signed  [data_bit-1:0]range_value_positive_1_point_109375_reg = range_value_positive_1_point_109375;
    wire signed  [data_bit-1:0]range_value_positive_1_point_09375_reg  = range_value_positive_1_point_09375 ;
    wire signed  [data_bit-1:0]range_value_positive_1_point_078125_reg = range_value_positive_1_point_078125;
    wire signed  [data_bit-1:0]range_value_positive_1_point_0625_reg   = range_value_positive_1_point_0625  ;
    wire signed  [data_bit-1:0]range_value_positive_1_point_046875_reg = range_value_positive_1_point_046875;
    wire signed  [data_bit-1:0]range_value_positive_1_point_03125_reg  = range_value_positive_1_point_03125 ;
    wire signed  [data_bit-1:0]range_value_positive_1_point_015625_reg = range_value_positive_1_point_015625;
    wire signed  [data_bit-1:0]range_value_positive_1_point_reg        = range_value_positive_1_point       ;
    wire signed  [data_bit-1:0]range_value_positive_0_point_125_reg    = range_value_positive_0_point_125   ;
    wire signed  [data_bit-1:0]range_value_positive_0_point_109375_reg = range_value_positive_0_point_109375;
    wire signed  [data_bit-1:0]range_value_positive_0_point_09375_reg  = range_value_positive_0_point_09375 ;
    wire signed  [data_bit-1:0]range_value_positive_0_point_078125_reg = range_value_positive_0_point_078125;
    wire signed  [data_bit-1:0]range_value_positive_0_point_0625_reg   = range_value_positive_0_point_0625  ;
    wire signed  [data_bit-1:0]range_value_positive_0_point_046875_reg = range_value_positive_0_point_046875;
    wire signed  [data_bit-1:0]range_value_positive_0_point_03125_reg  = range_value_positive_0_point_03125 ;
    wire signed  [data_bit-1:0]range_value_positive_0_point_015625_reg = range_value_positive_0_point_015625;
    wire signed  [data_bit-1:0]range_value_positive_0_point_reg        = range_value_positive_0_point       ;
    wire signed  [data_bit-1:0]range_value_negative_0_point_875_reg    = range_value_negative_0_point_875  ;
    wire signed  [data_bit-1:0]range_value_negative_0_point_89063_reg  = range_value_negative_0_point_89063;
    wire signed  [data_bit-1:0]range_value_negative_0_point_90625_reg  = range_value_negative_0_point_90625;
    wire signed  [data_bit-1:0]range_value_negative_0_point_92188_reg  = range_value_negative_0_point_92188;
    wire signed  [data_bit-1:0]range_value_negative_0_point_9375_reg   = range_value_negative_0_point_9375 ;
    wire signed  [data_bit-1:0]range_value_negative_0_point_95313_reg  = range_value_negative_0_point_95313;
    wire signed  [data_bit-1:0]range_value_negative_0_point_96875_reg  = range_value_negative_0_point_96875;
    wire signed  [data_bit-1:0]range_value_negative_0_point_98438_reg  = range_value_negative_0_point_98438;
    wire signed  [data_bit-1:0]range_value_negative_1_point_reg        = range_value_negative_1_point      ;
    wire signed  [data_bit-1:0]range_value_negative_1_point_875_reg    = range_value_negative_1_point_875  ;
    wire signed  [data_bit-1:0]range_value_negative_1_point_89063_reg  = range_value_negative_1_point_89063;
    wire signed  [data_bit-1:0]range_value_negative_1_point_90625_reg  = range_value_negative_1_point_90625;
    wire signed  [data_bit-1:0]range_value_negative_1_point_92188_reg  = range_value_negative_1_point_92188;
    wire signed  [data_bit-1:0]range_value_negative_1_point_9375_reg   = range_value_negative_1_point_9375 ;
    wire signed  [data_bit-1:0]range_value_negative_1_point_95313_reg  = range_value_negative_1_point_95313;
    wire signed  [data_bit-1:0]range_value_negative_1_point_96875_reg  = range_value_negative_1_point_96875;
    wire signed  [data_bit-1:0]range_value_negative_1_point_98438_reg  = range_value_negative_1_point_98438;
    wire signed  [data_bit-1:0]range_value_negative_2_point_reg        = range_value_negative_2_point      ;

    reg  signed [data_bit-1:0]output_alpha_find;
    reg  signed [data_bit-1:0]output_bias_find;
    wire signed [data_bit-1:0]output_bias_find_output;
    reg        [5:0]         range_signal;

    exp_bias_choose_func_layer#(.bias_shift_bit(bias_shift_bit)) exp_layer(
        .repair_bit(repair_bit),
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
                output_alpha_find = (data_positive_exp_1_point_125_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_125_reg>>repair_bit);
            end
            1   :   begin
                output_alpha_find = (data_positive_exp_1_point_117188_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_109375_reg>>repair_bit);
            end
            2   :   begin
                output_alpha_find = (data_positive_exp_1_point_101563_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_09375_reg>>repair_bit);
            end
            3   :   begin
                output_alpha_find = (data_positive_exp_1_point_085938_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_078125_reg>>repair_bit); 
            end
            4   :   begin
                output_alpha_find = (data_positive_exp_1_point_070313_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_0625_reg>>repair_bit); 
            end
            5   :   begin
                output_alpha_find = (data_positive_exp_1_point_054688_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_046875_reg>>repair_bit); 
            end
            6   :   begin
                output_alpha_find = (data_positive_exp_1_point_039063_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_03125_reg>>repair_bit); 
            end
            7   :   begin
                output_alpha_find = (data_positive_exp_1_point_023438_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_015625_reg>>repair_bit); 
            end
            8   :   begin
                output_alpha_find = (data_positive_exp_1_point_007813_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_1_point_reg>>repair_bit); 
            end
            9   :   begin
                output_alpha_find = (data_positive_exp_0_point_125_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_125_reg>>repair_bit); 
            end
            10  :   begin
                output_alpha_find = (data_positive_exp_0_point_117188_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_109375_reg>>repair_bit);
            end
            11  :   begin
                output_alpha_find = (data_positive_exp_0_point_101563_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_09375_reg>>repair_bit);
            end
            12  :   begin
                output_alpha_find = (data_positive_exp_0_point_085938_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_078125_reg>>repair_bit);
            end
            13  :   begin
                output_alpha_find = (data_positive_exp_0_point_070313_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_0625_reg>>repair_bit);
            end
            14  :   begin
                output_alpha_find = (data_positive_exp_0_point_054688_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_046875_reg>>repair_bit);
            end
            15  :   begin
                output_alpha_find = (data_positive_exp_0_point_039063_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_03125_reg>>repair_bit);
            end
            16  :   begin
                output_alpha_find = (data_positive_exp_0_point_023438_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_015625_reg>>repair_bit);
            end
            17  :   begin
                output_alpha_find = (data_positive_exp_0_point_007813_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_positive_0_point_reg>>repair_bit);
            end
            18  :   begin
                output_alpha_find = (data_negative_exp_0_point_875_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_875_reg>>repair_bit);
            end
            19  :   begin
                output_alpha_find = (data_negative_exp_0_point_88281_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_89063_reg>>repair_bit);
            end
            20  :   begin
                output_alpha_find = (data_negative_exp_0_point_89844_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_90625_reg>>repair_bit);
            end
            21  :   begin
                output_alpha_find = (data_negative_exp_0_point_91406_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_92188_reg>>repair_bit);
            end
            22  :   begin
                output_alpha_find = (data_negative_exp_0_point_92969_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_9375_reg>>repair_bit);  
            end
            23  :   begin
                output_alpha_find = (data_negative_exp_0_point_94531_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_95313_reg>>repair_bit);
            end
            24  :   begin
                output_alpha_find = (data_negative_exp_0_point_96094_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_96875_reg>>repair_bit);
            end
            25  :   begin
                output_alpha_find = (data_negative_exp_0_point_97656_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_0_point_98438_reg>>repair_bit);
            end
            26  :   begin
                output_alpha_find = (data_negative_exp_0_point_99219_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_reg>>repair_bit);
            end
            27  :   begin
                output_alpha_find = (data_negative_exp_1_point_875_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_875_reg>>repair_bit);
            end
            28  :   begin
                output_alpha_find = (data_negative_exp_1_point_88281_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_89063_reg>>repair_bit);
            end
            29  :   begin
                output_alpha_find = (data_negative_exp_1_point_89844_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_90625_reg>>repair_bit);
            end
            30  :   begin
                output_alpha_find = (data_negative_exp_1_point_91406_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_92188_reg>>repair_bit);
            end
            31  :   begin
                output_alpha_find = (data_negative_exp_1_point_92969_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_9375_reg>>repair_bit);
            end
            32  :   begin
                output_alpha_find = (data_negative_exp_1_point_94531_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_95313_reg>>repair_bit);
            end
            33  :   begin
                output_alpha_find = (data_negative_exp_1_point_96094_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_96875_reg>>repair_bit);
            end
            34  :   begin
                output_alpha_find = (data_negative_exp_1_point_97656_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_1_point_98438_reg>>repair_bit);
            end
            35  :   begin
                output_alpha_find = (data_negative_exp_1_point_99219_reg>>repair_bit);
                output_bias_find  = input_data - (range_value_negative_2_point_reg>>repair_bit);
            end
            36  :   begin
                output_alpha_find = (data_negative_exp_2_point_reg>>repair_bit);
                output_bias_find  = 16'h0000;
            end
            default: begin
                output_alpha_find = 16'hxxxx;
                output_bias_find  = 16'hxxxx;
            end
        endcase
    end

    always@(posedge M_AXI_ACLK)begin
        if(input_data > (range_value_positive_1_point_125_reg>>repair_bit))
            range_signal <= 0;
        else if(input_data > (range_value_positive_1_point_109375_reg>>repair_bit))
            range_signal <= 1;
        else if(input_data > (range_value_positive_1_point_09375_reg>>repair_bit))
            range_signal <= 2;
        else if(input_data > (range_value_positive_1_point_078125_reg>>repair_bit))
            range_signal <= 3;
        else if(input_data > (range_value_positive_1_point_0625_reg>>repair_bit))
            range_signal <= 4;
        else if(input_data > (range_value_positive_1_point_046875_reg>>repair_bit))
            range_signal <= 5;
        else if(input_data > (range_value_positive_1_point_03125_reg>>repair_bit))
            range_signal <= 6;
        else if(input_data > (range_value_positive_1_point_015625_reg>>repair_bit))
            range_signal <= 7;
        else if(input_data > (range_value_positive_1_point_reg>>repair_bit))
            range_signal <= 8;
        else if(input_data > (range_value_positive_0_point_125_reg>>repair_bit))//next range(1 -> 0.125)
            range_signal <= 9;
        else if(input_data > (range_value_positive_0_point_109375_reg>>repair_bit))
            range_signal <= 10;
        else if(input_data > (range_value_positive_0_point_09375_reg>>repair_bit))
            range_signal <= 11;
        else if(input_data > (range_value_positive_0_point_078125_reg>>repair_bit))
            range_signal <= 12;
        else if(input_data > (range_value_positive_0_point_0625_reg>>repair_bit))
            range_signal <= 13;
        else if(input_data > (range_value_positive_0_point_046875_reg>>repair_bit))
            range_signal <= 14;
        else if(input_data > (range_value_positive_0_point_03125_reg>>repair_bit))
            range_signal <= 15;
        else if(input_data > (range_value_positive_0_point_015625_reg>>repair_bit))
            range_signal <= 16;
        else if(input_data > (range_value_positive_0_point_reg>>repair_bit))
            range_signal <= 17;
        else if(input_data > (range_value_negative_0_point_875_reg>>repair_bit))//next range(0 -> -0.875)
            range_signal <= 18;
        else if(input_data > (range_value_negative_0_point_89063_reg>>repair_bit))
            range_signal <= 19;
        else if(input_data > (range_value_negative_0_point_90625_reg>>repair_bit))
            range_signal <= 20;
        else if(input_data > (range_value_negative_0_point_92188_reg>>repair_bit))
            range_signal <= 21;
        else if(input_data > (range_value_negative_0_point_9375_reg>>repair_bit))
            range_signal <= 22;
        else if(input_data > (range_value_negative_0_point_95313_reg>>repair_bit))
            range_signal <= 23;
        else if(input_data > (range_value_negative_0_point_96875_reg>>repair_bit))
            range_signal <= 24;
        else if(input_data > (range_value_negative_0_point_98438_reg>>repair_bit))
            range_signal <= 25;
        else if(input_data > (range_value_negative_1_point_reg>>repair_bit))
            range_signal <= 26;
        else if(input_data > (range_value_negative_1_point_875_reg>>repair_bit))//next range(-1 -> -1.875)
            range_signal <= 27;
        else if(input_data > (range_value_negative_1_point_89063_reg>>repair_bit))
            range_signal <= 28;
        else if(input_data > (range_value_negative_1_point_90625_reg>>repair_bit))
            range_signal <= 29;
        else if(input_data > (range_value_negative_1_point_92188_reg>>repair_bit))
            range_signal <= 30;
        else if(input_data > (range_value_negative_1_point_9375_reg>>repair_bit))
            range_signal <= 31;
        else if(input_data > (range_value_negative_1_point_95313_reg>>repair_bit))
            range_signal <= 32;
        else if(input_data > (range_value_negative_1_point_96875_reg>>repair_bit))
            range_signal <= 33;    
        else if(input_data > (range_value_negative_1_point_98438_reg>>repair_bit))
            range_signal <= 34;
        else if(input_data > (range_value_negative_2_point_reg>>repair_bit))
            range_signal <= 35;
        else if(input_data <= (range_value_negative_2_point_reg>>repair_bit))
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
        input   [2:0]repair_bit,
        input   signed [data_bit-1:0] input_data,
        output  reg signed [data_bit-1:0] output_data
    );
    wire signed [data_bit-1:0] range_value_positive_0_point_8125_reg = range_value_positive_0_point_8125;
    wire signed [data_bit-1:0] range_value_positive_0_point_6875_reg = range_value_positive_0_point_6875;
    wire signed [data_bit-1:0] range_value_positive_0_point_5625_reg = range_value_positive_0_point_5625;
    wire signed [data_bit-1:0] range_value_positive_0_point_4375_reg = range_value_positive_0_point_4375;
    wire signed [data_bit-1:0] range_value_positive_0_point_3125_reg = range_value_positive_0_point_3125;
    wire signed [data_bit-1:0] range_value_positive_0_point_1875_reg = range_value_positive_0_point_1875;
    wire signed [data_bit-1:0] range_value_positive_0_point_0625_reg = range_value_positive_0_point_0625;
    wire signed [data_bit-1:0] data_positive_exp_0_point_875_reg     = data_positive_exp_0_point_875    ;
    wire signed [data_bit-1:0] data_positive_exp_0_point_75_reg      = data_positive_exp_0_point_75     ;
    wire signed [data_bit-1:0] data_positive_exp_0_point_625_reg     = data_positive_exp_0_point_625    ;
    wire signed [data_bit-1:0] data_positive_exp_0_point_5_reg       = data_positive_exp_0_point_5      ;
    wire signed [data_bit-1:0] data_positive_exp_0_point_375_reg     = data_positive_exp_0_point_375    ;
    wire signed [data_bit-1:0] data_positive_exp_0_point_250_reg     = data_positive_exp_0_point_250    ;
    wire signed [data_bit-1:0] data_positive_exp_0_point_125_reg     = data_positive_exp_0_point_125    ;
    wire signed [data_bit-1:0] data_positive_exp_0_point_reg         = data_positive_exp_0_point        ;
    always@(*)begin
        if(input_data>(range_value_positive_0_point_8125_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_875_reg>>repair_bit);
        end else if(input_data>(range_value_positive_0_point_6875_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_75_reg>>repair_bit);
        end else if(input_data>(range_value_positive_0_point_5625_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_625_reg>>repair_bit);
        end else if(input_data>(range_value_positive_0_point_4375_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_5_reg>>repair_bit);
        end else if(input_data>(range_value_positive_0_point_3125_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_375_reg>>repair_bit);
        end else if(input_data>(range_value_positive_0_point_1875_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_250_reg>>repair_bit);
        end else if(input_data>(range_value_positive_0_point_0625_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_125_reg>>repair_bit);
        end else if(input_data<=(range_value_positive_0_point_0625_reg>>repair_bit))begin
            output_data = (data_positive_exp_0_point_reg>>repair_bit);
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
