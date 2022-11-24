`timescale 1ns / 1ps
`define MODULE_WORD_SIZE_hw 16
`define HW_ADD_SIZE_hw          (`MODULE_WORD_SIZE_hw/2)*3+7
`define HW_ADD_SIZE_hw_DWC      (`MODULE_WORD_SIZE_hw/2)*3+5
`define VIVADO_MODE 1
module OBUF_CHIP #(
    parameter       BK_ADDR_SIZE                =   9,          // one bank length is 408 = 9'b1_1001_1000 9 bits
    parameter       BK_NUM                      =   3,          // 3 Output Bank form a 3x3 conv output channel                                                            // 1 Output Bank form a 1x1 conv output channel
    //parameter       ADDR_SIZE                   =   9,
    parameter       HALF_ADDR_SIZE              =   6,
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE                   =   WORD_SIZE/2,
    parameter       HW_ADD_SIZE                 =   `HW_ADD_SIZE_hw,
    parameter       HW_ADD_SIZE_SUM             =   HW_ADD_SIZE+HALF_SIZE,
    parameter       HW_ADD_SIZE_DWC             =   `HW_ADD_SIZE_hw_DWC,
    parameter       HW_ADD_SIZE_DWC_SUM         =   HW_ADD_SIZE_DWC+HALF_SIZE,
    parameter       TILE_NUM                    =   2,
    parameter       AXI_DATA_WIDTH              =   8,
    parameter       PE_ARRAY_4_v                =   8,
    parameter       PE_ARRAY_3_v                =   3,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_1_2_v              =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v              =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v                  =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v,
    parameter       ADD_SIZE                    =   HALF_SIZE*3,
    parameter       ADD_SIZE_1                  =   ADD_SIZE+1,
    parameter       ADD_SIZE_2                  =   ADD_SIZE_1+1,
    parameter       ADD_SIZE_3                  =   ADD_SIZE_2+1,
    parameter       ADD_SIZE_4                  =   ADD_SIZE_3+1,
    parameter       ADD_SIZE_5                  =   ADD_SIZE_4+1,
    parameter       ADD_SIZE_6                  =   ADD_SIZE_5+1,
    parameter       ADD_SIZE_7                  =   ADD_SIZE_6+1,
    parameter       SPE_TO_LINE_BUFFER          =   1,
    parameter       OBUF_TO_LINE_BUFFER         =   2,
    parameter       KERNEL_3x3                  =   9,
    parameter       CONV_MODE                   =   2'b00,
    parameter       FC_MODE                     =   2'b01,
    parameter       DECONV_MODE                 =   2'b10,
    parameter       DWC_MODE                    =   2'b11
)(
    input                                           clk,
                                                    obuf_rst,
    //======================== WBUF ========================
                                                    wbuf_rst_A,
                                                    wbuf_rst_B,
                                                    WBUF_RLAST,
                                                    WBUF_VALID_FLAG,
                                                    WBUF_CHOOSE,
    //======================== WBUF ========================
    //======================== LAYER INFO ==================
    input                                           pwc_dwc_combine_,
                                                    concat_output_control_,
//                                                    bk_combine_,
                                                    set_isize_,
                                                    set_wsize_,
                                                    batch_first_,            //1: Normalization and then Activation ; 
                                                    have_batch_,             //Normalization Need
                                                    have_batch_dwc_,
                                                    have_relu_,              //Activation
                                                    have_relu_dwc_,
                                                    have_leaky_,             //1: Leaky relu ; 0: Relu
                                                    have_sigmoid_,
                                                    have_pool_,
                                                    Is_Upsample_,
    input           [3:0]                           ker_size_,
                                                    ker_strd_,
    input           [1:0]                           pool_size_,
                                                    pool_strd_,
    input           [1:0]                           Bit_serial_,
/*
    * In Fully Connect Mode, obuf_tile  =>                length_x = {obuf_tile_size_y_,obuf_tile_size_x_}  / length_y = 1
    * In Convolution Mode, obuf_tile    =>                length_x = obuf_tile_size_x_                      / length_y = obuf_tile_size_y_
    * In Pooling Mode, obuf_tile        => before pooling length_x = obuf_tile_size_x_                      / length_y = obuf_tile_size_y_
                                        => afte   pooling length_x = obuf_tile_size_for_pooling_x_          / length_y = obuf_tile_size_for_pooling_y_
*/
    input           [HALF_ADDR_SIZE-1'b1:0]         obuf_tile_size_x_,         //end address of write mode 
                                                    obuf_tile_size_y_,
                                                    obuf_tile_size_x_aft_pool_,
                                                    obuf_tile_size_y_aft_pool_,
    input           [5:0]                           quant_pe_,
                                                    quant_normalization_,    //After Multiply Alpha,shift to fix point
                                                    quant_activation_,       //After Multiply Leaky constant,shift to fix point
                                                    quant_next_layer_,       //After SPE process, Next Layer's Fix point is different, shift to fix point
                                                    quant_pool_next_layer_,
    input           [WORD_SIZE-1:0]                 leaky_constant_,         //Leaky is product multiply 0.125 or 0.1.
    //======================== LAYER INFO ==================
    //======================== TILE  INFO ==================
    input           [1:0]                           hw_icp_able_cacl_,
                                                    hw_ocp_able_cacl_,
    input                                           have_accu_,            //Accumulate Parti sum
                                                    have_last_ich_,          //Partial sum finish
                                                    Is_last_ker_,
                                                    Is_Final_Tile_,
    input                                           IBUF_DATA_TRANS_START_,
    input           [PE_ARRAY_1_2_v*WORD_SIZE-1:0]  ibuf_idata,
    input           [AXI_DATA_WIDTH*WORD_SIZE-1:0]  axi_wdata,
    //======================== USER CTRL ========================
    //input                                           user_obuf_read_en,
    input           [HALF_ADDR_SIZE-1'b1:0]         user_obuf_oaddr_x,
                                                    user_obuf_oaddr_y,
    input           [1:0]                           user_obuf_oaddr_z,
    input                                           Master_Output_Finish,
    output                                          OBUF_FINISH_FLAG, //obuf_Finish
    output                                          For_State_Finish,
                                                    Pad_Start_OBUF_FINISH,
    output          [AXI_DATA_WIDTH*WORD_SIZE-1:0]  OBUF_TO_DRAM_DATA,
    //======================== USER CTRL ========================
    input           [1:0]                           CONV_FLAG_,
    output                                          IRQ_TO_MASTER_CTRL,
                                                    have_pool_ing,
    output       [1:0]                              DEBUG_obuf_state,
                                                    DEBUG_obuf_pool_s,
                                                    DEBUG_obuf_finish_state        
);
    wire            [1:0]                                           CONV_FLAG;
    reg                                                             IBUF_DATA_TRANS_START,
                                                                    bk_combine_,
                                                                    bk_combine;
    //======================== OBUF SETTING ========================
    wire                                                            pwc_dwc_combine,
                                                                    concat_output_control,
                                                                    set_isize,
                                                                    set_wsize,
                                                                    batch_first,            //1: Normalization and then Activation ; 
                                                                    have_batch,             //Normalization Need
                                                                    have_batch_dwc,
                                                                    have_relu,              //Activation
                                                                    have_relu_dwc,
                                                                    have_leaky,             //1: Leaky relu ; 0: Relu
                                                                    have_sigmoid,
//                                                                    have_pool_ing,
                                                                    have_pool,
                                                                    Is_Upsample;
    wire            [3:0]                                           ker_size,
                                                                    ker_strd;
    wire            [1:0]                                           pool_size,
                                                                    pool_strd;
    wire            [1:0]                                           Bit_serial;
    wire            [HALF_ADDR_SIZE-1'b1:0]                         obuf_tile_size_x,         //end address of write mode 
                                                                    obuf_tile_size_y,
                                                                    obuf_tile_size_x_aft_pool,
                                                                    obuf_tile_size_y_aft_pool;
    wire            [5:0]                                           quant_pe,
                                                                    quant_normalization,    //After Multiply Alpha,shift to fix point
                                                                    quant_activation,       //After Multiply Leaky constant,shift to fix point
                                                                    quant_next_layer,       //After SPE process, Next Layer's Fix point is different, shift to fix point
                                                                    quant_pool_next_layer;
    wire            [WORD_SIZE-1:0]                                 leaky_constant;         //Leaky is product multiply 0.125 or 0.1.
    wire            [1:0]                                           hw_icp_able_cacl,
                                                                    hw_ocp_able_cacl;
    wire                                                            have_accu,            //Accumulate Parti sum
                                                                    have_last_ich,
                                                                    Is_last_ker,
                                                                    Is_Final_Tile;
    //======================== OBUF SETTING ========================
    //======================== OBUF CTRL ========================
    wire            [8:0]                                           mult_en;
    reg                                                             mult_en_dwc;
    wire            [PE_ARRAY_3_v-1:0]                              spe_mult_en,
                                                                    spe_dwc_mult_en;
    wire                                                            DECONVING;
    wire            [AXI_DATA_WIDTH-1:0]                            WBUF_LOAD_OCH_FLAG;
    wire            [AXI_DATA_WIDTH*3-1:0]                          WBUF_SPE_LOAD_OCH_FLAG;
    wire            [1:0]                                           DWC_DATAFLOW;
    wire                                                            WBUF_AB_LOAD_FLAG,
                                                                    WBUF_AB_CACL_FLAG;
    wire                                                            WBUF_CONV_OR_DWC_SPE_FLAG;
    wire            [3:0]                                           wbuf_addr_ker_cont;
    wire                                                            wbuf_addr_spe_weight_cont;
    //======================== OBUF CTRL ========================
    //======================== AXI WBUF ========================
    wire            [(AXI_DATA_WIDTH)*(TILE_NUM)-1:0]               axi_wdata_sign_out;
    wire            [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]              axi_wdata_out;
    //======================== AXI WBUF ========================
    //======================== Output Buffer ========================
    reg             [BK_NUM-1:0]                                    read_en_pre;
    wire            [BK_NUM-1:0]                                    read_en;
    wire            [BK_NUM*BK_ADDR_SIZE-1:0]                       read_oaddr;
    reg             [BK_NUM-1:0]                                    write_en_pre;
    wire            [BK_NUM-1:0]                                    write_en;
    wire            [BK_NUM*BK_ADDR_SIZE-1:0]                       write_iaddr;
    wire            [PE_ARRAY_3_4_v*WORD_SIZE-1:0]                  obuf_idata,
                                                                    obuf_idata_;
    wire            [PE_ARRAY_3_4_v*WORD_SIZE-1:0]                  obuf_odata;
    
`ifdef VIVADO_MODE

