// Create Date: 06/08/2021 06:23:07 AM
`timescale 1ns / 1ps
`define MODULE_WORD_SIZE_hw     16
`define VIVADO_MODE 1
module pe_array_3x24#(
    parameter       TILE_NUM        =   2,
    parameter       AXI_DATA_WIDTH  =   8,
    parameter       PE_ARRAY_4_v    =   8,
    parameter       PE_ARRAY_3_v    =   3,
    parameter       PE_ARRAY_2_v    =   3,
    parameter       PE_ARRAY_1_v    =   8,
    parameter       PE_ARRAY_1_2_v  =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v  =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v      =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v,
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3,
    parameter       ADD_SIZE_1      =   ADD_SIZE+1,
    parameter       ADD_SIZE_2      =   ADD_SIZE_1+1,
    parameter       ADD_SIZE_3      =   ADD_SIZE_2+1,
    parameter       ADD_SIZE_4      =   ADD_SIZE_3+1,
    parameter       ADD_SIZE_5      =   ADD_SIZE_4+1,
    parameter       ADD_SIZE_6      =   ADD_SIZE_5+1,
    parameter       ADD_SIZE_7      =   ADD_SIZE_6+1,
    parameter       KERNEL_3x3      =   9
)(
    input                                                           clk,
                                                                    wbuf_rst_A,
                                                                    wbuf_rst_B,
                                                                    DECONVING,
                                                                    WBUF_AB_LOAD_FLAG,
                                                                    WBUF_AB_CACL_FLAG,
                                                                    WBUF_LOAD_OCH_FLAG,
                                                                    bk_combine,
    input           [1:0]                                           DWC_DATAFLOW,
    input           [3:0]                                           wbuf_addr_ker_cont,
    input           [8:0]                                           mult_en,
    input                                                           mult_en_dwc,
    input           [PE_ARRAY_1_2_v*PE_ARRAY_3_v*TILE_NUM-1:0]      sign_flag_input,
    input           [PE_ARRAY_1_2_v*PE_ARRAY_3_v*WORD_SIZE-1:0]     idata,
    input           [PE_ARRAY_3_v*KERNEL_3x3*TILE_NUM-1:0]          linebuffer_sign_array,        //KERNEL[8] OF ( OCH[i] , OCH[i+8] , OCH[i+16]
    input           [PE_ARRAY_3_v*KERNEL_3x3*WORD_SIZE-1:0]         linebuffer_array,                  //KERNEL[8] OF ( OCH[i] , OCH[i+8] , OCH[i+16]
    input           [AXI_DATA_WIDTH*TILE_NUM-1:0]                   sign_flag_weight,
    input           [AXI_DATA_WIDTH*WORD_SIZE-1:0]                  wdata,
    input           [TILE_NUM-1:0]                                  sign_flag_weight_dwc,
    input           [WORD_SIZE-1:0]                                 wdata_dwc,
    output          [PE_ARRAY_3_v*ADD_SIZE_5-1:0]                   add_odata_dwc_5_H,
                                                                    add_odata_dwc_5_L,
    output  reg     [PE_ARRAY_3_v*ADD_SIZE_7-1:0]                   add_odata_7_H,
                                                                    add_odata_7_L
);
    wire            [ADD_SIZE_5-1:0]                                add_odata_deconv_5_H,
                                                                    add_odata_deconv_5_L;
    wire            [PE_ARRAY_3_v*ADD_SIZE_5-1:0]                   add_odata_5_H,
                                                                    add_odata_5_L;
    reg             [ADD_SIZE_6-1:0]                                add_odata_6_H,add_odata_6_L;
    reg             [PE_ARRAY_3_v*ADD_SIZE_6-1:0]                   add_odata_6_H_pip,
                                                                    add_odata_6_L_pip;

    reg             [(PE_ARRAY_2_v)*(PE_ARRAY_3_v)+3-1:0]           WBUF_LOAD_KER_FLAG;
    integer                                                         i;
    always @ ( * ) begin
        case ( {WBUF_LOAD_OCH_FLAG,wbuf_addr_ker_cont} )
            {1'b1,4'd0}  : WBUF_LOAD_KER_FLAG = 12'b0000_0000_0001;
            {1'b1,4'd1}  : WBUF_LOAD_KER_FLAG = 12'b0000_0000_0010;
            {1'b1,4'd2}  : WBUF_LOAD_KER_FLAG = 12'b0000_0000_0100;
            {1'b1,4'd3}  : WBUF_LOAD_KER_FLAG = 12'b0000_0000_1000;
            {1'b1,4'd4}  : WBUF_LOAD_KER_FLAG = 12'b0000_0001_0000;
            {1'b1,4'd5}  : WBUF_LOAD_KER_FLAG = 12'b0000_0010_0000;
            {1'b1,4'd6}  : WBUF_LOAD_KER_FLAG = 12'b0000_0100_0000;
            {1'b1,4'd7}  : WBUF_LOAD_KER_FLAG = 12'b0000_1000_0000;
            {1'b1,4'd8}  : WBUF_LOAD_KER_FLAG = 12'b0001_0000_0000;
            {1'b1,4'd9}  : WBUF_LOAD_KER_FLAG = 12'b0010_0000_0000; // 0 <= OCH < 8     kernel[8] (Last Kernel)
            {1'b1,4'd10} : WBUF_LOAD_KER_FLAG = 12'b0100_0000_0000; // 8 <= OCH < 16    kernel[8] (Last Kernel)
            {1'b1,4'd11} : WBUF_LOAD_KER_FLAG = 12'b1000_0000_0000; // 16<= OCH < 24    kernel[8] (Last Kernel)
            default : WBUF_LOAD_KER_FLAG = 12'd0;
        endcase
    end

    pe_array_3x8 u_pe_array_3x8x1_OCH_0n(
        .clk                    (clk),
        .wbuf_rst_A             (wbuf_rst_A),
        .wbuf_rst_B             (wbuf_rst_B),
        .DWC_DATAFLOW           (DWC_DATAFLOW),
        .WBUF_AB_LOAD_FLAG      (WBUF_AB_LOAD_FLAG),
        .WBUF_AB_CACL_FLAG      (WBUF_AB_CACL_FLAG),
        .WBUF_LOAD_KER_FLAG     ({WBUF_LOAD_KER_FLAG    [(0)+9],    
                                  WBUF_LOAD_KER_FLAG    [(0)*(PE_ARRAY_2_v)                 +:(PE_ARRAY_2_v)]}),
        .mult_en                (mult_en                [(0)*(PE_ARRAY_2_v)                 +:(PE_ARRAY_2_v)]),
        .mult_en_dwc            (mult_en_dwc            ),
        .sign_flag_input        (sign_flag_input        [(0)*(PE_ARRAY_1_2_v)*(TILE_NUM)    +:(PE_ARRAY_1_2_v)*(TILE_NUM)]),
        .idata                  (idata                  [(0)*(PE_ARRAY_1_2_v)*(WORD_SIZE)   +:(PE_ARRAY_1_2_v)*(WORD_SIZE)]),
        .linebuffer_sign_array  (linebuffer_sign_array  [(0)*  (KERNEL_3x3)  *(TILE_NUM)    +:  (KERNEL_3x3)  *(TILE_NUM)]),
        .linebuffer_array       (linebuffer_array       [(0)*  (KERNEL_3x3)  *(WORD_SIZE)   +:  (KERNEL_3x3)  *(WORD_SIZE)]),
        .sign_flag_weight       (sign_flag_weight),
        .wdata                  (wdata),
        .sign_flag_weight_dwc   (sign_flag_weight_dwc),
        .wdata_dwc              (wdata_dwc),
        .add_odata_dwc_5_H      (add_odata_dwc_5_H      [(0)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_dwc_5_L      (add_odata_dwc_5_L      [(0)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_5_H          (add_odata_5_H          [(0)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_5_L          (add_odata_5_L          [(0)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)])
    );
    pe_array_3_8_able_deconv u_pe_array_3x8x1_OCH_8n(
        .clk                    (clk),
        .wbuf_rst_A             (wbuf_rst_A),
        .wbuf_rst_B             (wbuf_rst_B),
        .DECONVING              (DECONVING),
        .DWC_DATAFLOW           (DWC_DATAFLOW),
        .WBUF_AB_LOAD_FLAG      (WBUF_AB_LOAD_FLAG),
        .WBUF_AB_CACL_FLAG      (WBUF_AB_CACL_FLAG),
        .WBUF_LOAD_KER_FLAG     ({WBUF_LOAD_KER_FLAG    [(1)+9],    
                                  WBUF_LOAD_KER_FLAG    [(1)*(PE_ARRAY_2_v)                 +:(PE_ARRAY_2_v)]}),
        .mult_en                (mult_en                [(1)*(PE_ARRAY_2_v)                 +:(PE_ARRAY_2_v)]),
        .mult_en_dwc            (mult_en_dwc            ),
        .sign_flag_input        (sign_flag_input        [(1)*(PE_ARRAY_1_2_v)*(TILE_NUM)    +:(PE_ARRAY_1_2_v)*(TILE_NUM)]),
        .idata                  (idata                  [(1)*(PE_ARRAY_1_2_v)*(WORD_SIZE)   +:(PE_ARRAY_1_2_v)*(WORD_SIZE)]),
        .linebuffer_sign_array  (linebuffer_sign_array  [(1)*  (KERNEL_3x3)  *(TILE_NUM)    +:  (KERNEL_3x3)  *(TILE_NUM)]),
        .linebuffer_array       (linebuffer_array       [(1)*  (KERNEL_3x3)  *(WORD_SIZE)   +:  (KERNEL_3x3)  *(WORD_SIZE)]),
        .sign_flag_weight       (sign_flag_weight),
        .wdata                  (wdata),
        .sign_flag_weight_dwc   (sign_flag_weight_dwc),
        .wdata_dwc              (wdata_dwc),
        .add_odata_dwc_5_H      (add_odata_dwc_5_H      [(1)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_dwc_5_L      (add_odata_dwc_5_L      [(1)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_5_H          (add_odata_5_H          [(1)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_5_L          (add_odata_5_L          [(1)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_deconv_5_H   (add_odata_deconv_5_H),
        .add_odata_deconv_5_L   (add_odata_deconv_5_L)
    );
    pe_array_3x8 u_pe_array_3x8x1_OCH_16n(
        .clk                    (clk),
        .wbuf_rst_A             (wbuf_rst_A),
        .wbuf_rst_B             (wbuf_rst_B),
        .DWC_DATAFLOW           (DWC_DATAFLOW),
        .WBUF_AB_LOAD_FLAG      (WBUF_AB_LOAD_FLAG),
        .WBUF_AB_CACL_FLAG      (WBUF_AB_CACL_FLAG),
        .WBUF_LOAD_KER_FLAG     ({WBUF_LOAD_KER_FLAG    [(2)+9],    
                                  WBUF_LOAD_KER_FLAG    [(2)*(PE_ARRAY_2_v)                 +:(PE_ARRAY_2_v)]}),
        .mult_en                (mult_en                [(2)*(PE_ARRAY_2_v)                 +:(PE_ARRAY_2_v)]),
        .mult_en_dwc            (mult_en_dwc            ),
        .sign_flag_input        (sign_flag_input        [(2)*(PE_ARRAY_1_2_v)*(TILE_NUM)    +:(PE_ARRAY_1_2_v)*(TILE_NUM)]),
        .idata                  (idata                  [(2)*(PE_ARRAY_1_2_v)*(WORD_SIZE)   +:(PE_ARRAY_1_2_v)*(WORD_SIZE)]),
        .linebuffer_sign_array  (linebuffer_sign_array  [(2)*  (KERNEL_3x3)  *(TILE_NUM)    +:  (KERNEL_3x3)  *(TILE_NUM)]),
        .linebuffer_array       (linebuffer_array       [(2)*  (KERNEL_3x3)  *(WORD_SIZE)   +:  (KERNEL_3x3)  *(WORD_SIZE)]),
        .sign_flag_weight       (sign_flag_weight),
        .wdata                  (wdata),
        .sign_flag_weight_dwc   (sign_flag_weight_dwc),
        .wdata_dwc              (wdata_dwc),
        .add_odata_dwc_5_H      (add_odata_dwc_5_H      [(2)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_dwc_5_L      (add_odata_dwc_5_L      [(2)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_5_H          (add_odata_5_H          [(2)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)]),
        .add_odata_5_L          (add_odata_5_L          [(2)*(ADD_SIZE_5)                   +:(ADD_SIZE_5)])
    );
        always @ ( posedge clk ) begin
            add_odata_6_H_pip[(0)*(ADD_SIZE_6)+:(ADD_SIZE_6)] <= ( DECONVING ) ? {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H  [ADD_SIZE_5*(   1   )-1]}},  add_odata_5_H   [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]}
                                                                               + {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H  [ADD_SIZE_5*(   2   )-1]}},  add_odata_5_H   [ADD_SIZE_5*(  1  )+:ADD_SIZE_5]} 
                                                                               : {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H  [ADD_SIZE_5*(   1   )-1]}},  add_odata_5_H   [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]};
            add_odata_6_L_pip[(0)*(ADD_SIZE_6)+:(ADD_SIZE_6)] <= ( DECONVING ) ? {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L  [ADD_SIZE_5*(   1   )-1]}},  add_odata_5_L   [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]}
                                                                               + {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L  [ADD_SIZE_5*(   2   )-1]}},  add_odata_5_L   [ADD_SIZE_5*(  1  )+:ADD_SIZE_5]} 
                                                                               : {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L  [ADD_SIZE_5*(   1   )-1]}},  add_odata_5_L   [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]};

            add_odata_6_H_pip[(1)*(ADD_SIZE_6)+:(ADD_SIZE_6)] <=                 {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H  [ADD_SIZE_5*(   2   )-1]}},  add_odata_5_H   [ADD_SIZE_5*(  1  )+:ADD_SIZE_5]};
            add_odata_6_L_pip[(1)*(ADD_SIZE_6)+:(ADD_SIZE_6)] <=                 {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L  [ADD_SIZE_5*(   2   )-1]}},  add_odata_5_L   [ADD_SIZE_5*(  1  )+:ADD_SIZE_5]};

            add_odata_6_H_pip[(2)*(ADD_SIZE_6)+:(ADD_SIZE_6)] <= ( DECONVING ) ? {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H          [ADD_SIZE_5*(   3   )-1]}},  add_odata_5_H          [ADD_SIZE_5*(  2  )+:ADD_SIZE_5]}
                                                                               + {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_deconv_5_H   [ADD_SIZE_5*(   1   )-1]}},  add_odata_deconv_5_H   [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]} 
                                                                               : {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H          [ADD_SIZE_5*(   3   )-1]}},  add_odata_5_H          [ADD_SIZE_5*(  2  )+:ADD_SIZE_5]};
            add_odata_6_L_pip[(2)*(ADD_SIZE_6)+:(ADD_SIZE_6)] <= ( DECONVING ) ? {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L          [ADD_SIZE_5*(   3   )-1]}},  add_odata_5_L          [ADD_SIZE_5*(  2  )+:ADD_SIZE_5]}
                                                                               + {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_deconv_5_L   [ADD_SIZE_5*(   1   )-1]}},  add_odata_deconv_5_L   [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]} 
                                                                               : {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L          [ADD_SIZE_5*(   3   )-1]}},  add_odata_5_L          [ADD_SIZE_5*(  2  )+:ADD_SIZE_5]};
        end 

    always @ ( posedge clk ) begin   // CONV DATA
        //-------------------------- ICH 0 ( 1x1 Conv ) or Deconv Y JUMP TO 0_ --------------------------
            add_odata_7_H[ADD_SIZE_7*0+:ADD_SIZE_7]    <=              
            {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_H_pip  [ADD_SIZE_6*(   1   )-1]}},  add_odata_6_H_pip   [ADD_SIZE_6*(  0  )+:ADD_SIZE_6]} ;
            add_odata_7_L[ADD_SIZE_7*0+:ADD_SIZE_7]    <=               
            {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_L_pip  [ADD_SIZE_6*(   1   )-1]}},  add_odata_6_L_pip   [ADD_SIZE_6*(  0  )+:ADD_SIZE_6]} ;
        
        //-------------------------- ICH 0 ( 1x1 Conv ) or Deconv Y JUMP TO 0 --------------------------
        //-------------------------- ICH 1 ( 1x1 Conv ) or ICH 0 ( 3x3 Conv ) -----------------------
            add_odata_6_H [ADD_SIZE_6*0+:ADD_SIZE_6]    <= 
            {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H      [ADD_SIZE_5*(   1   )-1]}},  add_odata_5_H       [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]}
          + {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_H      [ADD_SIZE_5*(   2   )-1]}},  add_odata_5_H       [ADD_SIZE_5*(  1  )+:ADD_SIZE_5]};
            add_odata_6_L [ADD_SIZE_6*0+:ADD_SIZE_6]    <= 
            {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L      [ADD_SIZE_5*(   1   )-1]}},  add_odata_5_L       [ADD_SIZE_5*(  0  )+:ADD_SIZE_5]}
          + {   {(ADD_SIZE_6-ADD_SIZE_5)   {add_odata_5_L      [ADD_SIZE_5*(   2   )-1]}},  add_odata_5_L       [ADD_SIZE_5*(  1  )+:ADD_SIZE_5]};

            add_odata_7_H[ADD_SIZE_7*1+:ADD_SIZE_7]    <= ( bk_combine == 0 ) ? 
            {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_H_pip  [ADD_SIZE_6*(   2   )-1]}},  add_odata_6_H_pip   [ADD_SIZE_6*(  1  )+:ADD_SIZE_6]}    // 1x1 Conv
          : {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_H      [ADD_SIZE_6*(   1   )-1]}},  add_odata_6_H       [ADD_SIZE_6*(  0  )+:ADD_SIZE_6]}    // 3x3 Conv 
          + {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_H_pip  [ADD_SIZE_6*(   3   )-1]}},  add_odata_6_H_pip   [ADD_SIZE_6*(  2  )+:ADD_SIZE_6]} ;  // 3x3 Conv 
            add_odata_7_L[ADD_SIZE_7*1+:ADD_SIZE_7]    <= ( bk_combine == 0 ) ? 
            {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_L_pip  [ADD_SIZE_6*(   2   )-1]}},  add_odata_6_L_pip   [ADD_SIZE_6*(  1  )+:ADD_SIZE_6]}    // 1x1 Conv
          : {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_L      [ADD_SIZE_6*(   1   )-1]}},  add_odata_6_L       [ADD_SIZE_6*(  0  )+:ADD_SIZE_6]}    // 3x3 Conv
          + {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_L_pip  [ADD_SIZE_6*(   3   )-1]}},  add_odata_6_L_pip   [ADD_SIZE_6*(  2  )+:ADD_SIZE_6]} ;  // 3x3 Conv
        //-------------------------- ICH 1 ( 1x1 Conv ) or ICH 0 ( 3x3 Conv ) -----------------------
        //-------------------------- ICH 2 ( 1x1 Conv ) or Deconv Y JUMP TO 1 --------------------------
            add_odata_7_H[ADD_SIZE_7*2+:ADD_SIZE_7]    <=              
            {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_H_pip  [ADD_SIZE_6*(   3   )-1]}},  add_odata_6_H_pip   [ADD_SIZE_6*(  2  )+:ADD_SIZE_6]} ;
            add_odata_7_L[ADD_SIZE_7*2+:ADD_SIZE_7]    <=               
            {   {(ADD_SIZE_7-ADD_SIZE_6)   {add_odata_6_L_pip  [ADD_SIZE_6*(   3   )-1]}},  add_odata_6_L_pip   [ADD_SIZE_6*(  2  )+:ADD_SIZE_6]} ;
        //-------------------------- ICH 2 ( 1x1 Conv ) or Deconv Y JUMP TO 1 --------------------------
    end
    integer add_odata_7_show [0:2],
             add_odata_7_show_H [0:2],
             add_odata_7_show_L [0:2]; 
    always @ ( * ) begin
        for ( i=0 ; i<3 ; i=i+1 )begin
            add_odata_7_show_H[i] = $signed(add_odata_7_H[i*ADD_SIZE_7+:ADD_SIZE_7]);
            add_odata_7_show_L[i] = $signed(add_odata_7_L[i*ADD_SIZE_7+:ADD_SIZE_7]);
            add_odata_7_show[i] =  (add_odata_7_show_H[i]<<8) + add_odata_7_show_L[i];
        end
    end
endmodule

module pe_array_3_8_able_deconv#(
    parameter       TILE_NUM                    =   2,
    parameter       AXI_DATA_WIDTH              =   8,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_v                  =   24,
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE                   =   WORD_SIZE/2,
    parameter       ADD_SIZE                    =   HALF_SIZE*3,
    parameter       ADD_SIZE_1                  =   ADD_SIZE+1,
    parameter       ADD_SIZE_2                  =   ADD_SIZE_1+1,
    parameter       ADD_SIZE_3                  =   ADD_SIZE_2+1,
    parameter       ADD_SIZE_4                  =   ADD_SIZE_3+1,
    parameter       ADD_SIZE_5                  =   ADD_SIZE_4+1,
    parameter       SPE_TO_LINE_BUFFER          =   1,
    parameter       OBUF_TO_LINE_BUFFER         =   2,
    parameter       KERNEL_3x3                  =   9
)(
    input                                           clk,
                                                    wbuf_rst_A,
                                                    wbuf_rst_B,
                                                    DECONVING,
    input           [1:0]                           DWC_DATAFLOW,
    input                                           WBUF_AB_LOAD_FLAG,
                                                    WBUF_AB_CACL_FLAG,
    input           [PE_ARRAY_2_v+1-1:0]            WBUF_LOAD_KER_FLAG,
    input           [PE_ARRAY_2_v-1:0]              mult_en,
    input                                           mult_en_dwc,
    input           [PE_ARRAY_v*TILE_NUM-1:0]       sign_flag_input,
    input           [PE_ARRAY_v*WORD_SIZE-1:0]      idata,
    input           [KERNEL_3x3*TILE_NUM-1:0]       linebuffer_sign_array,
    input           [KERNEL_3x3*WORD_SIZE-1:0]      linebuffer_array,
    input           [AXI_DATA_WIDTH*TILE_NUM-1:0]   sign_flag_weight,
    input           [AXI_DATA_WIDTH*WORD_SIZE-1:0]  wdata,
    input           [TILE_NUM-1:0]                  sign_flag_weight_dwc,
    input           [WORD_SIZE-1:0]                 wdata_dwc,
    output  reg     [ADD_SIZE_5-1:0]                add_odata_dwc_5_H,
                                                    add_odata_dwc_5_L,
    output  reg     [ADD_SIZE_5-1:0]                add_odata_5_H,
                                                    add_odata_5_L,
    output  reg     [ADD_SIZE_5-1:0]                add_odata_deconv_5_H,
                                                    add_odata_deconv_5_L

);
    reg             [PE_ARRAY_v*WORD_SIZE-1:0]      idata_;
    reg             [PE_ARRAY_v*TILE_NUM-1:0]       sign_flag_input_;
    wire            [ADD_SIZE_3-1:0]                add_odata_dwc_3_H,
                                                    add_odata_dwc_3_L;
    wire            [PE_ARRAY_2_v*ADD_SIZE_3-1:0]   add_odata_3_H,
                                                    add_odata_3_L;
    reg             [ADD_SIZE_4-1:0]                add_odata_3_H_,add_odata_3_L_;
    reg             [ADD_SIZE_4-1:0]                add_odata_4_H,add_odata_4_L;
    integer                                         i;
    always @ ( * ) begin
        idata_          [(0)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] = idata                    [(0)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        idata_          [(1)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] = idata                    [(1)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        idata_          [(2)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] = ( DWC_DATAFLOW == 0 ) ? 
                                                                                       idata                    [(2)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                     : linebuffer_array         [(0)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        sign_flag_input_[(0)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] = sign_flag_input          [(0)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        sign_flag_input_[(1)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] = sign_flag_input          [(1)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        sign_flag_input_[(2)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] = ( DWC_DATAFLOW == 0 ) ? 
                                                                                       sign_flag_input          [(2)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                     : linebuffer_sign_array    [(0)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
    end
    pe_array_dwc u_pe_array_dwc(
        .clk                    (clk),
        .wbuf_rst_A             (wbuf_rst_A),
        .wbuf_rst_B             (wbuf_rst_B),
        .WBUF_AB_LOAD_FLAG      (WBUF_AB_LOAD_FLAG),
        .WBUF_AB_CACL_FLAG      (WBUF_AB_CACL_FLAG),
        .WBUF_LOAD_KER_FLAG     (WBUF_LOAD_KER_FLAG     [PE_ARRAY_2_v]),
        .mult_en                (mult_en_dwc),
        .sign_flag_input        (linebuffer_sign_array  [(8)*(TILE_NUM) +:(TILE_NUM)]),
        .idata                  (linebuffer_array       [(8)*(WORD_SIZE)+:(WORD_SIZE)]),
        .sign_flag_weight_dwc   (sign_flag_weight_dwc),
        .wdata_dwc              (wdata_dwc),
        .add_odata_3_H          (add_odata_dwc_3_H      [0+:ADD_SIZE_3]),
        .add_odata_3_L          (add_odata_dwc_3_L      [0+:ADD_SIZE_3])
    );                
    genvar x_var;
    generate
        for ( x_var=0 ; x_var<PE_ARRAY_2_v ; x_var=x_var+1 ) begin
            pe_array_8x1 u_pe_array_8x1(
                .clk                (clk),
                .wbuf_rst_A         (wbuf_rst_A),
                .wbuf_rst_B         (wbuf_rst_B),
                .WBUF_AB_LOAD_FLAG  (WBUF_AB_LOAD_FLAG),
                .WBUF_AB_CACL_FLAG  (WBUF_AB_CACL_FLAG),
                .WBUF_LOAD_KER_FLAG (WBUF_LOAD_KER_FLAG         [(x_var)]),
                .mult_en            (mult_en                    [(x_var)]),
                .sign_flag_input    (sign_flag_input_           [(x_var)*PE_ARRAY_1_v*2         +:PE_ARRAY_1_v*2]),
                .idata              (idata_                     [(x_var)*PE_ARRAY_1_v*WORD_SIZE +:PE_ARRAY_1_v*WORD_SIZE]),
                .sign_flag_weight   (sign_flag_weight),
                .wdata              (wdata),
                .add_odata_3_H      (add_odata_3_H              [(x_var)*ADD_SIZE_3             +:ADD_SIZE_3]),
                .add_odata_3_L      (add_odata_3_L              [(x_var)*ADD_SIZE_3             +:ADD_SIZE_3])
            );
        end
    endgenerate
    always @ ( posedge clk ) begin
        //======================== PIP1 ========================
        for ( i=2 ; i<PE_ARRAY_2_v ; i=i+1 ) begin
            add_odata_3_H_      [ADD_SIZE_4*0+:ADD_SIZE_4] <= ( DWC_DATAFLOW == 0 ) ?
                                                              {add_odata_3_H        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_H      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             :{add_odata_3_H        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_H      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_dwc_3_H    [ADD_SIZE_3*(   1   )-1],add_odata_dwc_3_H  [ADD_SIZE_3*(  0  )+:ADD_SIZE_3]};
                                                             
            add_odata_3_L_      [ADD_SIZE_4*0+:ADD_SIZE_4] <= ( DWC_DATAFLOW == 0 ) ?
                                                              {add_odata_3_L        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_L      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             :{add_odata_3_L        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_L      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_dwc_3_L    [ADD_SIZE_3*(   1   )-1],add_odata_dwc_3_L  [ADD_SIZE_3*(  0  )+:ADD_SIZE_3]};
                                                             
        end
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_4_H       [ADD_SIZE_4*i+:ADD_SIZE_4] <= {add_odata_3_H        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_H [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_3_H        [ADD_SIZE_3*(  i+2  )-1],add_odata_3_H [ADD_SIZE_3*( i+1 )+:ADD_SIZE_3]};
            add_odata_4_L       [ADD_SIZE_4*i+:ADD_SIZE_4] <= {add_odata_3_L        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_L [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_3_L        [ADD_SIZE_3*(  i+2  )-1],add_odata_3_L [ADD_SIZE_3*( i+1 )+:ADD_SIZE_3]};
        end
        //======================== PIP1 ========================
        //======================== PIP2 ========================
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_dwc_5_H   [ADD_SIZE_5*i+:ADD_SIZE_5] <= {add_odata_3_H_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_H_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};
            add_odata_dwc_5_L   [ADD_SIZE_5*i+:ADD_SIZE_5] <= {add_odata_3_L_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_L_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};

            add_odata_5_H       [ADD_SIZE_5*i+:ADD_SIZE_5] <= ( DWC_DATAFLOW == 0 && DECONVING == 0 ) ?
                                                              {add_odata_4_H        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_H [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}  
                                                             +{add_odata_3_H_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_H_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}
                                                             :{add_odata_4_H        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_H [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};
                                                             
            add_odata_5_L       [ADD_SIZE_5*i+:ADD_SIZE_5] <= ( DWC_DATAFLOW == 0 && DECONVING == 0 ) ?
                                                              {add_odata_4_L        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_L [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}
                                                             +{add_odata_3_L_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_L_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}
                                                             :{add_odata_4_L        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_L [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};
        end
            add_odata_deconv_5_H[ADD_SIZE_5*0+:ADD_SIZE_5] <= ( DECONVING == 0 ) ? {ADD_SIZE_5{1'b0}} : {add_odata_3_H_       [ADD_SIZE_4*(   1   )-1],add_odata_3_H_[ADD_SIZE_4*(  0  )+:ADD_SIZE_4]};
            add_odata_deconv_5_L[ADD_SIZE_5*0+:ADD_SIZE_5] <= ( DECONVING == 0 ) ? {ADD_SIZE_5{1'b0}} : {add_odata_3_L_       [ADD_SIZE_4*(   1   )-1],add_odata_3_L_[ADD_SIZE_4*(  0  )+:ADD_SIZE_4]};
        //======================== PIP2 ========================
    end

endmodule


module pe_array_3x8#(
    parameter       TILE_NUM                    =   2,
    parameter       AXI_DATA_WIDTH              =   8,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_v                  =   24,
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE                   =   WORD_SIZE/2,
    parameter       ADD_SIZE                    =   HALF_SIZE*3,
    parameter       ADD_SIZE_1                  =   ADD_SIZE+1,
    parameter       ADD_SIZE_2                  =   ADD_SIZE_1+1,
    parameter       ADD_SIZE_3                  =   ADD_SIZE_2+1,
    parameter       ADD_SIZE_4                  =   ADD_SIZE_3+1,
    parameter       ADD_SIZE_5                  =   ADD_SIZE_4+1,
    parameter       SPE_TO_LINE_BUFFER          =   1,
    parameter       OBUF_TO_LINE_BUFFER         =   2,
    parameter       KERNEL_3x3                  =   9
)(
    input                                           clk,
                                                    wbuf_rst_A,
                                                    wbuf_rst_B,
    input           [1:0]                           DWC_DATAFLOW,
    input                                           WBUF_AB_LOAD_FLAG,
                                                    WBUF_AB_CACL_FLAG,
    input           [PE_ARRAY_2_v+1-1:0]            WBUF_LOAD_KER_FLAG,
    input           [PE_ARRAY_2_v-1:0]              mult_en,
    input                                           mult_en_dwc,
    input           [PE_ARRAY_v*TILE_NUM-1:0]       sign_flag_input,
    input           [PE_ARRAY_v*WORD_SIZE-1:0]      idata,
    input           [KERNEL_3x3*TILE_NUM-1:0]       linebuffer_sign_array,
    input           [KERNEL_3x3*WORD_SIZE-1:0]      linebuffer_array,
    input           [AXI_DATA_WIDTH*TILE_NUM-1:0]   sign_flag_weight,
    input           [AXI_DATA_WIDTH*WORD_SIZE-1:0]  wdata,
    input           [TILE_NUM-1:0]                  sign_flag_weight_dwc,
    input           [WORD_SIZE-1:0]                 wdata_dwc,
    output  reg     [ADD_SIZE_5-1:0]                add_odata_dwc_5_H,
                                                    add_odata_dwc_5_L,
    output  reg     [ADD_SIZE_5-1:0]                add_odata_5_H,
                                                    add_odata_5_L
);
    reg             [PE_ARRAY_v*WORD_SIZE-1:0]      idata_;
    reg             [PE_ARRAY_v*TILE_NUM-1:0]       sign_flag_input_;
    wire            [ADD_SIZE_3-1:0]                add_odata_dwc_3_H,
                                                    add_odata_dwc_3_L;
    wire            [PE_ARRAY_2_v*ADD_SIZE_3-1:0]   add_odata_3_H,
                                                    add_odata_3_L;
    reg             [ADD_SIZE_4-1:0]                add_odata_3_H_,add_odata_3_L_;
    reg             [ADD_SIZE_4-1:0]                add_odata_4_H,add_odata_4_L;
    integer                                         i;
    always @ ( * ) begin
        idata_          [(0)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] = idata                    [(0)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        idata_          [(1)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] = idata                    [(1)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        idata_          [(2)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] = ( DWC_DATAFLOW == 0 ) ? 
                                                                                       idata                    [(2)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                     : linebuffer_array         [(0)*(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        sign_flag_input_[(0)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] = sign_flag_input          [(0)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        sign_flag_input_[(1)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] = sign_flag_input          [(1)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        sign_flag_input_[(2)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] = ( DWC_DATAFLOW == 0 ) ? 
                                                                                       sign_flag_input          [(2)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                     : linebuffer_sign_array    [(0)*(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
    end
    pe_array_dwc u_pe_array_dwc(
        .clk                    (clk),
        .wbuf_rst_A             (wbuf_rst_A),
        .wbuf_rst_B             (wbuf_rst_B),
        .WBUF_AB_LOAD_FLAG      (WBUF_AB_LOAD_FLAG),
        .WBUF_AB_CACL_FLAG      (WBUF_AB_CACL_FLAG),
        .WBUF_LOAD_KER_FLAG     (WBUF_LOAD_KER_FLAG     [PE_ARRAY_2_v]),
        .mult_en                (mult_en_dwc),
        .sign_flag_input        (linebuffer_sign_array  [(8)*(TILE_NUM) +:(TILE_NUM)]),
        .idata                  (linebuffer_array       [(8)*(WORD_SIZE)+:(WORD_SIZE)]),
        .sign_flag_weight_dwc   (sign_flag_weight_dwc),
        .wdata_dwc              (wdata_dwc),
        .add_odata_3_H          (add_odata_dwc_3_H      [0+:ADD_SIZE_3]),
        .add_odata_3_L          (add_odata_dwc_3_L      [0+:ADD_SIZE_3])
    );      
    genvar x_var;
    generate
        for ( x_var=0 ; x_var<PE_ARRAY_2_v ; x_var=x_var+1 ) begin
            pe_array_8x1 u_pe_array_8x1(
                .clk                (clk),
                .wbuf_rst_A         (wbuf_rst_A),
                .wbuf_rst_B         (wbuf_rst_B),
                .WBUF_AB_LOAD_FLAG  (WBUF_AB_LOAD_FLAG),
                .WBUF_AB_CACL_FLAG  (WBUF_AB_CACL_FLAG),
                .WBUF_LOAD_KER_FLAG (WBUF_LOAD_KER_FLAG         [(x_var)]),
                .mult_en            (mult_en                    [(x_var)]),
                .sign_flag_input    (sign_flag_input_           [(x_var)*PE_ARRAY_1_v*2         +:PE_ARRAY_1_v*2]),
                .idata              (idata_                     [(x_var)*PE_ARRAY_1_v*WORD_SIZE +:PE_ARRAY_1_v*WORD_SIZE]),
                .sign_flag_weight   (sign_flag_weight),
                .wdata              (wdata),
                .add_odata_3_H      (add_odata_3_H              [(x_var)*ADD_SIZE_3             +:ADD_SIZE_3]),
                .add_odata_3_L      (add_odata_3_L              [(x_var)*ADD_SIZE_3             +:ADD_SIZE_3])
            );
        end
    endgenerate
    always @ ( posedge clk ) begin
        for ( i=2 ; i<PE_ARRAY_2_v ; i=i+1 ) begin
            add_odata_3_H_      [ADD_SIZE_4*0+:ADD_SIZE_4] <= ( DWC_DATAFLOW == 0 ) ?
                                                              {add_odata_3_H        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_H      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             :{add_odata_3_H        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_H      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_dwc_3_H    [ADD_SIZE_3*(   1   )-1],add_odata_dwc_3_H  [ADD_SIZE_3*(  0  )+:ADD_SIZE_3]};
                                                             
            add_odata_3_L_      [ADD_SIZE_4*0+:ADD_SIZE_4] <= ( DWC_DATAFLOW == 0 ) ?
                                                              {add_odata_3_L        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_L      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             :{add_odata_3_L        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_L      [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_dwc_3_L    [ADD_SIZE_3*(   1   )-1],add_odata_dwc_3_L  [ADD_SIZE_3*(  0  )+:ADD_SIZE_3]};
                                                             
        end
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_4_H       [ADD_SIZE_4*i+:ADD_SIZE_4] <= {add_odata_3_H        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_H [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_3_H        [ADD_SIZE_3*(  i+2  )-1],add_odata_3_H [ADD_SIZE_3*( i+1 )+:ADD_SIZE_3]};
            add_odata_4_L       [ADD_SIZE_4*i+:ADD_SIZE_4] <= {add_odata_3_L        [ADD_SIZE_3*(  i+1  )-1],add_odata_3_L [ADD_SIZE_3*(  i  )+:ADD_SIZE_3]}
                                                             +{add_odata_3_L        [ADD_SIZE_3*(  i+2  )-1],add_odata_3_L [ADD_SIZE_3*( i+1 )+:ADD_SIZE_3]};
        end
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_dwc_5_H   [ADD_SIZE_5*i+:ADD_SIZE_5] <= {add_odata_3_H_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_H_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};
            add_odata_dwc_5_L   [ADD_SIZE_5*i+:ADD_SIZE_5] <= {add_odata_3_L_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_L_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};

            add_odata_5_H       [ADD_SIZE_5*i+:ADD_SIZE_5] <= ( DWC_DATAFLOW == 0 ) ?
                                                              {add_odata_4_H        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_H [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}  
                                                             +{add_odata_3_H_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_H_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}
                                                             :{add_odata_4_H        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_H [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};
                                                             
            add_odata_5_L       [ADD_SIZE_5*i+:ADD_SIZE_5] <= ( DWC_DATAFLOW == 0 ) ?
                                                              {add_odata_4_L        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_L [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}
                                                             +{add_odata_3_L_       [ADD_SIZE_4*(  i+1  )-1],add_odata_3_L_[ADD_SIZE_4*(  i  )+:ADD_SIZE_4]}
                                                             :{add_odata_4_L        [ADD_SIZE_4*(  i+1  )-1],add_odata_4_L [ADD_SIZE_4*(  i  )+:ADD_SIZE_4]};
        end
    end

endmodule

//Add 8 ICH
module pe_array_dwc#(
    parameter       AXI_DATA_WIDTH  =   8,
    parameter       PE_ARRAY_1_v    =   8,
    parameter       TILE_NUM        =   2,
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3,
    parameter       ADD_SIZE_1      =   ADD_SIZE+1,
    parameter       ADD_SIZE_2      =   ADD_SIZE_1+1,
    parameter       ADD_SIZE_3      =   ADD_SIZE_2+1,
    parameter       A_BUF           =   0,
    parameter       B_BUF           =   1
)(
    input                                               clk,
                                                        wbuf_rst_A,
                                                        wbuf_rst_B,
                                                        WBUF_AB_LOAD_FLAG,
                                                        WBUF_AB_CACL_FLAG,
                                                        WBUF_LOAD_KER_FLAG,
    input                                               mult_en,
    input           [TILE_NUM-1:0]                      sign_flag_input,
    input           [WORD_SIZE-1:0]                     idata,
    input           [TILE_NUM-1:0]                      sign_flag_weight_dwc,
    input           [WORD_SIZE-1:0]                     wdata_dwc,
    output  reg     [ADD_SIZE_3-1:0]                    add_odata_3_H,add_odata_3_L
);
    reg             [TILE_NUM   -1:0]                   wdata_dwc_ich_sign_a,   wdata_dwc_ich_sign_b;
    reg             [WORD_SIZE  -1:0]                   wdata_dwc_ich_a,        wdata_dwc_ich_b;
    wire            [TILE_NUM   -1:0]                   wdata_dwc_ich_sign;     
    wire            [WORD_SIZE  -1:0]                   wdata_dwc_ich;      
    wire            [ADD_SIZE-1:0]     add_odata_H  ,add_odata_L;
    reg             [ADD_SIZE_1-1:0]   add_odata_1_H,add_odata_1_L;
    reg             [ADD_SIZE_2-1:0]   add_odata_2_H,add_odata_2_L;
    integer i;
    always @ ( posedge clk ) begin : WBUF_A_BLOCK
        if ( wbuf_rst_A ) begin
            wdata_dwc_ich_sign_a      <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b1}};
            wdata_dwc_ich_a           <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b0}};
        end else if ( WBUF_AB_LOAD_FLAG == A_BUF && WBUF_LOAD_KER_FLAG ) begin
            wdata_dwc_ich_sign_a      <=  sign_flag_weight_dwc;
            wdata_dwc_ich_a           <=  wdata_dwc;
        end
    end
    always @ ( posedge clk ) begin : WBUF_B_BLOCK
        if ( wbuf_rst_B ) begin
            wdata_dwc_ich_sign_b      <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b1}};
            wdata_dwc_ich_b           <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b0}};
        end else if ( WBUF_AB_LOAD_FLAG == B_BUF && WBUF_LOAD_KER_FLAG ) begin
            wdata_dwc_ich_sign_b      <=  sign_flag_weight_dwc;
            wdata_dwc_ich_b           <=  wdata_dwc;
        end
    end

    assign wdata_dwc_ich_sign = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_dwc_ich_sign_a   : wdata_dwc_ich_sign_b ;
    assign wdata_dwc_ich      = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_dwc_ich_a        : wdata_dwc_ich_b ;
    always @ ( posedge clk ) begin
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_1_H[ADD_SIZE_1*  i  +:ADD_SIZE_1] <= {add_odata_H  [ADD_SIZE  *(  i+1  )-1],add_odata_H  [ADD_SIZE  *(  i  )+:ADD_SIZE  ]};
//                                                          +{add_odata_H  [ADD_SIZE  *(  i+5  )-1],add_odata_H  [ADD_SIZE  *( i+4 )+:ADD_SIZE  ]};
            add_odata_1_L[ADD_SIZE_1*  i  +:ADD_SIZE_1] <= {add_odata_L  [ADD_SIZE  *(  i+1  )-1],add_odata_L  [ADD_SIZE  *(  i  )+:ADD_SIZE  ]};
//                                                          +{add_odata_L  [ADD_SIZE  *(  i+5  )-1],add_odata_L  [ADD_SIZE  *( i+4 )+:ADD_SIZE  ]};
        end
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_2_H[ADD_SIZE_2*  i  +:ADD_SIZE_2] <= {add_odata_1_H[ADD_SIZE_1*(  i+1  )-1],add_odata_1_H[ADD_SIZE_1*(  i  )+:ADD_SIZE_1]};
//                                                          +{add_odata_1_H[ADD_SIZE_1*(  i+3  )-1],add_odata_1_H[ADD_SIZE_1*( i+2 )+:ADD_SIZE_1]};
            add_odata_2_L[ADD_SIZE_2*  i  +:ADD_SIZE_2] <= {add_odata_1_L[ADD_SIZE_1*(  i+1  )-1],add_odata_1_L[ADD_SIZE_1*(  i  )+:ADD_SIZE_1]};
//                                                          +{add_odata_1_L[ADD_SIZE_1*(  i+3  )-1],add_odata_1_L[ADD_SIZE_1*( i+2 )+:ADD_SIZE_1]};
        end
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_3_H[ADD_SIZE_3*  i  +:ADD_SIZE_3] <= {add_odata_2_H[ADD_SIZE_2*(  i+1  )-1],add_odata_2_H[ADD_SIZE_2*(  i  )+:ADD_SIZE_2]};
//                                                          +{add_odata_2_H[ADD_SIZE_2*(  i+2  )-1],add_odata_2_H[ADD_SIZE_2*( i+1 )+:ADD_SIZE_2]};
            add_odata_3_L[ADD_SIZE_3*  i  +:ADD_SIZE_3] <= {add_odata_2_L[ADD_SIZE_2*(  i+1  )-1],add_odata_2_L[ADD_SIZE_2*(  i  )+:ADD_SIZE_2]};
//                                                          +{add_odata_2_L[ADD_SIZE_2*(  i+2  )-1],add_odata_2_L[ADD_SIZE_2*( i+1 )+:ADD_SIZE_2]};
        end
    end

    genvar x_var;
    generate    
    for ( x_var=0 ; x_var<1 ; x_var=x_var+1)begin
        mult_4_8x8  u_mult_4_8x8(
            .clk                                (clk),
            .mult_en                            (mult_en),
            .sign_flag_input                    (sign_flag_input        [(x_var)*(TILE_NUM)     +:(TILE_NUM)]),
            .idata                              (idata                  [(x_var)*(WORD_SIZE)    +:WORD_SIZE]),
            .sign_flag_weight                   (wdata_dwc_ich_sign     [(x_var)*(TILE_NUM)     +:(TILE_NUM)]),
            .wdata                              (wdata_dwc_ich          [(x_var)*(WORD_SIZE)    +:(WORD_SIZE)]),
            .add_odata                          ({add_odata_H           [(x_var)*(ADD_SIZE)     +:(ADD_SIZE)],add_odata_L[(x_var)*(ADD_SIZE)+:(ADD_SIZE)]})
        );
    end
    endgenerate
endmodule

//Add 8 ICH
module pe_array_8x1#(
    parameter       AXI_DATA_WIDTH  =   8,
    parameter       PE_ARRAY_1_v    =   8,
    parameter       TILE_NUM        =   2,
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3,
    parameter       ADD_SIZE_1      =   ADD_SIZE+1,
    parameter       ADD_SIZE_2      =   ADD_SIZE_1+1,
    parameter       ADD_SIZE_3      =   ADD_SIZE_2+1,
    parameter       A_BUF           =   0,
    parameter       B_BUF           =   1
)(
    input                                               clk,
                                                        wbuf_rst_A,
                                                        wbuf_rst_B,
                                                        WBUF_AB_LOAD_FLAG,
                                                        WBUF_AB_CACL_FLAG,
                                                        WBUF_LOAD_KER_FLAG,
    input                                               mult_en,
    input           [PE_ARRAY_1_v*TILE_NUM-1:0]         sign_flag_input,
    input           [PE_ARRAY_1_v*WORD_SIZE-1:0]        idata,
    input           [AXI_DATA_WIDTH*TILE_NUM-1:0]       sign_flag_weight,
    input           [AXI_DATA_WIDTH*WORD_SIZE-1:0]      wdata,
    output  reg     [ADD_SIZE_3-1:0]                    add_odata_3_H,add_odata_3_L
);
    reg             [TILE_NUM*PE_ARRAY_1_v-1:0]         wdata_8_ich_sign_a, wdata_8_ich_sign_b;
    reg             [WORD_SIZE*PE_ARRAY_1_v-1:0]        wdata_8_ich_a,wdata_8_ich_b;
    wire            [TILE_NUM*PE_ARRAY_1_v-1:0]         wdata_8_ich_sign;
    wire            [WORD_SIZE*PE_ARRAY_1_v-1:0]        wdata_8_ich;
    wire            [(PE_ARRAY_1_v)  *ADD_SIZE-1:0]     add_odata_H  ,add_odata_L;
    reg             [(PE_ARRAY_1_v/2)*ADD_SIZE_1-1:0]   add_odata_1_H,add_odata_1_L;
    reg             [(PE_ARRAY_1_v/4)*ADD_SIZE_2-1:0]   add_odata_2_H,add_odata_2_L;
    integer i;
    always @ ( posedge clk ) begin : WBUF_A_BLOCK
        if ( wbuf_rst_A ) begin
            wdata_8_ich_sign_a      <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b1}};
            wdata_8_ich_a           <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b0}};
        end else if ( WBUF_AB_LOAD_FLAG == A_BUF && WBUF_LOAD_KER_FLAG ) begin
            wdata_8_ich_sign_a      <=  sign_flag_weight;
            wdata_8_ich_a           <=  wdata;
        end
    end
    always @ ( posedge clk ) begin : WBUF_B_BLOCK
        if ( wbuf_rst_B ) begin
            wdata_8_ich_sign_b      <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b1}};
            wdata_8_ich_b           <=  0;//{PE_ARRAY_1_v*WORD_SIZE,{1'b0}};
        end else if ( WBUF_AB_LOAD_FLAG == B_BUF && WBUF_LOAD_KER_FLAG ) begin
            wdata_8_ich_sign_b      <=  sign_flag_weight;
            wdata_8_ich_b           <=  wdata;
        end
    end

    assign wdata_8_ich_sign = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_8_ich_sign_a   : wdata_8_ich_sign_b ;
    assign wdata_8_ich      = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_8_ich_a        : wdata_8_ich_b ;
    always @ ( posedge clk ) begin
        for ( i=0 ; i<4 ; i=i+1 ) begin
            add_odata_1_H[ADD_SIZE_1*  i  +:ADD_SIZE_1] <= {add_odata_H  [ADD_SIZE  *(  i+1  )-1],add_odata_H  [ADD_SIZE  *(  i  )+:ADD_SIZE  ]}
                                                          +{add_odata_H  [ADD_SIZE  *(  i+5  )-1],add_odata_H  [ADD_SIZE  *( i+4 )+:ADD_SIZE  ]};
            add_odata_1_L[ADD_SIZE_1*  i  +:ADD_SIZE_1] <= {add_odata_L  [ADD_SIZE  *(  i+1  )-1],add_odata_L  [ADD_SIZE  *(  i  )+:ADD_SIZE  ]}
                                                          +{add_odata_L  [ADD_SIZE  *(  i+5  )-1],add_odata_L  [ADD_SIZE  *( i+4 )+:ADD_SIZE  ]};
        end
        for ( i=0 ; i<2 ; i=i+1 ) begin
            add_odata_2_H[ADD_SIZE_2*  i  +:ADD_SIZE_2] <= {add_odata_1_H[ADD_SIZE_1*(  i+1  )-1],add_odata_1_H[ADD_SIZE_1*(  i  )+:ADD_SIZE_1]}
                                                          +{add_odata_1_H[ADD_SIZE_1*(  i+3  )-1],add_odata_1_H[ADD_SIZE_1*( i+2 )+:ADD_SIZE_1]};
            add_odata_2_L[ADD_SIZE_2*  i  +:ADD_SIZE_2] <= {add_odata_1_L[ADD_SIZE_1*(  i+1  )-1],add_odata_1_L[ADD_SIZE_1*(  i  )+:ADD_SIZE_1]}
                                                          +{add_odata_1_L[ADD_SIZE_1*(  i+3  )-1],add_odata_1_L[ADD_SIZE_1*( i+2 )+:ADD_SIZE_1]};
        end
        for ( i=0 ; i<1 ; i=i+1 ) begin
            add_odata_3_H[ADD_SIZE_3*  i  +:ADD_SIZE_3] <= {add_odata_2_H[ADD_SIZE_2*(  i+1  )-1],add_odata_2_H[ADD_SIZE_2*(  i  )+:ADD_SIZE_2]}
                                                          +{add_odata_2_H[ADD_SIZE_2*(  i+2  )-1],add_odata_2_H[ADD_SIZE_2*( i+1 )+:ADD_SIZE_2]};
            add_odata_3_L[ADD_SIZE_3*  i  +:ADD_SIZE_3] <= {add_odata_2_L[ADD_SIZE_2*(  i+1  )-1],add_odata_2_L[ADD_SIZE_2*(  i  )+:ADD_SIZE_2]}
                                                          +{add_odata_2_L[ADD_SIZE_2*(  i+2  )-1],add_odata_2_L[ADD_SIZE_2*( i+1 )+:ADD_SIZE_2]};
        end
    end
    genvar x_var;
    generate    
    for ( x_var=0 ; x_var<PE_ARRAY_1_v ; x_var=x_var+1)begin
        mult_4_8x8  u_mult_4_8x8(
            .clk                                (clk),
            .mult_en                            (mult_en),
            .sign_flag_input                    (sign_flag_input        [(x_var)*(TILE_NUM)     +:(TILE_NUM)]),
            .idata                              (idata                  [(x_var)*(WORD_SIZE)    +:WORD_SIZE]),
            .sign_flag_weight                   (wdata_8_ich_sign       [(x_var)*(TILE_NUM)     +:(TILE_NUM)]),
            .wdata                              (wdata_8_ich            [(x_var)*(WORD_SIZE)    +:(WORD_SIZE)]),
            .add_odata                          ({add_odata_H           [(x_var)*(ADD_SIZE)     +:(ADD_SIZE)],add_odata_L[(x_var)*(ADD_SIZE)+:(ADD_SIZE)]})
        );
    end
    endgenerate
endmodule

module mult_4_8x8#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADD_SIZE        =   HALF_SIZE*3
)(
    input                               clk,
    input                               mult_en,
    input       [1:0]                   sign_flag_input,
                                        sign_flag_weight,
    input       [WORD_SIZE-1:0]         idata,
                                        wdata,
    output  reg [ADD_SIZE*2-1:0]        add_odata
);

    wire        [WORD_SIZE*4-1:0]       mult_data;
    wire        [WORD_SIZE-1:0]         A,B,C,D;
    wire        [ADD_SIZE-1:0]          A_,B_,C_,D_;

    reg                                 sign_flag_LL,
                                        sign_flag_LH,
                                        sign_flag_HL,
                                        sign_flag_HH;
always @ ( posedge clk ) begin
    sign_flag_LL    <= sign_flag_input[0]^sign_flag_weight[0];
    sign_flag_LH    <= sign_flag_input[0]^sign_flag_weight[1];
    sign_flag_HL    <= sign_flag_input[1]^sign_flag_weight[0];
    sign_flag_HH    <= sign_flag_input[1]^sign_flag_weight[1];
end
/*
mult_8x8 #(WORD_SIZE,HALF_SIZE) LL_mult (
    .clk(clk),
    .mult_en(mult_en),
    .idata(idata[HALF_SIZE*0+:HALF_SIZE]),
    .wdata(wdata[HALF_SIZE*0+:HALF_SIZE]),
    .odata(mult_data[WORD_SIZE*0+:WORD_SIZE])
);
mult_8x8 #(WORD_SIZE,HALF_SIZE) LH_mult (
    .clk(clk),
    .mult_en(mult_en),
    .idata(idata[HALF_SIZE*0+:HALF_SIZE]),
    .wdata(wdata[HALF_SIZE*1+:HALF_SIZE]),
    .odata(mult_data[WORD_SIZE*1+:WORD_SIZE])
);
mult_8x8 #(WORD_SIZE,HALF_SIZE) HL_mult (
    .clk(clk),
    .mult_en(mult_en),
    .idata(idata[HALF_SIZE*1+:HALF_SIZE]),
    .wdata(wdata[HALF_SIZE*0+:HALF_SIZE]),
    .odata(mult_data[WORD_SIZE*2+:WORD_SIZE])
);
mult_8x8 #(WORD_SIZE,HALF_SIZE) HH_mult (
    .clk(clk),
    .mult_en(mult_en),
    .idata(idata[HALF_SIZE*1+:HALF_SIZE]),
    .wdata(wdata[HALF_SIZE*1+:HALF_SIZE]),
    .odata(mult_data[WORD_SIZE*3+:WORD_SIZE])
);
*/
/*
    
    * idata   { IH , IL }
    * wdata   { WH , WL }
    * --------------------
    *           IL x WL       A mult_data[WORD_SIZE*1-1-:WORD_SIZE]
    *     IL x WH  << 8       B mult_data[WORD_SIZE*2-1-:WORD_SIZE]
    *     IH x WL  << 8       C mult_data[WORD_SIZE*3-1-:WORD_SIZE]
    * IH x WH      <<16       D mult_data[WORD_SIZE*4-1-:WORD_SIZE]
    * 16x16 - one feat tile
    * add_odata[23:0]  A+(B<<8)
    * add_odata[47:24] C+(D<<8)

    * 16x8  - one feat tile
    * add_odata[23:0]  A+(B<<8)
    * add_odata[47:24] x

    * 8x16  - two feat tile
    * add_odata[23:0]  A+(B<<8)
    * add_odata[47:24] C+(D<<8)

    * 8x8   - two feat tile
    * add_odata[23:0]  A
    * add_odata[47:24] C
*/
    assign  A  = mult_data[WORD_SIZE*0+:WORD_SIZE];
    assign  B  = mult_data[WORD_SIZE*2+:WORD_SIZE];
    assign  C  = mult_data[WORD_SIZE*1+:WORD_SIZE];
    assign  D  = mult_data[WORD_SIZE*3+:WORD_SIZE];

    assign  A_ = ( sign_flag_LL ) ? -({{HALF_SIZE{A[WORD_SIZE-1]}},A}) : {{HALF_SIZE{1'b0}},A};
    assign  B_ = ( sign_flag_LH ) ? -({{HALF_SIZE{B[WORD_SIZE-1]}},B}) : {{HALF_SIZE{1'b0}},B};
    assign  C_ = ( sign_flag_HL ) ? -({{HALF_SIZE{C[WORD_SIZE-1]}},C}) : {{HALF_SIZE{1'b0}},C};
    assign  D_ = ( sign_flag_HH ) ? -({{HALF_SIZE{D[WORD_SIZE-1]}},D}) : {{HALF_SIZE{1'b0}},D};
always @ ( posedge clk ) begin
    add_odata[ADD_SIZE*0+:ADD_SIZE]   <=  $signed(A_)+($signed(B_)<<HALF_SIZE);   // * TILE_SIZE[0]
    add_odata[ADD_SIZE*1+:ADD_SIZE]   <=  $signed(C_)+($signed(D_)<<HALF_SIZE);   // * TILE_SIZE[1]
end


mult_25x18 mult_25x18_L_weight(
    .clk(clk),
    .mult_en(mult_en),
    .idata({idata[HALF_SIZE*1+:HALF_SIZE],{HALF_SIZE{1'b0}},idata[HALF_SIZE*0+:HALF_SIZE]}),
    .wdata(wdata[HALF_SIZE*0+:HALF_SIZE]),
    .odata(mult_data[WORD_SIZE*0+:WORD_SIZE*2])
);
mult_25x18 mult_25x18_H_weight(
    .clk(clk),
    .mult_en(mult_en),
    .idata({idata[HALF_SIZE*1+:HALF_SIZE],{HALF_SIZE{1'b0}},idata[HALF_SIZE*0+:HALF_SIZE]}),
    .wdata(wdata[HALF_SIZE*1+:HALF_SIZE]),
    .odata(mult_data[WORD_SIZE*2+:WORD_SIZE*2])
);

endmodule

module mult_25x18#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADATA_SIZE  =   HALF_SIZE*3,    // Can't Over 25
    parameter       BDATA_SIZE  =   HALF_SIZE,      // Can't Over 18
    parameter       DSPOUT_SIZE =   HALF_SIZE*4
)(
    input                               clk,
                                        mult_en,
    input       [ADATA_SIZE-1:0]        idata,
    input       [BDATA_SIZE-1:0]        wdata,
    output      [DSPOUT_SIZE-1:0]       odata
);

`ifdef VIVADO_MODE
    mult_25x18_only_dsp mult_25x18_only_dsp(
        .clk        (clk),
        .mult_en    (mult_en),
        .idata      (idata),
        .wdata      (wdata[HALF_SIZE*0+:HALF_SIZE]),
        .odata      (odata[WORD_SIZE*0+:WORD_SIZE*2])
    );
