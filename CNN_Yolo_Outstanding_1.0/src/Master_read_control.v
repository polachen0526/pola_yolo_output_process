`timescale 1ns / 1ps
`define VIVADO_MODE
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/02/17 15:07:10
// Design Name: 
// Module Name: Master_read_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// Bitparal 8 8 Version

module Master_read_control #(
    parameter WORD_SIZE = 16,
    parameter OUT_WORD_SIZE = 36,
    parameter INTEGER = 32,
    parameter EIGHT_WORD_SIZE = 128,
    parameter OFF_TO_ON_ADDRESS_SIZE = 11, // 1156 (Dec) 484(hex) 0100 1000 0100(bin) 
    parameter ON_TO_OFF_ADDRESS_SIZE = 10,
    parameter BOUNDARY_SIZE = 12,
    parameter ADDR_SIZE = 8,
    
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_M_AXI_ID_WIDTH	    = 1,
    parameter C_M_AXI_ADDR_WIDTH	= 32,
    parameter C_M_AXI_DATA_WIDTH	= 128,
    parameter C_M_AXI_AWUSER_WIDTH	= 1,
    parameter C_M_AXI_ARUSER_WIDTH	= 1,
    parameter C_M_AXI_WUSER_WIDTH	= 1,
    parameter C_M_AXI_RUSER_WIDTH	= 1,
    parameter C_M_AXI_BUSER_WIDTH	= 1,
   
    parameter MIDDLE = 4,
    parameter ALL_NO_PADDING = 10
    `define   IDLE  0
    `define   INST  1
    `define   INPUT_LOAD 2
    `define   PE  3
    `define   OUTPUT  4
    `define   WAIT_PE 5
    `define   PADDING_A 6
    `define   PADDING_B 7
    
    `define   INPUT  1
    `define   INPUT_B 2
    `define   WEIGHT 3
    `define   WEIGHT_B 4
)(
        input                                    clk,
        input                                    rst,
        input                                    IRQ,
        input                                    s_axi_start,       
        input   [BOUNDARY_SIZE-1:0]              s_axi_img_size,    // number of instruction
        input   [C_S_AXI_DATA_WIDTH-1:0]         s_axi_dram_raddr,  // first addr
        
        /////////////////////////////////////////////////AR/////////////////////////////////////////////////
        input                                    M_AXI_ARREADY, // ready
        output  wire [C_M_AXI_ADDR_WIDTH-1 : 0]  M_AXI_ARADDR,  // addr
        output  reg [7 : 0]                      M_AXI_ARLEN,   // 128 bits * 256 len
        output  reg                              M_AXI_ARVALID, // same as ready, but just for one cycle
        
        /////////////////////////////////////////////////R/////////////////////////////////////////////////
        input  [C_M_AXI_DATA_WIDTH-1 : 0]        M_AXI_RDATA,   //Dram -> Sram Data
        input  [1 : 0]                           M_AXI_RRESP,   // feedback good or bad
        input                                    M_AXI_RLAST,   // last value
        input                                    M_AXI_RVALID,  // when valid is High , read data is effective
        output wire                              M_AXI_RREADY,   // ready to start reading
        output reg                               s_axi_Rerror,            //Trigger IRQ if error
        output reg [C_S_AXI_DATA_WIDTH-1:0]      s_axi_Rerror_addr,
        
        input wire [OFF_TO_ON_ADDRESS_SIZE-1:0] On_to_PE_addr,
        input                                   PE_finish,
        input                                   On_to_PE_finish,
        /////////////////////////////////////////////////signal/////////////////////////////////////////////////
        output wire                             rst_A,
        output wire                             rst_B,        
        output wire                             ready_A,
        output wire                             ready_B,
        output reg                              start_A,
        output reg                              start_B,
        
        /////////////////////////////////////////////////Layer instruction/////////////////////////////////////////////////
        input [OFF_TO_ON_ADDRESS_SIZE:0] Feature_map_size,
        input wire [1:0]     Kernel_Size,
        /////////////////////////////////////////////////TILE instruction/////////////////////////////////////////////////
        output wire [C_S_AXI_DATA_WIDTH-1:0] Input_Address,
        output wire [C_S_AXI_DATA_WIDTH-1:0] Weight_Address,
        output wire [C_S_AXI_DATA_WIDTH-1:0] Output_Address,
        output wire [C_S_AXI_DATA_WIDTH-1:0] Pooling_Address,
        output wire [3:0] Output_Tile_Type,
        output wire [3:0] Output_Tile_Valid,
        output wire Is_Final_Tile,
        output wire Have_Accumulate,
        output wire Is_Last_Channel,
        output wire Have_maxpooling,
        /////////////////////////////////////////////////Off to on addr/////////////////////////////////////////////////
        output wire                             On_to_PE_buffer_sel,
        output wire                             Reload,
        output wire [3:0]                       type,
        output wire                             Input_Buffer_to_PE_Ctrl_rst,
        output wire                             obuf_ctrl_rst,
        output wire                             Choose_Weight_buf,
        output wire                             obuffer_init,
        output wire                             weight_buffer_start,
        output wire[1:0]                        ibuf_iaddr_bank_sel,
        output wire                             ibuf_wr_A,
        output wire                             ibuf_wr_B,
        output wire [INTEGER-1:0]               ibuf_iaddr,
        output wire                             weight_rst_A,
        output wire                             weight_rst_B,
        output                                  off_to_on_valid_A,
        output                                  off_to_on_valid_B,
        output wire                             padding_start,
        output [1:0]                            next_state_bank_count,
        output [5:0]                            Input_Tile_Size_row,
        output [5:0]                            Input_Tile_Size_col,
        output [1:0]                            hw_icp_able_cacl,
        output [1:0]                            hw_ocp_able_cacl,
        output [1:0]                            hw_icp_able_cacl_to_input,

        output reg [2:0]                        DEBUG_INPUT_state,
                                                DEBUG_INPUT_start_valid_buffer,
                                                DEBUG_INPUT_state_input_ctrl
);

