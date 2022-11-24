`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/11 16:25:09
// Design Name: 
// Module Name: pola_yolo_Delay_module
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


module pola_yolo_Delay_signed_module#(
        parameter delay_clock = 10,
        parameter Data_bit = 16
    )(
        input  M_AXI_ACLK,
        input  rst,
        input  over_conf_threshold,
        input  signed [Data_bit-1 : 0]input_data,
        output signed [Data_bit-1 : 0]output_data
    );

    integer i;

    reg [Data_bit-1:0] r [0:delay_clock-1];

    assign output_data = r[delay_clock-1];

    always@(posedge M_AXI_ACLK)begin
        if(rst) begin
            for(i=0;i<delay_clock;i=i+1)begin
                r[i] <= 0;
            end
        end else begin
            for(i=0;i<delay_clock-1;i=i+1)begin
                r[i+1] <= r[i];
            end
            if(over_conf_threshold)begin
                r[0] <= input_data;
            end else begin
                r[0] <= 0;
            end
        end
    end

endmodule

module pola_yolo_Delay_unsigned_module#(
        parameter delay_clock = 10,
        parameter Data_bit = 16
    )(
        input  M_AXI_ACLK,
        input  rst,
        input  over_conf_threshold,
        input  [Data_bit-1 : 0]input_data,
        output [Data_bit-1 : 0]output_data
    );

    integer i;

    reg [Data_bit-1:0] r [0:delay_clock-1];

    assign output_data = r[delay_clock-1];

    always@(posedge M_AXI_ACLK)begin
        if(rst) begin
            for(i=0;i<delay_clock;i=i+1)begin
                r[i] <= 0;
            end
        end else begin
            for(i=0;i<delay_clock-1;i=i+1)begin
                r[i+1] <= r[i];
            end
            if(over_conf_threshold)begin
                r[0] <= input_data;
            end else begin
                r[0] <= 0;
            end
        end
    end

endmodule

module pola_yolo_Delay_1bit_module#(
        parameter delay_clock = 10
    )(
        input  M_AXI_ACLK,
        input  rst,
        input  over_conf_threshold,
        input  input_data,
        output output_data
    );

    integer i;

    reg  r [0:delay_clock-1];

    assign output_data = r[delay_clock-1];

    always@(posedge M_AXI_ACLK)begin
        if(rst) begin
            for(i=0;i<delay_clock;i=i+1)begin
                r[i] <= 0;
            end
        end else begin
            for(i=0;i<delay_clock-1;i=i+1)begin
                r[i+1] <= r[i];
            end
            if(over_conf_threshold)begin
                r[0] <= input_data;
            end else begin
                r[0] <= 0;
            end
        end
    end

endmodule