`timescale 1ns / 1ps
module OBUF_WRITE_CTRL#(
    parameter       BK_ADDR_SIZE                =   9,          // one bank length is 408 = 9'b1_1001_1000 9 bits
    parameter       BK_NUM                      =   3,          // 3 Output Bank form a 3x3 conv output channel                                                            // 1 Output Bank form a 1x1 conv output channel
    parameter       HALF_ADDR_SIZE              =   6,
    parameter       SETTING_SIZE                =   4,
    parameter       KER_SIZE_MODE               =   0,
    parameter       KER_STRD_MODE               =   1,
    parameter       WRITE_S_INIT                =   0,
    parameter       WRITE_S_IDLE                =   1,
    parameter       WRITE_S_CACL                =   2,
    parameter       FC_S_INIT                   =   0,
    parameter       FC_S_CACL                   =   1,
    parameter       FC_S_WAIT                   =   2,
    parameter       POOL_S_INIT                 =   0,
    parameter       POOL_S_CACL                 =   1,
    parameter       CONV_MODE                   =   2'b00,
    parameter       FC_MODE                     =   2'b01,
    parameter       DECONV_MODE                 =   2'b10,
    parameter       DWC_MODE                    =   2'b11
)(
    input                                           clk,
                                                    rst,
                                                    write_fc_fsm_start,
                                                    write_fsm_start,
                                                    write_pool_fsm_start,
                                                    have_pool,
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
/*
    input           [HALF_ADDR_SIZE-1'b1:0]         x_obuf_tile_size_x_bef_pool,
                                                    x_obuf_tile_size_y_bef_pool,
                                                    x_obuf_tile_size_x_aft_pool,
                                                    x_obuf_tile_size_y_aft_pool,
*/
    output  reg     [BK_NUM-1:0]                    write_en,
    output  reg     [BK_NUM*BK_ADDR_SIZE-1:0]       write_iaddr,
    output  reg                                     WRITE_STATE_FINISH,
    input           [1:0]                           CONV_FLAG,
    input                                           DECONV_ODD_EVEN_FLAG
);
    //====================================== WRITE ACCU CTRL ======================================  
    wire                                            WRITE_IDLE_FIN, WRITE_CACL_FIN, WRITE_ALL_CACL_FIN, WRITE_STRD_FLAG;
    reg             [HALF_ADDR_SIZE-1'b1:0]         write_tile_x_, write_tile_y_,
                                                    write_tile_x , write_tile_y;
    reg                                             write_size_strd_mode;
    reg             [SETTING_SIZE-1:0]              write_ker_size_cont,
                                                    write_ker_strd_cont;
    wire                                            write_read_en;
    reg             [BK_NUM-1:0]                    write_tile_sel_bk;
    reg             [BK_ADDR_SIZE-1:0]              write_bk_iaddr[0:BK_NUM-1];
    wire                                            write_bits_flag;
    reg             [3:0]                           write_bits_cont;
    reg             [1:0]                           write_s, write_s_n;
    //====================================== WRITE ACCU CTRL ======================================
    //====================================== FC   CTRL ======================================
    wire                                            fc_bits_flag;
    reg             [3:0]                           fc_bits_cont;
    reg             [1:0]                           fc_s, fc_s_n;
    wire                                            FC_CHANGE_ROW,
                                                    FC_CACL_FIN;
    reg             [(HALF_ADDR_SIZE)-1:0]          fc_tile_x,
                                                    fc_tile_y;
    reg                                             fc_write_en;
    reg             [BK_NUM-1:0]                    fc_tile_sel_bk;
    reg             [BK_ADDR_SIZE-1:0]              fc_bk_iaddr[0:BK_NUM-1];
    //====================================== FC   CTRL ======================================
    //====================================== WRITE POOL CTRL ======================================
    wire                                            POOL_CHANGE_ROW, POOL_CACL_FIN;
    reg                                             pool_write_en;
    reg             [HALF_ADDR_SIZE-1:0]            pool_tile_write_x, pool_tile_write_y;
    reg             [SETTING_SIZE-1:0]              pool_size_cont_x,
                                                    pool_size_cont_y;
    wire                                            POOL_SIZE_X_FLAG,POOL_SIZE_Y_FLAG;
    reg                                             pool_s, pool_s_n;
        //============================= POOL - LOOKUP TABLE =============================
    reg                                             pool_write_en_1,
                                                    pool_write_en_2;
    wire            [BK_NUM-1:0]                    pool_tile_write_bk;
    reg             [BK_NUM-1:0]                    pool_tile_write_bk_1;
    reg             [BK_ADDR_SIZE-1:0]              pool_bk_iaddr[0:BK_NUM-1];
        //============================= POOL - LOOKUP TABLE =============================
    //====================================== POOL CTRL ======================================
    //====================================== LOOKUP TABLE ======================================
    wire           [HALF_ADDR_SIZE-1:0]             lookup_table_index_x,
                                                    lookup_table_index_y;
    wire            [BK_NUM-1:0]                    lookup_table_bk;
    wire            [BK_ADDR_SIZE-1'b1:0]           lookup_table_output;
    //====================================== LOOKUP TABLE ======================================
    //====================================== WRITE POOL CTRL ======================================
    integer                                         i;
    always @ ( posedge clk ) begin
        if ( rst ) begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                write_en[i]                                     <= 0;
                write_iaddr[(i)*(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)] <= 0;
            end
        end else begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                write_en[i]                                     <= ( have_pool ) ? ( bk_combine ) ? pool_write_en_2 && pool_tile_write_bk_1[i] 
                                                                                                               : pool_write_en_2
                                                                 : ( CONV_FLAG == FC_MODE )   ? fc_tile_sel_bk[i]
                                                                 : ( CONV_FLAG == CONV_MODE ) ? write_tile_sel_bk[i] && write_read_en
                                                                 : ( CONV_FLAG == DWC_MODE  ) ? write_tile_sel_bk[i] && write_read_en
                                                                 : ( CONV_FLAG == DECONV_MODE)? write_tile_sel_bk[i] && write_read_en
                                                                                              : 1'b0;
                write_iaddr[(i)*(BK_ADDR_SIZE)+:(BK_ADDR_SIZE)] <= ( have_pool ) ? pool_bk_iaddr[(i)] 
                                                                 : ( CONV_FLAG == FC_MODE )   ? fc_bk_iaddr[(i)]
                                                                 : ( CONV_FLAG == CONV_MODE ) ? write_bk_iaddr[(i)]
                                                                 : ( CONV_FLAG == DWC_MODE  ) ? write_bk_iaddr[(i)]
                                                                 : ( CONV_FLAG == DECONV_MODE)?{write_bk_iaddr[(i)][BK_ADDR_SIZE-1:1],DECONV_ODD_EVEN_FLAG}
                                                                                              : 0;
            end
        end
    end
    //====================================== WRITE ACCU CTRL ======================================
    assign write_read_en = (write_s == WRITE_S_CACL) ? write_bits_flag : 1'b0;
    always @ ( posedge clk ) begin
        if ( rst )
            write_tile_sel_bk   <= 0;
        else begin
            if ( write_s == WRITE_S_INIT ) begin
                if ( bk_combine ) begin
                    if ( CONV_FLAG == DECONV_MODE )
                        write_tile_sel_bk   <= 3'b011;      // 8 Bank througput one time
                    else
                        write_tile_sel_bk   <= 3'b001;      // 8 Bank througput one time
                end else
                    write_tile_sel_bk   <= 3'b111;      // 24 Bank througput one time
//            end else if ( obuf_read_cont_x == obuf_tile_size_x-1'b1 && read_bits_flag ) begin
            end else if ( write_s == WRITE_S_CACL && write_bits_flag && WRITE_CACL_FIN ) begin
                if ( CONV_FLAG == DECONV_MODE )
                    write_tile_sel_bk   <= {write_tile_sel_bk[0],write_tile_sel_bk[2:1]};
                else
                    write_tile_sel_bk   <= {write_tile_sel_bk[1:0],write_tile_sel_bk[2]};
            end else begin
                write_tile_sel_bk   <= write_tile_sel_bk;
            end
        end
    end
    genvar x_var;
    generate
        for ( x_var=0 ; x_var<BK_NUM ; x_var=x_var+1 ) begin
            always @ ( posedge clk ) begin
                if ( rst ) begin
                    write_bk_iaddr[x_var]    <= 0;
                end else if ( write_tile_sel_bk[x_var] && write_read_en ) begin
                    write_bk_iaddr[x_var]    <= write_bk_iaddr[x_var]+1'b1;
                end
            end
        end
    endgenerate

    assign WRITE_IDLE_FIN       = ( write_s != WRITE_S_INIT ) ? ( write_size_strd_mode == KER_SIZE_MODE ) ? (write_ker_size_cont == (ker_size-2'b10)) && (write_bits_flag)
                                                                                                          : (write_ker_strd_cont == (ker_strd-1'b1 )) && (write_bits_flag)
                                                              : 1'b0;
    assign WRITE_CACL_FIN       = write_bits_flag && write_tile_x == obuf_tile_size_x-1'b1 && write_ker_strd_cont == 0;
    assign WRITE_ALL_CACL_FIN   = WRITE_CACL_FIN && write_tile_y == obuf_tile_size_y-1'b1;
    assign WRITE_STRD_FLAG      = write_bits_flag && ( write_size_strd_mode == KER_STRD_MODE ) && ( write_ker_strd_cont != ker_strd-1'b1 );
    always @ ( posedge clk ) begin
          WRITE_STATE_FINISH  <= ( have_pool ) ? ( pool_s  == POOL_S_CACL )  && ( pool_s_n  == POOL_S_INIT )
                               : ( CONV_FLAG == CONV_MODE ) ? ( write_s == WRITE_S_CACL ) && ( write_s_n == WRITE_S_INIT )
                               : ( CONV_FLAG == FC_MODE )   ? ( fc_s == FC_S_CACL ) && ( fc_s_n == FC_S_WAIT )
                               : ( CONV_FLAG == DWC_MODE )  ? ( write_s == WRITE_S_CACL ) && ( write_s_n == WRITE_S_INIT )
                               : ( CONV_FLAG == DECONV_MODE)? ( write_s == WRITE_S_CACL ) && ( write_s_n == WRITE_S_INIT )
                               : 1'b0; 
    end
/*
    assign WRITE_STATE_FINISH   = ( have_pool ) ? ( pool_s  == POOL_S_CACL )  && ( pool_s_n  == POOL_S_INIT )
                                                : ( write_s == WRITE_S_CACL ) && ( write_s_n == WRITE_S_INIT ); 
*/
    always @ ( posedge clk )
        if ( rst )
            write_s     <= WRITE_S_INIT;
        else 
            write_s     <= write_s_n;
    always @ ( * ) begin
        case ( write_s )
            WRITE_S_INIT : begin
                if ( write_fsm_start ) begin
                    if ( ker_size == 1 )
                        write_s_n       = WRITE_S_CACL;
                    else
                        write_s_n       = WRITE_S_IDLE;
                end else 
                    write_s_n       = WRITE_S_INIT;
            end
            WRITE_S_IDLE : begin
                if ( WRITE_IDLE_FIN )
                    write_s_n       = WRITE_S_CACL;
                else
                    write_s_n       = WRITE_S_IDLE;
            end
            WRITE_S_CACL : begin
                if ( WRITE_CACL_FIN ) begin
                    if ( WRITE_ALL_CACL_FIN ) begin
                        write_s_n    = WRITE_S_INIT;
                    end else if ( ker_size == 1 ) begin
                        write_s_n    = WRITE_S_CACL;
                    end else begin
                        write_s_n    = WRITE_S_IDLE;
                    end
                end else begin
                    if ( WRITE_STRD_FLAG ) begin
                        write_s_n    = WRITE_S_IDLE;
                    end else begin
                        write_s_n    = WRITE_S_CACL;
                    end
                end
            end
            default : begin
                write_s_n       = WRITE_S_INIT;
            end
        endcase
    end
    assign write_bits_flag = ( write_bits_cont == Bit_serial );
    always @ ( posedge clk ) begin
        if ( rst ) begin
            write_bits_cont  <=  0;
        end else if ( ( write_s != WRITE_S_INIT ) && ( write_bits_flag == 0 ) ) begin
            write_bits_cont  <=  write_bits_cont+1'b1;
        end else begin
            write_bits_cont  <=  0;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst )
            write_size_strd_mode  <= KER_SIZE_MODE;
        else begin
            if ( WRITE_CACL_FIN )
                write_size_strd_mode  <= KER_SIZE_MODE;
            else if( WRITE_IDLE_FIN ) begin
                write_size_strd_mode  <= KER_STRD_MODE;
            end  else begin
                write_size_strd_mode  <= write_size_strd_mode;
            end
        end
    end

    always @ ( posedge clk ) begin
        if ( rst )
            write_tile_x    <= 0;
        else
            write_tile_x    <= write_tile_x_;
    end
    always @ ( * ) begin
        if ( write_s == WRITE_S_CACL && write_bits_flag ) begin
            if ( WRITE_CACL_FIN )
                write_tile_x_   = 0;
            else
                write_tile_x_   = write_tile_x+1'b1;
        end else begin
            write_tile_x_   = write_tile_x;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst )
            write_tile_y <= 0;
        else
            write_tile_y <= write_tile_y_;
    end
    always @ ( * ) begin
        if ( write_s == WRITE_S_CACL && write_bits_flag ) begin
            if ( WRITE_CACL_FIN ) begin
                if ( WRITE_ALL_CACL_FIN ) begin
                    write_tile_y_   = 0;
                end else begin
                    write_tile_y_   = write_tile_y+1'b1;
                end
            end else begin
                write_tile_y_   = write_tile_y;
            end
        end else begin
            write_tile_y_   = write_tile_y;
        end 
    end
    always @ ( posedge clk ) begin
        if ( rst ) begin
            write_ker_size_cont  <= 0;
        end else if ( write_s != WRITE_S_INIT && write_size_strd_mode == KER_SIZE_MODE ) begin
            if ( write_bits_flag ) begin
                if ( write_ker_size_cont < ker_size-2'b10 )
                    write_ker_size_cont  <= write_ker_size_cont+1'b1;
                else
                    write_ker_size_cont  <= 0;
            end else begin
                write_ker_size_cont  <= write_ker_size_cont;
            end
        end else begin
            write_ker_size_cont  <= 0;
        end
    end
    
    always @ ( posedge clk ) begin
        if ( rst ) begin
            write_ker_strd_cont  <= 0;
        end else if ( write_s != WRITE_S_INIT && write_size_strd_mode == KER_STRD_MODE ) begin
            if ( write_bits_flag ) begin
                if ( write_ker_strd_cont < ker_strd-1'b1 )
                    write_ker_strd_cont  <= write_ker_strd_cont+1'b1;
                else
                    write_ker_strd_cont  <= 0;
            end else begin
                write_ker_strd_cont  <= write_ker_strd_cont;
            end
        end else begin
            write_ker_strd_cont  <= 0;
        end
    end
    //====================================== WRITE ACCU CTRL ======================================
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
                if ( write_fc_fsm_start ) 
                    fc_s_n      = FC_S_CACL;
                else
                    fc_s_n      = FC_S_INIT;
            end
            FC_S_CACL : begin
                if ( fc_bits_flag )
                    fc_s_n  = FC_S_WAIT;
                else
                    fc_s_n  = FC_S_CACL;
            end
            FC_S_WAIT : begin
                if ( write_fc_fsm_start )
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
            fc_write_en <= 1'b0;
        else if ( fc_s==FC_S_CACL && fc_bits_flag )
            fc_write_en <= 1'b1;
        else
            fc_write_en <= 1'b0;
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
        for ( x_var=0 ;x_var<BK_NUM ; x_var=x_var+1 ) begin
            always @ ( posedge clk ) begin
                if ( fc_s == FC_S_INIT ) begin
                    fc_bk_iaddr[x_var]  <=0;
                end else if ( rst ) begin // Turn Tile, Fully Connect index ++
                    fc_bk_iaddr[x_var]  <= fc_bk_iaddr[x_var]+1'b1;
                end else begin
                    fc_bk_iaddr[x_var]  <= fc_bk_iaddr[x_var];
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
    //====================================== WRITE POOL CTRL ======================================
    always @ ( posedge clk )
        if ( rst )
            pool_s          <= POOL_S_INIT;
        else 
            pool_s          <= pool_s_n;
    always @ ( * ) begin
        case ( pool_s )
            POOL_S_INIT : begin
                if ( write_pool_fsm_start )
                    pool_s_n    = POOL_S_CACL;
                else
                    pool_s_n    = POOL_S_INIT;
            end
            POOL_S_CACL : begin
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

    // 
    assign lookup_table_index_x = pool_tile_write_x;
    assign lookup_table_index_y = pool_tile_write_y;
    //======================== PIP 1 ========================
    always @ ( posedge clk ) begin
        pool_write_en_1                 <= pool_write_en;
    end
    lookup_table_y_bk u_write_pool_lookup_table_y_bk(
        .clk                (clk),
        .index_x            (lookup_table_index_x),
        .index_y            (lookup_table_index_y),
        .offset_x           (obuf_tile_size_x_aft_pool),
        .bk_combine         (bk_combine),
        .index_bk_1         (lookup_table_bk),
        .address_output     (lookup_table_output)
    );

    assign pool_tile_write_bk = lookup_table_bk;
    //======================== PIP 1 ========================
    //======================== PIP 2 ========================
        //============================= POOL - LOOKUP TABLE =============================
    always @ ( posedge clk ) begin
        pool_write_en_2                 <= pool_write_en_1;
        pool_tile_write_bk_1            <= pool_tile_write_bk;
        if ( rst ) begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                pool_bk_iaddr[i]        <= 0;
            end
        end else begin
            for ( i=0 ; i<BK_NUM ; i=i+1 ) begin
                if ( pool_tile_write_bk[i] || bk_combine == 1'b0 )
                    pool_bk_iaddr[i]    <= lookup_table_output;
                else
                    pool_bk_iaddr[i]    <= pool_bk_iaddr[i];
            end
        end
    end
        //============================= POOL - LOOKUP TABLE =============================
    /*
        * One Problem : Why Don't Use pool_tile_write_x, pool_tile_write_y In OBUF_READ_CTRL ?
        * 1. Example : pool_tile_write_x In OBUF_READ_CTRL called OR_ptw_x, Trigger every pool_size^2 cycles
        * 2. If OBUF_WRITE_CTRL need that signal, we need pip passing the address OR_ptr_x a lot of cycles
        * 3. If Pool_size is 8, when OR_ptw_x turn out, we need pip passing 64 cycles
    */
    //====================================== WRITE POOL CTRL ======================================
endmodule