`else
    mult_2_8x8_multiplier u_mult_2_8x8_multiplier(
        .clk        (clk),    
        .mult_en    (mult_en),        
        .idata      ({idata[HALF_SIZE*1+HALF_SIZE+:HALF_SIZE],idata[HALF_SIZE*0+:HALF_SIZE]}),    
        .wdata      (wdata),    
        .odata      (odata)
    );
`endif

endmodule


(* use_dsp ="yes" *)module mult_25x18_only_dsp#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       ADATA_SIZE  =   HALF_SIZE*3,    // Can't Over 25
    parameter       BDATA_SIZE  =   HALF_SIZE,      // Can't Over 18
    parameter       DSPOUT_SIZE =   HALF_SIZE*4
)(
    input                               clk,
                                        mult_en,
    input       [ADATA_SIZE-1:0]        idata,
    input       [BDATA_SIZE-1:0]        wdata,
    output  reg [DSPOUT_SIZE-1:0]       odata
);
    always @ ( posedge clk )
        if ( mult_en )
            odata   <=  idata * wdata;
        else
            odata   <=  0;
endmodule

module mult_2_8x8_multiplier#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2
)(
    input                               clk,
                                        mult_en,
    input       [WORD_SIZE-1:0]         idata,
    input       [HALF_SIZE-1:0]         wdata,
    output reg  [WORD_SIZE*2-1:0]       odata
);
    always @ ( posedge clk ) begin
        if ( mult_en ) begin
           odata[WORD_SIZE*0+:WORD_SIZE]    <= idata[HALF_SIZE*0+:HALF_SIZE] * wdata;
           odata[WORD_SIZE*1+:WORD_SIZE]    <= idata[HALF_SIZE*1+:HALF_SIZE] * wdata;
        end else begin
            odata[WORD_SIZE*0+:WORD_SIZE]   <= 0;
            odata[WORD_SIZE*1+:WORD_SIZE]   <= 0;
        end 
    end
endmodule