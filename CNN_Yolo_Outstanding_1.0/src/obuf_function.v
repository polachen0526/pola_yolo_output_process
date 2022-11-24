`timescale 1ns / 1ps
`define MODULE_WORD_SIZE_hw 16
`define HW_ADD_SIZE_hw          (`MODULE_WORD_SIZE_hw/2)*3+7
`define HW_ADD_SIZE_hw_DWC      (`MODULE_WORD_SIZE_hw/2)*3+5
module pip_passing #(
    parameter       DATA_WIDTH      =   16,
    parameter       PIP_NUM         =   2
)(
    input                                           clk,
    input           [(DATA_WIDTH)-1:0]              idata,
    output          [(DATA_WIDTH)-1:0]              odata
);
    reg             [(((DATA_WIDTH)*(PIP_NUM))-1):0]    pip_data;
    always @ ( posedge clk ) begin
        pip_data    <=  { pip_data[0+:((DATA_WIDTH)*(PIP_NUM-1))] ,idata};
    end
    assign  odata = pip_data[(DATA_WIDTH)*(PIP_NUM-1)+:(DATA_WIDTH)];
endmodule

module LINE_BUFFER#(
    parameter       HALF_ADDR_SIZE  =   6,
    parameter       WORD_SIZE       =   16,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       TILE_NUM        =   2,
    parameter       PE_ARRAY_4_v    =   8,
    parameter       PE_ARRAY_3_v    =   3,
    parameter       PE_ARRAY_2_v    =   3,
    parameter       PE_ARRAY_1_v    =   8,
    parameter       PE_ARRAY_1_2_v  =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v  =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v      =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v,
    parameter       KERNEL_3x3      =   9,
    parameter       MAX_TILE_ROW    =   6
)(
    input                                                       clk,
                                                                set_isize,
    input                                                       bk_combine,
    input           [HALF_ADDR_SIZE-1'b1:0]                     obuf_tile_size_x,         
    input           [PE_ARRAY_3_4_v*WORD_SIZE-1:0]              pwc_idata,
/*
    pwc_idata FORM
    OCH : [23][15][ 7][22][14][ 6].....[16][ 8][ 0]
    BANK: [23][22][21][20][19][18].....[ 2][ 1][ 0]
*/
    output  reg     [PE_ARRAY_3_4_v*KERNEL_3x3*TILE_NUM-1:0]    linebuffer_sign_array,
    output  reg     [PE_ARRAY_3_4_v*KERNEL_3x3*WORD_SIZE-1:0]   linebuffer_array
);
    reg             [PE_ARRAY_3_4_v*WORD_SIZE-1:0]              pwc_idata_;
    reg             [PE_ARRAY_3_4_v*TILE_NUM -1:0]              pwc_idata_sign_;
    reg             [PE_ARRAY_3_4_v*TILE_NUM -1:0]              line_buffer_sign_0  [0:MAX_TILE_ROW-1];
    reg             [PE_ARRAY_3_4_v*TILE_NUM -1:0]              line_buffer_sign_1  [0:MAX_TILE_ROW-1];
    reg             [PE_ARRAY_3_4_v*TILE_NUM -1:0]              line_buffer_sign_2  [0:2];
    reg             [PE_ARRAY_3_4_v*WORD_SIZE-1:0]              line_buffer_0       [0:MAX_TILE_ROW-1];
    reg             [PE_ARRAY_3_4_v*WORD_SIZE-1:0]              line_buffer_1       [0:MAX_TILE_ROW-1];
    reg             [PE_ARRAY_3_4_v*WORD_SIZE-1:0]              line_buffer_2       [0:2];
    reg             [PE_ARRAY_3_4_v*WORD_SIZE*3-1:0]            line_buffer_1_selc,
                                                                line_buffer_0_selc;
    reg             [PE_ARRAY_3_4_v*TILE_NUM *3-1:0]            line_buffer_sign_1_selc,
                                                                line_buffer_sign_0_selc;
    integer                                                     i;
always @ ( * ) begin
    for ( i=0 ; i<PE_ARRAY_3_4_v ; i=i+1 ) begin
        linebuffer_array        [((0) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_0_selc       [( (0)*(PE_ARRAY_3_4_v)+(i) )*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((1) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_0_selc       [( (1)*(PE_ARRAY_3_4_v)+(i) )*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((2) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_0_selc       [( (2)*(PE_ARRAY_3_4_v)+(i) )*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((3) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_1_selc       [( (0)*(PE_ARRAY_3_4_v)+(i) )*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((4) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_1_selc       [( (1)*(PE_ARRAY_3_4_v)+(i) )*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((5) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_1_selc       [( (2)*(PE_ARRAY_3_4_v)+(i) )*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((6) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_2            [0][(i)*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((7) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_2            [1][(i)*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_array        [((8) + (i  )*(KERNEL_3x3))*(WORD_SIZE)+:(WORD_SIZE)] =line_buffer_2            [2][(i)*(WORD_SIZE)+:(WORD_SIZE)];
        linebuffer_sign_array   [((0) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_0_selc  [( (0)*(PE_ARRAY_3_4_v)+(i) )*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((1) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_0_selc  [( (1)*(PE_ARRAY_3_4_v)+(i) )*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((2) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_0_selc  [( (2)*(PE_ARRAY_3_4_v)+(i) )*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((3) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_1_selc  [( (0)*(PE_ARRAY_3_4_v)+(i) )*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((4) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_1_selc  [( (1)*(PE_ARRAY_3_4_v)+(i) )*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((5) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_1_selc  [( (2)*(PE_ARRAY_3_4_v)+(i) )*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((6) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_2       [0][(i)*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((7) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_2       [1][(i)*(TILE_NUM )+:(TILE_NUM )];
        linebuffer_sign_array   [((8) + (i  )*(KERNEL_3x3))*(TILE_NUM )+:(TILE_NUM )] =line_buffer_sign_2       [2][(i)*(TILE_NUM )+:(TILE_NUM )];
    end
end
    
genvar x_var;
generate
    for ( x_var=0  ; x_var < PE_ARRAY_3_4_v*TILE_NUM ; x_var=x_var+1 ) begin
        if ( (x_var%TILE_NUM) == (TILE_NUM-1) ) begin
            always @ ( * ) begin
                pwc_idata_sign_  [(x_var)]  = pwc_idata[(x_var+1)*(HALF_SIZE)-1];
            end
        end else begin
            always @ ( * ) begin
                pwc_idata_sign_  [(x_var)]  = ( set_isize == 0 ) ? pwc_idata[(x_var+1)*(HALF_SIZE)-1] : 1'b0;
            end
        end
        always @ ( * ) begin
            pwc_idata_       [(x_var)*(HALF_SIZE)+:(HALF_SIZE)] = 
                                    ( pwc_idata_sign_[(x_var)] )
                                             ? -(pwc_idata[(x_var)*(HALF_SIZE)+:(HALF_SIZE)])
                                             :  (pwc_idata[(x_var)*(HALF_SIZE)+:(HALF_SIZE)]);
        end
    end
endgenerate

    always @ ( * ) begin
        line_buffer_1_selc      [0+:(3)*(PE_ARRAY_3_4_v)*(WORD_SIZE)] = {line_buffer_1        [MAX_TILE_ROW-obuf_tile_size_x+2],line_buffer_1         [MAX_TILE_ROW-obuf_tile_size_x+1],line_buffer_1         [MAX_TILE_ROW-obuf_tile_size_x]};
        line_buffer_0_selc      [0+:(3)*(PE_ARRAY_3_4_v)*(WORD_SIZE)] = {line_buffer_0        [MAX_TILE_ROW-obuf_tile_size_x+2],line_buffer_0         [MAX_TILE_ROW-obuf_tile_size_x+1],line_buffer_0         [MAX_TILE_ROW-obuf_tile_size_x]};
        line_buffer_sign_1_selc [0+:(3)*(PE_ARRAY_3_4_v)*(TILE_NUM )] = {line_buffer_sign_1   [MAX_TILE_ROW-obuf_tile_size_x+2],line_buffer_sign_1    [MAX_TILE_ROW-obuf_tile_size_x+1],line_buffer_sign_1    [MAX_TILE_ROW-obuf_tile_size_x]};
        line_buffer_sign_0_selc [0+:(3)*(PE_ARRAY_3_4_v)*(TILE_NUM )] = {line_buffer_sign_0   [MAX_TILE_ROW-obuf_tile_size_x+2],line_buffer_sign_0    [MAX_TILE_ROW-obuf_tile_size_x+1],line_buffer_sign_0    [MAX_TILE_ROW-obuf_tile_size_x]};
    end 
    always @ ( posedge clk ) begin
                                                                                                                //            Tile Row Current
                                                                                                                //                   down
        line_buffer_0[MAX_TILE_ROW-1]               <= line_buffer_1_selc[0+:(PE_ARRAY_3_4_v)*(WORD_SIZE)];     //ROW 0     [ ][ ]>>>[ ]>>>[ ]>>>>>>>>>[ ]>>>[ ]>>>[ ]>>>[ ]
                                                                                                                //                   up                      
                                                                                                                //                   |---------------------- 
                                                                                                                //                                         up
        line_buffer_1[MAX_TILE_ROW-1]               <= line_buffer_2[0];                                        //ROW 1     [ ]>>>[ ]>>>[ ]>>>[ ]>>>>>>>>>[ ]>>>[ ]>>>[ ]>>>[ ]
                                                                                                                //                   up                       
                                                                                                                //                   |---------------------- 
                                                                                                                //                                         up
        line_buffer_2[2]                            <= pwc_idata_;                                              //ROW 2                           [ ]>>>[ ]>>>[ ]
                                                                                                                //                                 up
                                                                                                                //              PWC_SPE_OUT--------up
        for ( i=0 ; i<MAX_TILE_ROW-1; i=i+1 ) begin
        line_buffer_0[i]                            <= line_buffer_0[i+1];
        end
        for ( i=0 ; i<MAX_TILE_ROW-1; i=i+1 ) begin
        line_buffer_1[i]                            <= line_buffer_1[i+1];
        end
        for ( i=0 ; i<2             ; i=i+1 ) begin
        line_buffer_2[i]                            <= line_buffer_2[i+1];
        end

        line_buffer_sign_0[MAX_TILE_ROW-1]          <= line_buffer_sign_1_selc[0+:(PE_ARRAY_3_4_v)*(TILE_NUM)];       
        line_buffer_sign_1[MAX_TILE_ROW-1]          <= line_buffer_sign_2[0];       
        line_buffer_sign_2[2]                       <= pwc_idata_sign_;           
        for ( i=0 ; i<MAX_TILE_ROW-1; i=i+1 ) begin
        line_buffer_sign_0[i]                       <= line_buffer_sign_0[i+1];
        end
        for ( i=0 ; i<MAX_TILE_ROW-1; i=i+1 ) begin
        line_buffer_sign_1[i]                       <= line_buffer_sign_1[i+1];
        end
        for ( i=0 ; i<2             ; i=i+1 ) begin
        line_buffer_sign_2[i]                       <= line_buffer_sign_2[i+1];
        end
    end
/*
    reg             [WORD_SIZE-1:0]              line_buffer_0_show       [0:MAX_TILE_ROW-1];
    reg             [WORD_SIZE-1:0]              line_buffer_1_show       [0:MAX_TILE_ROW-1];
    reg             [WORD_SIZE-1:0]              line_buffer_2_show       [0:2];
    always @ ( * )  begin
        for ( i=0 ; i<MAX_TILE_ROW ; i=i+1 )begin
        line_buffer_0_show[i] = line_buffer_0[i][0+:(WORD_SIZE)];
        line_buffer_1_show[i] = line_buffer_1[i][0+:(WORD_SIZE)];
        end
        for ( i=0 ; i<3 ; i=i+1 )begin
        line_buffer_2_show[i] = line_buffer_2[i][0+:(WORD_SIZE)];
        end
    end
*/
endmodule

module IBUF_DATA_ARRAY_PROCESSING #(
    parameter       WORD_SIZE                   =   16,
    parameter       HALF_SIZE                   =   WORD_SIZE/2,
    parameter       TILE_NUM                    =   2,
    parameter       PE_ARRAY_4_v                =   8,
    parameter       PE_ARRAY_3_v                =   3,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_1_2_v              =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v              =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v                  =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v
)(
    input                                                           clk,
                                                                    set_isize,
    input                                                           bk_combine,
                                                                    DECONVING,
    input           [PE_ARRAY_1_2_v*WORD_SIZE-1:0]                  data,
    output  reg     [PE_ARRAY_1_2_v*PE_ARRAY_3_v*TILE_NUM-1:0]      data_sign_array,
    output  reg     [PE_ARRAY_1_2_v*PE_ARRAY_3_v*WORD_SIZE-1:0]     data_array
);

    reg             [PE_ARRAY_1_2_v*PE_ARRAY_3_v*TILE_NUM-1:0]      data_sign_array_;
    reg             [PE_ARRAY_1_2_v*PE_ARRAY_3_v*WORD_SIZE-1:0]     data_array_;
    reg             [PE_ARRAY_1_2_v*TILE_NUM-1:0]                   data_sign_1;
    reg             [PE_ARRAY_1_2_v*WORD_SIZE-1:0]                  data_1;
    integer                                                         i,j,k;
/*
    reg [WORD_SIZE-1:0] Data_0_0 [0:2],
                        Data_0_1 [0:2],
                        Data_0_2 [0:2],
                        Data_1_0 [0:2],
                        Data_1_1 [0:2],
                        Data_1_2 [0:2],
                        Data_2_0 [0:2],
                        Data_2_1 [0:2],
                        Data_2_2 [0:2],
                        Data_3_0 [0:2],
                        Data_3_1 [0:2],
                        Data_3_2 [0:2],
                        Data_4_0 [0:2],
                        Data_4_1 [0:2],
                        Data_4_2 [0:2],
                        Data_5_0 [0:2],
                        Data_5_1 [0:2],
                        Data_5_2 [0:2],
                        Data_6_0 [0:2],
                        Data_6_1 [0:2],
                        Data_6_2 [0:2],
                        Data_7_0 [0:2],
                        Data_7_1 [0:2],
                        Data_7_2 [0:2];
    reg [WORD_SIZE-1:0] Data_array_for_show[0:71];
    reg [WORD_SIZE-1:0] Data_0   [0:7],
                        Data_1   [0:7],
                        Data_2   [0:7];

    wire     [PE_ARRAY_1_2_v*PE_ARRAY_3_v*WORD_SIZE-1:0]     data_array_pip;
    pip_passing #( PE_ARRAY_1_2_v*PE_ARRAY_3_v*WORD_SIZE, 10) u_pip_passing(
        .clk(clk),
        .idata(data_array),
        .odata(data_array_pip)
    );

    always @ ( * ) begin
        for ( i=0 ; i<8 ; i=i+1 ) begin
        for ( j=0 ; j<3 ; j=j+1 ) begin
        for ( k=0 ; k<3 ; k=k+1 ) begin
            Data_array_for_show[(j*3)+(2-k)+i*9] = data_array_pip[((j*3+(2-k))*(PE_ARRAY_1_v)+i)*(WORD_SIZE)+:(WORD_SIZE)];
        end
        end
        end
    end

    always @ ( * ) begin
for ( i=0 ; i<3 ; i=i+1 )begin
    Data_0_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+0)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_0_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+0)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_0_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+0)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_1_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+1)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_1_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+1)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_1_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+1)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_2_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+2)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_2_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+2)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_2_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+2)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_3_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+3)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_3_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+3)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_3_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+3)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_4_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+4)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_4_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+4)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_4_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+4)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_5_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+5)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_5_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+5)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_5_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+5)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_6_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+6)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_6_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+6)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_6_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+6)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_7_0[i] = data_array_pip[((3*0+i)*(PE_ARRAY_1_v)+7)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_7_1[i] = data_array_pip[((3*1+i)*(PE_ARRAY_1_v)+7)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_7_2[i] = data_array_pip[((3*2+i)*(PE_ARRAY_1_v)+7)*(WORD_SIZE)+:(WORD_SIZE)];
end
for ( i=0 ; i<8 ; i=i+1 )begin
    Data_0[i] = data_array[((0)*(PE_ARRAY_1_v)+i)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_1[i] = data_array[((1)*(PE_ARRAY_1_v)+i)*(WORD_SIZE)+:(WORD_SIZE)];
    Data_2[i] = data_array[((2)*(PE_ARRAY_1_v)+i)*(WORD_SIZE)+:(WORD_SIZE)];
end
    end
*/
genvar x_var;
generate
    for ( x_var=0  ; x_var < PE_ARRAY_1_2_v*TILE_NUM ; x_var=x_var+1 ) begin
        if ( (x_var%TILE_NUM) == (TILE_NUM-1) ) begin
            always @ ( * ) begin
                data_sign_1  [(x_var)]  = data[(x_var+1)*(HALF_SIZE)-1];
            end
        end else begin
            always @ ( * ) begin
                data_sign_1  [(x_var)]  = ( set_isize == 0 ) ? data[(x_var+1)*(HALF_SIZE)-1] : 1'b0;
            end
        end
        always @ ( * ) begin
            data_1       [(x_var)*(HALF_SIZE)+:(HALF_SIZE)] = 
                ( data_sign_1[(x_var)] ) ? -(data[(x_var)*(HALF_SIZE)+:(HALF_SIZE)])
                                         :  (data[(x_var)*(HALF_SIZE)+:(HALF_SIZE)]) ;
        end
    end
endgenerate
    always @ ( posedge clk ) begin
        data_array_     [(2) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_1           [(0)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(2)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(1) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_array_      [(2)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(1)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(0) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_array_      [(1)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(0)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(5) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_1           [(1)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(2)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(4) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_array_      [(5)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(1)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(3) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_array_      [(4)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(0)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(8) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_1           [(2)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(2)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(7) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_array_      [(8)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(1)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array_     [(6) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]  <= (  bk_combine   ) ? data_array_      [(7)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]
                                                                                                             : data_1           [(0)    *(PE_ARRAY_1_v  )*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_sign_array_[(2) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_1      [(0)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(2)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(1) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_array_ [(2)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(1)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(0) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_array_ [(1)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(0)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(5) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_1      [(1)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(2)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(4) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_array_ [(5)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(1)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(3) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_array_ [(4)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(0)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(8) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_1      [(2)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(2)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(7) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_array_ [(8)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(1)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array_[(6) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]  <= (  bk_combine   ) ? data_sign_array_ [(7)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]
                                                                                                             : data_sign_1      [(0)    *(PE_ARRAY_1_v  )*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
    end
    always @ ( * ) begin
        data_array      [(0) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =   (DECONVING ) ? data_array_     [(1) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(0) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(1) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =   (DECONVING ) ? data_array_     [(2) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(1) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(2) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =  ( DECONVING ) ? data_array_     [(4) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(2) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(3) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =  ( DECONVING ) ? data_array_     [(5) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(3) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(4) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =  ( DECONVING ) ? {PE_ARRAY_1_v*WORD_SIZE{1'b0}}                                                : data_array_     [(4) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(5) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =  ( DECONVING ) ? data_array_     [(4) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(5) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(6) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =  ( DECONVING ) ? data_array_     [(5) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(6) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(7) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =  ( DECONVING ) ? data_array_     [(7) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(7) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_array      [(8) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)]    =  ( DECONVING ) ? data_array_     [(8) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)] : data_array_     [(8) *(PE_ARRAY_1_v)*(WORD_SIZE)+:(PE_ARRAY_1_v)*(WORD_SIZE)];
        data_sign_array [(0) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(1) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(0) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(1) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(2) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(1) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(2) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(4) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(2) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(3) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(5) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(3) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(4) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? {PE_ARRAY_1_v*TILE_NUM{1'b0}}                                                 : data_sign_array_[(4) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(5) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(4) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(5) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(6) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(5) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(6) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(7) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(7) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(7) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
        data_sign_array [(8) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )]    =  ( DECONVING ) ? data_sign_array_[(8) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )] : data_sign_array_[(8) *(PE_ARRAY_1_v)*(TILE_NUM )+:(PE_ARRAY_1_v)*(TILE_NUM )];
    end
endmodule
module wbuf_spe_store#(
    parameter       A_BUF           =   0,
    parameter       B_BUF           =   1,
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE       =   WORD_SIZE/2,
    parameter       TILE_NUM        =   2,
    parameter       AXI_DATA_WIDTH  =   8,
    parameter       PE_ARRAY_4_v    =   8,
    parameter       PE_ARRAY_3_v    =   3,
    parameter       PE_ARRAY_2_v    =   3,
    parameter       PE_ARRAY_1_v    =   8,
    parameter       PE_ARRAY_1_2_v  =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v  =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v      =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v,
    parameter       WBUF_CONV       =   0,
    parameter       WBUF_DWC        =   1
)(
    input           [3:0]                               ker_size,
    input                                               bk_combine,
    input                                               clk,
                                                        wbuf_rst_A,
                                                        wbuf_rst_B,
                                                        WBUF_AB_LOAD_FLAG,
                                                        WBUF_AB_CACL_FLAG,
                                                        WBUF_CONV_OR_DWC_SPE_FLAG,
    input           [(PE_ARRAY_3_4_v)-1:0]              WBUF_SPE_LOAD_OCH_FLAG,
    input                                               wbuf_addr_spe_weight_cont,
    input           [(AXI_DATA_WIDTH)*(TILE_NUM)-1:0]   wdata_in_sign,
    input           [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]  wdata_in,
    output reg      [(PE_ARRAY_3_4_v)*(TILE_NUM)-1:0]   wdata_out_alpha_sign,
    output reg      [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]  wdata_out_alpha,
                                                        wdata_out_beta,
    output reg      [(PE_ARRAY_3_4_v)*(TILE_NUM)-1:0]   wdata_out_dwc_alpha_sign,
    output reg      [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]  wdata_out_dwc_alpha,
                                                        wdata_out_dwc_beta
);
    reg             [(PE_ARRAY_3_4_v)*(TILE_NUM)-1:0]   wdata_spe_sign_;
    reg             [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]  wdata_spe_;
    reg             [(PE_ARRAY_3_4_v)*(TILE_NUM)-1:0]   wdata_spe_a_alpha_sign,
                                                        wdata_spe_b_alpha_sign;
    reg             [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]  wdata_spe_a_alpha,
                                                        wdata_spe_a_beta,
                                                        wdata_spe_b_alpha,
                                                        wdata_spe_b_beta;
    
    reg             [(PE_ARRAY_3_4_v)*(TILE_NUM)-1:0]   wdata_spe_dwc_a_alpha_sign,
                                                        wdata_spe_dwc_b_alpha_sign;
    reg             [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]  wdata_spe_dwc_a_alpha,
                                                        wdata_spe_dwc_a_beta,
                                                        wdata_spe_dwc_b_alpha,
                                                        wdata_spe_dwc_b_beta;
    integer                                             i;
    always @ ( * ) begin
        wdata_out_alpha_sign    = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_spe_a_alpha_sign       : wdata_spe_b_alpha_sign    ;            
        wdata_out_alpha         = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_spe_a_alpha            : wdata_spe_b_alpha         ;
        wdata_out_beta          = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_spe_a_beta             : wdata_spe_b_beta          ;
        wdata_out_dwc_alpha_sign= ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_spe_dwc_a_alpha_sign   : wdata_spe_dwc_b_alpha_sign;            
        wdata_out_dwc_alpha     = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_spe_dwc_a_alpha        : wdata_spe_dwc_b_alpha     ;
        wdata_out_dwc_beta      = ( WBUF_AB_CACL_FLAG == A_BUF ) ? wdata_spe_dwc_a_beta         : wdata_spe_dwc_b_beta      ;
    end

/*
bk_combine     1  :  0  
                        OCH
[ 0]       <=       [0]  0
[ 1]       <= [0] : [0]  8
[ 2]       <=       [0] 16
[ 3]       <=       [1]  1
[ 4]       <= [1] : [1]  9
[ 5]       <=       [1] 17
[ 6]       <=       [2]  2
[ 7]       <= [2] : [2] 10
[ 8]       <=       [2] 18
[ 9]       <=       [3]  3
[10]       <= [3] : [3] 11
[11]       <=       [3] 19
[12]       <=       [4]  4
[13]       <= [4] : [4] 12
[14]       <=       [4] 20
[15]       <=       [5]  5
[16]       <= [5] : [5] 13
[17]       <=       [5] 21
[18]       <=       [6]  6
[19]       <= [6] : [6] 14
[20]       <=       [6] 22
[21]       <=       [7]  7
[22]       <= [7] : [7] 15
[23]       <=       [7] 23
*/
    always @ ( * ) begin
        for ( i=0 ; i<8 ; i=i+1 ) begin
            wdata_spe_sign_ [((i)*(3)+(0 ))*(TILE_NUM)+:(TILE_NUM)] = wdata_in_sign[(i )*(TILE_NUM)+:(TILE_NUM)];
            wdata_spe_sign_ [((i)*(3)+(1 ))*(TILE_NUM)+:(TILE_NUM)] = wdata_in_sign[(i )*(TILE_NUM)+:(TILE_NUM)];
            wdata_spe_sign_ [((i)*(3)+(2 ))*(TILE_NUM)+:(TILE_NUM)] = wdata_in_sign[(i )*(TILE_NUM)+:(TILE_NUM)];            
            wdata_spe_      [((i)*(3)+(0 ))*(WORD_SIZE)+:(WORD_SIZE)] = wdata_in[(i )*(WORD_SIZE)+:(WORD_SIZE)];
            wdata_spe_      [((i)*(3)+(1 ))*(WORD_SIZE)+:(WORD_SIZE)] = wdata_in[(i )*(WORD_SIZE)+:(WORD_SIZE)];
            wdata_spe_      [((i)*(3)+(2 ))*(WORD_SIZE)+:(WORD_SIZE)] = wdata_in[(i )*(WORD_SIZE)+:(WORD_SIZE)];
        end
    end
    reg         [1:0]  WBUF_SPE_LOAD_WEIGHT_FLAG;
    always @ ( * ) begin
        case ( wbuf_addr_spe_weight_cont )
            0 : WBUF_SPE_LOAD_WEIGHT_FLAG = 2'b01;
            1 : WBUF_SPE_LOAD_WEIGHT_FLAG = 2'b10;
            default : WBUF_SPE_LOAD_WEIGHT_FLAG = 2'b00;
        endcase
    end

    always @ ( posedge clk ) begin
        if ( wbuf_rst_A ) begin
            wdata_spe_a_alpha_sign  <= 0;
            wdata_spe_a_alpha       <= 0;
            wdata_spe_a_beta        <= 0;
        end else if ( WBUF_AB_LOAD_FLAG == A_BUF && WBUF_CONV_OR_DWC_SPE_FLAG == WBUF_CONV ) begin
            for ( i=0 ; i<PE_ARRAY_3_4_v ; i=i+1 ) begin
                if ( WBUF_SPE_LOAD_OCH_FLAG[i] ) begin
                    if ( WBUF_SPE_LOAD_WEIGHT_FLAG[0] ) begin
                        wdata_spe_a_alpha_sign[(i)*(TILE_NUM) +:(TILE_NUM)]                 <=                                          wdata_spe_sign_  [(i)*(TILE_NUM) +:(TILE_NUM)];
                        wdata_spe_a_alpha     [(i)*(WORD_SIZE)+:(WORD_SIZE)]                <=                                          wdata_spe_       [(i)*(WORD_SIZE)+:(WORD_SIZE)];
                    end else if ( WBUF_SPE_LOAD_WEIGHT_FLAG[1] ) begin
                        wdata_spe_a_beta      [(i)*(WORD_SIZE)            +:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+0] ) ? -wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)];
                        wdata_spe_a_beta      [(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+1] ) ? -wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)];
                    end
                end
            end
        end
    end
    always @ ( posedge clk ) begin
        if ( wbuf_rst_B) begin
            wdata_spe_b_alpha_sign  <= 0;
            wdata_spe_b_alpha       <= 0;
            wdata_spe_b_beta        <= 0;
        end else if ( WBUF_AB_LOAD_FLAG == B_BUF && WBUF_CONV_OR_DWC_SPE_FLAG == WBUF_CONV ) begin
            for ( i=0 ; i<PE_ARRAY_3_4_v ; i=i+1 ) begin
                if ( WBUF_SPE_LOAD_OCH_FLAG[i] ) begin
                    if ( WBUF_SPE_LOAD_WEIGHT_FLAG[0] ) begin
                        wdata_spe_b_alpha_sign[(i)*(TILE_NUM) +:(TILE_NUM)]                 <=                                          wdata_spe_sign_  [(i)*(TILE_NUM) +:(TILE_NUM)];
                        wdata_spe_b_alpha     [(i)*(WORD_SIZE)+:(WORD_SIZE)]                <=                                          wdata_spe_       [(i)*(WORD_SIZE)+:(WORD_SIZE)];
                    end else if ( WBUF_SPE_LOAD_WEIGHT_FLAG[1] ) begin
                        wdata_spe_b_beta      [(i)*(WORD_SIZE)            +:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+0] ) ? -wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)];
                        wdata_spe_b_beta      [(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+1] ) ? -wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)];
                    end
                end
            end
        end
    end
    always @ ( posedge clk ) begin
        if ( wbuf_rst_A ) begin
            wdata_spe_dwc_a_alpha_sign  <= 0;
            wdata_spe_dwc_a_alpha       <= 0;
            wdata_spe_dwc_a_beta        <= 0;
        end else if ( WBUF_AB_LOAD_FLAG == A_BUF && WBUF_CONV_OR_DWC_SPE_FLAG == WBUF_DWC ) begin
            for ( i=0 ; i<PE_ARRAY_3_4_v ; i=i+1 ) begin
                if ( WBUF_SPE_LOAD_OCH_FLAG[i] ) begin
                    if ( WBUF_SPE_LOAD_WEIGHT_FLAG[0] ) begin
                        wdata_spe_dwc_a_alpha_sign[(i)*(TILE_NUM) +:(TILE_NUM)]                 <=                                          wdata_spe_sign_  [(i)*(TILE_NUM) +:(TILE_NUM)];
                        wdata_spe_dwc_a_alpha     [(i)*(WORD_SIZE)+:(WORD_SIZE)]                <=                                          wdata_spe_       [(i)*(WORD_SIZE)+:(WORD_SIZE)];
                    end else if ( WBUF_SPE_LOAD_WEIGHT_FLAG[1] ) begin
                        wdata_spe_dwc_a_beta      [(i)*(WORD_SIZE)            +:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+0] ) ? -wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)];
                        wdata_spe_dwc_a_beta      [(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+1] ) ? -wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)];
                    end
                end
            end
        end
    end
    always @ ( posedge clk ) begin
        if ( wbuf_rst_B) begin
            wdata_spe_dwc_b_alpha_sign  <= 0;
            wdata_spe_dwc_b_alpha       <= 0;
            wdata_spe_dwc_b_beta        <= 0;
        end else if ( WBUF_AB_LOAD_FLAG == B_BUF && WBUF_CONV_OR_DWC_SPE_FLAG == WBUF_DWC ) begin
            for ( i=0 ; i<PE_ARRAY_3_4_v ; i=i+1 ) begin
                if ( WBUF_SPE_LOAD_OCH_FLAG[i] ) begin
                    if ( WBUF_SPE_LOAD_WEIGHT_FLAG[0] ) begin
                        wdata_spe_dwc_b_alpha_sign[(i)*(TILE_NUM) +:(TILE_NUM)]                 <=                                          wdata_spe_sign_  [(i)*(TILE_NUM) +:(TILE_NUM)];
                        wdata_spe_dwc_b_alpha     [(i)*(WORD_SIZE)+:(WORD_SIZE)]                <=                                          wdata_spe_       [(i)*(WORD_SIZE)+:(WORD_SIZE)];
                    end else if ( WBUF_SPE_LOAD_WEIGHT_FLAG[1] ) begin
                        wdata_spe_dwc_b_beta      [(i)*(WORD_SIZE)            +:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+0] ) ? -wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)            +:(HALF_SIZE)];
                        wdata_spe_dwc_b_beta      [(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)]    <= ( wdata_spe_sign_ [(i)*(TILE_NUM)+1] ) ? -wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)] : wdata_spe_[(i)*(WORD_SIZE)+(HALF_SIZE)+:(HALF_SIZE)];
                    end
                end
            end
        end
    end
endmodule

module bitparal_combine#(
    parameter       DATA_IWIDTH     =   99,
    parameter       SHIFTE_VAR      =   55,
    parameter       DATA_OWIDTH     =   1,
    parameter       TILE_NUM        =   2
)(
    input           [(DATA_IWIDTH)*(TILE_NUM)-1:0]  idata,
    output  reg     [(DATA_OWIDTH)-1:0]             odata
);
    reg             [(DATA_OWIDTH)*(TILE_NUM)-1:0]  idata_sign;
    reg             [2:0]                           i;
    //reg             [(DATA_OWIDTH-DATA_IWIDTH)-1:0] sign_show[0:TILE_NUM-1];
    //reg             [(DATA_OWIDTH)-1:0]             idata_sign_show[0:TILE_NUM-1];
    always @ ( * ) begin
        odata = 0;
        for ( i=0 ; i < TILE_NUM ; i=i+1 ) begin
            idata_sign[(DATA_OWIDTH)*(i)+:(DATA_OWIDTH)]    = {{(DATA_OWIDTH-DATA_IWIDTH){idata[(DATA_IWIDTH)*((i)+1)-1]}},     //Signed extension
                                                            idata[(DATA_IWIDTH)*(i)+:(DATA_IWIDTH)]};                         //origin data
            //sign_show[(i)] = {(DATA_OWIDTH-DATA_IWIDTH){idata[(DATA_IWIDTH)*((i)+1)-1]}};
            odata                                           = odata + (idata_sign[(DATA_OWIDTH)*i+:(DATA_OWIDTH)] << (SHIFTE_VAR*i)) ;
            //idata_sign_show[(i)]                            = idata_sign[(DATA_OWIDTH)*i+:(DATA_OWIDTH)] << (SHIFTE_VAR*i) ;
        end
    end
endmodule
module bitparal_adder#(
    parameter       DATA_IWIDTH     =   99,
    parameter       DATA_OWIDTH     =   1,
    parameter       TILE_NUM        =   2
)(
    input                                           add_en,
                                                    set_isize,
    input           [(DATA_IWIDTH)*(TILE_NUM)-1:0]  idata,
                                                    wdata,
    output          [(DATA_OWIDTH)*(TILE_NUM)-1:0]  odata
);
    wire            [(DATA_OWIDTH)*(TILE_NUM)-1:0]  idata_,wdata_;
genvar x_var;
generate
    for ( x_var=0 ; x_var<TILE_NUM ; x_var=x_var+1 )begin

        if ( x_var == (TILE_NUM)-1 ) begin
            assign idata_[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)] = {{(DATA_OWIDTH-DATA_IWIDTH){idata[(DATA_IWIDTH)*(x_var+1)-1]}},idata[(DATA_IWIDTH)*(x_var)+:(DATA_IWIDTH)]};
            assign wdata_[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)] = {{(DATA_OWIDTH-DATA_IWIDTH){wdata[(DATA_IWIDTH)*(x_var+1)-1]}},wdata[(DATA_IWIDTH)*(x_var)+:(DATA_IWIDTH)]};
        end else begin
            assign idata_[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)] = ( set_isize == 0 ) ?
                    {{(DATA_OWIDTH-DATA_IWIDTH){idata[(DATA_IWIDTH)*(x_var+1)-1]}},idata[(DATA_IWIDTH)*(x_var)+:(DATA_IWIDTH)]}
                   :{{(DATA_OWIDTH-DATA_IWIDTH){1'b0}}                            ,idata[(DATA_IWIDTH)*(x_var)+:(DATA_IWIDTH)]};
            assign wdata_[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)] = ( set_isize == 0 ) ?
                    {{(DATA_OWIDTH-DATA_IWIDTH){wdata[(DATA_IWIDTH)*(x_var+1)-1]}},wdata[(DATA_IWIDTH)*(x_var)+:(DATA_IWIDTH)]}
                   :{{(DATA_OWIDTH-DATA_IWIDTH){1'b0}}                            ,wdata[(DATA_IWIDTH)*(x_var)+:(DATA_IWIDTH)]};
        end
        
        assign odata[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)] = ( add_en ) ?
                             idata_[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)]+wdata_[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)]
                            :idata_[(DATA_OWIDTH)*(x_var)+:(DATA_OWIDTH)];
    end
endgenerate
endmodule

module satuation_oper#(
    parameter       DATA_IWIDTH     =   19,
    parameter       DATA_OWIDTH     =   16
)(
    input           [DATA_IWIDTH-1:0]               idata,
    output          [DATA_OWIDTH-1:0]               odata
);
    assign          odata   = ( idata[DATA_IWIDTH-1] == 1 ) ? (  &idata[DATA_IWIDTH-1:DATA_OWIDTH-1] == 1 ) ? idata[DATA_OWIDTH-1:0] : {1'b1,{DATA_OWIDTH-1{1'b0}}}
                                                            : (!(|idata[DATA_IWIDTH-1:DATA_OWIDTH-1])== 1 ) ? idata[DATA_OWIDTH-1:0] : {1'b0,{DATA_OWIDTH-1{1'b1}}} ;
endmodule

module AXI_WDATA_PROCESSING #(
    parameter       TILE_NUM                    =   2,
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE                   =   WORD_SIZE/2,
    parameter       AXI_DATA_WIDTH              =   8
) (
    input                                               clk,
                                                        set_wsize,
    input           [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]  axi_wdata,
    output  reg     [(AXI_DATA_WIDTH)*(TILE_NUM)-1:0]   axi_wdata_sign_out,
    output  reg     [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]  axi_wdata_out
);
    reg             [(AXI_DATA_WIDTH)*(TILE_NUM)-1:0]   axi_wdata_sign_1;
    reg             [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]  axi_wdata_1;
    reg             [(AXI_DATA_WIDTH)*(TILE_NUM)-1:0]   axi_wdata_sign_2;
    reg             [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]  axi_wdata_2;
    reg             [(AXI_DATA_WIDTH)*(TILE_NUM)-1:0]   axi_wdata_sign_3;
    reg             [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]  axi_wdata_3;
    genvar x_var;
    generate
        for ( x_var = 0 ; x_var < AXI_DATA_WIDTH*TILE_NUM ; x_var=x_var+1 ) begin
            if ( (x_var%TILE_NUM) == (TILE_NUM-1) ) begin
                always @ ( * ) begin
                    axi_wdata_sign_1[x_var] = ( axi_wdata[(x_var+1)*(HALF_SIZE)-1] ) ;
                end        
            end else begin
                always @ ( * ) begin
                    axi_wdata_sign_1[x_var] = ( set_wsize == 0 ) ? ( axi_wdata[(x_var+1)*(HALF_SIZE)-1] )
                                                                 : 1'b0;
                end        
            end
            always @ ( * ) begin
                axi_wdata_1[(x_var)*(HALF_SIZE)+:(HALF_SIZE)] = ( axi_wdata_sign_1[x_var] ) ?  -axi_wdata[(x_var)*(HALF_SIZE)+:(HALF_SIZE)]
                                                                                            :  axi_wdata[(x_var)*(HALF_SIZE)+:(HALF_SIZE)];
            end        
        end
    endgenerate
    always @ ( posedge clk ) begin
        axi_wdata_sign_2    <= axi_wdata_sign_1;
        axi_wdata_2         <= axi_wdata_1;
        axi_wdata_sign_out  <= axi_wdata_sign_2;
        axi_wdata_out       <= axi_wdata_2;
    end
endmodule
module PE_PRODUCD_PROCESSING #(
    parameter       BK_ADDR_SIZE                =   9,          // one bank length is 408 = 9'b1_1001_1000 9 bits
    parameter       BK_NUM                      =   3,          // 3 Output Bank form a 3x3 conv output channel                                                            // 1 Output Bank form a 1x1 conv output channel
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE                   =   WORD_SIZE/2,
    parameter       HW_ADD_SIZE                 =   `HW_ADD_SIZE_hw,
    parameter       HW_ADD_SIZE_SUM             =   HW_ADD_SIZE+HALF_SIZE,
    parameter       TILE_NUM                    =   2,
    parameter       AXI_DATA_WIDTH              =   8,
    parameter       PE_ARRAY_4_v                =   8,
    parameter       PE_ARRAY_3_v                =   3,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_1_2_v              =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v              =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v                  =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v    
) (
    input                                                           clk,
                                                                    set_isize,
                                                                    bk_combine,
                                                                    DECONVING,
    input           [BK_NUM-1:0]                                    read_en_pre,
    input           [5:0]                                           quant_pe,
    input           [(PE_ARRAY_3_4_v)*(HW_ADD_SIZE)-1:0]            add_odata_H,
                                                                    add_odata_L,
    output  reg     [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              PE_product
);
    

    wire            [(PE_ARRAY_3_4_v)*(HW_ADD_SIZE)-1:0]            add_odata_H_sh,
                                                                    add_odata_L_sh;
    wire            [(PE_ARRAY_3_4_v)*(HALF_SIZE)-1:0]              add_odata_H_sat,
                                                                    add_odata_L_sat;
    wire            [(PE_ARRAY_3_4_v)*(HW_ADD_SIZE_SUM)-1:0]        add_odata_H_L,
                                                                    add_odata_H_L_sh;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              add_odata_H_L_sat;
    genvar x_var;
    generate
    for ( x_var = 0 ; x_var < PE_ARRAY_3_4_v ; x_var=x_var+1 ) begin
        assign add_odata_H_sh[(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)] = $signed(add_odata_H[(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)]) >>> quant_pe;
        assign add_odata_L_sh[(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)] = $signed(add_odata_L[(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)]) >>> quant_pe;
        satuation_oper #(HW_ADD_SIZE, HALF_SIZE) pe_array_half_H_sat(
            .idata(add_odata_H_sh   [(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)]),
            .odata(add_odata_H_sat  [(x_var)*(HALF_SIZE)+:(HALF_SIZE)])
        );
        satuation_oper #(HW_ADD_SIZE, HALF_SIZE) pe_array_half_L_sat(
            .idata(add_odata_L_sh   [(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)]),
            .odata(add_odata_L_sat  [(x_var)*(HALF_SIZE)+:(HALF_SIZE)])
        );
        bitparal_combine #(HW_ADD_SIZE, HALF_SIZE, HW_ADD_SIZE_SUM, 2) pe_array_bitparal_combine(
            .idata({add_odata_H     [(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)],add_odata_L[(x_var)*(HW_ADD_SIZE)+:(HW_ADD_SIZE)]}),
            .odata(add_odata_H_L    [(x_var)*(HW_ADD_SIZE_SUM)+:(HW_ADD_SIZE_SUM)])
        );
        assign add_odata_H_L_sh[(x_var)*(HW_ADD_SIZE_SUM)+:(HW_ADD_SIZE_SUM)] = $signed(add_odata_H_L[(x_var)*(HW_ADD_SIZE_SUM)+:(HW_ADD_SIZE_SUM)]) >>> quant_pe;
        satuation_oper #(HW_ADD_SIZE_SUM, WORD_SIZE) pe_array_word_sat(
            .idata(add_odata_H_L_sh [(x_var)*(HW_ADD_SIZE_SUM)+:(HW_ADD_SIZE_SUM)]),
            .odata(add_odata_H_L_sat[(x_var)*(WORD_SIZE)+:(WORD_SIZE)])
        );
    end
    for ( x_var = 0 ; x_var < PE_ARRAY_4_v ; x_var=x_var+1 ) begin
        always @ ( * ) begin
        PE_product[((x_var)*(PE_ARRAY_3_v)+(0 ))*(WORD_SIZE)+:(WORD_SIZE)] = 
        ( DECONVING ) ? ( read_en_pre[0] ) ? ( read_en_pre[1] ) ? ( set_isize == 0 ) ? {add_odata_H_sat     [((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                                                                     :  add_odata_H_L_sat   [((x_var)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)]
                                                                : ( set_isize == 0 ) ? {add_odata_H_sat     [((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                                                                     :  add_odata_H_L_sat   [((x_var)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)]
                                            : 0
                      : ( set_isize == 0 ) ? {add_odata_H_sat                                               [((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                           :  add_odata_H_L_sat                                             [((x_var)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)];
        PE_product[((x_var)*(PE_ARRAY_3_v)+(1 ))*(WORD_SIZE)+:(WORD_SIZE)] = 
        ( DECONVING ) ? ( read_en_pre[1] ) ? ( read_en_pre[0] ) ? ( set_isize == 0 ) ? {add_odata_H_sat     [((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                                                                     :  add_odata_H_L_sat   [((x_var)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)]
                                                                : ( set_isize == 0 ) ? {add_odata_H_sat     [((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                                                                     :  add_odata_H_L_sat   [((x_var)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)]
                                            : 0
                      : ( set_isize == 0 ) ? {add_odata_H_sat                                               [((x_var)*(PE_ARRAY_3_v)+(1))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(1))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                           :  add_odata_H_L_sat                                             [((x_var)*(PE_ARRAY_3_v)+(1))*(WORD_SIZE)+:(WORD_SIZE)];
        PE_product[((x_var)*(PE_ARRAY_3_v)+(2 ))*(WORD_SIZE)+:(WORD_SIZE)] =
        ( DECONVING ) ? ( read_en_pre[2] ) ? ( read_en_pre[1] ) ? ( set_isize == 0 ) ? {add_odata_H_sat     [((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                                                                     :  add_odata_H_L_sat   [((x_var)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)]
                                                                : ( set_isize == 0 ) ? {add_odata_H_sat     [((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(0))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                                                                     :  add_odata_H_L_sat   [((x_var)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)]
                                            : 0
                      : ( set_isize == 0 ) ? {add_odata_H_sat                                               [((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[((x_var)*(PE_ARRAY_3_v)+(2))*(HALF_SIZE)+:(HALF_SIZE)]} 
                                           :  add_odata_H_L_sat                                             [((x_var)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)];
        end
    end
    endgenerate
endmodule

module PE_DWC_PRODUCD_PROCESSING #(
    parameter       BK_ADDR_SIZE                =   9,          // one bank length is 408 = 9'b1_1001_1000 9 bits
    parameter       BK_NUM                      =   3,          // 3 Output Bank form a 3x3 conv output channel                                                            // 1 Output Bank form a 1x1 conv output channel
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE                   =   WORD_SIZE/2,
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
    parameter       PE_ARRAY_v                  =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v    
) (
    input                                                           clk,
                                                                    set_isize,
                                                                    bk_combine,
    input           [5:0]                                           quant_pe,
    input           [(PE_ARRAY_3_4_v)*(HW_ADD_SIZE_DWC)-1:0]        add_odata_H,
                                                                    add_odata_L,
    output  reg     [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              PE_product
);
    

    wire            [(PE_ARRAY_3_4_v)*(HW_ADD_SIZE_DWC)-1:0]        add_odata_H_sh,
                                                                    add_odata_L_sh;
    wire            [(PE_ARRAY_3_4_v)*(HALF_SIZE)-1:0]              add_odata_H_sat,
                                                                    add_odata_L_sat;
    wire            [(PE_ARRAY_3_4_v)*(HW_ADD_SIZE_DWC_SUM)-1:0]    add_odata_H_L,
                                                                    add_odata_H_L_sh;
    wire            [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              add_odata_H_L_sat;
    genvar x_var;
    generate
    for ( x_var = 0 ; x_var < PE_ARRAY_3_4_v ; x_var=x_var+1 ) begin
        assign add_odata_H_sh[(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)] = $signed(add_odata_H[(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)]) >>> quant_pe;
        assign add_odata_L_sh[(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)] = $signed(add_odata_L[(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)]) >>> quant_pe;
        satuation_oper #(HW_ADD_SIZE_DWC, HALF_SIZE) pe_array_half_H_sat(
            .idata(add_odata_H_sh   [(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)]),
            .odata(add_odata_H_sat  [(x_var)*(HALF_SIZE)+:(HALF_SIZE)])
        );
        satuation_oper #(HW_ADD_SIZE_DWC, HALF_SIZE) pe_array_half_L_sat(
            .idata(add_odata_L_sh   [(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)]),
            .odata(add_odata_L_sat  [(x_var)*(HALF_SIZE)+:(HALF_SIZE)])
        );
        bitparal_combine #(HW_ADD_SIZE_DWC, HALF_SIZE, HW_ADD_SIZE_DWC_SUM, 2) pe_array_bitparal_combine(
            .idata({add_odata_H     [(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)],add_odata_L[(x_var)*(HW_ADD_SIZE_DWC)+:(HW_ADD_SIZE_DWC)]}),
            .odata(add_odata_H_L    [(x_var)*(HW_ADD_SIZE_DWC_SUM)+:(HW_ADD_SIZE_DWC_SUM)])
        );
        assign add_odata_H_L_sh[(x_var)*(HW_ADD_SIZE_DWC_SUM)+:(HW_ADD_SIZE_DWC_SUM)] = $signed(add_odata_H_L[(x_var)*(HW_ADD_SIZE_DWC_SUM)+:(HW_ADD_SIZE_DWC_SUM)]) >>> quant_pe;
        satuation_oper #(HW_ADD_SIZE_DWC_SUM, WORD_SIZE) pe_array_word_sat(
            .idata(add_odata_H_L_sh [(x_var)*(HW_ADD_SIZE_DWC_SUM)+:(HW_ADD_SIZE_DWC_SUM)]),
            .odata(add_odata_H_L_sat[(x_var)*(WORD_SIZE)+:(WORD_SIZE)])
        );
        always @ ( * ) begin
            PE_product[(x_var)*(WORD_SIZE)+:(WORD_SIZE)] = ( set_isize == 0 ) ? {add_odata_H_sat[(x_var)*(HALF_SIZE)+:(HALF_SIZE)],add_odata_L_sat[(x_var)*(HALF_SIZE)+:(HALF_SIZE)]} : add_odata_H_L_sat[(x_var)*(WORD_SIZE)+:(WORD_SIZE)] ;
        end
    end
    endgenerate
endmodule
module OBUF_IDATA_PROCESSING#(
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       PE_ARRAY_4_v                =   8,
    parameter       PE_ARRAY_3_v                =   3,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_1_2_v              =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v              =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v                  =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v    
)(
    input                                                           bk_combine,
                                                                    DECONVING,
    input           [(PE_ARRAY_3_v)-1:0]                            obuf_write_bk,
    input           [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              obuf_idata_,
    output  reg     [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              obuf_idata
);
    integer                                                         i;
    always @ ( * ) begin
        for ( i=0 ; i<PE_ARRAY_4_v ; i=i+1 ) begin

            obuf_idata[((i)*(PE_ARRAY_3_v)+(0 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_write_bk[(0)] ) ? ( bk_combine == 0 || DECONVING ) ? obuf_idata_[((i)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                                       : obuf_idata_[((i)*(PE_ARRAY_3_v)+(1))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                    :                                    16'd0 ;
            obuf_idata[((i)*(PE_ARRAY_3_v)+(1 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_write_bk[(1)] ) ?                                    obuf_idata_[((i)*(PE_ARRAY_3_v)+(1))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                    :                                    16'd0 ;
            obuf_idata[((i)*(PE_ARRAY_3_v)+(2 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_write_bk[(2)] ) ? ( bk_combine == 0 || DECONVING ) ? obuf_idata_[((i)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                                       : obuf_idata_[((i)*(PE_ARRAY_3_v)+(1))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                    :                                    16'd0 ;

        end
    end
endmodule

module OBUF_ACCU_DATA_PROCESSING#(
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       PE_ARRAY_4_v                =   8,
    parameter       PE_ARRAY_3_v                =   3,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_1_2_v              =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v              =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v                  =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v    
)(
    input                                                           bk_combine,
                                                                    DECONVING,
    input           [(PE_ARRAY_3_v)-1:0]                            obuf_accu_bk,
    input           [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              obuf_odata,
    output  reg     [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              obuf_accu_data
);
    integer                                                         i;
/*
    * obuf_accu_data[y] <= (obuf_accu_bk[x]) obuf_odata[z];
    * decide which value of bank goint accumulate
*/
    always @ ( * ) begin
//                                3 OCH Bank    No.OCH Bank                                             3 OCH BANK     3 OCH BANK
//          obuf_accu_data[((i)*(PE_ARRAY_3_v)+(0 ))*(WORD_SIZE)+:(WORD_SIZE)] <= ( obuf_accu_bk[(i)*(PE_ARRAY_3_v)*(PE_ARRAY_3_v)+(0)*(PE_ARRAY_3_v)+(0)] ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)] 
        for ( i=0 ; i<PE_ARRAY_4_v ; i=i+1 ) begin
            // CONV 1x1 : ICH 0, 1, 2, 3, 4, 5, 6, 7
            // CONV 3x3 : None
            obuf_accu_data[((i)*(PE_ARRAY_3_v)+(0 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_accu_bk[(0)] ) ?                       obuf_odata[((i)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                       :                       16'd0 ;
            // CONV 1x1 : ICH 8, 9,10,11,12,13,14,15
            // CONV 3x3 : ICH 0, 1, 2, 3, 4, 5, 6, 7
            obuf_accu_data[((i)*(PE_ARRAY_3_v)+(1 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( bk_combine == 1 && DECONVING == 0) ? ( obuf_accu_bk[(0)] ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                      : ( obuf_accu_bk[(1)] ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(1))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                      : ( obuf_accu_bk[(2)] ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                                              : 16'd0
                                                                                                                      : ( obuf_accu_bk[(1)] ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(1))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                             : 16'd0;

            // CONV 1x1 : ICH 16,17,18,19,20,21,22,23 
            // CONV 3x3 : None
            obuf_accu_data[((i)*(PE_ARRAY_3_v)+(2 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_accu_bk[(2)] ) ?                       obuf_odata[((i)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                       :                       16'd0 ;
        end
    end
endmodule

module OBUF_POOL_DATA_PROCESSING#(
    parameter       WORD_SIZE                   =   `MODULE_WORD_SIZE_hw,
    parameter       PE_ARRAY_4_v                =   8,
    parameter       PE_ARRAY_3_v                =   3,
    parameter       PE_ARRAY_2_v                =   3,
    parameter       PE_ARRAY_1_v                =   8,
    parameter       PE_ARRAY_1_2_v              =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v              =   PE_ARRAY_4_v*PE_ARRAY_3_v,
    parameter       PE_ARRAY_v                  =   PE_ARRAY_3_4_v*PE_ARRAY_1_2_v    
)(
    input                                                           bk_combine,
    input           [(PE_ARRAY_3_v)-1:0]                            obuf_pool_bk,
    input           [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              obuf_odata,
    output  reg     [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]              obuf_pool_idata
);
    integer                                                         i;
/*
    * obuf_pool_idata[y] <= (obuf_pool_bk[x]) obuf_odata[z];
    * decide which value of bank goint accumulate
*/
    always @ ( * ) begin
//                                3 OCH Bank    No.OCH Bank                                             3 OCH BANK     3 OCH BANK
//          obuf_pool_idata[((i)*(PE_ARRAY_3_v)+(0 ))*(WORD_SIZE)+:(WORD_SIZE)] <= ( obuf_pool_bk[(i)*(PE_ARRAY_3_v)*(PE_ARRAY_3_v)+(0)*(PE_ARRAY_3_v)+(0)] ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)] 
        for ( i=0 ; i<PE_ARRAY_4_v ; i=i+1 ) begin
            // CONV 1x1 : ICH 0, 3, 6, 9, 12, 15, 18, 21
            // CONV 3x3 : None
            obuf_pool_idata[((i)*(PE_ARRAY_3_v)+(0 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_pool_bk[(0)] ) ?                      obuf_odata[((i)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                        :                      16'd0 ;
            // CONV 1x1 : ICH 1, 4, 7, 10, 13, 16, 19, 22
            // CONV 3x3 : ICH 0, 1, 2, 3, 4, 5, 6, 7
            obuf_pool_idata[((i)*(PE_ARRAY_3_v)+(1 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_pool_bk[(0)] ) ? ( bk_combine == 1 ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(0))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                              : 16'd0
                                                                                : ( obuf_pool_bk[(1)] ) ?                       obuf_odata[((i)*(PE_ARRAY_3_v)+(1))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                : ( obuf_pool_bk[(2)] ) ? ( bk_combine == 1 ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                                              : 16'd0 
                                                                                                                              : 16'd0 ;
            // CONV 1x1 : ICH 2, 5, 8, 11, 14, 17, 20, 23
            // CONV 3x3 : None
            obuf_pool_idata[((i)*(PE_ARRAY_3_v)+(2 ))*(WORD_SIZE)+:(WORD_SIZE)] = ( obuf_pool_bk[(2)] ) ?                       obuf_odata[((i)*(PE_ARRAY_3_v)+(2))*(WORD_SIZE)+:(WORD_SIZE)] 
                                                                                                        :                       16'd0 ;
        end
    end
endmodule

module OBUF_TO_DRAM_DATA_QUANT_FINISH #(
    parameter       WORD_SIZE                                       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE                                       =   WORD_SIZE/2,
    parameter       WORD_EXT_SIZE                                   =   WORD_SIZE+9,
    parameter       HALF_EXT_SIZE                                   =   HALF_SIZE+9,
    parameter       TILE_NUM                                        =   2,
    parameter       AXI_DATA_WIDTH                                  =   8,
    parameter       PE_ARRAY_4_v                                    =   8,
    parameter       PE_ARRAY_3_v                                    =   3,
    parameter       PE_ARRAY_2_v                                    =   3,
    parameter       PE_ARRAY_1_v                                    =   8,
    parameter       PE_ARRAY_1_2_v                                  =   PE_ARRAY_2_v*PE_ARRAY_1_v,
    parameter       PE_ARRAY_3_4_v                                  =   PE_ARRAY_4_v*PE_ARRAY_3_v
)(
    input                                                               clk, //obuf_Finish
                                                                        OBUF_FINISH_FLAG, //obuf_Finish
                                                                        have_pool_ing,
                                                                        set_isize,
    input           [2:0]                                               read_en_pre,
    input           [5:0]                                               quant_next_layer_,
                                                                        quant_pool_next_layer_,
    input           [(PE_ARRAY_3_4_v)*(WORD_SIZE)-1:0]                  obuf_odata,
    output  reg     [(AXI_DATA_WIDTH)*(WORD_SIZE)-1:0]                  OBUF_TO_DRAM_DATA
);
    reg             [5:0]                                               quant_next_layer;
    reg             [(AXI_DATA_WIDTH)*           (WORD_SIZE)-1      :0] OBUF_TO_DRAM_DATA_;
    reg             [(AXI_DATA_WIDTH)*(TILE_NUM)*(HALF_EXT_SIZE)-1  :0] data_result_ext, data_result_shift;
    wire            [(AXI_DATA_WIDTH)*(TILE_NUM)*(HALF_SIZE)-1      :0] data_result_sat_;
    reg             [(AXI_DATA_WIDTH)*           (WORD_EXT_SIZE)-1  :0] data_result_sum_ext, data_result_sum_shift;
    wire            [(AXI_DATA_WIDTH)*           (WORD_SIZE)-1      :0] data_result_sum_sat_;
    integer                                                            i;
always @ ( posedge clk ) begin
    quant_next_layer <= ( have_pool_ing ) ? quant_pool_next_layer_ : quant_next_layer_;
end

always @ ( * ) begin
    for ( i=0 ; i<AXI_DATA_WIDTH ; i=i+1 ) begin
        OBUF_TO_DRAM_DATA_[(i)*(WORD_SIZE)+:(WORD_SIZE)] = ( OBUF_FINISH_FLAG ) ? (   read_en_pre[(0)]  ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+0)*(WORD_SIZE)+:(WORD_SIZE)] // 1 Bank 1 OCH
                                                                                : (   read_en_pre[(1)]  ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+1)*(WORD_SIZE)+:(WORD_SIZE)] // 1 Bank 1 OCH
                                                                                : (   read_en_pre[(2)]  ) ? obuf_odata[((i)*(PE_ARRAY_3_v)+2)*(WORD_SIZE)+:(WORD_SIZE)] // 1 Bank 1 OCH
                                                                                                          : {(AXI_DATA_WIDTH)*(WORD_SIZE){1'b0}}
                                                                                : {(AXI_DATA_WIDTH)*(WORD_SIZE){1'b0}};
    end
end

//  Data To DRAM Shifter
genvar x_var;
generate
    for ( x_var=0 ; x_var<AXI_DATA_WIDTH ; x_var=x_var+1 )begin
        always @ ( * ) begin
            data_result_ext         [( (x_var)*(TILE_NUM)+(0) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)] =                                  $signed(OBUF_TO_DRAM_DATA_ [( (x_var)*(TILE_NUM)+(0) ) * (HALF_SIZE)    +:(HALF_SIZE)]) ;
            data_result_ext         [( (x_var)*(TILE_NUM)+(1) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)] =                                  $signed(OBUF_TO_DRAM_DATA_ [( (x_var)*(TILE_NUM)+(1) ) * (HALF_SIZE)    +:(HALF_SIZE)]) ;
            data_result_sum_ext     [  (x_var)                  * (WORD_EXT_SIZE)+:(WORD_EXT_SIZE)] =                                  $signed(OBUF_TO_DRAM_DATA_ [  (x_var)                  * (WORD_SIZE)    +:(WORD_SIZE)]) ;
            data_result_shift       [( (x_var)*(TILE_NUM)+(0) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)] = ( quant_next_layer[5] == 0 ) ? ( $signed(data_result_ext    [( (x_var)*(TILE_NUM)+(0) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)]) >>> quant_next_layer )  
                                                                                                                                   : ( $signed(data_result_ext    [( (x_var)*(TILE_NUM)+(0) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)]) << (-quant_next_layer)) ; 
            data_result_shift       [( (x_var)*(TILE_NUM)+(1) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)] = ( quant_next_layer[5] == 0 ) ? ( $signed(data_result_ext    [( (x_var)*(TILE_NUM)+(1) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)]) >>> quant_next_layer )  
                                                                                                                                   : ( $signed(data_result_ext    [( (x_var)*(TILE_NUM)+(1) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)]) << (-quant_next_layer)) ; 
            data_result_sum_shift   [  (x_var)                  * (WORD_EXT_SIZE)+:(WORD_EXT_SIZE)] = ( quant_next_layer[5] == 0 ) ? ( $signed(data_result_sum_ext[  (x_var)                  * (WORD_EXT_SIZE)+:(WORD_EXT_SIZE)]) >>> quant_next_layer ) 
                                                                                                                                   : ( $signed(data_result_sum_ext[  (x_var)                  * (WORD_EXT_SIZE)+:(WORD_EXT_SIZE)]) << (-quant_next_layer)) ;     
        end
        satuation_oper #(HALF_EXT_SIZE,HALF_SIZE) SPE_out_satuation_oper_HALF_SIZE_0(
            .idata  (data_result_shift      [( (x_var)*(TILE_NUM)+(0) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)]),
            .odata  (data_result_sat_       [( (x_var)*(TILE_NUM)+(0) ) * (HALF_SIZE)    +:(HALF_SIZE)])
        );
        satuation_oper #(HALF_EXT_SIZE,HALF_SIZE) SPE_out_satuation_oper_HALF_SIZE_1(
            .idata  (data_result_shift      [( (x_var)*(TILE_NUM)+(1) ) * (HALF_EXT_SIZE)+:(HALF_EXT_SIZE)]),
            .odata  (data_result_sat_       [( (x_var)*(TILE_NUM)+(1) ) * (HALF_SIZE)    +:(HALF_SIZE)])
        );
        satuation_oper #(WORD_EXT_SIZE,WORD_SIZE) SPE_out_satuation_oper_WORD_SIZE(
            .idata  (data_result_sum_shift  [  (x_var)                  * (WORD_EXT_SIZE)+:(WORD_EXT_SIZE)]),
            .odata  (data_result_sum_sat_   [  (x_var)                  * (WORD_SIZE)    +:(WORD_SIZE)])
        );
    end
endgenerate
always @ ( * ) begin
        OBUF_TO_DRAM_DATA = ( set_isize == 0 ) ? data_result_sat_ 
                                               : data_result_sum_sat_;
end
endmodule