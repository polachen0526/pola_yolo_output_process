`timescale 1ns / 1ps
`define MODULE_WORD_SIZE_hw 16
module special_process_element_dwc#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       WORD_EXT_SIZE   =   WORD_SIZE+9,
    parameter       HALF_EXT_SIZE   =   HALF_SIZE+9,
    parameter       AXI_DATA_WIDTH  =   8,
    parameter       TILE_NUM        =   2
)(
    input                                           clk,
                                                    set_isize,
                                                    set_wsize,
                                                    batch_first,            //1: Normalization and then Activation ; 
                                                    have_batch,             //Normalization Need
                                                    have_relu,              //Activation
/*
                                                    have_leaky,             //1: Leaky relu ; 0: Relu
                                                    have_sigmoid,
                                                    have_last_ich,          //Partial sum finish
*/
    input           [5:0]                           quant_pe,
                                                    quant_normalization,    //After Multiply Alpha,shift to fix point
//                                                    quant_activation,       //After Multiply Leaky constant,shift to fix point
//    input           [WORD_SIZE-1:0]                 leaky_constant,         //Leaky is product multiply 0.125 or 0.1.
    input           [TILE_NUM-1:0]                  normalization_alpha_sign,
    input           [WORD_SIZE-1:0]                 normalization_alpha,    //As it's name
    input           [WORD_SIZE-1:0]                 normalization_beta,     //As it's name
                                                    PE_product,             //{HIGH_DATA,LOW_DATA} {TOTAL_DATA}
    output  reg     [WORD_SIZE-1:0]                 SPE_product             //
);
/*
    wire            [(HALF_SIZE+2)*(TILE_NUM)-1:0]  data_accu_;
    wire            [(WORD_SIZE+1)-1:0]             data_accu_sum;
    wire            [(HALF_SIZE)*(TILE_NUM)-1:0]    data_accu_sat_;
    wire            [(WORD_SIZE)-1:0]               data_accu_sum_sat_;
*/
    wire            [(WORD_SIZE)-1:0]               act_out ,batch_out;
    reg             [(WORD_SIZE)-1:0]               act_in, batch_in, batch_act_result;
    reg             [(HALF_EXT_SIZE)*(TILE_NUM)-1:0]data_result_ext, data_result_shift;
    reg             [(WORD_EXT_SIZE)-1:0]           data_result_sum_ext, data_result_sum_shift;
    wire            [(HALF_SIZE)*(TILE_NUM)-1:0]    data_result_sat_;
    wire            [(WORD_SIZE)-1:0]               data_result_sum_sat_;
    integer                                         i;
