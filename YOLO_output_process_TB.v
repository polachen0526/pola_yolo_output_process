`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/08/20 12:36:01
// Design Name: 
// Module Name: YOLO_output_process_TB
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

`define period 10.0
`include "settings.svh"
`include "File.sv"
`include "DRAM_Slave.sv"

module YOLO_output_process_TB;
    parameter C_S_AXI_DATA_WIDTH = 32;
    parameter C_M_AXI_DATA_WIDTH = 128;
    parameter DATA_WIDTH = 2;// DATA_WIDTH_OFFSET
    integer addr_tmp;
    integer weight_addr;
    logic                               S_AXI_ACLK = 1;
    logic                               S_AXI_ARESETN;
    logic                               IRQ;

    logic                               s_axi_start;
    logic                               s_axi_inst_valid;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_inst_0;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_inst_1;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_inst_2;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_inst_3;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_inst_4;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_inst_5;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_inst_number;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_error;            //Trigger IRQ if error
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_Rerror_addr;
    logic  [0:0]                        s_axi_Rerror;
    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_Werror_addr;
    logic  [1:0]                        s_axi_Werror;

    logic  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_dram_addr_inst;   //Instruction
    logic  [C_S_AXI_DATA_WIDTH-1:0]		s_axi_leaky_factor;
    
    logic  [C_S_AXI_DATA_WIDTH-1:0]    s_axi_img_size;     ////////
    logic  [C_S_AXI_DATA_WIDTH-1:0]    s_axi_dram_raddr;   ///////

    integer addr_test;
    string filename, num;
    //Interface declaration
    AXI_FULL axi_if (S_AXI_ACLK, S_AXI_ARESETN);

    DUT_wrapper u_DUT(
       //S_AXI-Lite
       .S_AXI_ACLK             (S_AXI_ACLK),
       .S_AXI_ARESETN          (S_AXI_ARESETN),
       .IRQ                    (IRQ),
       .s_axi_inst_0           (s_axi_inst_0),
       .s_axi_inst_1           (s_axi_inst_1),
       .s_axi_inst_2           (s_axi_inst_2),
       .s_axi_inst_3           (s_axi_inst_3),
       .s_axi_inst_4           (s_axi_inst_4),
       .s_axi_inst_5           (s_axi_inst_5),
       .s_axi_start(s_axi_start),
   
       .s_axi_Rerror(s_axi_Rerror),            //Trigger IRQ if error
       .s_axi_Rerror_addr(s_axi_Rerror_addr),
       .s_axi_Werror(s_axi_Werror),            //Trigger IRQ if error
       .s_axi_Werror_addr(s_axi_Werror_addr),
       
       .mif                    (axi_if)
    );

    DRAM DRAM = new(axi_if);
    File File = new;
    
    default clocking cb@(posedge S_AXI_ACLK);
    endclocking

    always #(`period / 2.0) S_AXI_ACLK <= ~S_AXI_ACLK;

    always@(cb) begin
            /*DRAM.b_handle();
            DRAM.w_handle();
            DRAM.r_handle_seq();
            //Must used r_handle_comb at bottom?
            DRAM.r_handle_comb();*/
            
            DRAM.ar_handle();
            DRAM.aw_handle(); 
    end

    initial begin
        @(cb)    
        File.load_feature(32'h0023ec00 , "C:/Users/polapc/Desktop/YOLO_data_process/",8,24,8,1,"Layer10", DRAM);//Fix it Inst addr
        File.load_feature(32'h0027dc00 , "C:/Users/polapc/Desktop/YOLO_data_process/",8,24,16,1,"Layer13", DRAM);//Fix it Inst addr
        //File.load_feature(32'h0023ec00 , "C:/Users/polapc/Desktop/YOLO_data_process/",8,24,8,1,"pola_hw_layer_0", DRAM);//Fix it Inst addr
        //File.load_feature(32'h0027dc00 , "C:/Users/polapc/Desktop/YOLO_data_process/",8,24,16,1,"pola_hw_layer_1", DRAM);//Fix it Inst addr
        File.load_feature(32'h00280c00 , "C:/Users/polapc/Desktop/YOLO_data_process/",8,8,256,1,"pola_hw_type_org_image",DRAM);
        @(cb)
        
        S_AXI_ARESETN        = 1'b0;

        s_axi_start          = {C_S_AXI_DATA_WIDTH{1'b0}};
        s_axi_dram_addr_inst = 32'h0100_0000;
        s_axi_leaky_factor   = 32'h000000_0d;

        @(cb)
        S_AXI_ARESETN = 1;

        @(cb)
        for(int loop=0; loop<1; loop=loop+1) begin
            #10
            s_axi_start          = {C_S_AXI_DATA_WIDTH{1'b0}};
            {s_axi_inst_5, s_axi_inst_4, s_axi_inst_3,s_axi_inst_2,s_axi_inst_1,s_axi_inst_0} = 192'h00380c00_00280c00_FE52FCA4_030000c0_0027dc00_0023ec00;
            #10
            s_axi_start         = 32'd1;
            wait(IRQ);
            s_axi_start         = 32'd0;
        end
        @(cb)
        /*for(int test_count = 0; test_count < 1 ; test_count+=1)begin
            addr_test = 32'h00080000 + 224*224*8*test_count;
            #10
            File.store_mem(addr_test, 224, 1, test_count, 224*224, 1.0, "Yolo_Output_Process_Layer1", DRAM);
            
        end*/
        ##100 $stop;
    end
endmodule