`else
    wire            CENYA, CENYB;
    wire    [8:0]   AYA,AYB;
    wire    [15:0]  DYB;    
`endif
    //======================== Output Buffer ========================
    //======================== IDATA PROCESSING ========================
    wire            [(PE_ARRAY_3_v)-1:0]                            obuf_write_bk;

    //======================== IDATA PROCESSING ========================
    //======================== PE array ========================
    wire            [(PE_ARRAY_1_2_v)*(PE_ARRAY_3_v)*(WORD_SIZE)-1:0]idata_array;
    wire            [(PE_ARRAY_1_2_v)*(PE_ARRAY_3_v)*(TILE_NUM)-1:0]idata_sign_array;
    reg             [PE_ARRAY_3_4_v*WORD_SIZE-1:0]                  pwc_idata;
    wire            [PE_ARRAY_3_4_v*KERNEL_3x3*TILE_NUM-1:0]        linebuffer_sign_array;
    wire            [PE_ARRAY_3_4_v*KERNEL_3x3*WORD_SIZE-1:0]       linebuffer_array;
/*
    wire            [PE_ARRAY_3_4_v*TILE_NUM-1:0]                   dwc_idata_sign_array;
    wire            [PE_ARRAY_3_4_v*WORD_SIZE-1:0]                  dwc_idata_array;
*/

    wire            [(PE_ARRAY_3_4_v)*(ADD_SIZE_5)-1:0]             add_odata_dwc_H,
                                                                    add_odata_dwc_L;
    wire            [(PE_ARRAY_3_4_v)*(HW_ADD_SIZE)-1:0]            add_odata_H,
                                                                    add_odata_L;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              PE_product;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              PE_product_dwc;
    //======================== PE array ========================
    //======================== ACCU PROCESSING ========================
    wire            [(PE_ARRAY_3_v)-1:0]                            obuf_accu_bk;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              obuf_accu_data;
    //======================== ACCU PROCESSING ========================
    //======================== SPE array ========================
    wire            [(PE_ARRAY_3_4_v)*(TILE_NUM)-1:0]               normalization_alpha_sign;                      
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              normalization_alpha, 
                                                                    normalization_beta;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              SPE_product;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              SPE_product_dwc;
    //======================== SPE array ========================
    //======================== DWC SPE array ========================
    wire            [(PE_ARRAY_3_4_v)*(TILE_NUM)-1:0]               normalization_dwc_alpha_sign;                      
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              normalization_dwc_alpha, 
                                                                    normalization_dwc_beta;
