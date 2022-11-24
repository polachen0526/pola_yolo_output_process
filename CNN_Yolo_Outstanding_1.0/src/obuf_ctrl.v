`timescale 1ns / 1ps
module OBUF_CTRL#(
    parameter       PE_ARRAY_4_v                =   8,
    parameter       PE_ARRAY_3_v                =   3,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_1_2_v              =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v              =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       BK_ADDR_SIZE                =   9,          // one bank length is 408 = 9'b1_1001_1000 9 bits
    parameter       BK_NUM                      =   3,          // 3 Output Bank form a 3x3 conv output channel                                                            // 1 Output Bank form a 1x1 conv output channel
    parameter       HALF_ADDR_SIZE              =   6,
    parameter       SETTING_SIZE                =   4,
    parameter       OBUF_S_INIT                 =   0,
    parameter       OBUF_S_FSM_START            =   1,
    parameter       OBUF_S_CACL                 =   2,
    parameter       OBUF_S_WAIT_RST             =   3,
    parameter       READ_ACCU_DELAY             =   6, 
    parameter       READ_POOL_DELAY             =   1,
    parameter       WRITE_LAST_ICH_DELAY        =   22,         
    parameter       WRITE_NOT_JUST_DELAY        =   8,        
    parameter       WRITE_POOL_DELAY            =   3,
    parameter       DWC_DELAY                   =   19,
    parameter       PWC_DWC_DELAY               =   34,
    parameter       FIN_OBUF_S_INIT             =   0,
    parameter       FIN_OBUF_S_MASTER_READ      =   1,
    parameter       FIN_OBUF_S_NEXT_TILE_LAYER  =   2,
    parameter       FIN_OBUF_S_WAIT_RST         =   3,
    parameter       WBUF_S_INIT                 =   0,
    parameter       WBUF_S_LOADING_KERNEL       =   1,
    parameter       WBUF_S_LOADING_BATCH_WEIGHT =   2,
    parameter       WBUF_S_DWC_LOADING_KERNEL   =   3,
    parameter       WBUF_S_DWC_LOADING_KERNEL_LAST  =   4,
    parameter       WBUF_S_DWC_LOADING_BATCH_WEIGHT =   5,
    parameter       OBUF_S_POOL_INIT            =   0,
    parameter       OBUF_S_POOL_WAIT_CONV_WRITE_DONE = 1,
    parameter       OBUF_S_POOL_CACL            =   2,
    parameter       OBUF_S_POOL_WAIT_RST        =   3,
    parameter       DWC_S_INIT                  =   0,
    parameter       DWC_S_PWC                   =   1, 
    parameter       DWC_S_DWC                   =   2,
    parameter       DWC_S_PWC_DWC               =   3,
    parameter       DWC_CACL_S_INIT             =   0,
    parameter       DWC_CACL_S_WAIT_LINE_BUFFER =   1,
    parameter       DWC_CACL_S_FSM_START        =   2,  
    parameter       DWC_CACL_S_WAIT_RST         =   3,
    parameter       DECONV_S_INIT_1ST           =   0,
    parameter       DECONV_S_ODD_TILE           =   1,
    parameter       DECONV_S_INIT_2ND           =   2,
    parameter       DECONV_S_EVEN_TILE          =   3,
    parameter       A_BUF                       =   0,
    parameter       B_BUF                       =   1,
    parameter       AXI_DATA_WIDTH              =   8,
    parameter       SPE_TO_LINE_BUFFER          =   1,
    parameter       OBUF_TO_LINE_BUFFER         =   2,
    parameter       CONV_MODE                   =   2'b00,
    parameter       FC_MODE                     =   2'b01,
    parameter       DECONV_MODE                 =   2'b10,
    parameter       DWC_MODE                    =   2'b11
)(
    input                                           clk,
                                                    rst,
    //======================== WBUF ========================
                                                    wbuf_rst_A,
                                                    wbuf_rst_B,
    input                                           WBUF_RLAST,
                                                    WBUF_VALID_FLAG,
                                                    WBUF_CHOOSE,
    output  reg     [AXI_DATA_WIDTH-1:0]            WBUF_LOAD_OCH_FLAG,
    output  reg                                     WBUF_AB_LOAD_FLAG,
                                                    WBUF_AB_CACL_FLAG,
    output  reg                                     WBUF_CONV_OR_DWC_SPE_FLAG,
    output  reg     [3:0]                           wbuf_addr_ker_cont,
    output  reg                                     wbuf_addr_spe_weight_cont,
    output  reg     [AXI_DATA_WIDTH*3-1:0]          WBUF_SPE_LOAD_OCH_FLAG,
    output  reg     [1:0]                           DWC_DATAFLOW,
    //======================== WBUF ========================
    //======================== LAYER INFO ==================
    output reg                                      have_pool_ing,
    input                                           pwc_dwc_combine_,
                                                    pwc_dwc_combine,
                                                    concat_output_control,
                                                    have_pool,
                                                    have_batch_,
                                                    have_batch,
                                                    have_batch_dwc_,
                                                    have_batch_dwc,
                                                    Is_Upsample,
                                                    bk_combine,
                                                    bk_combine_,
                                                    IBUF_DATA_TRANS_START,
    input           [SETTING_SIZE-1:0]              ker_size,
                                                    ker_strd,
    input           [1:0]                           pool_size,
                                                    pool_strd,
    input           [1:0]                           Bit_serial,
    input           [HALF_ADDR_SIZE-1'b1:0]         obuf_tile_size_x,         //end address of write mode 
                                                    obuf_tile_size_y,
                                                    obuf_tile_size_x_aft_pool,
                                                    obuf_tile_size_y_aft_pool,
    //======================== LAYER INFO ==================
    //======================== TILE  INFO ==================
    input           [1:0]                           hw_icp_able_cacl,
                                                    hw_ocp_able_cacl,
    input                                           have_accu,
                                                    have_last_ich_,
                                                    have_last_ich,
                                                    Is_last_ker,
                                                    Is_Final_Tile,
    //======================== TILE  INFO ==================
    output          [BK_NUM-1:0]                    read_en,
    output          [BK_NUM*BK_ADDR_SIZE-1:0]       read_oaddr,
    output          [BK_NUM-1:0]                    write_en,
    output          [BK_NUM*BK_ADDR_SIZE-1:0]       write_iaddr,
    output                                          pool_ctrl,
    //======================== USER CTRL ========================
    //input                                           user_obuf_read_en,
    input           [HALF_ADDR_SIZE-1'b1:0]         user_obuf_oaddr_x,
                                                    user_obuf_oaddr_y,
    input           [1:0]                           user_obuf_oaddr_z,
    input                                           Master_Output_Finish,
    output  reg                                     OBUF_FINISH_FLAG, //obuf_Finish
    output  reg                                     For_State_Finish,
                                                    Pad_Start_OBUF_FINISH,
    //======================== USER CTRL ========================
    input           [1:0]                           CONV_FLAG,
                                                    CONV_FLAG_,
    output  reg                                     IRQ_TO_MASTER_CTRL,
    output  reg     [PE_ARRAY_3_v-1:0]              spe_mult_en,
                                                    spe_dwc_mult_en,
    output  reg     [PE_ARRAY_2_v*PE_ARRAY_3_v-1:0] mult_en,
    output  reg                                     DECONVING,


    output  reg     [1:0]                           DEBUG_obuf_state,
                                                    DEBUG_obuf_pool_s,
                                                    DEBUG_obuf_finish_state
);
    reg             [1:0]                           obuf_state, 
                                                    obuf_state_n;                        
    wire                                            DECONV_ODD_EVEN_FLAG ;         
    reg             [1:0]                           deconv_s, 
                                                    deconv_s_n;                        
    reg             [1:0]                           obuf_pool_s, 
                                                    obuf_pool_s_n;
    //reg                                             OBUF_FINISH_FLAG;
    reg             [4:0]                           pipline_cont;
    reg                                             write_fc_fsm_start,
                                                    read_fc_fsm_start,
                                                    accu_fsm_start,
                                                    pool_fsm_start,
                                                    write_fsm_start,
                                                    write_pool_fsm_start;
    reg             [1:0]                           obuf_finish_state,
                                                    obuf_finish_state_n;
    wire                                            WRITE_STATE_FINISH,
    //======================== WBUF ========================
                                                    wbuf_rst;
    reg             [2:0]                           wbuf_s, 
                                                    wbuf_s_n;
    reg                                             WBUF_RLAST_1,
                                                    WBUF_VALID_FLAG_1,
                                                    WBUF_RLAST_2,
                                                    WBUF_VALID_FLAG_2;
    wire                                            WBUF_KERNEL_LOADING_FIN,
                                                    WBUF_BATCH_WEIGHT_LOADING_FIN;
    wire                                            WBUF_LOAD_FLAG,
                                                    WBUF_DWC_LAST_LOAD_FLAG;
    wire                                            WBUF_SPE_LOAD_FLAG;
    wire                                            WBUF_ADDR_OCH_CONT_FLAG;
    reg             [2:0]                           wbuf_addr_och_cont;
    wire                                            WBUF_ADDR_KER_CONT_FLAG;
    reg             [AXI_DATA_WIDTH*3-1:0]          WBUF_SPE_LOAD_OCH_FLAG_reg;
    reg             [1:0]                           wbuf_addr_spe_och_cont;
    wire                                            WBUF_ADDR_SPE_OCH_CONT_FLAG,
                                                    WBUF_ADDR_SPE_WEIGHT_CONT_FLAG;
    //======================== WBUF ========================
    wire            [SETTING_SIZE-1:0]              read_ker_size, 
                                                    read_ker_strd,
                                                    write_ker_size,
                                                    write_ker_strd;
    reg             [1:0]                           pwc_dwc_s, 
                                                    pwc_dwc_s_n;
    reg             [1:0]                           dwc_s,  
                                                    dwc_s_n;
    wire                                            DWC_LINEBUFFER_READY;
    wire                                            DWC_ONLY_WRITE_FLAG,
                                                    PWC_DWC_ONLY_WRITE_FLAG;
    reg             [5:0]                           pipline_cont_dwc;
    integer                                         i;


always @ ( posedge clk ) begin
    DEBUG_obuf_state                <= obuf_state;    
    DEBUG_obuf_pool_s               <= obuf_pool_s;    
    DEBUG_obuf_finish_state         <= obuf_finish_state;            
end



always @ ( posedge clk ) begin
    if ( ( obuf_pool_s == OBUF_S_POOL_CACL || obuf_pool_s == OBUF_S_POOL_WAIT_RST ) )
        have_pool_ing <= 1 ;
    else
        have_pool_ing <= 0 ;
end
reg [(PE_ARRAY_2_v)-1:0] ICH_ABLE_CACL;
reg [(PE_ARRAY_3_v)-1:0] OCH_ABLE_CACL;
always @ ( posedge clk ) begin
    if ( CONV_FLAG == CONV_MODE ) begin
        if ( ker_size == 3 ) begin
            ICH_ABLE_CACL       <= 3'b111;
        end else if ( hw_icp_able_cacl == 1 ) begin
            ICH_ABLE_CACL       <= 3'b001;
        end else if ( hw_icp_able_cacl == 2 ) begin
            ICH_ABLE_CACL       <= 3'b011;
        end else if ( hw_icp_able_cacl == 3 ) begin
            ICH_ABLE_CACL       <= 3'b111;
        end else begin
            ICH_ABLE_CACL       <= 3'b000;
        end
//    end else if ( CONV_FLAG == DWC_MODE ) begin
    end else if ( pwc_dwc_s == DWC_S_PWC ) begin
        if ( hw_icp_able_cacl == 1 ) begin
            ICH_ABLE_CACL       <= 3'b001;
        end else if ( hw_icp_able_cacl == 2 ) begin
            ICH_ABLE_CACL       <= 3'b011;
        end else if ( hw_icp_able_cacl == 3 ) begin
            ICH_ABLE_CACL       <= 3'b111;
        end else begin
            ICH_ABLE_CACL       <= 3'b000;
        end
    end else if ( pwc_dwc_s == DWC_S_PWC_DWC ) begin
        if ( hw_icp_able_cacl == 1 ) begin
            ICH_ABLE_CACL       <= 3'b101;
        end else if ( hw_icp_able_cacl == 2 ) begin
            ICH_ABLE_CACL       <= 3'b111;
        end else if ( hw_icp_able_cacl == 3 ) begin
            ICH_ABLE_CACL       <= 3'b111;
        end else begin
            ICH_ABLE_CACL       <= 3'b100;
        end
    end else if ( pwc_dwc_s == DWC_S_DWC ) begin
            ICH_ABLE_CACL       <= 3'b100;
    end else if ( CONV_FLAG == FC_MODE ) begin
        if ( hw_icp_able_cacl == 1 ) begin
            ICH_ABLE_CACL       <= 3'b001;
        end else if ( hw_icp_able_cacl == 2 ) begin
            ICH_ABLE_CACL       <= 3'b011;
        end else if ( hw_icp_able_cacl == 3 ) begin
            ICH_ABLE_CACL       <= 3'b111;
        end else begin
            ICH_ABLE_CACL       <= 3'b000;
        end
    end else if ( CONV_FLAG == DECONV_MODE ) begin
            ICH_ABLE_CACL       <= 3'b111;
    end else begin
        ICH_ABLE_CACL           <= 3'b000;
    end
end

always @ ( posedge clk ) begin
    if ( CONV_FLAG == CONV_MODE ) begin
        if ( ker_size == 3 ) begin
            OCH_ABLE_CACL       <= 3'b111;
        end else if ( hw_ocp_able_cacl == 1 ) begin
            OCH_ABLE_CACL       <= 3'b001;
        end else if ( hw_ocp_able_cacl == 2 ) begin
            OCH_ABLE_CACL       <= 3'b011;
        end else if ( hw_ocp_able_cacl == 3 ) begin
            OCH_ABLE_CACL       <= 3'b111;
        end else begin
            OCH_ABLE_CACL       <= 3'b000;
        end
//    end else if ( CONV_FLAG == DWC_MODE ) begin
    end else if ( CONV_FLAG == DWC_MODE ) begin
        if ( hw_ocp_able_cacl == 1 ) begin
            OCH_ABLE_CACL       <= 3'b001;
        end else if ( hw_ocp_able_cacl == 2 ) begin
            OCH_ABLE_CACL       <= 3'b011;
        end else if ( hw_ocp_able_cacl == 3 ) begin
            OCH_ABLE_CACL       <= 3'b111;
        end else begin
            OCH_ABLE_CACL       <= 3'b000;
        end
    end else if ( CONV_FLAG == FC_MODE ) begin
        if ( hw_ocp_able_cacl == 1 ) begin
            OCH_ABLE_CACL       <= 3'b001;
        end else if ( hw_ocp_able_cacl == 2 ) begin
            OCH_ABLE_CACL       <= 3'b011;
        end else if ( hw_ocp_able_cacl == 3 ) begin
            OCH_ABLE_CACL       <= 3'b111;
        end else begin
            OCH_ABLE_CACL       <= 3'b000;
        end
    end else if ( CONV_FLAG == DECONV_MODE ) begin
            OCH_ABLE_CACL       <= 3'b111;
    end else begin
        OCH_ABLE_CACL           <= 3'b000;
    end
end
/*
mult_en usaga 72bit
[ICH:ICH]-[OCH-OCH]
    [ 2 ]        [ 1 ]       [ 0 ]     BIT
23:16- 0: 7 / 15:8- 0: 7 / 0:7- 0: 7
    [ 5 ]        [ 4 ]       [ 3 ]     BIT
23:16-15: 8 / 15:8-15: 8 / 0:7-15: 8
    [ 8 ]        [ 7 ]       [ 6 ]     BIT
23:16-23:16 / 15:8-23:16 / 0:7-23:16
*/
always @ ( posedge clk ) begin
    if ( rst ) begin
        mult_en <= 0;
    end else if ( obuf_state == OBUF_S_CACL || obuf_state == OBUF_S_FSM_START )  begin
        for ( i=0 ; i<PE_ARRAY_3_v ; i=i+1 ) begin
            mult_en[ (i) * 3 + 0 ] <= ( ICH_ABLE_CACL[0] && OCH_ABLE_CACL[(i)] );
            mult_en[ (i) * 3 + 1 ] <= ( ICH_ABLE_CACL[1] && OCH_ABLE_CACL[(i)] );
            mult_en[ (i) * 3 + 2 ] <= ( ICH_ABLE_CACL[2] && OCH_ABLE_CACL[(i)] );
        end
    end else begin
        mult_en <= 0;
    end
end


always @ ( posedge clk ) begin
    if ( rst )
        spe_mult_en <= 0;
    else if ( have_last_ich && obuf_state == OBUF_S_CACL && pwc_dwc_s != DWC_S_DWC )
        spe_mult_en <= OCH_ABLE_CACL;
    else
        spe_mult_en <= 0;
end
always @ ( posedge clk ) begin
    if ( rst )
        spe_dwc_mult_en <= 0;
    else if ( obuf_state == OBUF_S_CACL && ( pwc_dwc_s == DWC_S_DWC || pwc_dwc_s == DWC_S_PWC_DWC ) ) 
        spe_dwc_mult_en <= OCH_ABLE_CACL;
    else
        spe_dwc_mult_en <= 0;
     
end
always @ ( posedge clk ) begin
    if ( rst ) 
        IRQ_TO_MASTER_CTRL  <= 1'b0;
    else if ( obuf_pool_s == OBUF_S_POOL_CACL || obuf_pool_s == OBUF_S_WAIT_RST )
        IRQ_TO_MASTER_CTRL  <= 1'b1;
    else if ( have_pool == 0 && have_last_ich )
        IRQ_TO_MASTER_CTRL <=  1'b1;
    else
        IRQ_TO_MASTER_CTRL <=  1'b0; 
end
always @ ( posedge clk ) begin
    if ( deconv_s == DECONV_S_ODD_TILE || deconv_s == DECONV_S_EVEN_TILE ) begin
        DECONVING <= 1'b1;
    end else begin
        DECONVING <= 1'b0;
    end
end

assign DECONV_ODD_EVEN_FLAG = ( deconv_s == DECONV_S_EVEN_TILE );

always @ ( posedge clk ) begin
    deconv_s            <= deconv_s_n;
end
always @ ( * ) begin
    case ( deconv_s )
        DECONV_S_INIT_1ST : begin
            if ( CONV_FLAG == DECONV_MODE && IBUF_DATA_TRANS_START )
                deconv_s_n  = DECONV_S_ODD_TILE;
            else
                deconv_s_n  = DECONV_S_INIT_1ST;
        end
        DECONV_S_ODD_TILE : begin // Obuf Address : 0 2 4 ... 2n
            if ( WRITE_STATE_FINISH )
                deconv_s_n  = DECONV_S_INIT_2ND;
            else
                deconv_s_n  = DECONV_S_ODD_TILE;
        end
        DECONV_S_INIT_2ND : begin
            if ( IBUF_DATA_TRANS_START )
                deconv_s_n  = DECONV_S_EVEN_TILE;
            else
                deconv_s_n  = DECONV_S_INIT_2ND;
        end        
        DECONV_S_EVEN_TILE : begin // Obuf Address : 1 3 ... 2n+1
            if ( WRITE_STATE_FINISH )
                deconv_s_n  = DECONV_S_INIT_1ST;
            else
                deconv_s_n  = DECONV_S_EVEN_TILE;
        end
        default : begin
            deconv_s_n  = DECONV_S_INIT_1ST;
        end
    endcase
end


always @ ( posedge clk ) begin
    if ( rst )
        obuf_pool_s     <= OBUF_S_POOL_INIT;
    else
        obuf_pool_s     <= obuf_pool_s_n;
end
always @ ( * ) begin
    case ( obuf_pool_s )    
        OBUF_S_POOL_INIT : begin
            if ( WRITE_STATE_FINISH && have_pool )
                obuf_pool_s_n   = OBUF_S_POOL_WAIT_CONV_WRITE_DONE;
            else
                obuf_pool_s_n   = OBUF_S_POOL_INIT;
        end
        OBUF_S_POOL_WAIT_CONV_WRITE_DONE : begin
            if ( concat_output_control ) begin
                if ( obuf_finish_state == FIN_OBUF_S_NEXT_TILE_LAYER )
                    obuf_pool_s_n   = OBUF_S_POOL_CACL;
                else
                    obuf_pool_s_n   = OBUF_S_POOL_WAIT_CONV_WRITE_DONE;
            end else begin
                obuf_pool_s_n   = OBUF_S_POOL_CACL;
            end
        end
        OBUF_S_POOL_CACL : begin
            if ( WRITE_STATE_FINISH )
                obuf_pool_s_n   = OBUF_S_POOL_WAIT_RST;
            else
                obuf_pool_s_n   = OBUF_S_POOL_CACL;
        end
        OBUF_S_POOL_WAIT_RST : begin
            obuf_pool_s_n   = OBUF_S_POOL_WAIT_RST;
        end
        default : begin
            obuf_pool_s_n   = OBUF_S_POOL_INIT;
        end
    endcase
end

always @ ( posedge clk ) begin
    if ( rst )
        obuf_state      <= OBUF_S_INIT;
    else 
        obuf_state      <= obuf_state_n;
end

always @ ( * ) begin
    case ( obuf_state )
        OBUF_S_INIT : begin
            if ( IBUF_DATA_TRANS_START || obuf_pool_s == OBUF_S_POOL_CACL || pwc_dwc_s == DWC_S_DWC ) begin
                obuf_state_n    = OBUF_S_FSM_START;
            end else
                obuf_state_n    = OBUF_S_INIT;
        end
        OBUF_S_FSM_START : begin
            obuf_state_n        = OBUF_S_CACL;
        end
        OBUF_S_CACL : begin
            if ( WRITE_STATE_FINISH )
                obuf_state_n        = OBUF_S_WAIT_RST;
            else
                obuf_state_n        = OBUF_S_CACL;
        end
        OBUF_S_WAIT_RST : begin
            if ( obuf_pool_s == OBUF_S_POOL_WAIT_CONV_WRITE_DONE && concat_output_control && obuf_finish_state != FIN_OBUF_S_NEXT_TILE_LAYER )
                obuf_state_n        = OBUF_S_WAIT_RST;
            else
                obuf_state_n        = OBUF_S_INIT;
        end
        default : begin
            obuf_state_n        = OBUF_S_INIT;
        end
    endcase
end
always @ ( posedge clk ) begin
    if ( rst )
        pipline_cont        <= 0;
    else if ( obuf_state == OBUF_S_INIT )
        pipline_cont        <= 0;
    else if ( obuf_state != OBUF_S_INIT && (&pipline_cont) == 0 )
        pipline_cont        <= pipline_cont + 1'b1;

end
always @ ( posedge clk ) begin
    if ( rst ) begin
        read_fc_fsm_start   <= 0;
        write_fc_fsm_start  <= 0;
        accu_fsm_start      <= 0;
        pool_fsm_start      <= 0;
        write_fsm_start     <= 0;
        write_pool_fsm_start<= 0;
    end else begin
        read_fc_fsm_start   <= ( pipline_cont == READ_ACCU_DELAY        && CONV_FLAG == FC_MODE     && have_accu )              ? 1'b1 // FC MODE       , [USE]
                                                                                                                                : 1'b0;// UNKNOW        , [UNUSE]
        write_fc_fsm_start  <= ( pipline_cont == WRITE_LAST_ICH_DELAY   && CONV_FLAG == FC_MODE     && have_last_ich == 1'b1 )  ? 1'b1 // FC MODE       , [USE]
                             : ( pipline_cont == WRITE_NOT_JUST_DELAY   && CONV_FLAG == FC_MODE     && have_last_ich == 1'b0 )  ? 1'b1 // FC MODE       , [USE]
                                                                                                                                : 1'b0;// UNKNOW        , [UNUSE]
        accu_fsm_start      <= ( obuf_pool_s != OBUF_S_POOL_INIT )                                                              ? 1'b0 // POOL ING      , [UNUSE]
                             : ( pipline_cont == READ_ACCU_DELAY        &&(CONV_FLAG == CONV_MODE   
                                                                        || CONV_FLAG == DECONV_MODE)/*&& have_accu*/)           ? 1'b1 // CONV MODE     , [USE]
                             : ( pipline_cont == READ_ACCU_DELAY        && CONV_FLAG == DWC_MODE    
                                                                        &&(pwc_dwc_s == DWC_S_PWC   || pwc_dwc_s == DWC_S_PWC_DWC)) ? 1'b1 // PD MODE => PWC, [USE]    (Including "PWC Only" & "PWC DWC COMBINE")
                             : ( pipline_cont == 1                      && CONV_FLAG == DWC_MODE    && pwc_dwc_s == DWC_S_DWC ) ? 1'b1 // PD MODE => DWC, [USE]    ("DWC Only")
                                                                                                                                : 1'b0;// UNKNOW        , [UNUSE]
        pool_fsm_start      <= ( pipline_cont == READ_POOL_DELAY        && ( obuf_pool_s != OBUF_S_POOL_INIT ) )                ? 1'b1 // POOL ING      , [USE]
                                                                                                                                : 1'b0;// NOT POOL ING  , [UNUSE]
        write_pool_fsm_start<= ( pipline_cont == WRITE_POOL_DELAY       && ( obuf_pool_s != OBUF_S_POOL_INIT ) )                ? 1'b1 // POOL ING      , [USE]
                                                                                                                                : 1'b0;// NOT POOL ING  , [UNUSE]
        write_fsm_start     <= ( obuf_pool_s != OBUF_S_POOL_INIT )                                                              ? 1'b0 // POOL ING      , [UNUSE]
                             : ( pipline_cont == WRITE_LAST_ICH_DELAY   &&(CONV_FLAG == CONV_MODE  )&&(Is_last_ker   == 1'b1 
                                                                                                    && have_last_ich == 1'b1))  ? 1'b1 // CONV MODE     , [USE]
                             : ( pipline_cont == WRITE_LAST_ICH_DELAY   &&(CONV_FLAG == DECONV_MODE)&& have_last_ich == 1'b1 )  ? 1'b1 
                             : ( pipline_cont == WRITE_NOT_JUST_DELAY   &&(CONV_FLAG == CONV_MODE  )&&(have_last_ich == 1'b0    
                                                                                                    || Is_last_ker   == 1'b0))  ? 1'b1
                             : ( pipline_cont == WRITE_NOT_JUST_DELAY   &&(CONV_FLAG == DECONV_MODE)&& have_last_ich == 1'b0 )  ? 1'b1 // CONV MODE     , [USE]
                             : ( pipline_cont == WRITE_NOT_JUST_DELAY   && CONV_FLAG == DWC_MODE    && have_last_ich == 1'b0 )  ? 1'b1 // PD MODE => PWC, [USE]     ("PWC Not Last Ich")
                             : ( pipline_cont == WRITE_LAST_ICH_DELAY   && CONV_FLAG == DWC_MODE    && have_last_ich == 1'b1
                                                                                                    && pwc_dwc_s == DWC_S_PWC ) ? 1'b1 // PD MODE => PWC, [USE]     ("PWC Is  Last Ich")
                             : ( DWC_ONLY_WRITE_FLAG                    && CONV_FLAG == DWC_MODE    && pwc_dwc_s == DWC_S_DWC ) ? 1'b1 // PD MODE => DWC, [USE]     ("DWC Only")
                             : ( PWC_DWC_ONLY_WRITE_FLAG                && CONV_FLAG == DWC_MODE    && pwc_dwc_s == DWC_S_PWC_DWC )? 1'b1 // PD MODE => PWC_DWC, [USE] ("PWC_DWC Only")
                                                                                                                                : 1'b0;// UNKNOW        , [UNUSE]
    end
end

//======================================= DWC CTRL =======================================
always @( posedge clk ) begin
    if ( rst && pwc_dwc_s != DWC_S_DWC ) begin
        pwc_dwc_s   <= DWC_S_INIT;
    end else begin
        pwc_dwc_s   <= pwc_dwc_s_n;
    end
end
always @ ( posedge clk ) begin
    DWC_DATAFLOW <= ( pwc_dwc_s == DWC_S_DWC )    ? OBUF_TO_LINE_BUFFER
                  : ( pwc_dwc_s == DWC_S_PWC_DWC )? SPE_TO_LINE_BUFFER
                                                  : 0;
end


always @ ( * ) begin
    case ( pwc_dwc_s )
        DWC_S_INIT : begin
            if ( CONV_FLAG_ == DWC_MODE ) begin 
                if ( have_last_ich_ == 0 || pwc_dwc_combine_ == 0 )
                        pwc_dwc_s_n = DWC_S_PWC;
                else
                        pwc_dwc_s_n = DWC_S_PWC_DWC;
            end else begin
                pwc_dwc_s_n = DWC_S_INIT;
            end
        end
        DWC_S_PWC : begin
            if ( WRITE_STATE_FINISH ) begin
                if ( have_last_ich == 1 )
                    pwc_dwc_s_n = DWC_S_DWC;
                else
                    pwc_dwc_s_n = DWC_S_INIT;
            end else
                pwc_dwc_s_n = DWC_S_PWC;
        end
        DWC_S_DWC : begin
            if ( WRITE_STATE_FINISH )
                pwc_dwc_s_n = DWC_S_INIT;
            else
                pwc_dwc_s_n = DWC_S_DWC;
        end
        DWC_S_PWC_DWC : begin
            if ( WRITE_STATE_FINISH )
                pwc_dwc_s_n = DWC_S_INIT;
            else
                pwc_dwc_s_n = DWC_S_PWC_DWC;
        end
        default : begin
                pwc_dwc_s_n = DWC_S_INIT;
        end
    endcase
end
assign DWC_ONLY_WRITE_FLAG      = ( pipline_cont_dwc == DWC_DELAY )      ? 1'b1 : 1'b0;
assign PWC_DWC_ONLY_WRITE_FLAG  = ( pipline_cont_dwc == PWC_DWC_DELAY )  ? 1'b1 : 1'b0;

always @ ( posedge clk ) begin
    if ( rst && dwc_s == DWC_CACL_S_WAIT_RST )
        dwc_s   <= DWC_CACL_S_INIT;
    else
        dwc_s   <= dwc_s_n;
end

always @ ( * ) begin
    case ( dwc_s )
        DWC_CACL_S_INIT : begin
            if (  CONV_FLAG == DWC_MODE && have_last_ich && obuf_state == OBUF_S_FSM_START )
                dwc_s_n = DWC_CACL_S_WAIT_LINE_BUFFER;
            else
                dwc_s_n = DWC_CACL_S_INIT;
        end
        DWC_CACL_S_WAIT_LINE_BUFFER : begin
            if ( DWC_LINEBUFFER_READY && ( pwc_dwc_s == DWC_S_DWC || pwc_dwc_s == DWC_S_PWC_DWC ) )
                dwc_s_n =    DWC_CACL_S_FSM_START;
            else
                dwc_s_n     = DWC_CACL_S_WAIT_LINE_BUFFER;
        end
        DWC_CACL_S_FSM_START : begin
                dwc_s_n     = DWC_CACL_S_WAIT_RST;
        end
        DWC_CACL_S_WAIT_RST : begin
                dwc_s_n        = DWC_CACL_S_WAIT_RST;
        end
        default : begin
            dwc_s_n     = DWC_CACL_S_INIT;
        end
    endcase
end

always @ ( posedge clk ) begin
    if ( rst )
        pipline_cont_dwc <= 0;
    else if ( dwc_s == DWC_CACL_S_INIT )
        pipline_cont_dwc <= 0;
    else if ( dwc_s != DWC_CACL_S_INIT && dwc_s != DWC_CACL_S_WAIT_LINE_BUFFER  && (&pipline_cont_dwc) == 0 )
        pipline_cont_dwc <= pipline_cont_dwc + 1;
end
//======================================= DWC CTRL =======================================
always @ ( posedge clk ) begin
    if ( rst ) begin
        obuf_finish_state   <= FIN_OBUF_S_INIT;
    end else begin
        obuf_finish_state   <= obuf_finish_state_n;
    end
end
always @ ( * ) begin
    case ( obuf_finish_state )
        FIN_OBUF_S_INIT : begin
            if ( WRITE_STATE_FINISH ) begin
                if ( Is_last_ker && have_last_ich ) begin
                    if ( CONV_FLAG == CONV_MODE ) begin
                        if ( ( concat_output_control && obuf_pool_s == OBUF_S_POOL_INIT )   // DATA Before Pooling Write Out
                            || obuf_pool_s == OBUF_S_POOL_CACL ) begin                      // DATA After  Pooling Write Out
                            obuf_finish_state_n = FIN_OBUF_S_MASTER_READ;                   
                        end else if ( concat_output_control == 0 && have_pool == 0 ) begin  // Write Out Conv Data
                            obuf_finish_state_n = FIN_OBUF_S_MASTER_READ;                   
                        end else begin
                            obuf_finish_state_n = FIN_OBUF_S_INIT;                          // DATA Before Pooling But Don't need Write Out
                        end
                    end else if ( CONV_FLAG == DWC_MODE ) begin
                        if ( pwc_dwc_s == DWC_S_PWC ) begin                        // NEXT IS "Only DWC Cacl", Turn next tile
                            obuf_finish_state_n = FIN_OBUF_S_NEXT_TILE_LAYER;               
                        end else begin
                            obuf_finish_state_n = FIN_OBUF_S_MASTER_READ;
                        end
                    end else if ( CONV_FLAG == FC_MODE ) begin
                        if ( Is_Final_Tile ) begin
                            obuf_finish_state_n = FIN_OBUF_S_MASTER_READ;
                        end else begin
                            obuf_finish_state_n = FIN_OBUF_S_NEXT_TILE_LAYER;                        
                        end  
                    end else if ( CONV_FLAG == DECONV_MODE ) begin
                        obuf_finish_state_n = FIN_OBUF_S_NEXT_TILE_LAYER;
                    end else begin
                        obuf_finish_state_n = FIN_OBUF_S_MASTER_READ;
                    end
                end else begin
                    obuf_finish_state_n     = FIN_OBUF_S_NEXT_TILE_LAYER;
                end
            end else begin
                obuf_finish_state_n     = FIN_OBUF_S_INIT;
            end
        end
        FIN_OBUF_S_MASTER_READ : begin
            if ( Master_Output_Finish )
                obuf_finish_state_n     = FIN_OBUF_S_NEXT_TILE_LAYER;
            else
                obuf_finish_state_n     = FIN_OBUF_S_MASTER_READ;
        end
        FIN_OBUF_S_NEXT_TILE_LAYER : begin
            if( obuf_pool_s == OBUF_S_POOL_WAIT_CONV_WRITE_DONE )
                obuf_finish_state_n     = FIN_OBUF_S_INIT;
            else
                obuf_finish_state_n     = FIN_OBUF_S_WAIT_RST;
        end
        FIN_OBUF_S_WAIT_RST : begin
            obuf_finish_state_n         = FIN_OBUF_S_WAIT_RST;
        end
        default :
            obuf_finish_state_n         = FIN_OBUF_S_INIT;
    endcase
end
always @ ( posedge clk )
    if ( obuf_finish_state != FIN_OBUF_S_INIT )
        OBUF_FINISH_FLAG                <= 1'b1;
    else
        OBUF_FINISH_FLAG                <= 1'b0;
always @ ( posedge clk ) begin
    Pad_Start_OBUF_FINISH <= obuf_finish_state == FIN_OBUF_S_MASTER_READ;
    For_State_Finish      <= obuf_finish_state == FIN_OBUF_S_NEXT_TILE_LAYER && obuf_finish_state_n == FIN_OBUF_S_WAIT_RST;
end
assign  read_ker_size   = ( CONV_FLAG == DWC_MODE )                           ? 1 
                        : ( CONV_FLAG == DECONV_MODE )                        ? 2
                                                                              : ker_size;
assign  read_ker_strd   = ( CONV_FLAG == DWC_MODE )                           ? 1 
                        : ( CONV_FLAG == DECONV_MODE )                        ? 1
                                                                              : ker_strd;
assign  write_ker_size  = ( CONV_FLAG == DWC_MODE && pwc_dwc_s == DWC_S_PWC ) ? 1 
                        : ( CONV_FLAG == DECONV_MODE )                        ? 2
                                                                              : ker_size;
assign  write_ker_strd  = ( CONV_FLAG == DWC_MODE && pwc_dwc_s == DWC_S_PWC ) ? 1 
                        : ( CONV_FLAG == DECONV_MODE )                        ? 1
                                                                              : ker_strd;
reg           [HALF_ADDR_SIZE-1'b1:0]           user_read_obuf_tile_size_x,
                                                user_read_obuf_tile_size_y,
                                                read_obuf_tile_size_x,
                                                read_obuf_tile_size_y,
                                                write_obuf_tile_size_x,
                                                write_obuf_tile_size_y;
always @ ( posedge clk ) begin
    if ( pwc_dwc_s == DWC_S_PWC_DWC || pwc_dwc_s == DWC_S_DWC ) begin
        write_obuf_tile_size_x <= (obuf_tile_size_x - ker_size + 1) >> ( ker_strd-1);
        write_obuf_tile_size_y <= (obuf_tile_size_y - ker_size + 1) >> ( ker_strd-1);
    end else if ( CONV_FLAG == DECONV_MODE ) begin
        write_obuf_tile_size_x <= obuf_tile_size_x>>1;
        write_obuf_tile_size_y <= obuf_tile_size_y>>1;
    end else begin
        write_obuf_tile_size_x <= obuf_tile_size_x;
        write_obuf_tile_size_y <= obuf_tile_size_y;
    end
end
always @ ( posedge clk ) begin
    if ( pwc_dwc_s == DWC_S_PWC_DWC || pwc_dwc_s == DWC_S_DWC ) begin
        read_obuf_tile_size_x <= (obuf_tile_size_x - ker_size + 1) >> ( ker_strd-1);
        read_obuf_tile_size_y <= (obuf_tile_size_y - ker_size + 1) >> ( ker_strd-1);
    end else if ( CONV_FLAG == DECONV_MODE ) begin
        read_obuf_tile_size_x <= obuf_tile_size_x>>1;
        read_obuf_tile_size_y <= obuf_tile_size_y>>1;
    end else begin
        read_obuf_tile_size_x <= obuf_tile_size_x;
        read_obuf_tile_size_y <= obuf_tile_size_y;
    end

end
always @ ( posedge clk ) begin
    if ( have_pool_ing ) begin
        user_read_obuf_tile_size_x <= obuf_tile_size_x_aft_pool;
        user_read_obuf_tile_size_y <= obuf_tile_size_y_aft_pool;
    end else if ( pwc_dwc_s == DWC_S_PWC_DWC || pwc_dwc_s == DWC_S_DWC ) begin
        user_read_obuf_tile_size_x <= (obuf_tile_size_x - ker_size + 1) >> ( ker_strd-1);
        user_read_obuf_tile_size_y <= (obuf_tile_size_y - ker_size + 1) >> ( ker_strd-1);
    end else begin
        user_read_obuf_tile_size_x <= obuf_tile_size_x;
        user_read_obuf_tile_size_y <= obuf_tile_size_y;
    end

end
OBUF_READ_CTRL u_OBUF_READ_CTRL(
    .clk                            (clk),       
    .rst                            (rst),       
    .read_fc_fsm_start              (read_fc_fsm_start),
    .accu_fsm_start                 (accu_fsm_start),
    .pool_fsm_start                 (pool_fsm_start),
    .have_accu                      (have_accu),
    .have_pool                      (have_pool_ing),
    .have_last_ich                  (have_last_ich),
    .Is_Upsample                    (Is_Upsample),
    .bk_combine                     (bk_combine),
    .ker_size                       (read_ker_size),          
    .ker_strd                       (read_ker_strd),          
    .pool_size                      (pool_size),
    .pool_strd                      (pool_strd), 
    .Bit_serial                     (Bit_serial),                  
    .obuf_tile_size_x               (read_obuf_tile_size_x),               
    .obuf_tile_size_y               (read_obuf_tile_size_y),    
    .obuf_tile_size_x_aft_pool      (obuf_tile_size_x_aft_pool),
    .obuf_tile_size_y_aft_pool      (obuf_tile_size_y_aft_pool),
    .user_read_obuf_tile_size_x     (user_read_obuf_tile_size_x),
    .user_read_obuf_tile_size_y     (user_read_obuf_tile_size_y),
    .read_en                        (read_en),           
    .read_oaddr                     (read_oaddr), 
    .pool_ctrl_pip_out              (pool_ctrl),
    .OBUF_FINISH_FLAG               (OBUF_FINISH_FLAG),
    //.user_obuf_read_en              (user_obuf_read_en),
    .user_obuf_oaddr_x              (user_obuf_oaddr_x),
    .user_obuf_oaddr_y              (user_obuf_oaddr_y),
    .user_obuf_oaddr_z              (user_obuf_oaddr_z),
    .CONV_FLAG                      (CONV_FLAG),
    .DWC_LINEBUFFER_READY           (DWC_LINEBUFFER_READY),
    .DECONV_ODD_EVEN_FLAG           (DECONV_ODD_EVEN_FLAG)
);

OBUF_WRITE_CTRL u_OBUF_WRITE_CTRL(
    .clk                            (clk),     
    .rst                            (rst),    
    .write_fc_fsm_start             (write_fc_fsm_start), 
    .write_fsm_start                (write_fsm_start),  
    .write_pool_fsm_start           (write_pool_fsm_start),                     
    .have_pool                      (have_pool_ing), 
//    .have_pool                      (x_have_pool),         
    .bk_combine                     (bk_combine),         
    .ker_size                       (write_ker_size),         
    .ker_strd                       (write_ker_strd),                  
    .pool_size                      (pool_size),
    .pool_strd                      (pool_strd),    
    .Bit_serial                     (Bit_serial),                
    .obuf_tile_size_x               (write_obuf_tile_size_x),               
    .obuf_tile_size_y               (write_obuf_tile_size_y),           
    .obuf_tile_size_x_aft_pool      (obuf_tile_size_x_aft_pool),
    .obuf_tile_size_y_aft_pool      (obuf_tile_size_y_aft_pool),
    .write_en                       (write_en), 
    .write_iaddr                    (write_iaddr),
    .WRITE_STATE_FINISH             (WRITE_STATE_FINISH),
    .CONV_FLAG                      (CONV_FLAG),
    .DECONV_ODD_EVEN_FLAG           (DECONV_ODD_EVEN_FLAG)
);
//======================== WBUF ========================
assign wbuf_rst = wbuf_rst_A || wbuf_rst_B;

always @ ( posedge clk ) begin
    WBUF_RLAST_1                <= WBUF_RLAST;
    WBUF_VALID_FLAG_1           <= WBUF_VALID_FLAG;
    WBUF_RLAST_2                <= WBUF_RLAST_1;
    WBUF_VALID_FLAG_2           <= WBUF_VALID_FLAG_1;
end

always @ ( posedge clk )
    if ( wbuf_rst_A )
        WBUF_AB_LOAD_FLAG       <= A_BUF;
    else if ( wbuf_rst_B )
        WBUF_AB_LOAD_FLAG       <= B_BUF;

always @ ( posedge clk )
    if ( rst )
        WBUF_AB_CACL_FLAG       <= WBUF_CHOOSE;

always @ ( posedge clk )
    if ( wbuf_rst )
        wbuf_s                  <= WBUF_S_INIT;
    else
        wbuf_s                  <= wbuf_s_n;
always @ ( * ) begin
    case ( wbuf_s )
        WBUF_S_INIT : begin
            if ( WBUF_VALID_FLAG_1 ) begin
                if ( dwc_s == DWC_CACL_S_WAIT_LINE_BUFFER ) begin 
                    wbuf_s_n        = WBUF_S_DWC_LOADING_KERNEL;
                end else begin
                    wbuf_s_n        = WBUF_S_LOADING_KERNEL;
                end
            end else begin
                wbuf_s_n            = WBUF_S_INIT;
            end
        end
        WBUF_S_LOADING_KERNEL : begin
            if ( WBUF_KERNEL_LOADING_FIN ) begin
                if ( have_last_ich_ && have_batch_ ) begin
                    wbuf_s_n        = WBUF_S_LOADING_BATCH_WEIGHT;
                end else if ( pwc_dwc_s == DWC_S_DWC || pwc_dwc_s == DWC_S_PWC_DWC ) begin
                    wbuf_s_n        = WBUF_S_DWC_LOADING_KERNEL;
                end else begin
                    wbuf_s_n        = WBUF_S_INIT;
                end
            end else
                wbuf_s_n            = WBUF_S_LOADING_KERNEL;
        end
        WBUF_S_LOADING_BATCH_WEIGHT : begin
            if ( WBUF_BATCH_WEIGHT_LOADING_FIN ) begin
                if ( pwc_dwc_s == DWC_S_DWC || pwc_dwc_s == DWC_S_PWC_DWC ) begin
                    wbuf_s_n        = WBUF_S_DWC_LOADING_KERNEL;
                end else begin
                    wbuf_s_n        = WBUF_S_INIT;
                end
            end else begin
                wbuf_s_n            = WBUF_S_LOADING_BATCH_WEIGHT;
            end
        end
        WBUF_S_DWC_LOADING_KERNEL : begin
            if ( WBUF_KERNEL_LOADING_FIN ) begin
                wbuf_s_n            = WBUF_S_DWC_LOADING_KERNEL_LAST;
            end else begin
                wbuf_s_n            = WBUF_S_DWC_LOADING_KERNEL;
            end
        end
        WBUF_S_DWC_LOADING_KERNEL_LAST : begin
            if ( WBUF_ADDR_KER_CONT_FLAG ) begin
                if ( have_last_ich_ && have_batch_dwc_ ) begin
                    wbuf_s_n            = WBUF_S_DWC_LOADING_BATCH_WEIGHT;
                end else begin
                    wbuf_s_n            = WBUF_S_INIT;
                end
            end else begin
                wbuf_s_n                = WBUF_S_DWC_LOADING_KERNEL_LAST;
            end
        end
        WBUF_S_DWC_LOADING_BATCH_WEIGHT : begin
            if ( WBUF_BATCH_WEIGHT_LOADING_FIN ) begin
                wbuf_s_n            = WBUF_S_INIT;
            end else begin
                wbuf_s_n            = WBUF_S_DWC_LOADING_BATCH_WEIGHT;
            end
        end
        default : begin
            wbuf_s_n            = WBUF_S_INIT;
        end
    endcase
end

assign WBUF_LOAD_FLAG                   = WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_LOADING_KERNEL || wbuf_s == WBUF_S_DWC_LOADING_KERNEL );
assign WBUF_DWC_LAST_LOAD_FLAG          = WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_DWC_LOADING_KERNEL_LAST );
assign WBUF_SPE_LOAD_FLAG               = WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_LOADING_BATCH_WEIGHT || wbuf_s == WBUF_S_DWC_LOADING_BATCH_WEIGHT );
//======================== KERNEL WEIGHT LOADING ========================
assign WBUF_KERNEL_LOADING_FIN          = WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_LOADING_KERNEL || wbuf_s == WBUF_S_DWC_LOADING_KERNEL ) && WBUF_ADDR_OCH_CONT_FLAG && WBUF_ADDR_KER_CONT_FLAG;
assign WBUF_ADDR_OCH_CONT_FLAG          = ( wbuf_addr_och_cont == (8-1) );
assign WBUF_ADDR_KER_CONT_FLAG          = ( wbuf_s == WBUF_S_DWC_LOADING_KERNEL_LAST ) ? wbuf_addr_ker_cont == (12-1)
                                                                                       : wbuf_addr_ker_cont == (9-1) ;
always @ ( posedge clk ) begin
    if ( wbuf_rst )
        wbuf_addr_och_cont      <= 0;
    else if (  WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_LOADING_KERNEL || wbuf_s == WBUF_S_DWC_LOADING_KERNEL ) && WBUF_ADDR_KER_CONT_FLAG ) begin
        wbuf_addr_och_cont  <= wbuf_addr_och_cont + 1'b1;
    end else if ( wbuf_s == WBUF_S_INIT )
        wbuf_addr_och_cont      <= 0;
    else 
        wbuf_addr_och_cont      <= wbuf_addr_och_cont;
end
always @ ( posedge clk ) begin
    if ( wbuf_rst ) begin
        wbuf_addr_ker_cont   <= 0;
    end else if (  wbuf_s != WBUF_S_DWC_LOADING_KERNEL && wbuf_s_n == WBUF_S_DWC_LOADING_KERNEL ) begin
            wbuf_addr_ker_cont  <= 2;
    end else if (  wbuf_s != WBUF_S_DWC_LOADING_KERNEL_LAST && wbuf_s_n == WBUF_S_DWC_LOADING_KERNEL_LAST ) begin
            wbuf_addr_ker_cont  <= 9;
    end else if ( WBUF_VALID_FLAG_2 && wbuf_s == WBUF_S_LOADING_KERNEL ) begin                  // 0 - 1 - 2 .... 8
        if ( WBUF_ADDR_KER_CONT_FLAG ) begin
            wbuf_addr_ker_cont  <= 0;       
        end else begin
            wbuf_addr_ker_cont  <= wbuf_addr_ker_cont + 1'b1;
        end
    end else if ( WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_DWC_LOADING_KERNEL ) ) begin      // 2 - 5 - 8
        if ( WBUF_ADDR_KER_CONT_FLAG ) begin
            wbuf_addr_ker_cont  <= 2;       
        end else begin
            wbuf_addr_ker_cont  <= wbuf_addr_ker_cont + 3;
        end
    end else if ( WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_DWC_LOADING_KERNEL_LAST ) ) begin // 9 - 10 - 11
        if ( WBUF_ADDR_KER_CONT_FLAG ) begin
            wbuf_addr_ker_cont  <= 0;       
        end else begin
            wbuf_addr_ker_cont  <= wbuf_addr_ker_cont + 1;
        end
    end else if ( wbuf_s == WBUF_S_INIT ) begin
        wbuf_addr_ker_cont      <= 0;
    end else begin
        wbuf_addr_ker_cont      <= wbuf_addr_ker_cont;
    end
end

always @ ( * ) begin
    case ( {WBUF_DWC_LAST_LOAD_FLAG,WBUF_LOAD_FLAG,wbuf_addr_och_cont[2:0]} )
        {1'b1,1'b0,3'd0} : WBUF_LOAD_OCH_FLAG = 8'b1111_1111;
        {1'b0,1'b1,3'd0} : WBUF_LOAD_OCH_FLAG = 8'b0000_0001;
        {1'b0,1'b1,3'd1} : WBUF_LOAD_OCH_FLAG = 8'b0000_0010;
        {1'b0,1'b1,3'd2} : WBUF_LOAD_OCH_FLAG = 8'b0000_0100;
        {1'b0,1'b1,3'd3} : WBUF_LOAD_OCH_FLAG = 8'b0000_1000; 
        {1'b0,1'b1,3'd4} : WBUF_LOAD_OCH_FLAG = 8'b0001_0000; 
        {1'b0,1'b1,3'd5} : WBUF_LOAD_OCH_FLAG = 8'b0010_0000; 
        {1'b0,1'b1,3'd6} : WBUF_LOAD_OCH_FLAG = 8'b0100_0000;
        {1'b0,1'b1,3'd7} : WBUF_LOAD_OCH_FLAG = 8'b1000_0000;
        default : WBUF_LOAD_OCH_FLAG = 8'b0000_0000;
    endcase
end

//======================== KERNEL WEIGHT LOADING ========================
//======================== SPE    WEIGHT LOADING ========================
assign WBUF_BATCH_WEIGHT_LOADING_FIN    = WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_LOADING_BATCH_WEIGHT || wbuf_s == WBUF_S_DWC_LOADING_BATCH_WEIGHT ) && WBUF_ADDR_SPE_WEIGHT_CONT_FLAG && WBUF_ADDR_SPE_OCH_CONT_FLAG;
assign WBUF_ADDR_SPE_OCH_CONT_FLAG      = ( bk_combine_ == 0 ) ? ( wbuf_addr_spe_och_cont == 2 )
                                                               : ( wbuf_addr_spe_och_cont == 0 );
assign WBUF_ADDR_SPE_WEIGHT_CONT_FLAG   = ( wbuf_addr_spe_weight_cont == 1 );        // one cycle : alpha , one cycle : beta

always @ ( posedge clk ) begin
    if ( wbuf_rst )
        wbuf_addr_spe_och_cont          <= 0;
    else if ( WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_LOADING_BATCH_WEIGHT || wbuf_s == WBUF_S_DWC_LOADING_BATCH_WEIGHT ) ) begin
        if ( WBUF_ADDR_SPE_OCH_CONT_FLAG )
            wbuf_addr_spe_och_cont      <= 0;
        else
            wbuf_addr_spe_och_cont      <= wbuf_addr_spe_och_cont + 1'b1;
    end else if ( wbuf_s == WBUF_S_INIT )
        wbuf_addr_spe_och_cont          <= 0;
    else 
        wbuf_addr_spe_och_cont          <= wbuf_addr_spe_och_cont;
end
always @ ( posedge clk ) begin
    if ( wbuf_rst )
        wbuf_addr_spe_weight_cont       <= 0;
    else if ( WBUF_VALID_FLAG_2 && ( wbuf_s == WBUF_S_LOADING_BATCH_WEIGHT || wbuf_s == WBUF_S_DWC_LOADING_BATCH_WEIGHT ) && WBUF_ADDR_SPE_OCH_CONT_FLAG ) begin
        if ( WBUF_ADDR_SPE_WEIGHT_CONT_FLAG )
            wbuf_addr_spe_weight_cont   <= 0;       
        else
            wbuf_addr_spe_weight_cont   <= wbuf_addr_spe_weight_cont + 1'b1;
    end else if ( wbuf_s == WBUF_S_INIT )   
        wbuf_addr_spe_weight_cont       <= 0;
    else 
        wbuf_addr_spe_weight_cont       <= wbuf_addr_spe_weight_cont;
end

//======================== WBUF ========================
always @ ( * )
    if ( wbuf_s == WBUF_S_DWC_LOADING_BATCH_WEIGHT )
        WBUF_CONV_OR_DWC_SPE_FLAG = 1;              // Load Normalization to DWC  SPE
    else    
        WBUF_CONV_OR_DWC_SPE_FLAG = 0;              // Load Normalization to CONV SPE

always @ ( posedge clk ) begin
    if ( wbuf_rst || ( wbuf_s != WBUF_S_LOADING_BATCH_WEIGHT && wbuf_s_n == WBUF_S_LOADING_BATCH_WEIGHT ) || ( wbuf_s != WBUF_S_DWC_LOADING_BATCH_WEIGHT && wbuf_s_n == WBUF_S_DWC_LOADING_BATCH_WEIGHT ) || WBUF_ADDR_SPE_OCH_CONT_FLAG ) begin
        if ( bk_combine_ == 1 ) begin
            if ( CONV_FLAG == DECONV_MODE )
                WBUF_SPE_LOAD_OCH_FLAG_reg <= 24'b1111_1111_1111_1111_1111_1111;
            else
                WBUF_SPE_LOAD_OCH_FLAG_reg <= 24'b0100_1001_0010_0100_1001_0010;
        end else
            WBUF_SPE_LOAD_OCH_FLAG_reg <= 24'b0010_0100_1001_0010_0100_1001;
    end else if ( WBUF_SPE_LOAD_FLAG ) begin
        if ( bk_combine_ == 1 )
            WBUF_SPE_LOAD_OCH_FLAG_reg <= WBUF_SPE_LOAD_OCH_FLAG;
        else
            WBUF_SPE_LOAD_OCH_FLAG_reg <= WBUF_SPE_LOAD_OCH_FLAG<<1;
    end
end
always @ ( * ) begin
    if ( WBUF_SPE_LOAD_FLAG ) begin
        WBUF_SPE_LOAD_OCH_FLAG = WBUF_SPE_LOAD_OCH_FLAG_reg;
    end else
        WBUF_SPE_LOAD_OCH_FLAG = 24'd0;
end
endmodule


module lookup_table_y_bk#(
    parameter       BK_ADDR_SIZE        =   4'd9,
    parameter       HALF_ADDR_SIZE      =   6,
    parameter       BK_NUM              =   3
)( 
    input                                           clk,
    input           [HALF_ADDR_SIZE-1:0]            index_x,
                                                    index_y,
                                                    offset_x,
    input                                           bk_combine,
    output  reg     [BK_NUM-1:0]                    index_bk_1,
    output          [BK_ADDR_SIZE-1'b1:0]           address_output
);
    reg             [BK_NUM-1'b1:0]                 index_bk;
    reg             [3:0]                           index_quotient;
    reg             [HALF_ADDR_SIZE-1'b1:0]         index_x_1,
                                                    index_y_1;
    reg             [3:0]                           index_quotient_1;
    wire            [HALF_ADDR_SIZE-1:0]            mult_tile_size;
    always @ ( * ) begin
        case ( index_y )
            0 ,3 ,6 ,9 ,12 ,15 ,18 , 21, 24, 27, 30, 33 : index_bk = 3'b001;
            1 ,4 ,7 ,10,13 ,16 ,19 , 22, 25, 28, 31 : index_bk = 3'b010;
            2 ,5 ,8 ,11,14 ,17 ,20 , 23, 26, 29, 32 : index_bk = 3'b100;
            default : index_bk = 0;
        endcase
        case ( index_y )
            0  ,1  ,2  : index_quotient = 0;
            3  ,4  ,5  : index_quotient = 1; 
            6  ,7  ,8  : index_quotient = 2;
            9  ,10 ,11 : index_quotient = 3; 
            12 ,13 ,14 : index_quotient = 4;
            15 ,16 ,17 : index_quotient = 5;
            18 ,19 ,20 : index_quotient = 6;
            21 ,22 ,23 : index_quotient = 7;
            24 ,25 ,26 : index_quotient = 8; 
            27 ,28 ,29 : index_quotient = 9;
            30 ,31 ,32 : index_quotient = 10;
            33         : index_quotient = 11;
            default : index_quotient = 0;
        endcase
    end
    always @ ( posedge clk ) begin
        index_x_1                   <= index_x;
        index_y_1                   <= index_y;
        index_bk_1                  <= index_bk;
        index_quotient_1            <= index_quotient;
    end
    assign mult_tile_size = ( bk_combine ) ? {2'b00,index_quotient_1} : index_y_1;
    assign address_output = mult_tile_size*offset_x + index_x_1;

endmodule
