`timescale 1ns / 1ps
module OBUF_READ_CTRL#(
    parameter       BK_ADDR_SIZE                =   9,          // one bank length is 408 = 9'b1_1001_1000 9 bits
    parameter       BK_NUM                      =   3,          // 3 Output Bank form a 3x3 conv output channel                                                            // 1 Output Bank form a 1x1 conv output channel
    parameter       HALF_ADDR_SIZE              =   6,
    parameter       SETTING_SIZE                =   4,
    parameter       KER_SIZE_MODE               =   0,
    parameter       KER_STRD_MODE               =   1,
    parameter       ACCU_S_INIT                 =   0,
    parameter       ACCU_S_IDLE                 =   1,
    parameter       ACCU_S_CACL                 =   2,
    parameter       FC_S_INIT                   =   0,
    parameter       FC_S_CACL                   =   1,
    parameter       FC_S_WAIT                   =   2,
    parameter       POOL_S_INIT                 =   0,
    parameter       POOL_S_CACL                 =   1,
    parameter       POOL_CTRL_SET               =   0,
    parameter       POOL_CTRL_COMPARE           =   1,
    parameter       CONV_MODE                   =   2'b00,
    parameter       FC_MODE                     =   2'b01,
    parameter       DECONV_MODE                 =   2'b10,
    parameter       DWC_MODE                    =   2'b11
)(
    input                                           clk,
                                                    rst,
                                                    read_fc_fsm_start,
                                                    accu_fsm_start,
                                                    pool_fsm_start,
                                                    have_accu,
                                                    have_pool,
                                                    have_last_ich,
                                                    Is_Upsample,
                                                    bk_combine,
    input           [SETTING_SIZE-1:0]              ker_size,
                                                    ker_strd,
    input           [1:0]                           pool_size,
                                                    pool_strd,
    input           [1:0]                           Bit_serial,
    input           [HALF_ADDR_SIZE-1'b1:0]         obuf_tile_size_x,
                                                    obuf_tile_size_y,
                                                    obuf_tile_size_x_aft_pool,
                                                    obuf_tile_size_y_aft_pool,
                                                    user_read_obuf_tile_size_x,
                                                    user_read_obuf_tile_size_y,
    output  reg     [BK_NUM-1:0]                    read_en,
    output  reg     [BK_NUM*BK_ADDR_SIZE-1:0]       read_oaddr,
    output                                          pool_ctrl_pip_out,
    input                                           OBUF_FINISH_FLAG,
    //input                                           user_obuf_read_en,
    input           [HALF_ADDR_SIZE-1'b1:0]         user_obuf_oaddr_x,
                                                    user_obuf_oaddr_y,
    input           [1:0]                           user_obuf_oaddr_z,
    input           [1:0]                           CONV_FLAG,
    output                                          DWC_LINEBUFFER_READY,
    input                                           DECONV_ODD_EVEN_FLAG
);
    //====================================== ACCU CTRL ======================================
    wire                                            ACCU_IDLE_FIN, ACCU_CACL_FIN, ACCU_ALL_CACL_FIN, ACCU_STRD_FLAG;
    reg             [HALF_ADDR_SIZE-1'b1:0]         accu_tile_x_, accu_tile_y_,
                                                    accu_tile_x , accu_tile_y;
    reg                                             accu_size_strd_mode;
    reg             [SETTING_SIZE-1:0]              accu_ker_size_cont,
                                                    accu_ker_strd_cont;
    wire                                            accu_read_en;
    reg             [BK_NUM-1:0]                    accu_tile_sel_bk;
    reg             [BK_ADDR_SIZE-1:0]              accu_bk_oaddr[0:BK_NUM-1];
    wire                                            accu_bits_flag;
    reg             [3:0]                           accu_bits_cont;
    reg             [1:0]                           accu_s, accu_s_n;
    //====================================== ACCU CTRL ======================================
    //====================================== FC   CTRL ======================================
    wire                                            fc_bits_flag;
    reg             [3:0]                           fc_bits_cont;
    reg             [1:0]                           fc_s, fc_s_n;
    wire                                            FC_CHANGE_ROW,
                                                    FC_CACL_FIN;
    reg             [(HALF_ADDR_SIZE)-1:0]          fc_tile_x,
                                                    fc_tile_y;
    reg                                             fc_read_en;
    reg             [BK_NUM-1:0]                    fc_tile_sel_bk;
    reg             [BK_ADDR_SIZE-1:0]              fc_bk_oaddr[0:BK_NUM-1];
    //====================================== FC   CTRL ======================================
    //====================================== POOL CTRL ======================================
    reg                                             pool_ctrl, pool_ctrl_;
    wire                                            POOL_CHANGE_ROW, POOL_CACL_FIN;
    reg                                             pool_write_en;
    reg             [HALF_ADDR_SIZE-1:0]            pool_tile_write_x, pool_tile_write_y, 
                                                    pool_tile_ori_x, pool_tile_ori_x_,
                                                    pool_tile_ori_y, pool_tile_ori_y_,
                                                    pool_tile_sel_x, pool_tile_sel_y;
    reg             [SETTING_SIZE-1:0]              pool_size_cont_x,
                                                    pool_size_cont_y;
    wire                                            POOL_SIZE_X_FLAG,POOL_SIZE_Y_FLAG;
    reg             [1:0]                           i;
    reg                                             pool_s, pool_s_n;
        //============================= POOL - LOOKUP TABLE =============================
    wire            [BK_NUM-1:0]                    pool_tile_sel_bk;
    reg             [BK_NUM-1:0]                    pool_tile_sel_bk_1;
    reg             [BK_ADDR_SIZE-1:0]              pool_bk_oaddr[0:BK_NUM-1];
        //============================= POOL - LOOKUP TABLE =============================
    //====================================== POOL CTRL ======================================
        //============================= USER - LOOKUP TABLE =============================
    reg             [BK_NUM-1:0]                    user_obuf_oaddr_z_bk;
    wire            [BK_NUM-1:0]                    user_obuf_bk;
    reg             [BK_NUM-1:0]                    user_obuf_bk_1;
    reg             [BK_ADDR_SIZE-1:0]              user_bk_oaddr[0:BK_NUM-1];
        //============================= USER - LOOKUP TABLE =============================
    //====================================== LOOKUP TABLE ======================================
    wire            [HALF_ADDR_SIZE-1:0]            lookup_table_index_x_pool,
                                                    lookup_table_index_y_pool;
    wire            [HALF_ADDR_SIZE-1'b1:0]         lookup_table_offset_x;
    wire            [BK_NUM-1:0]                    lookup_table_bk_pool;
    wire            [BK_ADDR_SIZE-1'b1:0]           lookup_table_output_pool;
    //====================================== LOOKUP TABLE ======================================
    //====================================== LOOKUP TABLE ======================================
    wire           [HALF_ADDR_SIZE-1:0]             lookup_table_index_x,
                                                    lookup_table_index_y;
    wire            [BK_NUM-1:0]                    lookup_table_bk;
    wire            [BK_ADDR_SIZE-1'b1:0]           lookup_table_output;
    //====================================== LOOKUP TABLE ======================================
    
    assign  DWC_LINEBUFFER_READY = ( CONV_FLAG == DWC_MODE ) ? ( accu_tile_x == 2 && accu_tile_y == 2 )
                                                             : 1'b0 ;
    
    always @ ( posedge clk ) begin
        if ( rst ) begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                read_en[i]                                      <= 0;
                read_oaddr[(i)*(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]  <= 0;
            end
        end else begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                read_en[i]                                      <= ( OBUF_FINISH_FLAG )       ?                  user_obuf_bk_1[i]
                                                                 : ( CONV_FLAG == FC_MODE   ) ?                  fc_tile_sel_bk[i]
                                                                 : ( have_pool )              ? ( bk_combine ) ? pool_tile_sel_bk_1[i] 
                                                                                                               : 1'b1 
                                                                 : ( CONV_FLAG == CONV_MODE ) ?                  accu_tile_sel_bk[i] & accu_read_en
                                                                 : ( CONV_FLAG == DWC_MODE )  ?                  accu_tile_sel_bk[i] & accu_read_en
                                                                 : ( CONV_FLAG == DECONV_MODE ) ?                accu_tile_sel_bk[i] & accu_read_en
                                                                                              :                  1'b0;
                read_oaddr[(i)*(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)]  <= ( OBUF_FINISH_FLAG )       ?                  user_bk_oaddr[i]
                                                                 : ( CONV_FLAG == FC_MODE   ) ?                  fc_bk_oaddr[i]                  
                                                                 : ( have_pool ) ?                               pool_bk_oaddr[i]
                                                                 : ( CONV_FLAG == CONV_MODE ) ?                  accu_bk_oaddr[i] 
                                                                 : ( CONV_FLAG == DWC_MODE )  ?                  accu_bk_oaddr[i] 
                                                                 : ( CONV_FLAG == DECONV_MODE)?                 {accu_bk_oaddr[i][BK_ADDR_SIZE-1:1],DECONV_ODD_EVEN_FLAG}
                                                                                              :                  0;
            end
        end
    end
    //====================================== ACCU CTRL ======================================

    assign accu_read_en = (accu_s == ACCU_S_CACL) ? accu_bits_flag : 1'b0;
    always @ ( posedge clk ) begin
        if ( rst )
            accu_tile_sel_bk   <= 0;
        else begin
            if ( accu_s == ACCU_S_INIT ) begin
                if ( bk_combine ) begin
                    if ( CONV_FLAG == DECONV_MODE )
                        accu_tile_sel_bk   <= 3'b011;      // 8 Bank througput one time
                    else
                        accu_tile_sel_bk   <= 3'b001;      // 8 Bank througput one time
                end else
                    accu_tile_sel_bk   <= 3'b111;      // 24 Bank througput one time
//            end else if ( obuf_read_cont_x == obuf_tile_size_x-1'b1 && read_bits_flag ) begin
            end else if ( accu_s == ACCU_S_CACL && accu_bits_flag && ACCU_CACL_FIN ) begin
                if ( CONV_FLAG == DECONV_MODE )
                    accu_tile_sel_bk   <= {accu_tile_sel_bk[0],accu_tile_sel_bk[2:1]};
                else
                    accu_tile_sel_bk   <= {accu_tile_sel_bk[1:0],accu_tile_sel_bk[2]};
            end else begin
                accu_tile_sel_bk   <= accu_tile_sel_bk;
            end
        end
    end
    genvar x_var;
    generate
        for ( x_var=0 ; x_var<BK_NUM ; x_var=x_var+1 ) begin
            always @ ( posedge clk ) begin
                if ( rst ) begin
                    accu_bk_oaddr[x_var]    <= 0;
                end else if ( accu_tile_sel_bk[x_var] && accu_read_en ) begin
                    if ( CONV_FLAG == DECONV_MODE ) begin
                        accu_bk_oaddr[x_var][0]                 <= accu_bk_oaddr[x_var][0];
                        accu_bk_oaddr[x_var][BK_ADDR_SIZE-1:1]  <= accu_bk_oaddr[x_var][BK_ADDR_SIZE-1:1]+1'b1;
                    end else
                        accu_bk_oaddr[x_var]                    <= accu_bk_oaddr[x_var]+1'b1;
                end
            end
        end
    endgenerate

    assign ACCU_IDLE_FIN        = ( accu_s != ACCU_S_INIT ) ? ( accu_size_strd_mode == KER_SIZE_MODE ) ? (accu_ker_size_cont == (ker_size-2'b10)) && (accu_bits_flag)
                                                                                                      : (accu_ker_strd_cont == (ker_strd-1'b1 )) && (accu_bits_flag)
                                                            : 1'b0;            
    assign ACCU_CACL_FIN        = accu_bits_flag && accu_tile_x == obuf_tile_size_x-1'b1 && accu_ker_strd_cont == 0;
    assign ACCU_ALL_CACL_FIN    = ACCU_CACL_FIN && accu_tile_y == obuf_tile_size_y-1'b1;
    assign ACCU_STRD_FLAG       = accu_bits_flag && ( accu_size_strd_mode == KER_STRD_MODE ) && ( accu_ker_strd_cont != ker_strd-1'b1 );
    
    always @ ( posedge clk )
        if ( rst )
            accu_s      <=  ACCU_S_INIT;
        else
            accu_s      <=  accu_s_n;
    always @ ( * ) begin
        case ( accu_s )
            ACCU_S_INIT : begin
                if ( accu_fsm_start ) begin
                    if ( ker_size == 1 )
                        accu_s_n        = ACCU_S_CACL;
                    else
                        accu_s_n        = ACCU_S_IDLE;
                end else begin
                    accu_s_n    = ACCU_S_INIT;
                end
            end
            ACCU_S_IDLE  : begin
                if ( ACCU_IDLE_FIN )
                    accu_s_n    = ACCU_S_CACL;
                else
                    accu_s_n    = ACCU_S_IDLE;
            end
            ACCU_S_CACL : begin
                if ( ACCU_CACL_FIN ) begin
                    if ( ACCU_ALL_CACL_FIN ) begin
                        accu_s_n    = ACCU_S_INIT;
                    end else if ( ker_size == 1 ) begin
                        accu_s_n    = ACCU_S_CACL;
                    end else begin
                        accu_s_n    = ACCU_S_IDLE;
                    end
                end else begin
                    if ( ACCU_STRD_FLAG ) begin
                        accu_s_n    = ACCU_S_IDLE;
                    end else begin
                        accu_s_n    = ACCU_S_CACL;
                    end
                end
            end
            default : begin
                accu_s_n    = ACCU_S_INIT;
            end
        endcase
    end
    assign accu_bits_flag = ( accu_bits_cont == Bit_serial );
    always @ ( posedge clk ) begin
        if ( rst ) begin
            accu_bits_cont  <=  0;
        end else if ( ( accu_s != ACCU_S_INIT ) && ( accu_bits_flag == 0 ) ) begin
            accu_bits_cont  <=  accu_bits_cont+1'b1;
        end else begin
            accu_bits_cont  <=  0;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst )
            accu_size_strd_mode  <= KER_SIZE_MODE;
        else begin
            if ( ACCU_CACL_FIN )
                accu_size_strd_mode  <= KER_SIZE_MODE;
            else if( ACCU_IDLE_FIN ) begin
                accu_size_strd_mode  <= KER_STRD_MODE;
            end  else begin
                accu_size_strd_mode  <= accu_size_strd_mode;
            end
        end
    end

    always @ ( posedge clk ) begin
        if ( rst )
            accu_tile_x    <= 0;
        else
            accu_tile_x    <= accu_tile_x_;
    end
    always @ ( * ) begin
        if ( accu_s == ACCU_S_CACL && accu_bits_flag ) begin
            if ( ACCU_CACL_FIN )
                accu_tile_x_   = 0;
            else
                accu_tile_x_   = accu_tile_x+1'b1;
        end else begin
            accu_tile_x_   = accu_tile_x;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst )
            accu_tile_y <= 0;
        else
            accu_tile_y <= accu_tile_y_;
    end
    always @ ( * ) begin
        if ( accu_s == ACCU_S_CACL && accu_bits_flag ) begin
            if ( ACCU_CACL_FIN ) begin
                if ( ACCU_ALL_CACL_FIN ) begin
                    accu_tile_y_   = 0;
                end else begin
                    accu_tile_y_   = accu_tile_y+1'b1;
                end
            end else begin
                accu_tile_y_   = accu_tile_y;
            end
        end else begin
            accu_tile_y_   = accu_tile_y;
        end 
    end
    always @ ( posedge clk ) begin
        if ( rst ) begin
            accu_ker_size_cont  <= 0;
        end else if ( ( accu_s != ACCU_S_INIT ) && accu_size_strd_mode == KER_SIZE_MODE ) begin
            if ( accu_bits_flag ) begin
                if ( accu_ker_size_cont < ker_size-2'b10 )
                    accu_ker_size_cont  <= accu_ker_size_cont+1'b1;
                else
                    accu_ker_size_cont  <= 0;
            end else begin
                accu_ker_size_cont  <= accu_ker_size_cont;
            end
        end else begin
            accu_ker_size_cont  <= 0;
        end
    end
    
    always @ ( posedge clk ) begin
        if ( rst ) begin
            accu_ker_strd_cont  <= 0;
        end else if ( ( accu_s != ACCU_S_INIT ) && accu_size_strd_mode == KER_STRD_MODE ) begin
            if ( accu_bits_flag ) begin
                if ( accu_ker_strd_cont < ker_strd-1'b1 )
                    accu_ker_strd_cont  <= accu_ker_strd_cont+1'b1;
                else
                    accu_ker_strd_cont  <= 0;
            end else begin
                accu_ker_strd_cont  <= accu_ker_strd_cont;
            end
        end else begin
            accu_ker_strd_cont  <= 0;
        end
    end
    //====================================== ACCU CTRL ======================================
    //====================================== FC   CTRL ======================================

    assign fc_bits_flag = ( fc_bits_cont == Bit_serial );
    always @ ( posedge clk ) begin
        if ( rst ) begin
            fc_bits_cont  <=  0;
        end else if ( ( fc_s != FC_S_INIT ) && ( fc_bits_flag == 0 ) ) begin
            fc_bits_cont  <=  fc_bits_cont+1'b1;
        end else begin
            fc_bits_cont  <=  0;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst && FC_CHANGE_ROW && FC_CACL_FIN ) begin
            fc_s        <=  FC_S_INIT;
        end else begin
            fc_s        <=  fc_s_n;
        end
    end
    always @ ( * ) begin
        case ( fc_s ) 
            FC_S_INIT : begin
                if ( read_fc_fsm_start ) 
                    fc_s_n      = FC_S_CACL;
                else
                    fc_s_n      = FC_S_INIT;
            end
            FC_S_CACL : begin
                if ( fc_bits_flag )
                    fc_s_n  = FC_S_CACL;
                else
                    fc_s_n  = FC_S_WAIT;
            end
            FC_S_WAIT : begin
                if ( read_fc_fsm_start )
                    fc_s_n  = FC_S_CACL;
                else
                    fc_s_n  = FC_S_WAIT;
            end
            default : begin
                fc_s_n      = FC_S_INIT;
            end
        endcase
    end
    always @ ( posedge clk ) begin
        if ( rst && FC_CHANGE_ROW && FC_CACL_FIN )
            fc_read_en <= 1'b0;
        else if ( fc_s==FC_S_CACL && fc_bits_flag )
            fc_read_en <= 1'b1;
        else
            fc_read_en <= 1'b0;
    end
    always @ ( posedge clk ) begin
        if ( rst )
            fc_tile_sel_bk  <= 0;
        else if ( fc_s_n == FC_S_CACL && fc_bits_flag ) begin
            fc_tile_sel_bk  <= 3'b111;
        end else begin
            fc_tile_sel_bk  <= 0;
        end
    end
    generate
        for ( x_var=0 ; x_var<BK_NUM ; x_var=x_var+1 ) begin
            always @ ( posedge clk ) begin
                if ( fc_s == FC_S_INIT ) begin
                    fc_bk_oaddr[x_var]  <=0;
                end else if ( rst ) begin // Turn Tile, Fully Connect index ++
                    fc_bk_oaddr[x_var]  <= fc_bk_oaddr[x_var]+1'b1;
                end else begin
                    fc_bk_oaddr[x_var]  <= fc_bk_oaddr[x_var];
                end
            end
        end
    endgenerate

    assign FC_CHANGE_ROW    = ( fc_tile_x == (obuf_tile_size_x-1'b1));
    assign FC_CACL_FIN      = ( fc_tile_y == (obuf_tile_size_y-1'b1));
    
    always @ ( posedge clk ) begin
        if ( fc_s == FC_S_INIT ) begin
            fc_tile_x       <= 0;
        end else if ( rst ) begin
            if ( FC_CHANGE_ROW )
                fc_tile_x       <= 0;
            else
                fc_tile_x       <= fc_tile_x+1'b1;
        end else begin
            fc_tile_x       <= fc_tile_x;
        end
    end
    always @ ( posedge clk ) begin
        if ( fc_s == FC_S_INIT ) begin
            fc_tile_y       <= 0;
        end else if ( rst && FC_CHANGE_ROW ) begin
            fc_tile_y   <= fc_tile_y+1'b1;
        end else begin
            fc_tile_y       <= fc_tile_y;
        end
    end

    //====================================== FC   CTRL ======================================
    //====================================== POOL CTRL ======================================
    always @ ( * ) begin
        pool_ctrl_              = ( pool_size_cont_x == 0 && pool_size_cont_y == 0 ) ? POOL_CTRL_SET : POOL_CTRL_COMPARE;
    end
    always @ ( posedge clk )
        if ( rst )
            pool_ctrl           <= POOL_CTRL_SET;
        else
            pool_ctrl           <= pool_ctrl_;


    always @ ( posedge clk )
        if ( rst )
            pool_s              <= POOL_S_INIT;
        else
            pool_s              <= pool_s_n;

    pip_passing #(1, 3) pool_ctrl_pip_passing(
        .clk                (clk),
        .idata              (pool_ctrl),
        .odata              (pool_ctrl_pip_out)
    );
    always @ ( * ) begin
        case ( pool_s )
            POOL_S_INIT : begin
                if ( pool_fsm_start )
                    pool_s_n    = POOL_S_CACL;
                else
                    pool_s_n    = POOL_S_INIT;
            end
            POOL_S_CACL : begin
                //if ( POOL_SIZE_X_FLAG && POOL_SIZE_Y_FLAG && POOL_CHANGE_ROW && POOL_CACL_FIN ) begin
                if ( pool_write_en && POOL_CHANGE_ROW && POOL_CACL_FIN ) begin
                    pool_s_n    = POOL_S_INIT;
                end else begin
                    pool_s_n    = POOL_S_CACL;
                end
            end
            default : pool_s_n    = POOL_S_INIT;
        endcase
    end
    assign POOL_CHANGE_ROW = ( pool_tile_write_x == (obuf_tile_size_x_aft_pool-1'b1));
    assign POOL_CACL_FIN = ( pool_tile_write_y == (obuf_tile_size_y_aft_pool-1'b1));
    
    always @ ( posedge clk )
        if ( rst )
            pool_write_en           <= 1'b0;
        else if ( pool_s == POOL_S_CACL && (pool_size_cont_x == pool_size-2) && POOL_SIZE_Y_FLAG )
            pool_write_en           <=1'b1;
        else
            pool_write_en           <=1'b0;
    always @ ( posedge clk ) begin
        if ( rst )
            pool_tile_write_x       <= 0;
        //else if ( pool_s == POOL_S_CACL && POOL_SIZE_X_FLAG && POOL_SIZE_Y_FLAG ) begin
        else if ( pool_write_en ) begin
            if ( POOL_CHANGE_ROW )
                pool_tile_write_x       <= 0;
            else
                pool_tile_write_x       <= pool_tile_write_x+1'b1;
        end else begin
            pool_tile_write_x       <= pool_tile_write_x;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst )
            pool_tile_write_y       <= 0;
        //else if ( pool_s == POOL_S_CACL && POOL_SIZE_X_FLAG && POOL_SIZE_Y_FLAG && POOL_CHANGE_ROW ) begin
        else if ( pool_write_en && POOL_CHANGE_ROW ) begin
            if ( POOL_CACL_FIN )
                pool_tile_write_y   <= 0;
            else 
                pool_tile_write_y   <= pool_tile_write_y+1'b1;
        end else begin
            pool_tile_write_y       <= pool_tile_write_y;
        end
    end

    always @ ( posedge clk ) begin
        if ( rst ) begin
            pool_tile_ori_x     <= 0;
        end else begin
            pool_tile_ori_x     <=  pool_tile_ori_x_;
        end
    end
    always @ ( * ) begin
        //if ( pool_s == POOL_S_CACL && POOL_SIZE_X_FLAG && POOL_SIZE_Y_FLAG ) begin
        if ( pool_write_en ) begin
            if ( POOL_CHANGE_ROW ) begin
                pool_tile_ori_x_    = 0;
            end else begin
                pool_tile_ori_x_    = pool_tile_ori_x + pool_strd;
            end
        end else begin
            pool_tile_ori_x_    = pool_tile_ori_x;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst ) begin
            pool_tile_ori_y     <= 0;
        end else begin
            pool_tile_ori_y     <= pool_tile_ori_y_;
        end
    end
    always @ ( * ) begin
        //if ( pool_s == POOL_S_CACL && POOL_SIZE_X_FLAG && POOL_SIZE_Y_FLAG && POOL_CHANGE_ROW ) begin
        if ( pool_write_en && POOL_CHANGE_ROW ) begin
            if ( POOL_CACL_FIN ) begin
                pool_tile_ori_y_    = 0;
            end else begin
                pool_tile_ori_y_    = pool_tile_ori_y + pool_strd;    
            end
        end else begin
            pool_tile_ori_y_    = pool_tile_ori_y;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst ) begin
            pool_tile_sel_x     <= 0;
        end else if ( pool_s == POOL_S_CACL ) begin
            if ( POOL_SIZE_X_FLAG )
                pool_tile_sel_x     <= pool_tile_ori_x_;
            else
                pool_tile_sel_x     <= pool_tile_sel_x+1'b1;
        end else begin
            pool_tile_sel_x     <= 0;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst ) begin
            pool_tile_sel_y     <= 0;
        end else if ( pool_s == POOL_S_CACL && POOL_SIZE_X_FLAG ) begin
            if ( POOL_SIZE_Y_FLAG ) begin
                pool_tile_sel_y     <= pool_tile_ori_y_;
            end else begin
                pool_tile_sel_y     <= pool_tile_sel_y+1'b1;
            end
        end else begin
            pool_tile_sel_y     <= pool_tile_sel_y;
        end
    end
    assign POOL_SIZE_X_FLAG = (pool_size_cont_x == pool_size-1);
    always @ ( posedge clk ) begin
        if ( rst ) begin
            pool_size_cont_x    <= 0;
        end else if ( pool_s == POOL_S_CACL ) begin
            if ( POOL_SIZE_X_FLAG )
                pool_size_cont_x    <= 0;
            else 
                pool_size_cont_x    <= pool_size_cont_x+1'b1;
        end else begin
            pool_size_cont_x    <= 0;
        end
    end
    assign POOL_SIZE_Y_FLAG = (pool_size_cont_y == pool_size-1);
    always @ ( posedge clk ) begin
        if ( rst ) begin
            pool_size_cont_y    <= 0;
        end else if ( pool_s == POOL_S_CACL && POOL_SIZE_X_FLAG ) begin
            if ( POOL_SIZE_Y_FLAG )
                pool_size_cont_y    <= 0;
            else
                pool_size_cont_y    <= pool_size_cont_y+1'b1;
        end else begin
            pool_size_cont_y    <= pool_size_cont_y;
        end
    end

    assign lookup_table_index_x_pool = pool_tile_sel_x;
    assign lookup_table_index_y_pool = pool_tile_sel_y;

    //======================== PIP 1 ========================
    lookup_table_y_bk u_read_pool_lookup_table_y_bk(
        .clk                (clk),
        .index_x            (lookup_table_index_x_pool),
        .index_y            (lookup_table_index_y_pool),
        .offset_x           (obuf_tile_size_x),
        .bk_combine         (bk_combine),
        .index_bk_1         (lookup_table_bk_pool),
        .address_output     (lookup_table_output_pool)
    );
    assign pool_tile_sel_bk = lookup_table_bk_pool;
    //======================== PIP 1 ========================
    //======================== PIP 2 ========================

        //============================= POOL - LOOKUP TABLE =============================
    always @ ( posedge clk ) begin
        pool_tile_sel_bk_1              <= pool_tile_sel_bk;
        if ( rst ) begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                pool_bk_oaddr[i]        <= 0;
            end
        end else begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                if ( pool_tile_sel_bk[i] || bk_combine == 1'b0 )
                    pool_bk_oaddr[i]    <= lookup_table_output_pool;
                else
                    pool_bk_oaddr[i]    <= 9'dx;
            end
        end
    end
    assign lookup_table_index_x = ( OBUF_FINISH_FLAG ) ? ( Is_Upsample ) ? {1'b0,user_obuf_oaddr_x[1+:HALF_ADDR_SIZE-1]}
                                                                          : user_obuf_oaddr_x
                                                         : 0;
    assign lookup_table_index_y = ( OBUF_FINISH_FLAG ) ? ( Is_Upsample ) ? {1'b0,user_obuf_oaddr_y[1+:HALF_ADDR_SIZE-1]} 
                                                                           : user_obuf_oaddr_y
                                                         : 0;
    assign lookup_table_offset_x =  user_read_obuf_tile_size_x;
    lookup_table_y_bk u_yolo_user_lookup_table_y_bk(
        .clk                (clk),
        .index_x            (lookup_table_index_x),
        .index_y            (lookup_table_index_y),
        .offset_x           (user_read_obuf_tile_size_x),
        .bk_combine         (bk_combine),
        .index_bk_1         (lookup_table_bk),
        .address_output     (lookup_table_output)
    );


    assign user_obuf_bk = ( bk_combine == 1 ) ? lookup_table_bk
                                              : user_obuf_oaddr_z_bk;
    always @ ( posedge clk ) begin
        user_obuf_oaddr_z_bk        <= ( user_obuf_oaddr_z == 2'b00 )    ? 3'b001 /*OCH 0-7 */
                                     : ( user_obuf_oaddr_z == 2'b01 )    ? 3'b010 /*OCH 0-7 */
                                     : ( user_obuf_oaddr_z == 2'b10 )    ? 3'b100 /*OCH 8-15*/
                                                                         : 3'b000;
        user_obuf_bk_1              <= user_obuf_bk;
        if ( rst ) begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                user_bk_oaddr[i]    <= 0;
            end
        end else begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                if ( user_obuf_bk[i] )
                    user_bk_oaddr[i] <= lookup_table_output;
                else
                    user_bk_oaddr[i] <= {(BK_ADDR_SIZE){1'bx}};
            end
        end
    end
endmodule