/*
    bitparal_adder   #(HALF_SIZE, HALF_SIZE+2, 2) u_data_accu_bitparal_adder(
        .add_en     (have_accu),
        .set_isize  (set_isize),
        .idata      (PE_product),
        .wdata      (OBUF_accu_odata),
        .odata      (data_accu_)
    );
    bitparal_combine #(HALF_SIZE+2 ,HALF_SIZE, WORD_SIZE+1, 2) u_data_accu_bitparal_combine(
        .idata  (data_accu_),
        .odata  (data_accu_sum)
    );
genvar x_var;

generate
    for ( x_var=0 ; x_var<2 ; x_var=x_var+1 )begin
        satuation_oper #(HALF_SIZE+2,HALF_SIZE) SPE_satuation_oper_HALF_SIZE(
            .idata  (data_accu_[(HALF_SIZE+2)*x_var+:(HALF_SIZE+2)]),
            .odata  (data_accu_sat_[(HALF_SIZE)*x_var+:(HALF_SIZE)])
        );
    end
        satuation_oper #(WORD_SIZE+1,WORD_SIZE) SPE_satuation_oper_WORD_SIZE(
            .idata  (data_accu_sum[(WORD_SIZE+1)*0+:(WORD_SIZE+1)]),
            .odata  (data_accu_sum_sat_[(WORD_SIZE)*0+:(WORD_SIZE)])
        );
endgenerate
*/
    //================================================================================================================================================
    always @ ( posedge clk ) begin
        if ( batch_first == 1'b1 ) begin
            act_in              <= batch_out;
            batch_in            <= PE_product ;
            batch_act_result    <= act_out;
        end else begin
            act_in              <= PE_product ;
            batch_in            <= act_out;
            batch_act_result    <= batch_out;
        end
    end
    //================================================================================================================================================
    pe_batch u_pe_batch(
        .clk                    (clk),
        .have_batch             (have_batch),
        .set_isize              (set_isize),
        .set_wsize              (set_wsize),
        .quant_normalization    (quant_normalization),
        .batch_in               (batch_in),
        .normalization_alpha_sign(normalization_alpha_sign),
        .normalization_alpha    (normalization_alpha),
        .normalization_beta     (normalization_beta),
        .batch_out              (batch_out)    
    );
    pe_act_dwc u_pe_act_dwc(
        .clk                    (clk),
        .have_relu              (have_relu), 
//        .have_leaky             (have_leaky),
//        .have_sigmoid           (have_sigmoid),
        .set_isize              (set_isize),
        .quant_pe               (quant_pe),
//        .quant_activation       (quant_activation),        //quant of leaky constant ; quant of lookup table
//        .leaky_constant         (leaky_constant),        
        .act_in                 (act_in),
        .act_out                (act_out)
    );
/*
    always @ ( * ) begin
        for ( i=0 ; i<TILE_NUM ; i=i+1 ) begin
            data_result_ext[HALF_EXT_SIZE*i+:HALF_EXT_SIZE]     = $signed(batch_act_result[HALF_SIZE*i+:HALF_SIZE]) ;
            data_result_shift[HALF_EXT_SIZE*i+:HALF_EXT_SIZE]   = ( quant_next_layer[5] == 0 ) ? ( $signed(data_result_ext[HALF_EXT_SIZE*i+:HALF_EXT_SIZE]) >>> quant_next_layer )  
                                                                                               : ( $signed(data_result_ext[HALF_EXT_SIZE*i+:HALF_EXT_SIZE]) << (-quant_next_layer)) ; 
        end
        data_result_sum_ext[WORD_EXT_SIZE*0+:WORD_EXT_SIZE]     = $signed(batch_act_result[WORD_SIZE*0+:WORD_SIZE]);
        data_result_sum_shift[WORD_EXT_SIZE*0+:WORD_EXT_SIZE]   = ( quant_next_layer[5] == 0 ) ? ( $signed(data_result_sum_ext[WORD_EXT_SIZE*0+:WORD_EXT_SIZE]) >>> quant_next_layer ) 
                                                                                               : ( $signed(data_result_sum_ext[WORD_EXT_SIZE*0+:WORD_EXT_SIZE]) << (-quant_next_layer)) ; 
    end
genvar x_var;
generate
    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 )begin
        satuation_oper #(HALF_EXT_SIZE,HALF_SIZE) SPE_out_satuation_oper_HALF_SIZE(
            .idata  (data_result_shift[(HALF_EXT_SIZE)*x_var+:(HALF_EXT_SIZE)]),
            .odata  (data_result_sat_[(HALF_SIZE)*x_var+:(HALF_SIZE)])
        );
    end
        satuation_oper #(WORD_EXT_SIZE,WORD_SIZE) SPE_out_satuation_oper_WORD_SIZE(
            .idata  (data_result_sum_shift[(WORD_EXT_SIZE)*0+:(WORD_EXT_SIZE)]),
            .odata  (data_result_sum_sat_[(WORD_SIZE)*0+:(WORD_SIZE)])
        );
endgenerate
    always @ ( posedge clk ) begin
        SPE_product         <= ( set_isize == 0 ) ? data_result_sat_    : data_result_sum_sat_;
    end
*/
    always @ ( posedge clk ) begin
        SPE_product         <= batch_act_result;
    end
endmodule

module pe_act_dwc#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3,
    parameter       ADD_SIZE_SUM    =   ADD_SIZE+HALF_SIZE,
    parameter       ReLu6_MAX_FX_16 =   16'd6,
    parameter       ReLu6_MAX_FX_8  =   8'd6,
    parameter       TILE_NUM        =   2,
    parameter       LUT_INDEX_SIZE  =   6,
    parameter       LUT_QUANT       =   3
)(
    input                                           clk,
                                                    have_relu,
//                                                    have_leaky,
//                                                    have_sigmoid,
                                                    set_isize,
    input           [5:0]                           quant_pe,
//                                                    quant_activation,
//    input           [(WORD_SIZE)-1:0]               leaky_constant,
    input           [(WORD_SIZE)-1:0]               act_in,
    output  reg     [(WORD_SIZE)-1:0]               act_out
);
    integer                                         i;
//================================== Positive/Negetive Detect ==================================

    reg             [(HALF_SIZE)*(TILE_NUM)-1:0]    act_in_pip_for_ReLu6,
                                                    act_in_int,
                                                    act_in_ReLu6,
                                                    act_in_Relu6_sum,
                                                    act_in_Relu6_half;
    wire            [(HALF_SIZE)*(TILE_NUM)-1:0]    act_in_ReLu6_pip;
    reg             [(TILE_NUM)-1:0]                signed_flag;
    wire            [(TILE_NUM)-1:0]                act_relu_sign_flag_out;
//==================================  Passing By For Don't Relu ==================================
    wire            [(WORD_SIZE)-1:0]               act_in_pip_out;
