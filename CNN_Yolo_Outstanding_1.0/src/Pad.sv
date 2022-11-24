`timescale 1ns / 1ps
module Pad_v2 #(
    parameter C_M_AXI_ADDR_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 32,
    parameter M_AXI_DATA_BW         = 128,
    parameter S_AXI_DATA_BW         = 32,
    parameter TILE_SIZE_BW          = 16,
    parameter LINE                  = 6,
    parameter BOUNDARY_SIZE         = 12,
    parameter TILE_SIZE             = 11,
    parameter LINE_BITWIDTH         = 3,
    parameter WAIT_PE               = 4,
    parameter PIP_CYCLE             = 0
    
    `define   IDLE                    0
    `define   ADDRESS_SETTING         1
    `define   CALCU                   2
    `define   COUNT_1                 1
    `define   COUNT_2                 2
    `define   FINISH                  3
    
) (
    //General
    input                                   clk,
    input                                   rst,
    output  reg                            irq,

    //Tile Info
    input   [C_S_AXI_ADDR_WIDTH-1 : 0]      Output_Address,
    input   [C_S_AXI_ADDR_WIDTH-1 : 0]      Pooling_Address,
    
    
    //input   [TILE_SIZE_BW-1 : 0]            Output_Tile_Number,
    input   [TILE_SIZE_BW-1 : 0]            Next_Input_Feature_Size_tmp, // next_input_feature_size
    input   [TILE_SIZE_BW-1 : 0]            Output_Tile_Size_row, //now output tile size
    input   [TILE_SIZE_BW-1 : 0]            Output_Tile_Size_col, //now output tile size
    input                                   is_final, // last deep and last tile
    input   [1:0]                           Kernel_Size,
    input                                   IRQ_TO_MASTER_CTRL,
    input   [1:0]                           hw_ocp_able_cacl,
    input                                   Is_Upsample,
    
    //Master Control
    input                                   start,
    input                                   Is_pooling,
    output                                  layer_done,  //Master output finish

    //On-Chip Memory
    input   [M_AXI_DATA_BW-1 : 0]           inter_data,
    output reg [TILE_SIZE_BW-1 : 0]         oc_addr_x,
    output [TILE_SIZE_BW-1 : 0]             oc_addr_y,

    //AW Channel
    input                                   m_axi_awready,
    output reg                              m_axi_awvalid,
    output reg [C_M_AXI_ADDR_WIDTH-1 : 0]   m_axi_awaddr,
    output reg [7:0]                        m_axi_awlen,
    
    //W Channel
    input                                   m_axi_wready,
    output [M_AXI_DATA_BW-1 : 0]            m_axi_wdata,
    output [TILE_SIZE_BW : 0]               m_axi_wstrb,
    output reg                              m_axi_wlast,
    output                                  m_axi_wvalid,
    
    input                                   m_axi_bvalid,
    output reg                              m_axi_bready,
    
    output reg [1:0]                        State_Bank_sel

);
    reg [2:0] AW_state , AW_next_state;
    reg [LINE-1:0] line_counter;
    reg [TILE_SIZE-1:0] total_pixel_counter;
    reg start_buf,next_m_axi_wlast;
    reg AW_valid_buf;
    reg [C_S_AXI_ADDR_WIDTH-1:0] AW_len_tail_buf;
    reg [7:0] AW_len_count;
    reg [2:0] wait_PE_pip;
    reg [1:0] next_State_Bank_sel;
    reg [9:0] B_ready_ctr;
    
    reg [3:0] pip_counter;
    reg awvalid_tri;
    wire [TILE_SIZE_BW-1 : 0] row_len,col_len;
    wire [1:0] bank_sel_counter;
    wire [TILE_SIZE-1:0] total_pixel;
    wire [C_S_AXI_ADDR_WIDTH-1:0] head_len_counter,tail_len_counter;
    wire pad_rst,state_rst;
    wire [TILE_SIZE_BW-1 : 0]            Next_Input_Feature_Size;
    
    assign m_axi_wdata = (start && m_axi_wvalid) ? inter_data : 0;
    assign pad_rst = (start_buf == 0 && start) ? 1'd1 : 1'd0;
    assign state_rst = (next_State_Bank_sel != State_Bank_sel) && (next_State_Bank_sel != `FINISH) ;
    assign m_axi_wstrb = 16'hffff;
    assign bank_sel_counter = (Kernel_Size == 2'd3) ? 2'd1 : 2'd3;
    assign total_pixel = (Is_pooling)  ? (Output_Tile_Size_row>>1) * (Output_Tile_Size_col>>1) :
                         (Is_Upsample) ? (Output_Tile_Size_row<<1) * (Output_Tile_Size_col<<1) : Output_Tile_Size_row * Output_Tile_Size_col;
    assign Next_Input_Feature_Size = (Is_pooling) ? (Next_Input_Feature_Size_tmp>>1) : Next_Input_Feature_Size_tmp;
    assign row_len = (Is_pooling)  ? (Output_Tile_Size_row>>1) : 
                     (Is_Upsample) ? (Output_Tile_Size_row<<1) : Output_Tile_Size_row;
                     
    assign col_len = (Is_pooling)  ? (Output_Tile_Size_col>>1) : 
                     (Is_Upsample) ? (Output_Tile_Size_col<<1) : Output_Tile_Size_col;
     
    assign m_axi_wvalid = ((AW_state == `CALCU && wait_PE_pip == WAIT_PE) && m_axi_wready) ? 1'b1 : 1'b0;
    always@(posedge clk) next_m_axi_wlast <= m_axi_wlast;
    assign layer_done = (B_ready_ctr==10'd40) && (State_Bank_sel == `FINISH);
    always@(posedge clk) irq <= is_final && IRQ_TO_MASTER_CTRL && layer_done;
    always@(posedge clk) m_axi_bready <= (B_ready_ctr == 10'd40) ? 1'b0 :
                                          (start) ? 1'b1 : m_axi_bready; 
                                          
   always@(posedge clk) begin
        if(rst || pad_rst)
            B_ready_ctr <= 0;
        else if(m_axi_bready && (State_Bank_sel == `FINISH) && B_ready_ctr < 10'd40)
            B_ready_ctr <= B_ready_ctr + 1'b1;
    end                                 
    
   always@(posedge clk) start_buf <= (rst) ? 0 : start;
   
   always@(posedge clk) begin
        if(rst || pad_rst)
            State_Bank_sel <= `IDLE;
        else
            State_Bank_sel <= next_State_Bank_sel;
    end  
   
   always@(*) begin
        case(State_Bank_sel)
            `IDLE : begin
                if(Kernel_Size == 2'd1 && m_axi_wlast && total_pixel_counter == (total_pixel-1'b1) && State_Bank_sel < (hw_ocp_able_cacl-1'd1)) next_State_Bank_sel = `COUNT_1;
                else if(Kernel_Size == 2'd1 && m_axi_wlast && total_pixel_counter == (total_pixel-1'b1) && State_Bank_sel >= (hw_ocp_able_cacl-1'd1)) next_State_Bank_sel = `FINISH;
                else if((Kernel_Size == 2'd3 && m_axi_wlast && total_pixel_counter == (total_pixel-1'b1)) /*|| (next_State_Bank_sel >= hw_ocp_able_cacl)*/) next_State_Bank_sel = `FINISH;
                else next_State_Bank_sel = State_Bank_sel;
            end
            `COUNT_1 : begin
                if(Kernel_Size == 2'd1 && m_axi_wlast && total_pixel_counter == (total_pixel-1'b1) && State_Bank_sel < (hw_ocp_able_cacl-1'd1)) next_State_Bank_sel = `COUNT_2;
                else if(Kernel_Size == 2'd1 && m_axi_wlast && total_pixel_counter == (total_pixel-1'b1) /*&& State_Bank_sel >= (hw_ocp_able_cacl-1'd1)*/) next_State_Bank_sel = `FINISH;
                else next_State_Bank_sel = State_Bank_sel;
            end
            `COUNT_2 : begin
                if(Kernel_Size == 2'd1 && m_axi_wlast && total_pixel_counter == (total_pixel-1'b1)) next_State_Bank_sel = `FINISH;
                else next_State_Bank_sel = State_Bank_sel;
            end
            `FINISH : begin
                if(start_buf == 0) next_State_Bank_sel = `IDLE;
                else next_State_Bank_sel = State_Bank_sel;
            end
            default : next_State_Bank_sel = `IDLE;
        endcase
   end
   
    always@(posedge clk) begin
        if(rst || pad_rst)
            AW_state <= 3'd0;
        else
            AW_state <= AW_next_state;
    end
    
    always@(*) begin
        case(AW_state)
            `IDLE : begin
                if(start && total_pixel_counter <= (total_pixel-1'b1)) AW_next_state = `ADDRESS_SETTING;
                else AW_next_state = AW_state;
            end
            `ADDRESS_SETTING : begin
                if(pip_counter == PIP_CYCLE && awvalid_tri)  AW_next_state = `CALCU;
                else AW_next_state = AW_state;
            end
            `CALCU : begin
                if(m_axi_wlast && total_pixel_counter < (total_pixel-1'b1)) AW_next_state = `ADDRESS_SETTING;
                else if(m_axi_wlast && total_pixel_counter == (total_pixel-1'b1)) AW_next_state = `IDLE; // layer done
                else AW_next_state = AW_state;
            end
             default: AW_next_state = `IDLE;
        endcase
    end
    
    always@(posedge clk) begin  // calculate the output tile size
        if(rst || pad_rst || state_rst)
            total_pixel_counter <= 0;
        else if(m_axi_wvalid && total_pixel_counter < total_pixel)
            total_pixel_counter <= total_pixel_counter + 1'd1;
    end
   
    always@(posedge clk) begin // count the line
        if(rst || pad_rst || state_rst)
            line_counter <= 0;
        else if(AW_len_count == (row_len-1'd1) && line_counter != row_len)
            line_counter <= line_counter + 1'd1;
    end
    
    always@(posedge clk) begin  // calculate the output tile size
        if(m_axi_awvalid || pad_rst || rst)
            oc_addr_x <= 0;
        else if(start && PIP_CYCLE == 0 && oc_addr_x < row_len)
            oc_addr_x <= oc_addr_x + 1'd1;
        else if(start && PIP_CYCLE > 0 && (pip_counter-1'd1) >= PIP_CYCLE && oc_addr_x < row_len)
            oc_addr_x <= oc_addr_x + 1'd1;
    end
    
    assign oc_addr_y = line_counter;
    
    always@(posedge clk) begin
       if(rst || pad_rst || state_rst)
           AW_valid_buf <= 0;
       else if(start && m_axi_awready && (AW_state == `IDLE && AW_next_state == `ADDRESS_SETTING || AW_next_state == `ADDRESS_SETTING && m_axi_wlast))/// m_axi_wready
           AW_valid_buf <= 1'b1;
       else
           AW_valid_buf <= 1'b0;
    end
    
   always@(posedge clk) m_axi_awvalid <= (rst || pad_rst) ? 0 : AW_valid_buf;
    
   assign head_len_counter = ((m_axi_awaddr[BOUNDARY_SIZE-1:4] + row_len) <= 32'hff) ? row_len - 1'd1: 32'hff - m_axi_awaddr[BOUNDARY_SIZE-1:4];
   assign tail_len_counter = ((m_axi_awaddr[BOUNDARY_SIZE-1:4] + row_len) > 32'h100) ? row_len - head_len_counter - 2'd2 : 0;
   
   always@(posedge clk) begin
        if(rst || pad_rst || state_rst) begin
           if(Is_pooling)
                m_axi_awaddr <= Pooling_Address;
           else if(Kernel_Size == 2'd3)
                m_axi_awaddr <= Output_Address;
           else
                m_axi_awaddr <= Output_Address + Next_Input_Feature_Size*next_State_Bank_sel*5'h10;
        end
        else if(m_axi_wready && !layer_done) begin
           if(AW_len_count == (row_len-1'd1)) begin
                if(Is_pooling)
                    m_axi_awaddr <= Pooling_Address + (((line_counter+1'd1) * Next_Input_Feature_Size)*5'h10);
                else if(Kernel_Size == 2'd3)
                    m_axi_awaddr <= Output_Address + (((line_counter+1'd1) * Next_Input_Feature_Size)*5'h10);
                else
                    m_axi_awaddr <= Output_Address + ((((line_counter+1'd1)*row_len) + Next_Input_Feature_Size*next_State_Bank_sel)*5'h10);
           end
           else if(AW_len_count == head_len_counter && AW_len_count != (row_len-1'd1))
                m_axi_awaddr <= m_axi_awaddr + (head_len_counter + 1'd1)*5'h10;
        end
   end
   
   always@(posedge clk) AW_len_tail_buf <= (head_len_counter != (row_len-1'd1)) ? tail_len_counter : 0;
   
   always@(posedge clk) begin
        if(rst || pad_rst)
            m_axi_awlen <= 0;
        else if(AW_valid_buf)
            if(AW_len_count == 4'd0)
                m_axi_awlen <= head_len_counter;
            else if(AW_len_count != ((row_len-1'd1) || 4'd0))
                m_axi_awlen <= AW_len_tail_buf;
   end
   
   always@(posedge clk) begin
       if(rst || pad_rst)
           m_axi_wlast <= 0;
       else if(m_axi_wvalid) begin
           if(AW_len_count == (head_len_counter-1'b1))
               m_axi_wlast <= 1'b1;
           else if(AW_len_count == (row_len - 2'b10))
               m_axi_wlast <= 1'b1;
           else
               m_axi_wlast <= 1'b0;
       end
   end
   
   //////////////////////////////////////////// Use for Pipeline //////////////////////////////////////////// 
   always@(posedge clk) begin
        if(m_axi_awvalid)
            pip_counter <= 0;
        else if(awvalid_tri && pip_counter < PIP_CYCLE)
            pip_counter <= pip_counter + 1'd1;
        else if(pip_counter == PIP_CYCLE && m_axi_wlast)
            pip_counter <= 0;
   end
   
   always@(posedge clk) begin
        if(rst || m_axi_wlast)
            awvalid_tri <= 0;
        else if(m_axi_awvalid)
            awvalid_tri <= 1;
   end
   
   //////////////////////////////////////////// Use for Count Line //////////////////////////////////////////// 
   always@(posedge clk) begin
        if(rst || AW_len_count == (row_len-1'd1))
            AW_len_count <= 0;
        else if(m_axi_wvalid && m_axi_wready)
            AW_len_count <= AW_len_count + 1'd1;
   end

    always@(posedge clk) begin
        if(rst || m_axi_awvalid)
            wait_PE_pip <= 0;
        else if(m_axi_wready && wait_PE_pip < WAIT_PE)
            wait_PE_pip <= wait_PE_pip + 1'd1;
    end
    
endmodule 