`timescale 1ns / 1ps
`define MODULE_WORD_SIZE_hw 16
module POOL_PE#(
    parameter       WORD_SIZE       =   `MODULE_WORD_SIZE_hw,
    parameter       HALF_SIZE               =   WORD_SIZE/2,
    parameter       TILE_NUM                =   2,
    parameter       POOL_CTRL_SET           =   0,
    parameter       POOL_CTRL_COMPARE       =   1
)(
    input                                           clk,
                                                    set_isize,
                                                    pool_ctrl,
    input           [(WORD_SIZE)-1'b1:0]            pool_idata,
    output reg      [(WORD_SIZE)-1'b1:0]            pool_odata
);
    reg             [(WORD_SIZE)-1'b1:0]            pool_odata_;
    reg             [1:0]                           i;
    always @ ( posedge clk ) begin
        pool_odata      <=  pool_odata_;
    end
    always @ ( * ) begin
        for (i=0 ; i<TILE_NUM ; i=i+1 ) begin
            if ( pool_ctrl == POOL_CTRL_SET ) begin
                pool_odata_     = pool_idata;
            end else begin
                if ( set_isize == 0 ) begin
                    pool_odata_[(HALF_SIZE)*(i)+:(HALF_SIZE)] = 
                        ( $signed(pool_odata[(HALF_SIZE)*(i)+:(HALF_SIZE)]) > $signed(pool_idata[(HALF_SIZE)*(i)+:(HALF_SIZE)]) ) ? 
                            pool_odata[(HALF_SIZE)*(i)+:(HALF_SIZE)]
                          : pool_idata[(HALF_SIZE)*(i)+:(HALF_SIZE)];
                end else begin
                    pool_odata_ = ( $signed(pool_odata) > $signed(pool_idata) ) ? pool_odata : pool_idata;
                end
            end
        end
    end
endmodule
