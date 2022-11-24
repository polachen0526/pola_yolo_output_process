`timescale 1ns / 1ps
module special_process_element#(
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
                                                    have_accu,            //Accumulate Parti sum
                                                    batch_first,            //1: Normalization and then Activation ; 
                                                    have_batch,             //Normalization Need
                                                    have_relu,              //Activation
                                                    have_leaky,             //1: Leaky relu ; 0: Relu
                                                    have_sigmoid,
                                                    have_last_ich,          //Partial sum finish
    input           [5:0]                           quant_normalization,    //After Multiply Alpha,shift to fix point
                                                    quant_activation,       //After Multiply Leaky constant,shift to fix point
    input           [WORD_SIZE-1:0]                 leaky_constant,         //Leaky is product multiply 0.125 or 0.1.
    input           [TILE_NUM-1:0]                  normalization_alpha_sign,
    input           [WORD_SIZE-1:0]                 normalization_alpha,    //As it's name
    input           [WORD_SIZE-1:0]                 normalization_beta,     //As it's name
                                                    PE_product,             //{HIGH_DATA,LOW_DATA} {TOTAL_DATA}
                                                    OBUF_accu_odata,        //From Output Buffer,Last input channel Partial sum accumulate
    output  reg     [WORD_SIZE-1:0]                 SPE_product             //
);
    wire            [(HALF_SIZE+2)*(TILE_NUM)-1:0]  data_accu_;
    wire            [(WORD_SIZE+1)-1:0]             data_accu_sum;
    wire            [(HALF_SIZE)*(TILE_NUM)-1:0]    data_accu_sat_;
    wire            [(WORD_SIZE)-1:0]               data_accu_sum_sat_;
    wire            [(WORD_SIZE)-1:0]               act_out ,batch_out;
    reg             [(WORD_SIZE)-1:0]               act_in, batch_in, batch_act_result;
    reg             [(HALF_EXT_SIZE)*(TILE_NUM)-1:0]data_result_ext, data_result_shift;
    reg             [(WORD_EXT_SIZE)-1:0]           data_result_sum_ext, data_result_sum_shift;
    wire            [(HALF_SIZE)*(TILE_NUM)-1:0]    data_result_sat_;
    wire            [(WORD_SIZE)-1:0]               data_result_sum_sat_;
    integer                                         i;

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
    //================================================================================================================================================
    always @ ( posedge clk ) begin
        if ( batch_first == 1'b1 ) begin
            act_in              <= batch_out;
            batch_in            <= ( set_isize == 0 ) ? data_accu_sat_ : data_accu_sum_sat_ ;
            batch_act_result    <= act_out;
        end else begin
            act_in              <= ( set_isize == 0 ) ? data_accu_sat_ : data_accu_sum_sat_ ;
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
    pe_act u_pe_act(
        .clk                    (clk),
        .have_relu              (have_relu),    
        .have_leaky             (have_leaky),
        .have_sigmoid           (have_sigmoid),
        .set_isize              (set_isize),
        .quant_activation       (quant_activation),        //quant of leaky constant ; quant of lookup table
        .leaky_constant         (leaky_constant),        
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
        SPE_product         <= ( have_last_ich ) ? ( set_isize == 0 ) ? data_result_sat_    : data_result_sum_sat_
                                                 : ( set_isize == 0 ) ? data_accu_sat_      : data_accu_sum_sat_ ;
    end
*/
    always @ ( posedge clk ) begin
        SPE_product         <= ( have_last_ich ) ?  batch_act_result
                                                 : ( set_isize == 0 ) ? data_accu_sat_      : data_accu_sum_sat_ ;
    end
endmodule

module pe_act#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3,
    parameter       ADD_SIZE_SUM    =   ADD_SIZE+HALF_SIZE,
    parameter       TILE_NUM        =   2,
    parameter       LUT_INDEX_SIZE  =   6,
    parameter       LUT_QUANT       =   3
)(
    input                                           clk,
                                                    have_relu,
                                                    have_leaky,
                                                    have_sigmoid,
                                                    set_isize,
    input           [5:0]                           quant_activation,
    input           [(WORD_SIZE)-1:0]               leaky_constant,
    input           [(WORD_SIZE)-1:0]               act_in,
    output  reg     [(WORD_SIZE)-1:0]               act_out
);
    integer                                         i;
//================================== Positive/Negetive Detect ==================================
    reg             [(TILE_NUM)-1:0]                signed_flag;
    wire            [(TILE_NUM)-1:0]                act_relu_sign_flag_out;
//==================================  Passing By For Don't Relu ==================================
    wire            [(WORD_SIZE)-1:0]               act_in_pip_out;
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
//================================== Positive/Negetive Detect ==================================
genvar x_var;
generate
    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 ) begin
    always @ ( * ) begin
        if ( (x_var%TILE_NUM) == (TILE_NUM-1) ) begin
            signed_flag[(x_var)] = ( have_relu ) ? act_in[(HALF_SIZE)*(x_var+1)-1]
                                                 : 1'b0;
        end else begin
            signed_flag[(x_var)] = ( have_relu ) ? ( set_isize == 0 ) ? act_in[(HALF_SIZE)*(x_var+1)-1]
                                                                      : act_in[(HALF_SIZE)*(TILE_NUM-1+1)-1]
                                                                      : 1'b0;
        end
    end
        pip_passing #(1,4) pip_passing_act_relu_sign_flag(
            .clk    (clk),
            .idata  (signed_flag                [(x_var)]),
            .odata  (act_relu_sign_flag_out     [(x_var)])
        );
    end
    
endgenerate
//================================== Positive/Negetive Detect ==================================
//==================================  Passing By For Don't Relu ==================================
pip_passing #(WORD_SIZE,4) pip_passing_relu(
    .clk    (clk),
    .idata  (act_in),
    .odata  (act_in_pip_out)
);
//==================================  Passing By For Don't Relu ==================================
//==================================  Leaky ReLu ==================================
signed_operation_mult_4_8x8 u_act_pe(
    .clk                (clk), 
    .mult_en            (have_relu&&have_leaky),
    .set_isize          (set_isize),
    .idata              (act_in),
    .wdata_sign         (2'b00),
    .wdata              (leaky_constant), 
    .odata              (act_mult_)
);

bitparal_combine #(ADD_SIZE, HALF_SIZE, ADD_SIZE_SUM, 2)u_act_bitparal_combine(
    .idata(act_mult_),
    .odata(act_mult_sum)
);
    always @ ( posedge clk ) begin
        for ( i=0 ; i<TILE_NUM ; i=i+1 )begin
            act_mult_shifted[(ADD_SIZE)*i+:(ADD_SIZE)] <= $signed(act_mult_[(ADD_SIZE)*i+:(ADD_SIZE)]) >>> quant_activation;
        end
        act_mult_sum_shifted[(ADD_SIZE_SUM)*0+:(ADD_SIZE_SUM)] <= $signed(act_mult_sum[(ADD_SIZE_SUM)*0+:(ADD_SIZE_SUM)]) >>> quant_activation;
    end


generate
    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 )begin
        satuation_oper #(ADD_SIZE,HALF_SIZE) SPE_act_satuation_oper_HALF_SIZE(
            .idata  (act_mult_shifted[(ADD_SIZE)*x_var+:(ADD_SIZE)]),
            .odata  (act_mult_sat[(HALF_SIZE)*x_var+:(HALF_SIZE)])
        );
    end
        satuation_oper #(ADD_SIZE_SUM,WORD_SIZE) SPE_act_satuation_oper_WORD_SIZE(
            .idata  (act_mult_sum_shifted[(ADD_SIZE_SUM)*0+:(ADD_SIZE_SUM)]),
            .odata  (act_mult_sum_sat[(WORD_SIZE)*0+:(WORD_SIZE)])
        );
//==================================  Leaky ReLu ==================================
//==================================  Lookup Table ==================================
    //==================================  PIP 0 ==================================
    assign act_in_sh = $signed(act_in) >>> (quant_activation-LUT_QUANT) ;
    /*
    satuation_oper #(WORD_SIZE,LUT_INDEX_SIZE) sat_lut(
        .idata  (act_in_sh),
        .odata  (act_in_sat)
    );
    */
    always @ ( posedge clk ) begin
        //act_in_lut_index <= act_in_sat;
        act_in_lut_index <= act_in_sh[0+:LUT_INDEX_SIZE];
    end
    always @ ( posedge clk ) begin
        act_lut_postive_overflow_ <= ( act_in_sh[WORD_SIZE-1] == 0 ) ? ( (|act_in_sh[WORD_SIZE-1:LUT_INDEX_SIZE-1]) == 1 ) ? 1'b1 : 1'b0 : 1'b0 ;
        act_lut_negedge_overflow_ <= ( act_in_sh[WORD_SIZE-1] == 1 ) ? (!(&act_in_sh[WORD_SIZE-1:LUT_INDEX_SIZE-1]) == 1 ) ? 1'b1 : 1'b0 : 1'b0 ;
    end

    //==================================  PIP 1 ==================================
    lookup_table_sigmoid #(LUT_INDEX_SIZE, WORD_SIZE) u_lut_16bit(
        .idata(act_in_lut_index),
        .odata(act_lut_out_)
    );
    always @ ( posedge clk ) begin
        act_lut_out <= act_lut_out_;
    end
    
    always @ ( posedge clk ) begin
        act_lut_postive_overflow  <= act_lut_postive_overflow_;
        act_lut_negedge_overflow  <= act_lut_negedge_overflow_;
    end
    //==================================  PIP 2 ==================================
    //==================================  PIP 3 and 4 ==================================
    assign act_sigmoid_out = ( act_lut_postive_overflow ) ? 16'd8000 
                            :( act_lut_negedge_overflow ) ? 16'd0000 
                            : act_lut_out;

    assign act_sigmoid_out_quant = act_sigmoid_out >> ((WORD_SIZE-1)-quant_activation);
    pip_passing #(WORD_SIZE,2) pip_passing_sigmoid_out(
        .clk    (clk),
        .idata  (act_sigmoid_out_quant),
        .odata  (act_sigmoid_out_pip)
    );
    //==================================  PIP 3 and 4 ==================================
//==================================  Lookup Table ==================================

    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 ) begin
            always @ ( posedge clk ) begin
                act_out[(x_var)*(HALF_SIZE)+:(HALF_SIZE)] <= ( have_relu )    ? ( act_relu_sign_flag_out[(x_var)] ) ? ( have_leaky ) ? ( set_isize == 0 ) ? act_mult_sat        [(HALF_SIZE)*(x_var)+:(HALF_SIZE)]
                                                                                                                                                          : act_mult_sum_sat    [(HALF_SIZE)*(x_var)+:(HALF_SIZE)]
                                                                                                                                     : {(HALF_SIZE){1'b0}}
                                                                                                                    : act_in_pip_out   [(HALF_SIZE)*(x_var)+:(HALF_SIZE)]
                                                           : ( have_sigmoid ) ? act_sigmoid_out_pip[(HALF_SIZE)*(x_var)+:(HALF_SIZE)] 
                                                                              : act_in_pip_out   [(HALF_SIZE)*(x_var)+:(HALF_SIZE)];
            end
    end
endgenerate
endmodule

module pe_batch#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3,
    parameter       ADD_SIZE_SUM    =   ADD_SIZE+HALF_SIZE,
    parameter       TILE_NUM        =   2
)(
    input                                           clk,
                                                    have_batch,
                                                    set_isize,
                                                    set_wsize,
    input           [5:0]                           quant_normalization,
    input           [WORD_SIZE-1:0]                 batch_in,
    input           [TILE_NUM-1:0]                  normalization_alpha_sign,
    input           [WORD_SIZE-1:0]                 normalization_alpha,
    input           [WORD_SIZE-1:0]                 normalization_beta,
    output  reg     [WORD_SIZE-1:0]                 batch_out
);
integer                                             i;

wire            [(WORD_SIZE)-1:0]                   batch_in_pip;
wire            [(ADD_SIZE)*(TILE_NUM)-1:0]         batch_mult_alpha;
reg             [(ADD_SIZE)*(TILE_NUM)-1:0]         batch_mult_alpha_shifted;
wire            [(ADD_SIZE_SUM)-1:0]                batch_mult_alpha_sum;
reg             [(ADD_SIZE_SUM)-1:0]                batch_mult_alpha_sum_shifted;
wire            [(WORD_SIZE)-1:0]                   batch_mult_alpha_sat, batch_mult_alpha_sum_sat;
reg             [(WORD_SIZE)-1:0]                   batch_alpha;
wire            [(WORD_SIZE+1)*(TILE_NUM)-1:0]      data_add_beta_;
//wire            [(WORD_SIZE+1)-1:0]                 data_add_beta_sum;
wire            [(WORD_SIZE)-1:0]                   data_add_beta_sat, data_add_beta_sum_sat;

pip_passing #((WORD_SIZE),5) u_have_batch_pip_passing(
    .clk                (clk),
    .idata              (batch_in),
    .odata              (batch_in_pip)
);
signed_operation_mult_4_8x8 u_nor_pe(
    .clk                (clk),
    .mult_en            (have_batch),
    .set_isize          (set_isize),
    .idata              (batch_in),
    .wdata_sign         (normalization_alpha_sign),
    .wdata              (normalization_alpha), 
    .odata              (batch_mult_alpha)
);
bitparal_combine #(ADD_SIZE, HALF_SIZE, ADD_SIZE_SUM, 2)u_nor_alpha_bitparal_combine(
    .idata(batch_mult_alpha),
    .odata(batch_mult_alpha_sum)
);

    always @ ( posedge clk ) begin
        for ( i=0 ; i<TILE_NUM ; i=i+1 )begin
            batch_mult_alpha_shifted[(ADD_SIZE)*i+:(ADD_SIZE)] <= $signed(batch_mult_alpha[(ADD_SIZE)*i+:(ADD_SIZE)]) >>> quant_normalization;
        end
        batch_mult_alpha_sum_shifted[(ADD_SIZE_SUM)*0+:(ADD_SIZE_SUM)] <= $signed(batch_mult_alpha_sum[(ADD_SIZE_SUM)*0+:(ADD_SIZE_SUM)]) >>> quant_normalization;
    end
genvar x_var;
generate
    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 )begin
        satuation_oper #(ADD_SIZE,HALF_SIZE) SPE_normalization_satuation_oper_HALF_SIZE(
            .idata  (batch_mult_alpha_shifted[(ADD_SIZE)*x_var+:(ADD_SIZE)]),
            .odata  (batch_mult_alpha_sat[(HALF_SIZE)*x_var+:(HALF_SIZE)])
        );

    end
        satuation_oper #(ADD_SIZE_SUM,WORD_SIZE) SPE_normalization_satuation_oper_WORD_SIZE(
            .idata  (batch_mult_alpha_sum_shifted[(ADD_SIZE_SUM)*0+:(ADD_SIZE_SUM)]),
            .odata  (batch_mult_alpha_sum_sat[(WORD_SIZE)*0+:(WORD_SIZE)])
        );
        
endgenerate
always @ ( posedge clk ) begin
    batch_alpha <= ( set_isize == 0 ) ? batch_mult_alpha_sat : batch_mult_alpha_sum_sat;
end
//=================================================================================================================


signed_operation_adder_2_8x8 u_nor_signed_operation_adder_2_8x8(
    .add_en     (have_batch),
    .set_isize  (set_isize),
    .set_wsize  (set_wsize),
    .idata      (batch_alpha),
    .wdata      (normalization_beta),
    .odata      (data_add_beta_)
);
/*
bitparal_combine #((WORD_SIZE+1), HALF_SIZE, (WORD_SIZE+1), 2)u_nor_bias_bitparal_combine(
    .idata(data_add_beta_),
    .odata(data_add_beta_sum)
);
*/
generate
    for ( x_var=0 ; x_var<2 ; x_var=x_var+1 )begin
        satuation_oper #(WORD_SIZE+1,HALF_SIZE) SPE_satuation_oper_HALF_SIZE(
            .idata  (data_add_beta_[(WORD_SIZE+1)*x_var+:(WORD_SIZE+1)]),
            .odata  (data_add_beta_sat[(HALF_SIZE)*x_var+:(HALF_SIZE)])
        );
    end
        satuation_oper #(WORD_SIZE+1,WORD_SIZE) SPE_satuation_oper_WORD_SIZE(
            .idata  (data_add_beta_[(WORD_SIZE+1)*0+:(WORD_SIZE+1)]),
            .odata  (data_add_beta_sum_sat[(WORD_SIZE)*0+:(WORD_SIZE)])
        );
endgenerate

    always @ ( posedge clk ) begin
        batch_out   <= ( have_batch ) ? ( set_isize == 0 ) ? data_add_beta_sat : data_add_beta_sum_sat
                                      : batch_in_pip;
    end

endmodule

module signed_operation_mult_4_8x8#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3,
    parameter       TILE_NUM        =   2    
)(
    input                                           clk,
                                                    mult_en,
                                                    set_isize,
    input           [(WORD_SIZE)-1:0]               idata,
    input           [(TILE_NUM)-1:0]                wdata_sign,
    input           [(WORD_SIZE)-1:0]               wdata,
    output          [(ADD_SIZE)*(TILE_NUM)-1:0]     odata
);
reg             [(WORD_SIZE)-1:0]                   idata_abs_, idata_abs,
                                                    /*wdata_abs_, */wdata_abs ;
reg             [(TILE_NUM)-1:0]                    sign_flag_input_ ,sign_flag_input,
                                                    /*sign_flag_weight_,*/sign_flag_weight;
    always @ ( * ) begin
        idata_abs_[HALF_SIZE*0+:HALF_SIZE]      = idata[HALF_SIZE*0+:HALF_SIZE];
        idata_abs_[HALF_SIZE*1+:HALF_SIZE]      = idata[HALF_SIZE*1+:HALF_SIZE];
        sign_flag_input_[0]                     = ( set_isize == 0 ) ? idata_abs_[HALF_SIZE-1] : 1'b0;
        sign_flag_input_[1]                     = idata_abs_[WORD_SIZE-1];
/*
        wdata_abs_[HALF_SIZE*0+:HALF_SIZE]      = wdata[HALF_SIZE*0+:HALF_SIZE];
        wdata_abs_[HALF_SIZE*1+:HALF_SIZE]      = ( set_wsize == 0 ) ? 4'd0 : wdata[HALF_SIZE*1+:HALF_SIZE];
        sign_flag_weight_[0]                    = ( set_wsize == 0 ) ? wdata_abs_[HALF_SIZE-1] : 1'b0;
        sign_flag_weight_[1]                    = wdata_abs_[WORD_SIZE-1];
*/
    end

    always @ ( posedge clk ) begin
        sign_flag_input[0]                      <= sign_flag_input_[0] ;
        sign_flag_input[1]                      <= sign_flag_input_[1] ;
        idata_abs[HALF_SIZE*0+:HALF_SIZE]       <= ( sign_flag_input_[0] )  ? -idata_abs_[HALF_SIZE*0+:HALF_SIZE] : idata_abs_[HALF_SIZE*0+:HALF_SIZE] ;
        idata_abs[HALF_SIZE*1+:HALF_SIZE]       <= ( sign_flag_input_[1] )  ? -idata_abs_[HALF_SIZE*1+:HALF_SIZE] : idata_abs_[HALF_SIZE*1+:HALF_SIZE] ;
/*
        sign_flag_weight[0]                     <= sign_flag_weight_[0] ;
        sign_flag_weight[1]                     <= sign_flag_weight_[1] ;
        wdata_abs[HALF_SIZE*0+:HALF_SIZE]       <= ( sign_flag_weight_[0] ) ? -wdata_abs_[HALF_SIZE*0+:HALF_SIZE] : wdata_abs_[HALF_SIZE*0+:HALF_SIZE] ;
        wdata_abs[HALF_SIZE*1+:HALF_SIZE]       <= ( sign_flag_weight_[1] ) ? -wdata_abs_[HALF_SIZE*1+:HALF_SIZE] : wdata_abs_[HALF_SIZE*1+:HALF_SIZE] ;
*/
        sign_flag_weight[0]                     <= wdata_sign[0] ;
        sign_flag_weight[1]                     <= wdata_sign[1] ;
        wdata_abs[HALF_SIZE*0+:HALF_SIZE]       <= wdata[HALF_SIZE*0+:HALF_SIZE];
        wdata_abs[HALF_SIZE*1+:HALF_SIZE]       <= wdata[HALF_SIZE*1+:HALF_SIZE];
    end
    mult_4_8x8 u_normalization_mult_4_8x8(
        .clk                (clk),
        .mult_en            (mult_en),
        .sign_flag_input    (sign_flag_input),
        .sign_flag_weight   (sign_flag_weight),
        .idata              (idata_abs),
        .wdata              (wdata_abs),
        .add_odata          (odata)
    );
endmodule

module signed_operation_adder_2_8x8 #(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       TILE_NUM        =   2
)(
    input                                           add_en,
                                                    set_isize,
                                                    set_wsize,
    input           [(WORD_SIZE)-1:0]               idata,
    input           [(WORD_SIZE)-1:0]               wdata,
    output          [(WORD_SIZE+1)*(TILE_NUM)-1:0]  odata
);
    wire            [(WORD_SIZE)-1:0]               idata0,idata1,wdata0;
    wire            [(WORD_SIZE+1)-1:0]             odata0,odata1;

    assign  idata0[(WORD_SIZE)*(0)+:(WORD_SIZE)] = ( set_isize == 0 ) ? {{(WORD_SIZE-HALF_SIZE){idata[(HALF_SIZE)*(1+0)-1]}},idata[(HALF_SIZE)*(0)+:(HALF_SIZE)]}
                                                                      : idata[(WORD_SIZE)*(0)+:(WORD_SIZE)];
    assign  idata1[(WORD_SIZE)*(0)+:(WORD_SIZE)] = ( set_isize == 0 ) ? {{(WORD_SIZE-HALF_SIZE){idata[(HALF_SIZE)*(1+1)-1]}},idata[(HALF_SIZE)*(1)+:(HALF_SIZE)]}
                                                                      : 0;
    assign  wdata0[(WORD_SIZE)*(0)+:(WORD_SIZE)] = ( set_wsize == 0 ) ? {{(WORD_SIZE-HALF_SIZE){wdata[(HALF_SIZE)*(1+0)-1]}},wdata[(HALF_SIZE)*(0)+:(HALF_SIZE)]}
                                                                      : wdata[(WORD_SIZE)*(0)+:(WORD_SIZE)];
    assign  odata0 = ( add_en == 1 ) ?
                     {idata0[(WORD_SIZE)*(1+0)-1],idata0[(WORD_SIZE)*(0)+:(WORD_SIZE)]} 
                    +{wdata0[(WORD_SIZE)*(1+0)-1],wdata0[(WORD_SIZE)*(0)+:(WORD_SIZE)]}
                    :{idata0[(WORD_SIZE)*(1+0)-1],idata0[(WORD_SIZE)*(0)+:(WORD_SIZE)]};
    assign  odata1 = ( add_en == 1 ) ?
                     {idata1[(WORD_SIZE)*(1+0)-1],idata1[(WORD_SIZE)*(0)+:(WORD_SIZE)]}
                    +{wdata0[(WORD_SIZE)*(1+0)-1],wdata0[(WORD_SIZE)*(0)+:(WORD_SIZE)]}
                    :{idata1[(WORD_SIZE)*(1+0)-1],idata1[(WORD_SIZE)*(0)+:(WORD_SIZE)]};
    assign  odata = {odata1,odata0};
endmodule