//======================== DWC SPE array ========================
    //======================== POOLING ========================

    wire            [(PE_ARRAY_3_v)-1:0]                            obuf_pool_bk;
    wire                                                            pool_ctrl;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              pool_idata;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              pool_odata;
    //======================== POOLING ========================
    integer                                                         i;
/*
    reg [15:0]  obuf_idata_show [0:23],
                 obuf_odata_show [0:23];
    always @ ( * ) begin
        for ( i=0 ; i<24 ; i=i+1 ) begin
            obuf_idata_show[i] = obuf_idata[i*16+:16];
            obuf_odata_show[i] = obuf_odata[i*16+:16];
        end
    end
*/
    assign set_isize = 1;
    assign set_wsize = 1;
    always @ ( posedge clk ) begin
        bk_combine_ <= ( CONV_FLAG_== DWC_MODE )  ? 0  
                       : ( ker_size_ == 1 )         ? 0 
                                                    : 1 ;
        bk_combine <=  ( CONV_FLAG == DWC_MODE )  ? 0  
                       : ( ker_size == 1  )         ? 0 
                                                    : 1 ;
        mult_en_dwc<= ( DWC_DATAFLOW == SPE_TO_LINE_BUFFER ) || ( DWC_DATAFLOW == OBUF_TO_LINE_BUFFER ) ; 
    end

always @ ( posedge clk ) begin
    IBUF_DATA_TRANS_START <= IBUF_DATA_TRANS_START_;
end
always @ ( posedge clk ) begin
    read_en_pre             <= read_en;
    write_en_pre            <= write_en;
end


OBUF_TO_DRAM_DATA_QUANT_FINISH u_OBUF_TO_DRAM_DATA_QUANT_FINISH(
    .clk                                (clk),        
    .OBUF_FINISH_FLAG                   (OBUF_FINISH_FLAG),                    
    .have_pool_ing                      (have_pool_ing),                
    .set_isize                          (set_isize),            
    .read_en_pre                        (read_en_pre),                
    .quant_next_layer_                  (quant_next_layer),                    
    .quant_pool_next_layer_             (quant_pool_next_layer),                        
    .obuf_odata                         (obuf_odata),            
    .OBUF_TO_DRAM_DATA                  (OBUF_TO_DRAM_DATA)                 
);

