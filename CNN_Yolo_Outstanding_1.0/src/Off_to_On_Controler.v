`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/02/05 15:37:57
// Design Name: 
// Module Name: Off_to_On_Controler
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
//Bitparal 8 8 Version
module Off_to_On_Controler #(
    parameter TYPE_SIZE = 4,
    parameter WORD_SIZE = 16,
    parameter LINE_SIZE = 6,
    parameter INTEGER = 32,
    parameter EIGHT_WORD_SIZE = 128,
    parameter BOUNDARY_SIZE = 12,
    parameter OFF_TO_ON_ADDRESS_SIZE = 11, // 1156 (Dec) 484(hex) 0100 1000 0100(bin) 
    parameter BUFFER_ROW = 34,
    parameter BUFFER_COL = 36,
    parameter ADDR_SIZE = 8,
    parameter WEIGHT_NUM = 74,
    parameter LEFT_UP = 0,
    parameter UP = 1,
    parameter RIGHT_UP = 2,
    parameter LEFT = 3,
    parameter MIDDLE = 4,
    parameter RIGHT = 5,
    parameter LEFT_DOWN = 6,
    parameter DOWN = 7,
    parameter RIGHT_DOWN = 8,
    parameter ALL_PADDING = 9,
    parameter ALL_NO_PADDING = 10
    `define   INPUT  1
    `define   INPUT_B 2
    `define   WEIGHT 3
    `define   WEIGHT_B 4
    
    `define   IDLE  0
    `define   INST  1
    `define   INPUT_LOAD 2
    `define   PE  3
    `define   OUTPUT  4
    
)(
    input           clk,
    input wire      rst_A,
    input wire      rst_B,
    input           ready_A,
    input           ready_B,
    input           M_AXI_RLAST,
    input           M_AXI_RVALID,  // when valid is High , read data is effective
    input           M_AXI_ARVALID,
    input           M_AXI_ARREADY,
    input [LINE_SIZE-1:0] TILE_SIZE_col,
    input [LINE_SIZE-1:0] TILE_SIZE_row,
    input  wire [2:0] state,
    input  wire [2:0] next_state_input_ctrl,
    input  wire [2:0] state_input_ctrl,
    input     start_A,
    input     start_B,
    input     Input_reuse_A,
    input     Input_reuse_B,
    input     Reload,
    input       [1:0] Kernel_Size,
    input       [OFF_TO_ON_ADDRESS_SIZE:0] Feature_map_size,
    input [TYPE_SIZE-1'b1 : 0] type, //10 type
    input [2:0] start_valid_buffer,
    output  reg    ibuf_wr_A,
    output  reg    ibuf_wr_B,
    output [1:0] bank_sel,
    
    input [INTEGER-1:0] first_addr,// the first addr begin
    input [INTEGER-1:0] Weight_Address,
    input Use_bufferAB,
    input [6:0] Weight_len,
    output  wire weight_buffer_start,
    output  wire next_valid,
    output  wire [ADDR_SIZE-1:0] AR_len,
    output  wire [INTEGER-1:0] off_to_on_ibuf_iaddr,
    output  [INTEGER-1:0] ibuf_bank_iaddr,
    output  reg input_finish_A,
    output  reg input_finish_B,
    output  reg weight_finish_A,
    output  reg weight_finish_B,
    output  reg [1:0] next_state_bank_count,
    output  padding_start,
    output  off_to_on_valid_A,
    output  off_to_on_valid_B,
    output  padding_Finish
    
);

wire [ADDR_SIZE-1:0] AR_4k_counter_head;
wire [BOUNDARY_SIZE-1:0] tile_length;
reg [LINE_SIZE-1:0]row_count;// ----
reg [INTEGER-1:0] counter; // count 0 to tile_length
reg [INTEGER-1:0] off_to_on_input_addr,off_to_on_weight_addr,off_to_on_input_addr_tmp;
reg [ADDR_SIZE-1:0] AR_4k_counter_head_tmp;
reg [BOUNDARY_SIZE-1:0] total_len_counter;
reg [3:0] AR_4k_counter;

wire [WORD_SIZE-1:0] AR_4k_counter_buffer;
wire [3:0] AR_4k_excision_counter;
wire IBUF_write_ack;
wire IBUF_write_ack_B;
wire [7:0] AR_len_input,AR_len_weight;
reg [1:0] state_bank_count;
reg [1:0] ibuf_iaddr_bank_sel;
reg [INTEGER-1:0] ibuf_iaddr;

wire [ADDR_SIZE-1:0] AR_4K_weight_head;
wire [WORD_SIZE-1:0] AR_4k_weight_buffer;
wire [3:0] AR_4k_weight_excision_counter;
wire [5:0] valid_tile_row,valid_tile_col;
wire [5:0] tile_row,tile_col;
wire [BOUNDARY_SIZE-1:0] total_tile_size;
wire [1:0] total_bank;
reg [2:0] state_total_bank_counter;
reg [2:0] total_bank_counter;
reg [9:0] off_to_on_iaddr_A,off_to_on_iaddr_B;
reg [6:0] col_position_A,col_position_B;
reg [6:0] row_position_A,row_position_B;
reg [3:0] bank_col;
reg [1:0] choose_bank;
reg [9:0] weight_counter;
wire [6:0] choose_col_position,off_to_on_col_position;
wire [6:0] row_position_A_buf,row_position_B_buf;
wire [6:0] col_position_A_buf,col_position_B_buf;
reg padding_start_A,padding_start_B;
wire [6:0] row_position_pad_buf;
wire [1:0] padding_bank_sel;
wire [OFF_TO_ON_ADDRESS_SIZE-1'b1 : 0] padding_value_addr;
//wire padding_Finish;

Padding uPadding(
    .clk(clk),
    .rst(rst_A || rst_B),
    .start_in(padding_start_A || padding_start_B),
    .type(type), //10 type
    .TILE_SIZE_row(TILE_SIZE_row),
    .TILE_SIZE_col(TILE_SIZE_col),
    .row_position(row_position_pad_buf),
    .col_position(choose_col_position),
    .start(padding_start),
    .next_state_padding_choose_bank(padding_bank_sel),
    .padding_value_addr(padding_value_addr),
    .finish(padding_Finish)
);

always@(posedge clk) padding_start_A <= (state_input_ctrl == `INPUT && M_AXI_RVALID && M_AXI_RLAST && next_state_bank_count == total_bank) ? 1 : 0;
always@(posedge clk) padding_start_B <= (state_input_ctrl == `INPUT_B && M_AXI_RVALID && M_AXI_RLAST && next_state_bank_count == total_bank) ? 1 : 0;

assign IBUF_write_ack = ( start_A == 0 && ready_A == 1 && counter < total_tile_size && Input_reuse_A);
assign IBUF_write_ack_B = ( start_B == 0 && ready_B == 1 && counter < total_tile_size && Input_reuse_B);

assign total_bank = (Kernel_Size == 2'd3) ? 2'd1 : 2'd3;

assign valid_tile_row = (type == ALL_PADDING || type == ALL_NO_PADDING) ? TILE_SIZE_row :
                        (type == UP || type == MIDDLE || type == DOWN) ? TILE_SIZE_row + 2'd2 : TILE_SIZE_row + 2'd1;
                        
assign valid_tile_col = (type == ALL_PADDING || type == ALL_NO_PADDING) ? TILE_SIZE_col:
                        (type == LEFT || type == MIDDLE || type == RIGHT) ? TILE_SIZE_col + 2'd2 : TILE_SIZE_col + 2'd1;
                        
assign total_tile_size = (Kernel_Size == 2'd3) ? valid_tile_row * valid_tile_col : TILE_SIZE_col * TILE_SIZE_row;
assign tile_length = (Kernel_Size == 2'd3) ? valid_tile_row : TILE_SIZE_col * TILE_SIZE_row;

always@(posedge clk) begin
    if(rst_A || rst_B) input_finish_A <= 0;
    else
        input_finish_A <= (state_input_ctrl == `INPUT && padding_Finish) ? 1'd1 :
                          (state == `INPUT_LOAD || (state_input_ctrl == `IDLE && next_state_input_ctrl == `INPUT_B)) ? 1'd0 : input_finish_A;//input_finish_A;    padding_start_A
end

always@(posedge clk)  begin
    if(rst_A || rst_B) input_finish_B <= 0;
    else input_finish_B <= (state_input_ctrl == `INPUT_B && padding_Finish) ? 1'd1 :
                           (state == `INPUT_LOAD || (state_input_ctrl == `IDLE && next_state_input_ctrl == `INPUT)) ? 1'd0 : input_finish_B;//input_finish_B;     padding_start_B
end

always@(posedge clk) weight_finish_A <= (state_input_ctrl == `WEIGHT && M_AXI_RVALID && M_AXI_RLAST && weight_counter == (Weight_len-1'd1)) ? 1'd1 :
                        (state == `INPUT_LOAD || (state_input_ctrl == `IDLE && next_state_input_ctrl == `WEIGHT_B)) ? 1'd0 : weight_finish_A;

always@(posedge clk) weight_finish_B <= (state_input_ctrl == `WEIGHT_B && M_AXI_RVALID && M_AXI_RLAST && weight_counter == (Weight_len-1'd1)) ? 1'd1 :
                        (state == `INPUT_LOAD || (state_input_ctrl == `IDLE && next_state_input_ctrl == `WEIGHT)) ? 1'd0 :weight_finish_B;

always@(posedge clk) begin
    if(rst_A || rst_B) begin
        AR_4k_counter_head_tmp <= (AR_4k_counter != 4'd0) ? AR_4k_counter_head_tmp :
                                  ((first_addr[BOUNDARY_SIZE-1:4] + tile_length) <= 32'hff) ? tile_length - 1'd1: 32'hff - first_addr[BOUNDARY_SIZE-1:4];
    end
    else if(AR_4k_counter == 0)
        AR_4k_counter_head_tmp <= AR_4k_counter_head;
end

always@(posedge clk) begin
    if(rst_A || rst_B) 
        off_to_on_input_addr_tmp <= first_addr;
    else if(AR_4k_counter == 0)
        off_to_on_input_addr_tmp <= off_to_on_input_addr;
end
/*
always@(posedge clk) AR_4k_counter_head_tmp <= (AR_4k_counter == 0) ? AR_4k_counter_head : AR_4k_counter_head_tmp;
always@(posedge clk) off_to_on_input_addr_tmp <= (AR_4k_counter == 0) ? off_to_on_input_addr : off_to_on_input_addr_tmp;
*/
assign AR_4k_counter_head = (AR_4k_counter != 4'd0) ? AR_4k_counter_head_tmp :
                            ((off_to_on_input_addr[BOUNDARY_SIZE-1:4] + tile_length) <= 32'hff) ? tile_length - 1'd1: 32'hff - off_to_on_input_addr[BOUNDARY_SIZE-1:4];           
assign AR_4k_counter_buffer = (AR_4k_counter == 0) ? off_to_on_input_addr[BOUNDARY_SIZE-1:0] + (tile_length - 1'd1) * 5'h10 : off_to_on_input_addr_tmp[BOUNDARY_SIZE-1:0] + (tile_length) * 5'h10;
assign AR_4k_excision_counter = (AR_4k_counter_buffer[BOUNDARY_SIZE-1:0] == 8'd0) ? AR_4k_counter_buffer[15:BOUNDARY_SIZE] : AR_4k_counter_buffer[15:BOUNDARY_SIZE] + 1'd1;


assign AR_4K_weight_head = (Weight_Address[BOUNDARY_SIZE-1:4] + Weight_len <= 12'h0ff) ? Weight_len - 1'd1: (8'hff - Weight_Address[BOUNDARY_SIZE-1:4]);
assign AR_4k_weight_buffer = Weight_Address[BOUNDARY_SIZE-1:0] + Weight_len * 5'h10;
assign AR_4k_weight_excision_counter = (AR_4k_weight_buffer[BOUNDARY_SIZE-1:0] == 8'd0) ? AR_4k_weight_buffer[15:BOUNDARY_SIZE] : AR_4k_weight_buffer[15:BOUNDARY_SIZE] + 1'd1;


assign AR_len_input = (AR_4k_counter == 4'd0 && (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B)) ? AR_4k_counter_head : 
                      (AR_4k_counter == (AR_4k_excision_counter-1'd1) && (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B)) ? AR_4k_counter_buffer[BOUNDARY_SIZE-1:4]-1'd1 : 8'd255;       
assign  AR_len_weight = (AR_4k_counter == 4'd0 && (state_input_ctrl == `WEIGHT || state_input_ctrl == `WEIGHT_B)) ? AR_4K_weight_head : AR_4k_weight_buffer[BOUNDARY_SIZE-1:4]-1'd1;

assign AR_len = (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B) ? AR_len_input : AR_len_weight;         
assign off_to_on_ibuf_iaddr = (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B) ? off_to_on_input_addr : off_to_on_weight_addr;

always@(posedge clk) begin         //////////// Aw addr ctrl
    if(next_state_input_ctrl == `INPUT || next_state_input_ctrl == `INPUT_B) begin
        if(rst_A || rst_B)
            off_to_on_input_addr <= first_addr;
            
        else if(M_AXI_ARVALID && AR_4k_counter == 4'd0 && AR_4k_excision_counter != 4'd1)
            off_to_on_input_addr <= off_to_on_input_addr + (AR_4k_counter_head_tmp + 1'd1)*5'h10;
        
        else if(M_AXI_ARVALID && AR_4k_counter == 4'd0 && AR_4k_excision_counter == 4'd1)
            off_to_on_input_addr <= off_to_on_input_addr + (13'h10 * Feature_map_size);
        
        else if(M_AXI_ARVALID && AR_4k_counter == 4'd1 && AR_4k_excision_counter == 4'd3)
            off_to_on_input_addr <= off_to_on_input_addr + 13'h1000;
        
        else if(M_AXI_ARVALID && AR_4k_counter == 4'd1 && AR_4k_excision_counter == 4'd2 && Kernel_Size == 3'd3)
            off_to_on_input_addr <= off_to_on_input_addr + ((13'h10 * Feature_map_size) - (AR_4k_counter_head_tmp + 1'd1)*5'h10);
            
        else if(M_AXI_ARVALID && AR_4k_counter == (AR_4k_excision_counter - 1'd1))
            off_to_on_input_addr <= off_to_on_input_addr_tmp +  Feature_map_size * 5'h10;
    end
end

always@(posedge clk) begin         //////////// Aw addr ctrl
      if(rst_A || rst_B)
          off_to_on_weight_addr <=  Weight_Address ;
      else if(M_AXI_ARVALID && AR_4k_counter == 4'd0 && (state_input_ctrl == `WEIGHT || state_input_ctrl == `WEIGHT_B))
          off_to_on_weight_addr <= off_to_on_weight_addr + (AR_4K_weight_head + 1'd1) * 5'h10;
end

always@(posedge clk)begin //counter
    if ( rst_A || rst_B) begin
        weight_counter <= 10'h000 ;
    end 
    else if (M_AXI_RVALID == 1'd1 && (state_input_ctrl == `WEIGHT || state_input_ctrl == `WEIGHT_B) && weight_counter < (Weight_len-1'd1) && weight_counter >= 10'd0) begin
            weight_counter <= weight_counter + 1'b1 ;
    end
end

assign next_valid = (Kernel_Size == 2'd3 && (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B) && M_AXI_ARREADY && total_len_counter < (total_tile_size-1'd1)) ? 1'd1 : 
                    (Kernel_Size == 2'd1 && (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B) && M_AXI_ARREADY && state_total_bank_counter <= 2'd2 && total_bank_counter != 3'd3) ? 1'd1 :
                    ((state_input_ctrl == `WEIGHT || state_input_ctrl == `WEIGHT_B) && M_AXI_ARREADY && AR_4k_counter < AR_4k_weight_excision_counter) ? 1'd1 : 1'd0;

assign weight_buffer_start = M_AXI_RVALID && (state_input_ctrl == `WEIGHT || state_input_ctrl == `WEIGHT_B);

always@(posedge clk) begin
    if(rst_A || rst_B)
        state_total_bank_counter <= 3'd0;
    else
        state_total_bank_counter <= total_bank_counter;
end

always@(*) begin // use for counting len size , to make sure is AXI next_vaild 1 or 0
    case(state_total_bank_counter)  
        0 : begin
            if(M_AXI_ARREADY && total_len_counter == total_tile_size) total_bank_counter = 3'd1;
            else total_bank_counter = state_total_bank_counter;
        end
        1 : begin
            if(M_AXI_ARREADY && total_len_counter == total_tile_size && Kernel_Size == 2'd1) total_bank_counter = 3'd2;
            else total_bank_counter = state_total_bank_counter;
        end
        2 : begin
            if(M_AXI_ARREADY && total_len_counter == total_tile_size) total_bank_counter = 3'd3;
            else total_bank_counter = state_total_bank_counter;
        end
        default : total_bank_counter = state_total_bank_counter;
    endcase
end

always@(posedge clk) begin
    if(rst_A || rst_B || next_state_input_ctrl != state_input_ctrl)
        AR_4k_counter <= 4'd0;
    else if(M_AXI_ARVALID && (state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B) && (AR_4k_excision_counter-1'd1) == AR_4k_counter)
        AR_4k_counter <= 4'd0;
    else if(M_AXI_ARVALID && (((state_input_ctrl == `INPUT || state_input_ctrl == `INPUT_B) && AR_4k_excision_counter > 0 && AR_4k_counter < AR_4k_excision_counter) || 
           ((state_input_ctrl == `WEIGHT || state_input_ctrl == `WEIGHT_B) && AR_4k_weight_excision_counter > 0 && AR_4k_counter < AR_4k_weight_excision_counter)))
        AR_4k_counter <= AR_4k_counter + 1'd1;
end

always@(posedge clk) begin
     if(rst_A || rst_B || next_state_input_ctrl != state_input_ctrl)
        total_len_counter <= 4'd0;
     else if(M_AXI_ARVALID && total_len_counter == total_tile_size && next_state_bank_count != 3'd3 && Kernel_Size == 2'd1)
        total_len_counter <= 1'd1 + AR_len_input;
     else if(M_AXI_ARVALID)
        total_len_counter <= total_len_counter + 1'd1 + AR_len_input;
end


////////////////////////////////////////////////////////////////////////// Buf ctrl ////////////////////////////////////////////////////////////////////////// 
always@(posedge clk) begin
    if(rst_A || rst_B || next_state_input_ctrl != state_input_ctrl) 
        state_bank_count <= 4'd0;
    else
        state_bank_count <= next_state_bank_count;
end

always@(*) begin   // count 1x1 mode witch bank is now
    case(state_bank_count)
        0 : begin
            if(M_AXI_RLAST && counter == (total_tile_size-1'd1)) next_state_bank_count = 1;
            else next_state_bank_count = state_bank_count;
        end
        1 : begin
            if(M_AXI_RLAST && counter == (total_tile_size-1'd1) && Kernel_Size == 2'd1) next_state_bank_count = 2;
            else next_state_bank_count = state_bank_count;
        end
        2 : begin
            if(M_AXI_RLAST && counter == (total_tile_size-1'd1)) next_state_bank_count = 3;
            else next_state_bank_count = state_bank_count;
        end
        default : next_state_bank_count = state_bank_count;
    endcase
end

////////////////////////////////////////////////////////////////////////// Buf ctrl ////////////////////////////////////////////////////////////////////////// 

always@(*)begin //ibuf_wr
    if ( IBUF_write_ack ) begin 
			ibuf_wr_A <= 1'b1 ;
	end 
	else begin
		ibuf_wr_A <= 1'b0 ;
	end 
end

always@(*)begin //ibuf_wr
	if ( IBUF_write_ack_B ) begin 
		ibuf_wr_B <= 1'b1 ;
	end 
	else begin
		ibuf_wr_B <= 1'b0 ;
	end 
end

always@(posedge clk)begin //counter
    if ( rst_A || rst_B || (Kernel_Size == 2'd1 && next_state_bank_count != state_bank_count && next_state_input_ctrl != 4'd3)) begin
        counter <= 10'h000 ;
    end else begin
        if (M_AXI_RVALID == 1'd1 && counter < (total_tile_size-1'd1) && counter >= 10'd0) begin
            counter <= counter + 1'b1 ;
        end
        else begin
            counter <= counter ;
        end
    end
end

always@(posedge clk)begin//address 
    if ( rst_A || rst_B || (Kernel_Size == 2'd1 && next_state_bank_count != state_bank_count && next_state_input_ctrl != 4'd3))
        row_count <= 6'h00 ;
    else if(M_AXI_RVALID == 1'b1 && counter < (total_tile_size-1'd1) && row_count < (valid_tile_row-1'b1))
        row_count <= row_count + 1'b1 ;
    else if(M_AXI_RVALID == 1'b1 && counter < (total_tile_size-1'd1) && row_count == (valid_tile_row-1'b1))
        row_count <= 6'd0;
end

////////////////////////////////////// off to on chip buffer bank sel ////////////////////////////////////// 
assign tile_row = (type == ALL_NO_PADDING) ?  TILE_SIZE_row : TILE_SIZE_row + 2;
assign tile_col = (type == ALL_NO_PADDING) ?  TILE_SIZE_col : TILE_SIZE_col + 2; 

assign row_position_A_buf = row_position_A + 2*tile_row;
assign row_position_B_buf = row_position_B + 2*tile_row;

assign col_position_A_buf = col_position_A + 2*tile_col;
assign col_position_B_buf = col_position_B + 2*tile_col;

always@(posedge clk) begin
    if(start_valid_buffer == 3'd3 && Reload)
        row_position_A <= 7'd0;
    else if(start_valid_buffer == 3'd3 && Use_bufferAB == 1) begin
        if(row_position_A_buf > BUFFER_ROW && col_position_A_buf <= BUFFER_COL)
            row_position_A <= 7'd0;
        else if(row_position_A_buf > BUFFER_ROW && col_position_A_buf > BUFFER_COL)
            row_position_A <= row_position_A;
        else
            row_position_A <= row_position_A + tile_row;
    end
end

always@(posedge clk) begin
    if(start_valid_buffer == 3'd3 && Reload)
        row_position_B <= 7'd0;
    else if(start_valid_buffer == 3'd3 && Use_bufferAB == 0)begin
        if(row_position_B_buf > BUFFER_ROW && col_position_B_buf <= BUFFER_COL)
            row_position_B <= 7'd0;
        else if(row_position_B_buf > BUFFER_ROW && col_position_B_buf > BUFFER_COL)
            row_position_B <= row_position_B;
        else
            row_position_B <= row_position_B + tile_row;
    end
end

always@(posedge clk) begin
    if(start_valid_buffer == 3'd3 && Reload)
        col_position_A <= 7'd0;
    else if(~Reload && start_valid_buffer == 3'd3 && Use_bufferAB == 1) begin
        if(col_position_A_buf > BUFFER_COL)
            col_position_A <= col_position_A;
        else if(row_position_A_buf > BUFFER_ROW)
            col_position_A <= col_position_A + tile_col;
    end
end

always@(posedge clk) begin
    if(start_valid_buffer == 3'd3 && Reload)
        col_position_B <= 7'd0;
    else if(~Reload && start_valid_buffer == 3'd3 && Use_bufferAB == 0) begin
        if(col_position_B_buf > BUFFER_COL)
            col_position_B <= col_position_B;
        else if(row_position_B_buf > BUFFER_ROW)
            col_position_B <= col_position_B + tile_col;
    end
end

assign choose_col_position = (start_valid_buffer == 3'd4 && Use_bufferAB == 0) ? col_position_B : 
                             (start_valid_buffer == 3'd4 && Use_bufferAB == 1) ? col_position_A : 0;
                             
assign off_to_on_col_position = (type == LEFT_UP || type == ALL_PADDING || type == UP || type == RIGHT_UP) ? choose_col_position+1'd1 : choose_col_position;
assign row_position_pad_buf = (Use_bufferAB) ? row_position_A : row_position_B;


always@(posedge clk) begin
    if(start_valid_buffer == 3'd3) begin
        choose_bank <= 2'd0; // 0 or 1 or 2
    end
    else if(start_valid_buffer == 3'd4)begin
        case(off_to_on_col_position)
            0,3,6,9,12,15,18,21,24,27,30,33 :   choose_bank <= 2'd0;
            1,4,7,10,13,16,19,22,25,28,31,32 :  choose_bank <= 2'd1;
            default :                           choose_bank <= 2'd2;
        endcase
    end
end

always@(posedge clk) begin
    if(start_valid_buffer == 3'd3) begin
        bank_col <= 7'd0; // 0~11
    end
    else if(start_valid_buffer == 3'd4)begin
        case(off_to_on_col_position)
            0,1,2    : bank_col <= 7'd0;
            3,4,5    : bank_col <= 7'd1;
            6,7,8    : bank_col <= 7'd2;
            9,10,11  : bank_col <= 7'd3;
            12,13,14 : bank_col <= 7'd4;
            15,16,17 : bank_col <= 7'd5;
            18,19,20 : bank_col <= 7'd6;
            21,22,23 : bank_col <= 7'd7;
            24,25,26 : bank_col <= 7'd8;
            27,28,29 : bank_col <= 7'd9;
            30,31,32 : bank_col <= 7'd10;
            default  : bank_col <= 7'd11;
        endcase
    end
end

always@(*) begin
    if(type == LEFT_UP || type == ALL_PADDING || type == LEFT || type == LEFT_DOWN)
        off_to_on_iaddr_A <= (row_position_A+1'd1) + bank_col * BUFFER_ROW;
    else 
        off_to_on_iaddr_A <= row_position_A + bank_col * BUFFER_ROW;
end

always@(*) begin
    if(type == LEFT_UP || type == ALL_PADDING || type == LEFT || type == LEFT_DOWN)
        off_to_on_iaddr_B <= (row_position_B+1'd1) + bank_col * BUFFER_ROW;
    else 
        off_to_on_iaddr_B <= row_position_B + bank_col * BUFFER_ROW;
end

always@(posedge clk) begin//address 
    if ( start_valid_buffer == 3'd5 || (Kernel_Size == 2'd1 && next_state_bank_count != state_bank_count && next_state_input_ctrl != 4'd3)) begin
        if(Use_bufferAB)
            ibuf_iaddr <= off_to_on_iaddr_A ;
        else if(~Use_bufferAB)
            ibuf_iaddr <= off_to_on_iaddr_B ;
    end 
    else if ((ibuf_wr_A || ibuf_wr_B) && counter < (total_tile_size-1'd1) && row_count == (valid_tile_row-1'b1) && ibuf_iaddr_bank_sel != 2'b10 && Kernel_Size == 3'd3) 
            ibuf_iaddr <= ibuf_iaddr - (valid_tile_row-1'b1);
    else if ((ibuf_wr_A || ibuf_wr_B) && counter < (total_tile_size-1'd1) && row_count == (valid_tile_row-1'b1) && ibuf_iaddr_bank_sel == 2'b10 && Kernel_Size == 3'd3)
            ibuf_iaddr <= ibuf_iaddr - (valid_tile_row-1'b1) + BUFFER_ROW;
    else if ((ibuf_wr_A || ibuf_wr_B) && M_AXI_RVALID == 1'b1 && counter < (total_tile_size)) 
        ibuf_iaddr <= ibuf_iaddr + 1;
end

always@(posedge clk)begin //counter
    if ( start_valid_buffer == 3'd5 )
        ibuf_iaddr_bank_sel <= choose_bank;
    else if((ibuf_wr_A || ibuf_wr_B) && counter < (total_tile_size-1'd1) && row_count == (valid_tile_row-1'b1) && ibuf_iaddr_bank_sel != 2'b10)
        ibuf_iaddr_bank_sel <= ibuf_iaddr_bank_sel + 1;
    else if((ibuf_wr_A || ibuf_wr_B) && counter < (total_tile_size-1'd1) && row_count == (valid_tile_row-1'b1) && ibuf_iaddr_bank_sel == 2'b10)
        ibuf_iaddr_bank_sel <= 0;
    else if((ibuf_wr_A || ibuf_wr_B) && counter ==  (total_tile_size-1'd1))
        ibuf_iaddr_bank_sel <= 2'b11;
end

assign ibuf_bank_iaddr = ((ibuf_wr_A || ibuf_wr_B) && M_AXI_RVALID == 1'b1 && counter <= (total_tile_size-1'd1)) ? ibuf_iaddr : padding_value_addr;
assign bank_sel = ((ibuf_wr_A || ibuf_wr_B) && M_AXI_RVALID == 1'b1 && counter <= (total_tile_size-1'd1)) ? ibuf_iaddr_bank_sel : padding_bank_sel;

assign off_to_on_valid_A = (state_input_ctrl == `INPUT && ibuf_wr_A && M_AXI_RVALID == 1'b1 && counter < (total_tile_size)) ? 1:
                           (state_input_ctrl == `INPUT && padding_start) ? 1 : 0;
                           
assign off_to_on_valid_B = (state_input_ctrl == `INPUT_B && ibuf_wr_B && M_AXI_RVALID == 1'b1 && counter < (total_tile_size)) ? 1:
                           (state_input_ctrl == `INPUT_B && padding_start) ? 1 : 0;
endmodule