reg curr_start;
wire state_start,inst_wr;//,counter_start;
wire input_next_valid,input_finish_A,input_finish_B;
wire weight_finish_A,weight_finish_B;
reg [INTEGER-1:0] AR_4k_counter_head;
//wire [INTEGER-1:0] operator_length; 
reg [WORD_SIZE-1:0] AR_4k_counter_tail;
wire [INTEGER-1:0] off_to_on_ibuf_iaddr;
wire [C_M_AXI_DATA_WIDTH-1:0] inst_data;
wire [ADDR_SIZE-1:0] AR_len_buffer;
wire [BOUNDARY_SIZE-1:0] next_AR_4k_state;
reg [3:0] AR_4k_excision_counter;
reg PE_finish_buf,PE_finish_buf_1x1;
wire Choose_Input_buf,Reload_buf,Input_reuse_A_buf,Input_reuse_B_buf;
wire padding_Finish;
wire [5:0] Master_Input_Tile_Size_row,Master_Input_Tile_Size_col;
wire [1:0] CONV_1x1_bank_limit_buf;

reg Buffer_choose;
reg [2:0] state_input_ctrl,next_state_input_ctrl;
reg [2:0] state,next_state,start_valid_buffer;
reg [7:0] AR_4k_counter;
reg [BOUNDARY_SIZE:0] inst_addr;
reg [BOUNDARY_SIZE-1:0] inst_counter;
wire input_buffer_loading,next_inst_finish;
reg rst_A_buf,rst_B_buf;
wire [6:0] Weight_len;

reg [C_S_AXI_DATA_WIDTH-1:0] Input_Address_A;
reg [C_S_AXI_DATA_WIDTH-1:0] Weight_Address_A;
reg [C_S_AXI_DATA_WIDTH-1:0] Output_Address_A;
reg [C_S_AXI_DATA_WIDTH-1:0] Pooling_Address_A;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_Row_In_Address_A;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_Row_Out_Address_A;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_In_Address_A;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_Out_Address_A;
reg [5:0] Input_Tile_Size_row_A,Input_Tile_Size_col_A;
reg [3:0] Output_Tile_Type_A,type_A;
reg [3:0] Output_Tile_Valid_A;
reg [6:0] Weight_len_A;
reg Is_Final_Tile_A,Have_maxpooling_A;
reg Have_Accumulate_A;
reg Is_Last_Channel_A;
reg Weight_reuse_A;
reg Input_reuse_A;
reg Use_Input_A,Use_Weight_A,Reload_A;
reg [1:0] hw_icp_able_cacl_A,hw_ocp_able_cacl_A;