OBUF_SETTING u_OBUF_SETTING(
    .clk                                (clk),                   
    .obuf_rst                           (obuf_rst),                              
    .set_isize_                         (set_isize_),                       
    .set_wsize_                         (set_wsize_),                       
    .batch_first_                       (batch_first_),                           
    .have_batch_                        (have_batch_),   
    .have_batch_dwc_                    (have_batch_dwc_),                        
    .have_relu_                         (have_relu_),     
    .have_relu_dwc_                     (have_relu_dwc_),                  
    .have_leaky_                        (have_leaky_),                           
    .have_sigmoid_                      (have_sigmoid_),    
    .concat_output_control_             (concat_output_control_),  
    .pwc_dwc_combine_                   (pwc_dwc_combine_),                     
    .have_pool_                         (have_pool_),                       
    .Is_Upsample_                       (Is_Upsample_),                           
    .ker_size_                          (ker_size_),                       
    .ker_strd_                          (ker_strd_),                       
    .pool_size_                         (pool_size_),                       
    .pool_strd_                         (pool_strd_),                       
    .Bit_serial_                        (Bit_serial_),                           
    .obuf_tile_size_x_                  (obuf_tile_size_x_),                               
    .obuf_tile_size_y_                  (obuf_tile_size_y_),                               
    .obuf_tile_size_x_aft_pool_         (obuf_tile_size_x_aft_pool_),                                      
    .obuf_tile_size_y_aft_pool_         (obuf_tile_size_y_aft_pool_),                                          
    .quant_pe_                          (quant_pe_),                       
    .quant_normalization_               (quant_normalization_),                                   
    .quant_activation_                  (quant_activation_),                               
    .quant_next_layer_                  (quant_next_layer_),   
    .quant_pool_next_layer_             (quant_pool_next_layer_),                            
    .leaky_constant_                    (leaky_constant_),
    .hw_icp_able_cacl_                  (hw_icp_able_cacl_),
    .hw_ocp_able_cacl_                  (hw_ocp_able_cacl_),
    .have_accu_                         (have_accu_),                       
    .have_last_ich_                     (have_last_ich_),
    .Is_last_ker_                       (Is_last_ker_),
    .Is_Final_Tile_                     (Is_Final_Tile_),
    .CONV_FLAG_                         (CONV_FLAG_),      
    .batch_first                        (batch_first),                           
    .have_batch                         (have_batch),       
    .have_batch_dwc                     (have_batch_dwc),                
    .have_relu                          (have_relu),  
    .have_relu_dwc                      (have_relu_dwc),                     
    .have_leaky                         (have_leaky),                       
    .have_sigmoid                       (have_sigmoid),                 
    .concat_output_control              (concat_output_control),   
    .pwc_dwc_combine                    (pwc_dwc_combine),       
    .have_pool                          (have_pool),                       
    .Is_Upsample                        (Is_Upsample),                           
    .ker_size                           (ker_size),                       
    .ker_strd                           (ker_strd),                       
    .pool_size                          (pool_size),                       
    .pool_strd                          (pool_strd),                       
    .Bit_serial                         (Bit_serial),                       
    .obuf_tile_size_x                   (obuf_tile_size_x),                               
    .obuf_tile_size_y                   (obuf_tile_size_y),                               
    .obuf_tile_size_x_aft_pool          (obuf_tile_size_x_aft_pool),                                           
    .obuf_tile_size_y_aft_pool          (obuf_tile_size_y_aft_pool),                                           
    .quant_pe                           (quant_pe),                       
    .quant_normalization                (quant_normalization),                                   
    .quant_activation                   (quant_activation),                               
    .quant_next_layer                   (quant_next_layer),       
    .quant_pool_next_layer              (quant_pool_next_layer),                        
    .leaky_constant                     (leaky_constant),    
    .hw_icp_able_cacl                   (hw_icp_able_cacl), 
    .hw_ocp_able_cacl                   (hw_ocp_able_cacl),                        
    .have_accu                          (have_accu),                       
    .have_last_ich                      (have_last_ich),
    .Is_last_ker                        (Is_last_ker),
    .Is_Final_Tile                      (Is_Final_Tile),
    .CONV_FLAG                          (CONV_FLAG)
);

