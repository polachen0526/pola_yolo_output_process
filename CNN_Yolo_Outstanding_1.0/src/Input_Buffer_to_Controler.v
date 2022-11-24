//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/22 22:13:59
// Design Name: 
// Module Name: Input_Buffer_to_Controler
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
//Bitserial 8 8 Version

module Input_Buffer_to_PE_Controler #(
    parameter OFF_TO_ON_ADDRESS_SIZE = 13, // 1156 (Dec) 484(hex) 0100 1000 0100(bin) 
    parameter BUFFER_ROW = 34,
    parameter BUFFER_COL = 36,
    parameter Bank_0 = 0,
    parameter Bank_1 = 1,
    parameter Bank_2 = 2,
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
    )(
    input clk,
    input Input_Buffer_to_PE_Ctrl_rst,
    
    input start_A,
    input start_B,
    
	input ibuf_rd_A,
	input ibuf_rd_B,
    input [3:0] Bit_serial,
    input [1:0] Kernel_Size,
    input [5:0] TILE_SIZE_col,
    input [5:0] TILE_SIZE_row,
    input [3:0] type,
    input On_to_PE_buffer_sel,
    input Reload,
    
    output reg [OFF_TO_ON_ADDRESS_SIZE-1:0] On_to_PE_addr,
    output reg [1:0] state,
    
    output [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_rd_0,
    output [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_rd_1,
    output [OFF_TO_ON_ADDRESS_SIZE-1:0] Bank_addr_rd_2,
    
    output [OFF_TO_ON_ADDRESS_SIZE-1:0] operator_length,
    output start_buffer_to_obuf_chip,
    output reg [3:0] Bit_serial_wait_counter,
    output  PE_rst,
    output reg On_to_PE_finish
    );
    
//reg [3:0] Bit_serial_wait_counter;
//reg [3:0] line_counter;
reg [OFF_TO_ON_ADDRESS_SIZE-1:0] operator_tile_conter;
reg start_buffer;
reg [5:0] row_count;
reg [3:0] line_select_bank_0;
reg [3:0] line_select_bank_2;
//reg [1:0] state_buffer;
reg [2:0] pip_buf;


reg [6:0] col_position_A,col_position_B;
reg [6:0] row_position_A,row_position_B;
reg [3:0] bank_col;
reg [1:0] choose_bank;
wire [6:0] choose_col_position;
wire [6:0] row_position_A_buf,row_position_B_buf;
wire [6:0] col_position_A_buf,col_position_B_buf;
wire [6:0] row_position_pad_buf;
wire [5:0] tile_row,tile_col;

assign start_buffer_to_obuf_chip = start_buffer ;
assign PE_rst = (pip_buf == 3'd3);

always@(posedge clk) begin
    if(Input_Buffer_to_PE_Ctrl_rst)
        On_to_PE_finish <= 0;
    else if(On_to_PE_addr == operator_length)
        On_to_PE_finish <= 1;
end

always@(posedge clk) begin
    if(Input_Buffer_to_PE_Ctrl_rst)
        pip_buf <= 0;
    else if(pip_buf < 3'd5)
        pip_buf <= pip_buf + 1'd1;
end

always@(posedge clk) begin
    if(Input_Buffer_to_PE_Ctrl_rst)
        start_buffer <= 1'b0;
    else if(pip_buf >= 3'd4)
        start_buffer <= (start_A == 1'b1 || start_B == 1'b1) ? 1'b1 : 1'b0;
end
/*
assign operator_length = (Kernel_Size == 2'b11 && fully_connected == 1'b0) ? ((TILE_SIZE_row + 2'd2) * TILE_SIZE_col + 1) : 
                         (Kernel_Size == 2'b01 && fully_connected == 1'b1) ? fully_connect_length :  TILE_SIZE_row * TILE_SIZE_col + 1;*/
assign operator_length = (Kernel_Size == 2'b11) ? ((TILE_SIZE_row + 2'd2) * TILE_SIZE_col + 1) : TILE_SIZE_row * TILE_SIZE_col + 1;      
                        // (Kernel_Size == 2'b01) ? fully_connect_length :  TILE_SIZE_row * TILE_SIZE_col + 1;                      
/////////////////////////////////////////////////////////////////////////////////////// Tile Select  ////////////////////////////////////////////////////////////////////////////////////// 
assign tile_row = (type == ALL_NO_PADDING) ?  TILE_SIZE_row : TILE_SIZE_row + 2;
assign tile_col = (type == ALL_NO_PADDING) ?  TILE_SIZE_col : TILE_SIZE_col + 2; 

assign row_position_A_buf = row_position_A + 2*tile_row;
assign row_position_B_buf = row_position_B + 2*tile_row;

assign col_position_A_buf = col_position_A + 2*tile_col;
assign col_position_B_buf = col_position_B + 2*tile_col;

always@(posedge clk) begin
    if(pip_buf == 3'd1 && Reload)
        row_position_A <= 7'd0;
    else if(pip_buf == 3'd1 && On_to_PE_buffer_sel == 0) begin
        if((row_position_A_buf > BUFFER_ROW && col_position_A_buf <= BUFFER_COL) || (row_position_A_buf > BUFFER_ROW && col_position_A_buf > BUFFER_COL))
            row_position_A <= 7'd0;
        else
            row_position_A <= row_position_A + tile_row;
    end
end

always@(posedge clk) begin
    if(pip_buf == 3'd1 && Reload)
        row_position_B <= 7'd0;
    else if(pip_buf == 3'd1 && On_to_PE_buffer_sel == 1)begin
        if((row_position_B_buf > BUFFER_ROW && col_position_B_buf <= BUFFER_COL) || (row_position_B_buf > BUFFER_ROW && col_position_B_buf > BUFFER_COL))
            row_position_B <= 7'd0;
        else
            row_position_B <= row_position_B + tile_row;
    end
end

always@(posedge clk) begin
    if(pip_buf == 3'd1 && Reload)
        col_position_A <= 7'd0;
    else if(~Reload && pip_buf == 3'd1 && On_to_PE_buffer_sel == 0) begin
        if(row_position_A_buf > BUFFER_ROW && col_position_A_buf > BUFFER_COL)
            col_position_A <= 0;
        else if(row_position_A_buf > BUFFER_ROW)
            col_position_A <= col_position_A + tile_col;
    end
end

always@(posedge clk) begin
    if(pip_buf == 3'd1 && Reload)
        col_position_B <= 7'd0;
    else if(~Reload && pip_buf == 3'd1 && On_to_PE_buffer_sel == 1) begin
        if(row_position_B_buf > BUFFER_ROW && col_position_B_buf > BUFFER_COL)
            col_position_B <= 0;
        else if(row_position_B_buf > BUFFER_ROW)
            col_position_B <= col_position_B + tile_col;
    end
end

assign choose_col_position = (pip_buf == 3'd2 && On_to_PE_buffer_sel == 1) ? col_position_B : 
                             (pip_buf == 3'd2 && On_to_PE_buffer_sel == 0) ? col_position_A : 0;
                             
assign row_position_pad_buf = (On_to_PE_buffer_sel) ? row_position_A : row_position_B;


always@(posedge clk) begin
    if(pip_buf == 3'd1) begin
        choose_bank <= 2'd0; // 0 or 1 or 2
    end
    else if(pip_buf == 3'd2)begin
        case(choose_col_position)
            0,3,6,9,12,15,18,21,24,27,30,33 :   choose_bank <= 2'd0;
            1,4,7,10,13,16,19,22,25,28,31,32 :  choose_bank <= 2'd1;
            default :                           choose_bank <= 2'd2;
        endcase
    end
end

always@(posedge clk) begin
    if(pip_buf == 3'd1) begin
        bank_col <= 7'd0; // 0~11
    end
    else if(pip_buf == 3'd2)begin
        case(choose_col_position)
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

/////////////////////////////////////////////////////////////////////////////////////// FSM //////////////////////////////////////////////////////////////////////////////////////
always@(posedge clk) begin
    if(Input_Buffer_to_PE_Ctrl_rst)
        state <= 0;
    else if(pip_buf == 3'd3) begin
        state <= choose_bank;
        line_select_bank_0 <= 1'b0;
        line_select_bank_2 <= 1'b0;
    end
    else if(row_count == (TILE_SIZE_row+1'b1) && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) begin
        case(state) // Bank_0 = 0 , Bank_1 = 1 , Bank_2 = 2
            0 : begin
                state <= Bank_1;
                line_select_bank_0 <= line_select_bank_0 + 1'b1;
            end
            1 : begin
                state <= Bank_2;
            end
            2 : begin
                state <= Bank_0;
                line_select_bank_2 <= line_select_bank_2 + 1'b1;
            end
            default : begin
                state <= state;
            end
        endcase     
    end
end

assign Bank_addr_rd_0 = ((ibuf_rd_A == 1 || ibuf_rd_B == 1) && (state == 2'b01 || state == 2'b10) && Kernel_Size == 2'b11) ? operator_tile_conter + BUFFER_ROW : operator_tile_conter;
assign Bank_addr_rd_1 = ((ibuf_rd_A == 1 || ibuf_rd_B == 1) && state == 2'b10 && Kernel_Size == 2'b11) ? operator_tile_conter + BUFFER_ROW : operator_tile_conter;
assign Bank_addr_rd_2 = operator_tile_conter;
////////////////////////////////////////////////////////////////////////////////////// Operator Counter ////////////////////////////////////////////////////////////////////////////////////// 
always@(posedge clk) begin  // counter the size 32x32
    if(Input_Buffer_to_PE_Ctrl_rst)
        On_to_PE_addr <= 1'b0;
    else if(start_buffer == 1 && Bit_serial_wait_counter == Bit_serial && On_to_PE_addr < operator_length)
            On_to_PE_addr <= On_to_PE_addr + 1'b1;
end  

always@(posedge clk) begin // Bit_serial wait
    if(Input_Buffer_to_PE_Ctrl_rst)
        Bit_serial_wait_counter <= 4'b0000;
    else if(start_buffer == 1 && Bit_serial_wait_counter >= Bit_serial && On_to_PE_addr < operator_length)
        Bit_serial_wait_counter <= 4'b0000;
    else if(start_buffer == 1 && Bit_serial_wait_counter < Bit_serial && operator_tile_conter < operator_length)
        Bit_serial_wait_counter <= Bit_serial_wait_counter + 1'b1;
end  
////////////////////////////////////////////////////////////////////////////////////// tile Counter ////////////////////////////////////////////////////////////////////////////////////// 

always@(posedge clk) begin
    if(Input_Buffer_to_PE_Ctrl_rst)
        operator_tile_conter <= 1'b0;
    else if(start_buffer && row_count == (TILE_SIZE_row+1'b1) && Kernel_Size == 2'b11 && state < 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) begin
        operator_tile_conter <= (line_select_bank_2 + bank_col) * BUFFER_ROW;
    end
    else if(start_buffer && row_count == (TILE_SIZE_row+1'b1) && Kernel_Size == 2'b11 && state == 2'b10 && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) begin
        operator_tile_conter <= (line_select_bank_0 + bank_col) * BUFFER_ROW;
    end
    else if(start_buffer &&  Bit_serial_wait_counter == Bit_serial && On_to_PE_addr < operator_length && Bit_serial == Bit_serial_wait_counter) begin
        operator_tile_conter <= operator_tile_conter + 1'b1;
    end
end

////////////////////////////////////////////////////////////////////////////////////// row Counter ////////////////////////////////////////////////////////////////////////////////////// 

always@(posedge clk) begin
    if(Input_Buffer_to_PE_Ctrl_rst)
        row_count <= 1'b0;
    else if(start_buffer && On_to_PE_addr < operator_length && row_count < (TILE_SIZE_row+1'b1) && Bit_serial == Bit_serial_wait_counter) begin
        row_count <= row_count + 1'b1;
    end
    else if(start_buffer && On_to_PE_addr < operator_length  && row_count == (TILE_SIZE_row+1'b1) && Bit_serial == Bit_serial_wait_counter) begin
        row_count <= 1'b0;
    end
end

endmodule