reg [C_S_AXI_DATA_WIDTH-1:0] Input_Address_B;
reg [C_S_AXI_DATA_WIDTH-1:0] Weight_Address_B;
reg [C_S_AXI_DATA_WIDTH-1:0] Output_Address_B;
reg [C_S_AXI_DATA_WIDTH-1:0] Pooling_Address_B;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_Row_In_Address_B;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_Row_Out_Address_B;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_In_Address_B;
reg [ON_TO_OFF_ADDRESS_SIZE-1:0] Output_On_Chip_Buffer_Limit_Out_Address_B;
reg [5:0] Input_Tile_Size_row_B,Input_Tile_Size_col_B;
reg [3:0] Output_Tile_Type_B,type_B;
reg [3:0] Output_Tile_Valid_B;
reg [6:0] Weight_len_B;
reg Is_Final_Tile_B,Have_maxpooling_B;
reg Have_Accumulate_B;
reg Is_Last_Channel_B;
reg Weight_reuse_B;
reg Input_reuse_B;
reg Use_Input_B,Use_Weight_B,Reload_B;
reg [1:0] hw_icp_able_cacl_B,hw_ocp_able_cacl_B;
wire            CENY, WENY;
wire [10:0]     AY;
wire [127:0]    DY;

always @ ( posedge clk ) begin
    DEBUG_INPUT_state              <= state;  
    DEBUG_INPUT_start_valid_buffer <= start_valid_buffer;              
    DEBUG_INPUT_state_input_ctrl   <= state_input_ctrl;              
end