OBUF_CTRL u_OBUF_CTRL(
    .clk                                 (clk),    
    .rst                                 (obuf_rst),    
    .wbuf_rst_A                          (wbuf_rst_A),            
    .wbuf_rst_B                          (wbuf_rst_B),            
    .WBUF_RLAST                          (WBUF_RLAST),            
    .WBUF_VALID_FLAG                     (WBUF_VALID_FLAG),                
    .WBUF_CHOOSE                         (WBUF_CHOOSE),            
    .WBUF_LOAD_OCH_FLAG                  (WBUF_LOAD_OCH_FLAG),                            
    .WBUF_AB_LOAD_FLAG                   (WBUF_AB_LOAD_FLAG),                    
    .WBUF_AB_CACL_FLAG                   (WBUF_AB_CACL_FLAG), 
    .WBUF_CONV_OR_DWC_SPE_FLAG           (WBUF_CONV_OR_DWC_SPE_FLAG),                   
    .wbuf_addr_ker_cont                  (wbuf_addr_ker_cont),                    
    .wbuf_addr_spe_weight_cont           (wbuf_addr_spe_weight_cont),                            
    .WBUF_SPE_LOAD_OCH_FLAG              (WBUF_SPE_LOAD_OCH_FLAG),        
    .DWC_DATAFLOW                        (DWC_DATAFLOW),
    .have_pool_ing                       (have_pool_ing),
    .pwc_dwc_combine_                    (pwc_dwc_combine_),
    .pwc_dwc_combine                     (pwc_dwc_combine),
    .concat_output_control               (concat_output_control),       
    .have_pool                           (have_pool),     
    .have_batch_                         (have_batch_),      
    .have_batch                          (have_batch),       
    .have_batch_dwc_                     (have_batch_dwc_),
    .have_batch_dwc                      (have_batch_dwc),
    .Is_Upsample                         (Is_Upsample),   
    .bk_combine_                         (bk_combine_),
    .bk_combine                          (bk_combine),            
    .IBUF_DATA_TRANS_START               (IBUF_DATA_TRANS_START),                        
    .ker_size                            (ker_size),            
    .ker_strd                            (ker_strd),            
    .pool_size                           (pool_size),            
    .pool_strd                           (pool_strd),            
    .Bit_serial                          (Bit_serial),            
    .obuf_tile_size_x                    (obuf_tile_size_x),                    
    .obuf_tile_size_y                    (obuf_tile_size_y),                    
    .obuf_tile_size_x_aft_pool           (obuf_tile_size_x_aft_pool),                                
    .obuf_tile_size_y_aft_pool           (obuf_tile_size_y_aft_pool),   
    .hw_icp_able_cacl                    (hw_icp_able_cacl), 
    .hw_ocp_able_cacl                    (hw_ocp_able_cacl),                                 
    .have_accu                           (have_accu),            
    .have_last_ich_                      (have_last_ich_),                
    .have_last_ich                       (have_last_ich),            
    .Is_last_ker                         (Is_last_ker),     
    .Is_Final_Tile                       (Is_Final_Tile),             
    .read_en                             (read_en),        
    .read_oaddr                          (read_oaddr),            
    .write_en                            (write_en),            
    .write_iaddr                         (write_iaddr),            
    .pool_ctrl                           (pool_ctrl),            
    //.user_obuf_read_en                   (user_obuf_read_en),                    
    .user_obuf_oaddr_x                   (user_obuf_oaddr_x),                    
    .user_obuf_oaddr_y                   (user_obuf_oaddr_y),      
    .user_obuf_oaddr_z                   (user_obuf_oaddr_z),
    .Master_Output_Finish                (Master_Output_Finish),                        
    .OBUF_FINISH_FLAG                    (OBUF_FINISH_FLAG),                    
    .For_State_Finish                    (For_State_Finish),                    
    .Pad_Start_OBUF_FINISH               (Pad_Start_OBUF_FINISH),
    .CONV_FLAG                           (CONV_FLAG),
    .CONV_FLAG_                          (CONV_FLAG_),
    .IRQ_TO_MASTER_CTRL                  (IRQ_TO_MASTER_CTRL),
    .mult_en                             (mult_en),
    .spe_mult_en                         (spe_mult_en),
    .spe_dwc_mult_en                     (spe_dwc_mult_en),
    .DECONVING                           (DECONVING),


    .DEBUG_obuf_state                    (DEBUG_obuf_state), 
    .DEBUG_obuf_pool_s                   (DEBUG_obuf_pool_s), 
    .DEBUG_obuf_finish_state             (DEBUG_obuf_finish_state)
);                                                   
IBUF_DATA_ARRAY_PROCESSING u_IBUF_DATA_ARRAY_PROCESSING(                                                                            
    .clk                    (clk),                                                                          
    .set_isize              (set_isize),     
    .bk_combine             (bk_combine),                 
    .DECONVING              (DECONVING),                                                              
    .data                   (ibuf_idata),                                                                                   
    .data_sign_array        (idata_sign_array),                                                                         
    .data_array             (idata_array)                                                                           
);
always @ ( * ) begin
    pwc_idata = ( DWC_DATAFLOW == SPE_TO_LINE_BUFFER ) ? SPE_product
              : ( DWC_DATAFLOW == OBUF_TO_LINE_BUFFER) ? obuf_odata
                                                       : 0;
end

LINE_BUFFER u_LINE_BUFFER(
    .clk                    (clk),       
    .set_isize              (set_isize),           
    .bk_combine             (bk_combine),           
    .obuf_tile_size_x       (obuf_tile_size_x),                   
    .pwc_idata              (pwc_idata),           
    .linebuffer_sign_array  (linebuffer_sign_array),                       
    .linebuffer_array       (linebuffer_array)               
);

        assign obuf_idata_ = ( have_pool_ing        ) ? pool_odata 
                           : ( DWC_DATAFLOW == 0    ) ? SPE_product
                           : ( |spe_dwc_mult_en )     ? SPE_product_dwc
                                                      : 0;      
        assign obuf_write_bk = write_en;
        OBUF_IDATA_PROCESSING u_OBUF_IDATA_PROCESSING(
            .bk_combine             (bk_combine),    
            .DECONVING              (DECONVING),
            .obuf_write_bk          (obuf_write_bk),           
            .obuf_idata_            (obuf_idata_),       
            .obuf_idata             (obuf_idata)       
        );

genvar x_var;
generate    

    for ( x_var = 0 ; x_var < PE_ARRAY_3_4_v ; x_var=x_var+1 ) begin
