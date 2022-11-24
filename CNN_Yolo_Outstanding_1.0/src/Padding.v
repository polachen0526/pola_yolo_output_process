`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/30 10:16:40
// Design Name: 
// Module Name: Padding
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

module Padding #(
    parameter TYPE_SIZE = 4,
    parameter MAX_TILE_SIZE_ADDR = 11, // 11 bits
    parameter MAX_TILE_SIZE = 34, // 40 x 40
    parameter LINE_SIZE = 6,
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
    input rst,
    input start_in,
    input [TYPE_SIZE-1'b1 : 0] type, //10 type
    input [LINE_SIZE-1:0] TILE_SIZE_row,
    input [LINE_SIZE-1:0] TILE_SIZE_col,
    input [LINE_SIZE:0] row_position,
    input [LINE_SIZE:0] col_position,
    output start,
    output reg [1:0] next_state_padding_choose_bank,
    output reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] padding_value_addr,
    output finish
    );
    
    wire [MAX_TILE_SIZE_ADDR-1'b1 : 0] type_9_last_line;
    wire [LINE_SIZE-1:0] type_9_left_pad;
    wire [LINE_SIZE-1:0] type_9_right_pad;
    reg [LINE_SIZE:0] type_bank_sel;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] padding_count;
    //reg [1:0] next_state_padding_choose_bank;
    reg [LINE_SIZE:0] state_padding_bank_col, next_state_padding_bank_col;
    reg [1:0] pip_counter;
    reg [1:0] type_9_counter;
    
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_counter;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_buf_type_0;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_buf_type_1_7;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_buf_type_2;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_buf_type_3_5;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_buf_type_6;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_buf_type_8;
    reg [MAX_TILE_SIZE_ADDR-1'b1 : 0] addr_buf_type_9;
    
    reg [LINE_SIZE : 0] addr_bank_sel_type_0_2;  
    reg [LINE_SIZE : 0] addr_bank_sel_type_1_7;
    reg [LINE_SIZE : 0] addr_bank_sel_type_3_5;
    reg [LINE_SIZE : 0] addr_bank_sel_type_6_8;
    reg [LINE_SIZE : 0] addr_bank_sel_type_9;
    
    reg start_in_buf;
    reg [1:0] finish_buf;
    
    always@(posedge clk) begin
        if(rst || finish)
            start_in_buf <= 0;
        else if(start_in)
            start_in_buf <= 1;
    end
    assign start = (finish_buf == 0 && pip_counter == 2'd2 && type != ALL_NO_PADDING && type != MIDDLE) ? 1 : 0;
    assign finish = ((finish_buf == 2'd1 && (type != ALL_NO_PADDING || type != MIDDLE)) || (start_in && (type == ALL_NO_PADDING || type == MIDDLE))) ? 1 : 0;
    
    always@(*) begin
            case(type)
                LEFT_UP,RIGHT_UP : type_bank_sel = addr_bank_sel_type_0_2;
                UP,DOWN : type_bank_sel = addr_bank_sel_type_1_7;
                LEFT,RIGHT : type_bank_sel =  addr_bank_sel_type_3_5;
                LEFT_DOWN,RIGHT_DOWN : type_bank_sel = addr_bank_sel_type_6_8;
                ALL_PADDING : type_bank_sel = addr_bank_sel_type_9;
                default: type_bank_sel = 0;
            endcase
    end
    
    always@(*) begin
        case(type_bank_sel)
             0,3,6,9,12,15,18,21,24,27,30,33 :  next_state_padding_choose_bank = 2'd0;
            1,4,7,10,13,16,19,22,25,28,31,34 :  next_state_padding_choose_bank = 2'd1;
            default :                           next_state_padding_choose_bank = 2'd2;
        endcase
    end
    
    always@(posedge clk) begin
        if(rst)
            state_padding_bank_col <= 0;
        else
            state_padding_bank_col <= next_state_padding_bank_col;
    end
    
    always@(*) begin
        case(type_bank_sel)
            0,1,2    : next_state_padding_bank_col = 7'd0;
            3,4,5    : next_state_padding_bank_col = 7'd1;
            6,7,8    : next_state_padding_bank_col = 7'd2;
            9,10,11  : next_state_padding_bank_col = 7'd3;
            12,13,14 : next_state_padding_bank_col = 7'd4;
            15,16,17 : next_state_padding_bank_col = 7'd5;
            18,19,20 : next_state_padding_bank_col = 7'd6;
            21,22,23 : next_state_padding_bank_col = 7'd7;
            24,25,26 : next_state_padding_bank_col = 7'd8;
            27,28,29 : next_state_padding_bank_col = 7'd9;
            30,31,32 : next_state_padding_bank_col = 7'd10;
            default  : next_state_padding_bank_col = 7'd11;
        endcase
    end
    
    
    always@(*) begin
        case(type)
            LEFT_UP : padding_value_addr = addr_buf_type_0;
            UP,DOWN : padding_value_addr = addr_buf_type_1_7;
            RIGHT_UP : padding_value_addr = addr_buf_type_2;
            LEFT,RIGHT : padding_value_addr = addr_buf_type_3_5;
            LEFT_DOWN : padding_value_addr = addr_buf_type_6;
            RIGHT_DOWN : padding_value_addr = addr_buf_type_8;
            ALL_PADDING : padding_value_addr = addr_buf_type_9;
            default: padding_value_addr = 0;
        endcase
    end
                           
    always@(*) begin
        if(type == LEFT_UP || type == RIGHT_UP)
            padding_count <= (TILE_SIZE_row + 2'd2) + (TILE_SIZE_col + 2'd1) - 1'd1;
        else if(type == UP || type == DOWN)
            padding_count <= (TILE_SIZE_row + 2'd2) - 1'd1;
        else if(type == LEFT || type == RIGHT)
            padding_count <= (TILE_SIZE_col + 2'd2) - 1'd1;
        else if(type == LEFT_DOWN || type == RIGHT_DOWN)
            padding_count <= (TILE_SIZE_row + 2'd1) + (TILE_SIZE_col + 2'd2) - 1'd1;
        else if(type == ALL_PADDING)
            padding_count <= 2 * (TILE_SIZE_row + 2'd2) + 2 * (TILE_SIZE_col) - 1'd1;
        else
            padding_count <= 0;
    end
    
    always@(posedge clk) begin
        if(rst)
            pip_counter <= 0;
        else if(start_in_buf && pip_counter < 2'd2)
            pip_counter <= pip_counter + 1'd1;
    end
    
    always@(posedge clk) begin
        if(rst)
            addr_counter <= 0;
        else if(start && addr_counter < padding_count)
            addr_counter <= addr_counter + 1'd1;
    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////// type 0 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    always@(posedge clk) begin       //////// padding 0 type
        if(pip_counter == 2'd1)
            addr_buf_type_0 <= row_position + state_padding_bank_col * MAX_TILE_SIZE;
        else if(start && type == LEFT_UP) begin
            if(addr_counter < TILE_SIZE_row+2'd1)
                addr_buf_type_0 <= addr_buf_type_0 + 1'd1;
            else if(addr_counter < padding_count && next_state_padding_choose_bank == 2'b10)
               addr_buf_type_0 <= row_position + (next_state_padding_bank_col+1'd1) * MAX_TILE_SIZE;
            else if(addr_counter < padding_count)
               addr_buf_type_0 <= row_position + next_state_padding_bank_col * MAX_TILE_SIZE;
        end    
    end
    
    always@(posedge clk) begin       //////// padding 0 & 2 type
        if(rst)
            addr_bank_sel_type_0_2 <= col_position;
        else if(start && (type == LEFT_UP || RIGHT_UP)) begin
           if(addr_counter < padding_count && addr_counter >= TILE_SIZE_row+2'd1)
                addr_bank_sel_type_0_2 <= addr_bank_sel_type_0_2 + 1'd1;
        end    
    end
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////// type 1 & 7  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    always@(posedge clk) begin       //////// padding 1 & 7  type
        if(pip_counter == 2'd1)
            addr_buf_type_1_7 <= row_position + state_padding_bank_col * MAX_TILE_SIZE;
        else if(start && (type == UP || type == DOWN))begin
           if(addr_counter < padding_count)
                addr_buf_type_1_7 <= addr_buf_type_1_7 + 1'd1;
        end    
    end
    
    always@(posedge clk) begin      /////// padding 1 & 7  type
        if(rst) begin
            if(type == UP)
                addr_bank_sel_type_1_7 <= col_position;
            else if(type == DOWN)
                addr_bank_sel_type_1_7 <= col_position + TILE_SIZE_col + 1'd1;
        end
    end
    
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// type 2  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
   always@(posedge clk) begin       //////// padding 2 type
        if(pip_counter == 2'd1)
            addr_buf_type_2 <= row_position + state_padding_bank_col * MAX_TILE_SIZE;
        else if(start && type == RIGHT_UP)begin
            if(addr_counter < TILE_SIZE_row+2'd1)
                addr_buf_type_2 <= addr_buf_type_2 + 1'd1;
            else if(addr_counter < padding_count && next_state_padding_choose_bank == 2'b10)
                addr_buf_type_2 <= row_position + (TILE_SIZE_row+2'd1) + (next_state_padding_bank_col+1'd1) * MAX_TILE_SIZE;
            else if(addr_counter < padding_count)
                addr_buf_type_2 <= row_position + (TILE_SIZE_row+2'd1) + next_state_padding_bank_col * MAX_TILE_SIZE;
        end    
    end 
    
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// type 3 & 5  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
   always@(posedge clk) begin       //////// padding 3 & 5  type
        if(rst)
            addr_buf_type_3_5 <= 0;
        else if(pip_counter == 2'd1 && type == LEFT) 
            addr_buf_type_3_5 <= row_position + state_padding_bank_col * MAX_TILE_SIZE;
        else if(pip_counter == 2'd1 && type == RIGHT)
            addr_buf_type_3_5 <= row_position + (TILE_SIZE_row+2'd1) + state_padding_bank_col * MAX_TILE_SIZE;
        else if(start && (type == LEFT || type == RIGHT)) begin
           if(addr_counter < padding_count && next_state_padding_choose_bank == 2'b10)
                addr_buf_type_3_5 <= addr_buf_type_3_5 + MAX_TILE_SIZE;
        end    
    end
    
    always@(posedge clk) begin       //////// padding 3 & 5 type
        if(rst)
            addr_bank_sel_type_3_5 <= col_position;
        else if(start && (type == LEFT || type == RIGHT)) begin
           if(addr_counter < padding_count)
                addr_bank_sel_type_3_5 <= addr_bank_sel_type_3_5 + 1'd1;
        end    
    end
    
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// type 6  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
    always@(posedge clk) begin       //////// padding 6 type
        if(pip_counter == 2'd1)
            addr_buf_type_6 <= row_position + state_padding_bank_col * MAX_TILE_SIZE;
        else if(start && type == LEFT_DOWN) begin
            if(addr_counter < TILE_SIZE_col+2'd1 && next_state_padding_choose_bank == 2'b10)
                addr_buf_type_6 <= row_position + (next_state_padding_bank_col+1'd1) * MAX_TILE_SIZE;
            else if(addr_counter < TILE_SIZE_col+2'd1)
                addr_buf_type_6 <= row_position + next_state_padding_bank_col * MAX_TILE_SIZE;
            else if(addr_counter < padding_count)
                addr_buf_type_6 <= addr_buf_type_6 + 1'd1;
        end    
    end
    
    always@(posedge clk) begin       //////// padding 6 & 8 type
        if(rst)
            addr_bank_sel_type_6_8 <= col_position;
        else if(start && (type == LEFT_DOWN || RIGHT_DOWN)) begin
           if(addr_counter < TILE_SIZE_col+2'd1)
                addr_bank_sel_type_6_8 <= addr_bank_sel_type_6_8 + 1'd1;
        end    
    end

 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// type 8  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    always@(posedge clk) begin       //////// padding 8 type
        if(pip_counter == 2'd1)
            addr_buf_type_8 <= row_position + (TILE_SIZE_row+2'd1) + state_padding_bank_col * MAX_TILE_SIZE;
        else if(start && type == RIGHT_DOWN)begin
            if(addr_counter < TILE_SIZE_col && next_state_padding_choose_bank == 2'b10)
                addr_buf_type_8 <= row_position + (TILE_SIZE_row+2'd1) + (next_state_padding_bank_col+1'd1) * MAX_TILE_SIZE;
            else if(addr_counter < TILE_SIZE_col)
                addr_buf_type_8 <= row_position + (TILE_SIZE_row+2'd1) + next_state_padding_bank_col * MAX_TILE_SIZE;
            else if(addr_counter == TILE_SIZE_col && next_state_padding_choose_bank == 2'b10)
                addr_buf_type_8 <= row_position + (next_state_padding_bank_col+1'd1) * MAX_TILE_SIZE;
            else if(addr_counter == TILE_SIZE_col)
                addr_buf_type_8 <= row_position + next_state_padding_bank_col * MAX_TILE_SIZE;
            else if(addr_counter < padding_count)
                addr_buf_type_8 <= addr_buf_type_8 + 1'd1;
        end    
    end

 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// type 8  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
 
    assign type_9_last_line = (TILE_SIZE_row + 2'd2) + (TILE_SIZE_col*2);
    assign type_9_left_pad  = MAX_TILE_SIZE - (TILE_SIZE_row + 1'd1);
    assign type_9_right_pad = (TILE_SIZE_row + 1'd1);
    
    always@(posedge clk) begin       //////// padding 9 type
        if(pip_counter == 2'd1)
            addr_buf_type_9 <= row_position + state_padding_bank_col * MAX_TILE_SIZE;
        else if(start && type == ALL_PADDING)begin
            if(addr_counter < TILE_SIZE_row+2'd1)
                addr_buf_type_9 <= addr_buf_type_9 + 1'd1;

            else if(addr_counter == TILE_SIZE_row+2'd1) begin
                if(next_state_padding_choose_bank == 2'b10)
                    addr_buf_type_9 <= row_position + (next_state_padding_bank_col+1'd1) * MAX_TILE_SIZE;
                else
                    addr_buf_type_9 <= row_position + next_state_padding_bank_col * MAX_TILE_SIZE; 
            end
            
            else if(addr_counter < padding_count && addr_counter >= type_9_last_line)
                addr_buf_type_9 <= addr_buf_type_9 + 1'd1;
                
            else if(type_9_counter == 2'd1 && addr_counter < type_9_last_line)
                addr_buf_type_9 <= addr_buf_type_9 + (TILE_SIZE_row + 1'd1);
                
            else if(type_9_counter == 2'd0 && addr_counter < type_9_last_line)
                if(next_state_padding_choose_bank == 2'b10)
                    addr_buf_type_9 <= row_position + (next_state_padding_bank_col+1'd1) * MAX_TILE_SIZE;
                else
                    addr_buf_type_9 <= row_position + next_state_padding_bank_col * MAX_TILE_SIZE;     
        end    
    end
    
    always@(posedge clk) begin       //////// padding 9 type
        if(rst)
            addr_bank_sel_type_9 <= col_position;
        else if(start && type == ALL_PADDING) begin
           if(addr_counter < type_9_last_line && addr_counter >= TILE_SIZE_row+2'd1 && type_9_counter == 2'd0)
                addr_bank_sel_type_9 <= addr_bank_sel_type_9 + 1'd1;
        end    
    end
    
    always@(posedge clk) begin
        if(rst || type_9_counter == 1'd1)
            type_9_counter <= 2'd0;
        else if(start && type == ALL_PADDING && addr_counter >= (TILE_SIZE_row+2'd1) && addr_counter < type_9_last_line)
            type_9_counter <= 2'd1;
    end
    
    
    
    always@(posedge clk) begin
        if(rst)
            finish_buf <= 0;
        else if(type == ALL_NO_PADDING || type == MIDDLE)
            finish_buf <= finish_buf;
        else if(addr_counter == padding_count && finish_buf < 2'd2)
            finish_buf <= finish_buf + 1'd1;
    end
    
endmodule
