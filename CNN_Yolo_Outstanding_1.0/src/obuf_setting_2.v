module OBUF_SETTING#(
    parameter WORD_SIZE         = 5'd16,
    parameter HALF_ADDR_SIZE    = 6
)(
    input                                           clk,
                                                    obuf_rst,
                                                    pwc_dwc_combine_,
                                                    concat_output_control_,
    input                                           set_isize_,
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
    input           [1:0]                           CONV_FLAG_,
    output  reg                                     pwc_dwc_combine,
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
                                                    have_pool,
                                                    Is_Upsample,
    output  reg     [3:0]                           ker_size,
                                                    ker_strd,
    output  reg     [1:0]                           pool_size,
                                                    pool_strd,
    output  reg     [1:0]                           Bit_serial,
    output  reg     [HALF_ADDR_SIZE-1'b1:0]         obuf_tile_size_x,         //end address of write mode 
                                                    obuf_tile_size_y,
                                                    obuf_tile_size_x_aft_pool,
                                                    obuf_tile_size_y_aft_pool,
    output  reg     [5:0]                           quant_pe,
                                                    quant_normalization,    //After Multiply Alpha,shift to fix point
                                                    quant_activation,       //After Multiply Leaky constant,shift to fix point
                                                    quant_next_layer,       //After SPE process, Next Layer's Fix point is different, shift to fix point
                                                    quant_pool_next_layer,
    output  reg     [WORD_SIZE-1:0]                 leaky_constant,         //Leaky is product multiply 0.125 or 0.1.
    output  reg     [1:0]                           hw_icp_able_cacl,
                                                    hw_ocp_able_cacl,
    output  reg                                     have_accu,            //Accumulate Parti sum
                                                    have_last_ich,
                                                    Is_last_ker,
                                                    Is_Final_Tile,
    output  reg     [1:0]                           CONV_FLAG
);

    always @ ( posedge clk ) begin
        if ( obuf_rst ) begin
            pwc_dwc_combine                     <= pwc_dwc_combine_;
            concat_output_control               <= concat_output_control_;
            set_isize                           <= set_isize_;    
            set_wsize                           <= set_wsize_;    
            batch_first                         <= batch_first_;    
            have_batch                          <= have_batch_;    
            have_batch_dwc                      <= have_batch_dwc_;
            have_relu                           <= have_relu_;    
            have_relu_dwc                       <= have_relu_dwc_;
            have_leaky                          <= have_leaky_;    
            have_sigmoid                        <= have_sigmoid_;        
            have_pool                           <= have_pool_;    
            Is_Upsample                         <= Is_Upsample_;    
            ker_size                            <= ker_size_;    
            ker_strd                            <= ker_strd_;
            pool_size                           <= pool_size_;       
            pool_strd                           <= pool_strd_;           
            Bit_serial                          <= Bit_serial_;    
            obuf_tile_size_x                    <= obuf_tile_size_x_;            
            obuf_tile_size_y                    <= obuf_tile_size_y_;            
            obuf_tile_size_x_aft_pool           <= obuf_tile_size_x_aft_pool_;                        
            obuf_tile_size_y_aft_pool           <= obuf_tile_size_y_aft_pool_;                        
            quant_pe                            <= quant_pe_;    
            quant_normalization                 <= quant_normalization_;            
            quant_activation                    <= quant_activation_;            
            quant_next_layer                    <= quant_next_layer_;         
            quant_pool_next_layer               <= quant_pool_next_layer_;   
            leaky_constant                      <= leaky_constant_;        
            hw_icp_able_cacl                    <= hw_icp_able_cacl_;
            hw_ocp_able_cacl                    <= hw_ocp_able_cacl_;
            have_accu                           <= have_accu_;    
            have_last_ich                       <= have_last_ich_;        
            Is_last_ker                         <= Is_last_ker_;
            Is_Final_Tile                       <= Is_Final_Tile_;        
            CONV_FLAG                           <= CONV_FLAG_;
        end
    end

endmodule