/*  
//==================================  Leaky ReLu ==================================
    wire            [(ADD_SIZE)*(TILE_NUM)-1:0]     act_mult_;
    reg             [(ADD_SIZE)*(TILE_NUM)-1:0]     act_mult_shifted;
    wire            [(ADD_SIZE_SUM)-1:0]            act_mult_sum;
    reg             [(ADD_SIZE_SUM)-1:0]            act_mult_sum_shifted;
    wire            [(WORD_SIZE)-1:0]               act_mult_sat, act_mult_sum_sat;
  
//==================================  Lookup Table ==================================
    wire            [(WORD_SIZE)-1:0]               act_in_sh;
    reg             [(LUT_INDEX_SIZE)-1:0]          act_in_lut_index;
    reg                                             act_lut_postive_overflow, act_lut_postive_overflow_,
                                                    act_lut_negedge_overflow, act_lut_negedge_overflow_;
    wire            [(WORD_SIZE)-1:0]               act_lut_out_;
    reg             [(WORD_SIZE)-1:0]               act_lut_out;
    wire            [(WORD_SIZE)-1:0]               act_sigmoid_out, act_sigmoid_out_quant, act_sigmoid_out_pip;
*/
//================================== Positive/Negetive Detect ReLu6 ==================================
genvar x_var;
generate
    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 ) begin
    // =============================================== Is Over ReLu Max Num ===============================================
    always @ ( posedge clk ) begin
        act_in_pip_for_ReLu6 <= act_in;
        if ( set_isize == 1 )
            act_in_int                                          <= ( $signed(act_in                                  ) >>> quant_pe ) ;
        else
            act_in_int[(x_var)*(HALF_SIZE)+:(HALF_SIZE)]        <= ( $signed(act_in[(x_var)*(HALF_SIZE)+:(HALF_SIZE)]) >>> quant_pe ) ;
    end
/*
    always @ ( * ) begin
        if ( set_isize == 1 ) begin
            if ( act_in_int > ReLu6_MAX_FX_16 ) begin
                act_in_ReLu6                                    = (ReLu6_MAX_FX_16) << quant_pe;
            end else begin
                act_in_ReLu6                                    = act_in_pip_for_ReLu6;
            end
        end else begin
            if ( act_in_int[(x_var)*(TILE_NUM)+:(TILE_NUM)] > ReLu6_MAX_FX_8 ) begin
                act_in_ReLu6[(x_var)*(TILE_NUM)+:(TILE_NUM)]    = (ReLu6_MAX_FX_8) << quant_pe;
            end else begin
                act_in_ReLu6[(x_var)*(TILE_NUM)+:(TILE_NUM)]    = act_in_pip_for_ReLu6[(x_var)*(TILE_NUM)+:(TILE_NUM)];
            end
        end
    end
*/
    always @ ( * ) begin
        act_in_Relu6_sum                                     = ( act_in_int                                   > ReLu6_MAX_FX_16 ) ? (ReLu6_MAX_FX_16) << quant_pe : act_in_pip_for_ReLu6;
    end
    always @ ( * ) begin
        act_in_Relu6_half[(x_var)*(HALF_SIZE)+:(HALF_SIZE)]  = ( act_in_int[(x_var)*(HALF_SIZE)+:(HALF_SIZE)] > ReLu6_MAX_FX_8  ) ? (ReLu6_MAX_FX_8)  << quant_pe : act_in_pip_for_ReLu6[(x_var)*(HALF_SIZE)+:(HALF_SIZE)];
    end
    always @ ( * ) begin
        act_in_ReLu6                                         = ( set_isize ) ? act_in_Relu6_sum : act_in_Relu6_half;
    end 
    
        pip_passing #(WORD_SIZE,3) pip_passing_act_in_ReLu6(
            .clk    (clk),
            .idata  (act_in_ReLu6),
            .odata  (act_in_ReLu6_pip)
        );
    // =============================================== Is Over ReLu Max Num ===============================================
    always @ ( * ) begin                                                //Negetive Detect
        if ( (x_var%TILE_NUM) == (TILE_NUM-1) ) begin
            signed_flag[(x_var)] = ( have_relu ) ? act_in[(HALF_SIZE)*(x_var+1)-1]
                                                 : 1'b0;
        end else begin
            signed_flag[(x_var)] = ( have_relu ) ? ( set_isize == 0 ) ? act_in[(HALF_SIZE)*(x_var+1)-1]         //According HALF_SIZE signed bit
                                                                      : act_in[(HALF_SIZE)*(TILE_NUM-1+1)-1]    //According WORD_SIZE signed bit
                                                                      : 1'b0;
        end
    end
        pip_passing #(1,4) pip_passing_act_relu_sign_flag(
            .clk    (clk),
            .idata  (signed_flag                [(x_var)]),
            .odata  (act_relu_sign_flag_out     [(x_var)])
        );
    end
//================================== Positive/Negetive Detect ==================================
//==================================  Passing By For Don't Relu ==================================
pip_passing #(WORD_SIZE,4) pip_passing_relu(
    .clk    (clk),
    .idata  (act_in),
    .odata  (act_in_pip_out)
);
//==================================  Passing By For Don't Relu6 ==================================
    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 ) begin
            always @ ( posedge clk ) begin
                act_out[(x_var)*(HALF_SIZE)+:(HALF_SIZE)] <= ( have_relu )    ? ( act_relu_sign_flag_out[(x_var)] ) ? {(HALF_SIZE){1'b0}}
                                                                                                                    : act_in_ReLu6_pip[(HALF_SIZE)*(x_var)+:(HALF_SIZE)]
                                                                              : act_in_pip_out   [(HALF_SIZE)*(x_var)+:(HALF_SIZE)];
            end
    end
endgenerate
endmodule