`ifdef VIVADO_MODE
        if ( x_var%3 == 0 ) begin
            blk_mem_dule_port  uOBUF0_BK(
                .clka           (clk),
                .wea            (write_en           [(0)]),
                .addra          (write_iaddr        [(0)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .dina           (obuf_idata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),
                .clkb           (clk),
                .addrb          (read_oaddr         [(0)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .doutb          (obuf_odata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)])
            );
        end else if ( x_var%3 == 1 ) begin
            blk_mem_dule_port  uOBUF0_BK(
                .clka           (clk),
                .wea            (write_en           [(1)]),
                .addra          (write_iaddr        [(1)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .dina           (obuf_idata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),
                .clkb           (clk),
                .addrb          (read_oaddr          [(1)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .doutb          (obuf_odata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)])
            );
        end else if ( x_var%3 == 2 ) begin
            blk_mem_dule_port  uOBUF0_BK(
                .clka           (clk),
                .wea            (write_en           [(2)]),
                .addra          (write_iaddr        [(2)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .dina           (obuf_idata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),
                .clkb           (clk),
                .addrb          (read_oaddr          [(2)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .doutb          (obuf_odata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)])
            );
        end
`else
        if ( x_var%3 == 0 ) begin
            rf_2p_hse           uOBUF0_BK(
                .CENYA       (CENYA),
                .AYA         (AYA),
                .CENYB       (CENYB),
                .AYB         (AYB),
                .DYB         (DYB),
                .QA          (obuf_odata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),),
                .CLKA        (clk),
                .CENA        (1'b1),
                .AA          (read_oaddr         [(0)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .CLKB        (clk),
                .CENB        (write_en[(0)]),
                .AB          (write_iaddr        [(0)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .DB          (obuf_idata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),
                .EMAA        (3'd0),
                .EMASA       (1'd0),
                .EMAB        (3'd0),
                .EMAWB       (2'd0),
                .TENA        (1'd1),
                .BENA        (1'd1),
                .TCENA       (1'd1),
                .TAA         (9'd0),
                .TQA         (16'd0),
                .TENB        (1'd1),
                .TCENB       (1'd1),
                .TAB         (9'd0),
                .TDB         (16'd0),
                .RET1N       (1'd1),
                .STOVA       (1'd1),
                .STOVB       (1'd1),
                .COLLDISN    (1'd1)
            );
        end else if ( x_var%3 == 1 ) begin
            rf_2p_hse           uOBUF0_BK(
                .CENYA       (CENYA),
                .AYA         (AYA),
                .CENYB       (CENYB),
                .AYB         (AYB),
                .DYB         (DYB),
                .QA          (obuf_odata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),),
                .CLKA        (clk),
                .CENA        (1'b1),
                .AA          (read_oaddr         [(1)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .CLKB        (clk),
                .CENB        (write_en[(1)]),
                .AB          (write_iaddr        [(1)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .DB          (obuf_idata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),
                .EMAA        (3'd0),
                .EMASA       (1'd0),
                .EMAB        (3'd0),
                .EMAWB       (2'd0),
                .TENA        (1'd1),
                .BENA        (1'd1),
                .TCENA       (1'd1),
                .TAA         (9'd0),
                .TQA         (16'd0),
                .TENB        (1'd1),
                .TCENB       (1'd1),
                .TAB         (9'd0),
                .TDB         (16'd0),
                .RET1N       (1'd1),
                .STOVA       (1'd1),
                .STOVB       (1'd1),
                .COLLDISN    (1'd1)
            );
        end else if ( x_var%3 == 2 ) begin
            rf_2p_hse           uOBUF0_BK(
                .CENYA       (CENYA),
                .AYA         (AYA),
                .CENYB       (CENYB),
                .AYB         (AYB),
                .DYB         (DYB),
                .QA          (obuf_odata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),),
                .CLKA        (clk),
                .CENA        (1'b1),
                .AA          (read_oaddr         [(2)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .CLKB        (clk),
                .CENB        (write_en[(2)]),
                .AB          (write_iaddr        [(2)    *(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]),
                .DB          (obuf_idata         [(x_var)*(WORD_SIZE)   +:(WORD_SIZE)]),
                .EMAA        (3'd0),
                .EMASA       (1'd0),
                .EMAB        (3'd0),
                .EMAWB       (2'd0),
                .TENA        (1'd1),
                .BENA        (1'd1),
                .TCENA       (1'd1),
                .TAA         (9'd0),
                .TQA         (16'd0),
                .TENB        (1'd1),
                .TCENB       (1'd1),
                .TAB         (9'd0),
                .TDB         (16'd0),
                .RET1N       (1'd1),
                .STOVA       (1'd1),
                .STOVB       (1'd1),
                .COLLDISN    (1'd1)
            );
        end
`endif
    end

    AXI_WDATA_PROCESSING u_AXI_WDATA_PROCESSING(
        .clk                    (clk), 
        .set_wsize              (set_wsize),     
        .axi_wdata              (axi_wdata),     
        .axi_wdata_sign_out     (axi_wdata_sign_out),             
        .axi_wdata_out          (axi_wdata_out)
    );
    for ( x_var = 0 ; x_var < PE_ARRAY_4_v ; x_var=x_var+1 ) begin
        pe_array_3x24 u_pe_array_3x24(
            .clk                    (clk),
            .wbuf_rst_A             (wbuf_rst_A),
            .wbuf_rst_B             (wbuf_rst_B),
            .DECONVING              (DECONVING),
            .WBUF_AB_LOAD_FLAG      (WBUF_AB_LOAD_FLAG),
            .WBUF_AB_CACL_FLAG      (WBUF_AB_CACL_FLAG),
            .WBUF_LOAD_OCH_FLAG     (WBUF_LOAD_OCH_FLAG     [(x_var)]),
            .wbuf_addr_ker_cont     (wbuf_addr_ker_cont),
            .bk_combine             (bk_combine),
            .DWC_DATAFLOW           (DWC_DATAFLOW),
            .mult_en                (mult_en),
            .mult_en_dwc            (mult_en_dwc),
            .sign_flag_input        (idata_sign_array),
            .idata                  (idata_array),
            .linebuffer_sign_array  (linebuffer_sign_array  [(x_var)*(PE_ARRAY_3_v)*(KERNEL_3x3)*(TILE_NUM) +:(PE_ARRAY_3_v)*(KERNEL_3x3)*(TILE_NUM)]),
            .linebuffer_array       (linebuffer_array       [(x_var)*(PE_ARRAY_3_v)*(KERNEL_3x3)*(WORD_SIZE)+:(PE_ARRAY_3_v)*(KERNEL_3x3)*(WORD_SIZE)]),
            .sign_flag_weight       (axi_wdata_sign_out),
            .wdata                  (axi_wdata_out),
            .sign_flag_weight_dwc   (axi_wdata_sign_out     [(x_var)*(TILE_NUM)+:(TILE_NUM)]),
            .wdata_dwc              (axi_wdata_out          [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),
            .add_odata_dwc_5_H      (add_odata_dwc_H        [(x_var)*(PE_ARRAY_3_v)*(ADD_SIZE_5     )+:(PE_ARRAY_3_v)*(ADD_SIZE_5 )]),
            .add_odata_dwc_5_L      (add_odata_dwc_L        [(x_var)*(PE_ARRAY_3_v)*(HW_ADD_SIZE_DWC)+:(PE_ARRAY_3_v)*(HW_ADD_SIZE_DWC)]),
            .add_odata_7_H          (add_odata_H            [(x_var)*(PE_ARRAY_3_v)*(HW_ADD_SIZE    )+:(PE_ARRAY_3_v)*(HW_ADD_SIZE)]),
            .add_odata_7_L          (add_odata_L            [(x_var)*(PE_ARRAY_3_v)*(HW_ADD_SIZE    )+:(PE_ARRAY_3_v)*(HW_ADD_SIZE)])
        );
    end

    PE_PRODUCD_PROCESSING u_PE_PRODUCD_PROCESSING(
            .clk                (clk),   
            .quant_pe           (quant_pe),
            .set_isize          (set_isize),
            .bk_combine         (bk_combine),
            .DECONVING          (DECONVING),
            .read_en_pre        (read_en_pre),
            .add_odata_H        (add_odata_H),   
            .add_odata_L        (add_odata_L),   
            .PE_product         (PE_product)   
    );
    PE_DWC_PRODUCD_PROCESSING u_PE_DWC_PRODUCD_PROCESSING(
            .clk                (clk),   
            .quant_pe           (quant_pe),
            .set_isize          (set_isize),
            .bk_combine         (bk_combine),
            .add_odata_H        (add_odata_dwc_H),   
            .add_odata_L        (add_odata_dwc_L),   
            .PE_product         (PE_product_dwc)   
    );
    wbuf_spe_store u_wbuf_spe_store(
        .ker_size                   (ker_size),
        .bk_combine                 (bk_combine),
        .clk                        (clk),
        .wbuf_rst_A                 (wbuf_rst_A),
        .wbuf_rst_B                 (wbuf_rst_B),
        .WBUF_AB_LOAD_FLAG          (WBUF_AB_LOAD_FLAG),
        .WBUF_AB_CACL_FLAG          (WBUF_AB_CACL_FLAG),
        .WBUF_CONV_OR_DWC_SPE_FLAG  (WBUF_CONV_OR_DWC_SPE_FLAG),
        .WBUF_SPE_LOAD_OCH_FLAG     (WBUF_SPE_LOAD_OCH_FLAG),
        .wbuf_addr_spe_weight_cont  (wbuf_addr_spe_weight_cont),
        .wdata_in_sign              (axi_wdata_sign_out),
        .wdata_in                   (axi_wdata_out),
        .wdata_out_alpha_sign       (normalization_alpha_sign),
        .wdata_out_alpha            (normalization_alpha),
        .wdata_out_beta             (normalization_beta),
        .wdata_out_dwc_alpha_sign   (normalization_dwc_alpha_sign),
        .wdata_out_dwc_alpha        (normalization_dwc_alpha),
        .wdata_out_dwc_beta         (normalization_dwc_beta)
    );
    assign obuf_accu_bk = ( have_accu ) ? read_en_pre : 3'b000;
    OBUF_ACCU_DATA_PROCESSING u_OBUF_ACCU_DATA_PROCESSING(
        .bk_combine                 (bk_combine),
        .DECONVING                  (DECONVING),
        .obuf_accu_bk               (obuf_accu_bk),
        .obuf_odata                 (obuf_odata),
        .obuf_accu_data             (obuf_accu_data)             
    );
    wire [(PE_ARRAY_3_4_v)-1:0] spe_have_batch, spe_have_relu;
    wire                        spe_have_last_ich;
    for ( x_var =0 ; x_var < PE_ARRAY_4_v ; x_var= x_var+1 ) begin
        assign spe_have_batch[(x_var)*(PE_ARRAY_3_v)+(0)] = have_batch & spe_mult_en[0];
        assign spe_have_batch[(x_var)*(PE_ARRAY_3_v)+(1)] = have_batch & spe_mult_en[1];
        assign spe_have_batch[(x_var)*(PE_ARRAY_3_v)+(2)] = have_batch & spe_mult_en[2];
        assign spe_have_relu [(x_var)*(PE_ARRAY_3_v)+(0)] = have_relu  & spe_mult_en[0];
        assign spe_have_relu [(x_var)*(PE_ARRAY_3_v)+(1)] = have_relu  & spe_mult_en[1];
        assign spe_have_relu [(x_var)*(PE_ARRAY_3_v)+(2)] = have_relu  & spe_mult_en[2];
    end
    assign spe_have_last_ich = ( CONV_FLAG == DECONV_MODE ) ? have_last_ich : have_last_ich & Is_last_ker;
    for ( x_var = 0 ; x_var < PE_ARRAY_3_4_v ; x_var=x_var+1 ) begin
        special_process_element u_special_process_element(
            .clk                        (clk),
            .set_isize                  (set_isize),
            .set_wsize                  (set_wsize),
            .have_accu                  (have_accu),
            .batch_first                (batch_first),    
            .have_batch                 (spe_have_batch[(x_var)]),
            .have_relu                  (spe_have_relu[(x_var)]),
            .have_leaky                 (have_leaky),
            .have_sigmoid               (have_sigmoid),
            .have_last_ich              (spe_have_last_ich),    
            .quant_normalization        (quant_normalization),            
            .quant_activation           (quant_activation),        
            .leaky_constant             (leaky_constant),
            .normalization_alpha_sign   (normalization_alpha_sign   [(x_var)*(TILE_NUM)+:(TILE_NUM)]),            
            .normalization_alpha        (normalization_alpha        [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),
            .normalization_beta         (normalization_beta         [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),     
            .PE_product                 (PE_product                 [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),
            .OBUF_accu_odata            (obuf_accu_data             [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),        
            .SPE_product                (SPE_product                [(x_var)*(WORD_SIZE)+:(WORD_SIZE)])
        );
    end
    wire [(PE_ARRAY_3_4_v)-1:0] spe_dwc_have_batch, spe_dwc_have_relu;
    for ( x_var =0 ; x_var < PE_ARRAY_4_v ; x_var= x_var+1 ) begin
        assign spe_dwc_have_batch[(x_var)*(PE_ARRAY_3_v)+(0)] = have_batch_dwc & spe_dwc_mult_en[0];
        assign spe_dwc_have_batch[(x_var)*(PE_ARRAY_3_v)+(1)] = have_batch_dwc & spe_dwc_mult_en[1];
        assign spe_dwc_have_batch[(x_var)*(PE_ARRAY_3_v)+(2)] = have_batch_dwc & spe_dwc_mult_en[2];
        assign spe_dwc_have_relu [(x_var)*(PE_ARRAY_3_v)+(0)] = have_relu_dwc  & spe_dwc_mult_en[0];
        assign spe_dwc_have_relu [(x_var)*(PE_ARRAY_3_v)+(1)] = have_relu_dwc  & spe_dwc_mult_en[1];
        assign spe_dwc_have_relu [(x_var)*(PE_ARRAY_3_v)+(2)] = have_relu_dwc  & spe_dwc_mult_en[2];
    end
    for ( x_var = 0 ; x_var < PE_ARRAY_3_4_v ; x_var=x_var+1 ) begin
        special_process_element_dwc u_special_process_element_dwc(
            .clk                        (clk),
            .set_isize                  (set_isize),
            .set_wsize                  (set_wsize),
            .batch_first                (batch_first),    
            .have_batch                 (spe_dwc_have_batch[(x_var)]),
            .have_relu                  (spe_dwc_have_relu[(x_var)]),
//            .have_leaky                 (have_leaky),
//            .have_sigmoid               (have_sigmoid),
//            .have_last_ich              (have_last_ich),    
            .quant_pe                   (quant_pe),
            .quant_normalization        (quant_normalization),            
//            .quant_activation           (quant_activation),        
//            .leaky_constant             (leaky_constant),
            .normalization_alpha_sign   (normalization_dwc_alpha_sign   [(x_var)*(TILE_NUM)+:(TILE_NUM)]),            
            .normalization_alpha        (normalization_dwc_alpha        [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),
            .normalization_beta         (normalization_dwc_beta         [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),     
            .PE_product                 (PE_product_dwc                 [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),
            .SPE_product                (SPE_product_dwc                [(x_var)*(WORD_SIZE)+:(WORD_SIZE)])  
        );
    end
    assign obuf_pool_bk = ( have_pool_ing ) ? read_en_pre : 3'b000;
    OBUF_POOL_DATA_PROCESSING u_OBUF_POOL_DATA_PROCESSING(
        .bk_combine                 (bk_combine),         
        .obuf_pool_bk               (obuf_pool_bk),             
        .obuf_odata                 (obuf_odata),         
        .obuf_pool_idata            (pool_idata)           
    );
    for ( x_var = 0 ; x_var < PE_ARRAY_3_4_v ; x_var=x_var+1 ) begin
        POOL_PE u_POOL_PE(
            .clk                        (clk), 
            .set_isize                  (set_isize),     
            .pool_ctrl                  (pool_ctrl),     
            .pool_idata                 (pool_idata                 [(x_var)*(WORD_SIZE)+:(WORD_SIZE)]),     
            .pool_odata                 (pool_odata                 [(x_var)*(WORD_SIZE)+:(WORD_SIZE)])     
        );
    end
endgenerate
endmodule