`ifdef VIVADO_MODE
    Instruction_Mem_128x256 uInstruction_Mem_128x256(
      .clka(clk),
      .wea(inst_wr),
      .addra(inst_counter),
      .dina(M_AXI_RDATA),
      .douta(inst_data)
    );
`else
 SRAM_SP_INST uSRAM_SP_INST(
   .CENY       (CENY),         
   .WENY       (WENY),         
   .AY         (AY),      
   .DY         (DY),      
   .Q          (inst_data),   
   .CLK        (clk),      
   .CEN        (1'b1),      
   .WEN        (inst_wr),      
   .A          (inst_counter[10:0]),   
   .D          (M_AXI_RDATA),   
   .EMA        (3'd0),      
   .EMAW       (2'd0),      
   .EMAS       (1'd0),      
   .TEN        (1'd1),      
   .BEN        (1'd1),      
   .TCEN       (1'd1),
   .TWEN       (1'd1),
   .TA         (9'd0),
   .TD         (128'd0),
   .TQ         (128'd0),
   .RET1N      (1'd1),
   .STOV       (1'd0)
);
`endif
Off_to_On_Controler uOff_to_On_Controler(
    .clk(clk),
    .rst_A(rst_A_buf),
    .rst_B(rst_B_buf),
    .ready_A(ready_A),
    .ready_B(ready_B),
    .M_AXI_RLAST(M_AXI_RLAST),
    .M_AXI_RVALID(M_AXI_RVALID),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_ARREADY(M_AXI_ARREADY),
    .state(state),
    .next_state_input_ctrl(next_state_input_ctrl),
    .state_input_ctrl(state_input_ctrl),
    .start_valid_buffer(start_valid_buffer),
    .Reload(Reload_buf),
    .Input_reuse_A(Input_reuse_A_buf),
    .Input_reuse_B(Input_reuse_B_buf),
    .Kernel_Size(Kernel_Size),
    .TILE_SIZE_row(Master_Input_Tile_Size_row),
    .TILE_SIZE_col(Master_Input_Tile_Size_col),
    .type(type),
    .Feature_map_size(Feature_map_size),
    .Weight_len(Weight_len),
    
    .start_A(start_A),
    .start_B(start_B),
    .ibuf_wr_A(ibuf_wr_A),
    .ibuf_wr_B(ibuf_wr_B),
    .bank_sel(ibuf_iaddr_bank_sel),
    .first_addr(Input_Address),
    .Weight_Address(Weight_Address),
    .Use_bufferAB(Buffer_choose),
    .weight_buffer_start(weight_buffer_start),
    .next_valid(input_next_valid),
    .AR_len(AR_len_buffer),
    .off_to_on_ibuf_iaddr(off_to_on_ibuf_iaddr),
    .ibuf_bank_iaddr(ibuf_iaddr),
    .input_finish_A(input_finish_A),
    .input_finish_B(input_finish_B),
    .weight_finish_A(weight_finish_A),
    .weight_finish_B(weight_finish_B),
    .padding_start(padding_start),
    .next_state_bank_count(next_state_bank_count),
    .off_to_on_valid_A(off_to_on_valid_A),
    .off_to_on_valid_B(off_to_on_valid_B),
    .padding_Finish(padding_Finish)
);
/*
assign operator_length = (Kernel_Size == 2'b11 && fully_connected == 1'b0) ? ((Input_Tile_Size_row + 2'd2) * Input_Tile_Size_row + 1) : 
                         (Kernel_Size == 2'b01 && fully_connected == 1'b1) ? fully_connect_length :  Input_Tile_Size_row * Input_Tile_Size_row + 1;*/

assign Reload = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Reload_B : Reload_A;
assign On_to_PE_buffer_sel = Buffer_choose;
assign M_AXI_RREADY = 1'd1;
assign obuf_ctrl_rst = ((state == `INPUT_LOAD && next_state == `PE)) ? 1'b1 : 1'b0;
assign obuffer_init = (state == `IDLE && next_state == `INST) ? 1'b1 : 1'b0;

always@(posedge clk)begin
    if(rst)
        s_axi_Rerror <= 1'd0;
    else if(M_AXI_RRESP != 2'd0)
        s_axi_Rerror <= 1'd1;
end

always@(posedge clk)begin
    if(rst)
        s_axi_Rerror_addr <= 32'd0;
    else
        s_axi_Rerror_addr <= (M_AXI_RRESP != 2'd0 && s_axi_Rerror == 1'd0) ? off_to_on_ibuf_iaddr : s_axi_Rerror_addr;
end

assign inst_wr = (state == `INST) ? M_AXI_RVALID : 1'd0; 

always@(*)begin
    M_AXI_ARVALID <= ((state == `INST || input_buffer_loading) && M_AXI_ARREADY && start_valid_buffer == 3'd5) ? 1'd1 :
                     (input_buffer_loading && input_next_valid && M_AXI_ARREADY && start_valid_buffer >= 3'd5) ? 1'd1 : 1'd0;
    
end

always@(posedge clk)begin // wait for start buffer
    if((state == `IDLE && next_state == `INST) || 
      (state == `INST && next_state == `INPUT_LOAD) || 
      (state == `INPUT_LOAD && next_state == `INST) ||
      (state_input_ctrl == `IDLE && (next_state_input_ctrl == `INPUT || next_state_input_ctrl == `INPUT_B || next_state_input_ctrl == `WEIGHT || next_state_input_ctrl == `WEIGHT_B)) || 
      (state == `INST && M_AXI_RLAST && M_AXI_RVALID))
        start_valid_buffer <= 3'd0;
    else if(start_valid_buffer < 3'd7)
        start_valid_buffer <= start_valid_buffer + 1'd1;
end
assign Input_Buffer_to_PE_Ctrl_rst = (state == `INPUT_LOAD && next_state == `PE) ? 1'b1 : 1'b0;
////////////////////////////////////////////////FSM////////////////////////////////////////////////
always@(posedge clk)begin
    if(rst)
        state <= `IDLE;
    else
        state <= next_state;
end

always@(posedge clk)begin
    if(rst)
        curr_start <= 1'b0;
    else
        curr_start <= s_axi_start;
end

always@(*) begin
    case(state)
      `IDLE : begin
          if(s_axi_start == 1'b1 && curr_start == 1'b0) next_state = `INST;
          else next_state = state;
      end
      `INST : begin
         if(start_valid_buffer >= 3'd6) begin
            if(IRQ) next_state = `IDLE;
            else if(inst_counter == s_axi_img_size && M_AXI_RLAST) next_state = `INPUT_LOAD;
            else next_state = state;
         end
         else 
            next_state = state;
      end
      `INPUT_LOAD : begin
         if(IRQ) next_state = `IDLE;
         else if((input_finish_A || input_finish_B) && ((Input_reuse_A == 1'd1 && Weight_reuse_A == 1'd0 && Buffer_choose == 1'd0) || (Input_reuse_B == 1'd1 && Weight_reuse_B == 1'd0 && Buffer_choose == 1'd1))) next_state = `PE;
         else if((weight_finish_A || weight_finish_B)) next_state = `PE;
         else if(start_valid_buffer == 3'd7 && inst_counter > 2'd2 && ((Input_reuse_A == 1'd0 && Weight_reuse_A == 1'd0 && Buffer_choose == 1'd0) || (Input_reuse_B == 1'd0 && Weight_reuse_B == 1'd0 && Buffer_choose == 1'd1))) next_state = `PE;
         else next_state = state;
      end
      `PE : begin
        if(IRQ) next_state = `IDLE;
        //else if(PE_finish_buf_1x1 && Kernel_Size == 2'd1 && (next_state_input_ctrl == `WEIGHT || next_state_input_ctrl == `WEIGHT_B)) next_state = `INPUT_LOAD;
        else if(PE_finish ) next_state = `INPUT_LOAD;
        else next_state = state;
      end
      default : next_state = `IDLE;
    endcase
end

always@(posedge clk) begin
    if(rst)             PE_finish_buf_1x1 <= 0;
    else if(PE_finish)  PE_finish_buf_1x1 <= 1;
    else if((next_state_input_ctrl == `WEIGHT || next_state_input_ctrl == `WEIGHT_B)) PE_finish_buf_1x1 <= 0;
end

always@(posedge clk)begin
    if(rst)
        state_input_ctrl <= `IDLE;
    else
        state_input_ctrl <= next_state_input_ctrl;
end

always@(*) begin
    case(state_input_ctrl)
      `IDLE : begin
         if(state == `INST && start_valid_buffer >= 3'd6 && inst_counter == s_axi_img_size && M_AXI_RLAST && AR_4k_counter == AR_4k_excision_counter && next_inst_finish != 1'b1)  next_state_input_ctrl = `INPUT;
         else if(state != `INST && start_valid_buffer >= 3'd2 && inst_addr < s_axi_img_size && state == `PE && Buffer_choose == 1'b1 && next_inst_finish != 1'b1) next_state_input_ctrl = `INPUT;
         else if(state != `INST && start_valid_buffer >= 3'd2 && inst_addr < s_axi_img_size && state == `PE && Buffer_choose == 1'b0 && next_inst_finish != 1'b1) next_state_input_ctrl = `INPUT_B;
         else next_state_input_ctrl = state_input_ctrl;
      end
      `INPUT : begin
         if(start_valid_buffer == 2'd3 && Input_reuse_A == 0 && Weight_reuse_A == 1'd1) next_state_input_ctrl = `WEIGHT;
         else if(start_valid_buffer == 2'd3 && Input_reuse_A == 0 && Weight_reuse_A == 1'd0) next_state_input_ctrl = `WAIT_PE;
         else if(input_finish_A && Weight_reuse_A) next_state_input_ctrl = `WEIGHT;
         else if(input_finish_A && state == `INPUT_LOAD && ~Weight_reuse_A) next_state_input_ctrl = `IDLE;
         else next_state_input_ctrl = state_input_ctrl;
      end
      `INPUT_B : begin
         if(start_valid_buffer == 2'd3 && Input_reuse_B == 0 && Weight_reuse_B == 1'd1) next_state_input_ctrl = `WEIGHT_B;
         else if(start_valid_buffer == 2'd3 && Input_reuse_B == 0 && Weight_reuse_B == 1'd0) next_state_input_ctrl = `WAIT_PE;
         else if(input_finish_B && Weight_reuse_B) next_state_input_ctrl = `WEIGHT_B;
         else if(input_finish_B && state == `INPUT_LOAD && ~Weight_reuse_B) next_state_input_ctrl = `IDLE;
         else next_state_input_ctrl = state_input_ctrl;
      end
      `WEIGHT : begin
         if(weight_finish_A && state == `INPUT_LOAD) next_state_input_ctrl = `IDLE;
         else if(weight_finish_A && inst_addr == 4'd2 || IRQ) next_state_input_ctrl = `IDLE;
         else next_state_input_ctrl = state_input_ctrl;
      end
      `WEIGHT_B : begin
         if(weight_finish_B && state == `INPUT_LOAD) next_state_input_ctrl = `IDLE;
         else if(weight_finish_B && inst_addr == 4'd2 || IRQ) next_state_input_ctrl = `IDLE;
         else next_state_input_ctrl = state_input_ctrl;
      end
      `WAIT_PE : begin
        if(PE_finish_buf) next_state_input_ctrl = `IDLE;
        else next_state_input_ctrl = state_input_ctrl;
      end
      default : next_state_input_ctrl = `IDLE;
    endcase
end
always@(posedge clk) PE_finish_buf <= PE_finish;
assign input_buffer_loading = (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B || 
                                state_input_ctrl == `WEIGHT || state_input_ctrl == `WEIGHT_B) ? 1'b1 : 1'b0;

//////////////////////////////////////4K Boundry//////////////////////////////////////
always@(posedge clk) AR_4k_counter_head <= (s_axi_dram_raddr[BOUNDARY_SIZE-1:4]+s_axi_img_size <= 8'hff) ? s_axi_img_size : 8'hff-s_axi_dram_raddr[BOUNDARY_SIZE-1:4];
always@(posedge clk) AR_4k_counter_tail <= s_axi_dram_raddr[BOUNDARY_SIZE-1:0] + s_axi_img_size*5'h10 ;
always@(posedge clk) AR_4k_excision_counter <= (AR_4k_counter_tail[BOUNDARY_SIZE-1:0] == 8'd0) ? AR_4k_counter_tail[15:12] - 1'd1 : AR_4k_counter_tail[15:12];

always@(*) begin
    if(rst)
        M_AXI_ARLEN = 8'd0;
    else if(state == `INST) begin
        M_AXI_ARLEN = next_AR_4k_state;
    end
    else if(input_buffer_loading) begin
        M_AXI_ARLEN = AR_len_buffer;
    end
    else
        M_AXI_ARLEN = 8'd0;
end
                          
assign next_AR_4k_state = (AR_4k_counter == 4'd0) ? AR_4k_counter_head : 
       (AR_4k_counter == AR_4k_excision_counter) ? AR_4k_counter_tail[BOUNDARY_SIZE-1:4] : 8'hff;                         

assign next_inst_finish = (inst_counter == (inst_addr-1'd1) && inst_addr >= s_axi_img_size && state != `INST) ? 1'b1 : 1'b0;

always@(posedge clk) begin
    if(rst)
        inst_addr <= 12'd0;
    else if(inst_addr < s_axi_img_size && (next_state_input_ctrl == `INPUT  || next_state_input_ctrl == `INPUT_B) && state_input_ctrl == `IDLE)
        inst_addr <= inst_addr + 8'd2;
    else if(state == `INPUT_LOAD && next_state == `INST)
        inst_addr <= 12'd0;
end

always@(posedge clk) begin
    if(rst)
        inst_counter <= 12'd0;
    else if(state == `INST && next_state == `INPUT_LOAD)
        inst_counter <= 12'd0;
    else if(state == `INPUT_LOAD && next_state_input_ctrl ==`IDLE && next_inst_finish != 1'b1)
        inst_counter <= inst_addr;
    else if(state == `INST && inst_counter < s_axi_img_size && M_AXI_RVALID)
        inst_counter <= inst_counter + 1'd1;
    else if(input_buffer_loading && (next_state_input_ctrl != `WEIGHT || next_state_input_ctrl != `WEIGHT_B) && inst_counter < (inst_addr-1'd1) && next_inst_finish != 1'b1)
        inst_counter <= inst_counter + 1'd1;
end

always@(posedge clk) begin
    if(rst)
        AR_4k_counter <= 3'd0;
    else if(state == `INST && M_AXI_RLAST && M_AXI_RVALID && AR_4k_counter < AR_4k_excision_counter)
        AR_4k_counter <= AR_4k_counter + 1'd1;
end

assign M_AXI_ARADDR = (state == `INST && AR_4k_counter == 4'd0) ? s_axi_dram_raddr :
                      (state == `INST && AR_4k_counter == 4'd1) ? s_axi_dram_raddr + (AR_4k_counter_head + 1'd1)*5'h10: 
                      (state == `INST && AR_4k_counter <= AR_4k_excision_counter) ? s_axi_dram_raddr + (AR_4k_counter_head + 1'd1)*5'h10 + (16'h1000 * (AR_4k_counter-1'b1)) : 
                      (input_buffer_loading) ? off_to_on_ibuf_iaddr : 32'd0;
////////////////////////////////////////////////////read inst////////////////////////////////////////////////////
always@(posedge clk) begin
    if(rst)
        Buffer_choose <= 1'b0;
     else if(state == `PE && next_state == `INPUT_LOAD)
        Buffer_choose <= Buffer_choose + 1'b1;
     else if(state == `INST && next_state == `INPUT_LOAD)
        Buffer_choose <= 1'b0;
end

assign Input_Address = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Input_Address_A : Input_Address_B;
assign Weight_Address = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Weight_Address_A : Weight_Address_B;
assign Output_Address = (Buffer_choose == 1'b0) ? Output_Address_A : Output_Address_B;
assign Pooling_Address = (Buffer_choose == 1'b0) ? Pooling_Address_A : Pooling_Address_B;
assign Weight_len = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Weight_len_A : Weight_len_B;
assign Is_Final_Tile = (Buffer_choose == 1'b0) ? Is_Final_Tile_A : Is_Final_Tile_B;
assign Have_Accumulate = (Buffer_choose == 1'b0) ? Have_Accumulate_A : Have_Accumulate_B;
assign Is_Last_Channel = (Buffer_choose == 1'b0) ? Is_Last_Channel_A : Is_Last_Channel_B;
assign Choose_Input_buf = (Buffer_choose == 1'b0) ? Use_Input_A : Use_Input_B;
assign Choose_Weight_buf = (Buffer_choose == 1'b0) ? Use_Weight_A : Use_Weight_B;
assign Reload_buf = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Reload_A : Reload_B;
assign Input_reuse_A_buf = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Input_reuse_A : 0;
assign Input_reuse_B_buf = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? 0 : Input_reuse_B;
assign type = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? type_A : type_B;
assign Master_Input_Tile_Size_row = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Input_Tile_Size_row_A : Input_Tile_Size_row_B;
assign Master_Input_Tile_Size_col = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Input_Tile_Size_col_A : Input_Tile_Size_col_B;
assign Input_Tile_Size_row = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Input_Tile_Size_row_B : Input_Tile_Size_row_A;
assign Input_Tile_Size_col = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? Input_Tile_Size_col_B : Input_Tile_Size_col_A;
assign Have_maxpooling = (Buffer_choose == 1'b0) ? Have_maxpooling_A : Have_maxpooling_B;
assign hw_icp_able_cacl = (Buffer_choose == 1'b0) ? hw_icp_able_cacl_A : hw_icp_able_cacl_B;
assign hw_ocp_able_cacl = (Buffer_choose == 1'b0) ? hw_ocp_able_cacl_A : hw_ocp_able_cacl_B;
assign hw_icp_able_cacl_to_input = (state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) ? hw_icp_able_cacl_A : hw_icp_able_cacl_B;

always@(posedge clk) begin
    if(rst)
        {hw_ocp_able_cacl_A,hw_icp_able_cacl_A,Input_reuse_A,Weight_reuse_A,Use_Input_A,Use_Weight_A,Reload_A,Have_maxpooling_A,Weight_len_A,Input_Tile_Size_col_A,Input_Tile_Size_row_A,
        type_A,Is_Final_Tile_A,Have_Accumulate_A,Is_Last_Channel_A,Pooling_Address_A,Input_Address_A,Weight_Address_A,Output_Address_A} <= 0;
    else if(state_input_ctrl == `INPUT) begin
        {Pooling_Address_A,Input_Address_A,Weight_Address_A,Output_Address_A} <= (start_valid_buffer == 3'd1) ? inst_data : {Pooling_Address_A,Input_Address_A,Weight_Address_A,Output_Address_A};
        
        {hw_ocp_able_cacl_A,hw_icp_able_cacl_A,Have_maxpooling_A,Weight_len_A,Input_Tile_Size_col_A,Input_Tile_Size_row_A,type_A,Is_Final_Tile_A,Have_Accumulate_A,Is_Last_Channel_A}
                <= (start_valid_buffer == 3'd2) ? inst_data[30:0] : {hw_ocp_able_cacl_A,hw_icp_able_cacl_A,Have_maxpooling_A,Weight_len_A,Input_Tile_Size_col_A,Input_Tile_Size_row_A,type_A,Is_Final_Tile_A,Have_Accumulate_A,Is_Last_Channel_A};
        Reload_A <= (start_valid_buffer == 3'd2) ? inst_data[108] : Reload_A;
        Use_Weight_A <= (start_valid_buffer == 3'd2) ? inst_data[112] : Use_Weight_A;
        Use_Input_A <= (start_valid_buffer == 3'd2) ? inst_data[116] : Use_Input_A;
        Weight_reuse_A <= (start_valid_buffer == 3'd2) ? inst_data[120] : Weight_reuse_A;
        Input_reuse_A <= (start_valid_buffer == 3'd2) ? inst_data[124] : Input_reuse_A;
    end
end
//,type_A,Is_Final_Tile_A,Have_Accumulate_A,Is_Last_Channel_A
always@(posedge clk) begin
    if(rst)
        {hw_ocp_able_cacl_B,hw_icp_able_cacl_B,Input_reuse_B,Weight_reuse_B,Use_Input_B,Use_Weight_B,Reload_B,Have_maxpooling_B,Weight_len_B,Input_Tile_Size_col_B,Input_Tile_Size_row_B,
        type_B,Is_Final_Tile_B,Have_Accumulate_B,Is_Last_Channel_B,Pooling_Address_B,Input_Address_B,Weight_Address_B,Output_Address_B} <= 0;
    else if(state_input_ctrl == `INPUT_B) begin
       {Pooling_Address_B,Input_Address_B,Weight_Address_B,Output_Address_B} <= (start_valid_buffer == 3'd1) ? inst_data : {Pooling_Address_B,Input_Address_B,Weight_Address_B,Output_Address_B};
    
        {hw_ocp_able_cacl_B,hw_icp_able_cacl_B,Have_maxpooling_B,Weight_len_B,Input_Tile_Size_col_B,Input_Tile_Size_row_B,type_B,Is_Final_Tile_B,Have_Accumulate_B,Is_Last_Channel_B}
                <= (start_valid_buffer == 3'd2) ? inst_data[30:0] : {hw_ocp_able_cacl_B,hw_icp_able_cacl_B,Have_maxpooling_B,Weight_len_B,Input_Tile_Size_col_B,Input_Tile_Size_row_B,type_B,Is_Final_Tile_B,Have_Accumulate_B,Is_Last_Channel_B};
        Reload_B = (start_valid_buffer == 3'd2) ? inst_data[108] : Reload_B;
        Use_Weight_B = (start_valid_buffer == 3'd2) ? inst_data[112] : Use_Weight_B;
        Use_Input_B = (start_valid_buffer == 3'd2) ? inst_data[116] : Use_Input_B;
        Weight_reuse_B = (start_valid_buffer == 3'd2) ? inst_data[120] : Weight_reuse_B;
        Input_reuse_B = (start_valid_buffer == 3'd2) ? inst_data[124] : Input_reuse_B;
    end
end
//Output_On_Chip_Buffer_Limit_In_Address_B,Output_On_Chip_Buffer_Limit_Out_Address_B,type_B,Is_Final_Tile_B,Have_Accumulate_B,Is_Last_Channel_B,
////////////////////////////////////////////////////For SRAM (INPUT) signal////////////////////////////////////////////////////

assign rst_A = (state_input_ctrl == `INPUT && start_valid_buffer == 3'd3) ? 1'd1 : 1'd0;
assign ready_A = ((state_input_ctrl == `INPUT || state_input_ctrl == `WEIGHT) /*&& start_valid_buffer < 2'd3 */&&  start_valid_buffer >= 3'd6) ? 1'd1 : 1'd0;
always@(posedge clk)  start_A <= (state == `PE && Choose_Input_buf == 1'd1 && ~On_to_PE_finish) ? 1'd1 : 1'd0;

assign rst_B = (state_input_ctrl == `INPUT_B && start_valid_buffer == 3'd3) ? 1'd1 : 1'd0;
assign ready_B = ((state_input_ctrl == `INPUT_B || state_input_ctrl == `WEIGHT_B)  /*&& start_valid_buffer < 2'd3 */&& start_valid_buffer >= 3'd6) ? 1'd1 : 1'd0;
always@(posedge clk) start_B <= (state == `PE && Choose_Input_buf == 1'd0 && ~On_to_PE_finish) ? 1'd1 : 1'd0;

always@(posedge clk) rst_A_buf <= rst_A;
always@(posedge clk) rst_B_buf <= rst_B;

assign weight_rst_A = rst_A & (Weight_reuse_A == 1'b1);
assign weight_rst_B = rst_B & (Weight_reuse_B == 1'b1);
endmodule
