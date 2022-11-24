module Cycle_counter(
    input                       clk,
                                rst,
                                IRQ,
                                M_AXI_RVALID,
                                M_AXI_WVALID,
                                DEBUG_have_pool_ing,
    input       [2:0]           DEBUG_INPUT_state_input_ctrl,
    input       [1:0]           DEBUG_obuf_state,
    input       [5:0]           DEBUF_Layer_selc,
    input       [2:0]           DEBUG_Layer_type,
	output reg  [31:0]          cycle_data
);
    reg [6:0]   Layer_Ptr;
    reg [31:0]  store_Input     [31:0],   
                store_Weight    [31:0],       
                store_Output    [31:0],       
                store_Cacl      [31:0],   
                store_Pooling   [31:0],       
                store_Layer     [31:0],   
                store_Total_Layer_time[31:0];
    reg [31:0]  Total_Input     ,
                Total_Weight    ,
                Total_Output    ,
                Total_Cacl      ,
                Total_Pooling   ,
                Total_Layer     ,   
                Total_Layer_time;
    reg         IRQ_befo,
                IRQ_trig;
    always @ ( posedge clk ) begin
        IRQ_befo <= IRQ ;
        if ( IRQ_befo == 0 && IRQ == 1 )
            IRQ_trig <= 1;
        else
            IRQ_trig <= 0;
    end
    always @ ( posedge clk ) begin
        if ( rst ) begin
            Layer_Ptr <= 0;
        end else if ( IRQ_trig ) begin
            Layer_Ptr <= Layer_Ptr + 1;
        end
    end
    always @ ( posedge clk ) begin
        if ( rst || IRQ_trig  ) begin
            Total_Input     <= 0;   
            Total_Weight    <= 0;       
            Total_Output    <= 0;       
            Total_Cacl      <= 0;   
            Total_Pooling   <= 0;       
            Total_Layer     <= 0;
            Total_Layer_time<= 0;   
        end else begin
            if ( DEBUG_INPUT_state_input_ctrl != 0 && IRQ == 0 )
                Total_Layer    <= Total_Layer+1;
            if ( M_AXI_RVALID == 1 && ( DEBUG_INPUT_state_input_ctrl == 2 || DEBUG_INPUT_state_input_ctrl == 1 ) )
                Total_Input <= Total_Input + 1'b1;
            if ( M_AXI_RVALID == 1 && ( DEBUG_INPUT_state_input_ctrl == 4 || DEBUG_INPUT_state_input_ctrl == 3 ) )
                Total_Weight<= Total_Weight+ 1'b1;
            if ( M_AXI_WVALID == 1 )
                Total_Output<= Total_Output+ 1'b1;
            if ( DEBUG_have_pool_ing && DEBUG_obuf_state == 2 )
                Total_Pooling<= Total_Pooling+1'b1;
            if ( DEBUG_have_pool_ing == 0 && DEBUG_obuf_state == 2 )
                Total_Cacl <= Total_Cacl+1'b1;
            Total_Layer_time<= Total_Layer_time + 1'b1 ;
        end
    end
    always @ ( posedge clk ) begin
        if ( IRQ_trig ) begin
            store_Input   [Layer_Ptr[4:0]] <= Total_Input    ;         
            store_Weight  [Layer_Ptr[4:0]] <= Total_Weight   ;             
            store_Output  [Layer_Ptr[4:0]] <= Total_Output   ;             
            store_Cacl    [Layer_Ptr[4:0]] <= Total_Cacl     ;     
            store_Pooling [Layer_Ptr[4:0]] <= Total_Pooling  ;             
            store_Layer   [Layer_Ptr[4:0]] <= Total_Layer    ;
            store_Total_Layer_time [Layer_Ptr[4:0]] <= Total_Layer_time;         
        end
    end
    always @ ( posedge clk ) begin
        case ( DEBUG_Layer_type )
            0 : cycle_data <= store_Input   [DEBUF_Layer_selc[5:0]];
            1 : cycle_data <= store_Weight  [DEBUF_Layer_selc[5:0]];
            2 : cycle_data <= store_Output  [DEBUF_Layer_selc[5:0]];
            3 : cycle_data <= store_Cacl    [DEBUF_Layer_selc[5:0]];
            4 : cycle_data <= store_Pooling [DEBUF_Layer_selc[5:0]];
            5 : cycle_data <= store_Layer   [DEBUF_Layer_selc[5:0]];
            6 : cycle_data <= store_Total_Layer_time [DEBUF_Layer_selc[5:0]];
        endcase
    end

endmodule