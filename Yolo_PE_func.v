module fpga_linear_sigmoid_func_layer_0(
        parameter data_bit = 16
    )(
        input               M_AXI_ACLK,
        input  signed       [data_bit-1:0] input_data, 
        output reg  signed  [data_bit-1:0] output_alpha,
        output reg  signed  [data-bit-1:0] output_bias
    );
    
    always@(posedge M_AXI_ACLK)begin
        if(input_data<16'hE000)begin
            output_alpha <= 0;
            output_bias  <= 0;
        end else if(input_data>16'hE000 && input_data<=16'hEE00)begin
            output_alpha <= 16'h0050;
            output_bias  <= 16'h0012;
        end else if(input_data>16'hEE00 && input_data<=16'hF400)begin
            output_alpha <= 16'h0317;
            output_bias  <= 16'h0076;
        end else if(input_data>16'hF400 && input_data<=16'hF600)begin
            output_alpha <= 16'h082D;
            output_bias  <= 16'h00F0;
        end else if(input_data>16'hF600 && input_data<=16'hF800)begin
            output_alpha <= 16'h0AA2;
            output_bias  <= 16'h0122;
        end else if(input_data>16'hF800 && input_data<=16'hFA00)begin
            output_alpha <= 16'h107F;
            output_bias  <= 16'h017F;
        end else if(input_data>16'hFA00 && input_data<=16'hFC00)begin
            output_alpha <= 16'h14ED;
            output_bias  <= 16'h01B5;
        end else if(input_data>16'hFC00 && input_data<=16'h0400)begin
            output_alpha <= 16'h1E4D;
            output_bias  <= 16'h0200;
        end else if(input_data>16'h0400 && input_data<=16'h0600)begin
            output_alpha <= 16'h14ED;
            output_bias  <= 16'h024A;
        end else if(input_data>16'h0600 && input_data<=16'h0800)begin
            output_alpha <= 16'h107F;
            output_bias  <= 16'h0280;
        end else if(input_data>16'h0800 && input_data<=16'h0A00)begin
            output_alpha <= 16'h0AA2;
            output_bias  <= 16'h02DD;
        end else if(input_data>16'h0A00 && input_data<=16'h0C00)begin
            output_alpha <= 16'h082D;
            output_bias  <= 16'h030F;
        end else if(input_data>16'h0C00 && input_data<=16'h1200)begin
            output_alpha <= 16'h0317;
            output_bias  <= 16'h0389;
        end else if(input_data>16'h1200 && input_data<=16'h2000)begin
            output_alpha <= 16'h0050;
            output_bias  <= 16'h03ED;
        end else if(input_data>16'h2000)begin
            output_alpha <= 0;
            output_bias  <= 0;
        end
    end
endmodule

module fpga_linear_sigmoid_func_layer_1(
        parameter data_bit = 16
    )(
        input               M_AXI_ACLK,
        input  signed       [data_bit-1:0] input_data, 
        output reg  signed  [data_bit-1:0] output_alpha,
        output reg  signed  [data-bit-1:0] output_bias
    );
    
    always@(posedge M_AXI_ACLK)begin
        if(input_data<16'hF000)begin
            output_alpha <= 0;
            output_bias  <= 0;
        end else if(input_data>16'hF000 && input_data<=16'hF700)begin
            output_alpha <= 16'h0050;
            output_bias  <= 16'h0009;
        end else if(input_data>16'hF700 && input_data<=16'hFA00)begin
            output_alpha <= 16'h0317;
            output_bias  <= 16'h003B;
        end else if(input_data>16'hFA00 && input_data<=16'hFB00)begin
            output_alpha <= 16'h082D;
            output_bias  <= 16'h0078;
        end else if(input_data>16'hFB00 && input_data<=16'hFC00)begin
            output_alpha <= 16'h0AA2;
            output_bias  <= 16'h0091;
        end else if(input_data>16'hFC00 && input_data<=16'hFD00)begin
            output_alpha <= 16'h107F;
            output_bias  <= 16'h00BF;
        end else if(input_data>16'hFD00 && input_data<=16'hFE00)begin
            output_alpha <= 16'h14ED;
            output_bias  <= 16'h00DA;
        end else if(input_data>16'hFE00 && input_data<=16'h0200)begin
            output_alpha <= 16'h1E4D;
            output_bias  <= 16'h0100;
        end else if(input_data>16'h0200 && input_data<=16'h0300)begin
            output_alpha <= 16'h14ED;
            output_bias  <= 16'h0125;
        end else if(input_data>16'h0300 && input_data<=16'h0400)begin
            output_alpha <= 16'h107F;
            output_bias  <= 16'h0140;
        end else if(input_data>16'h0400 && input_data<=16'h0500)begin
            output_alpha <= 16'h0AA2;
            output_bias  <= 16'h016E;
        end else if(input_data>16'h0500 && input_data<=16'h0600)begin
            output_alpha <= 16'h082D;
            output_bias  <= 16'h0187;
        end else if(input_data>16'h0600 && input_data<=16'h0900)begin
            output_alpha <= 16'h0317;
            output_bias  <= 16'h01C4;
        end else if(input_data>16'h0900 && input_data<=16'h1000)begin
            output_alpha <= 16'h0050;
            output_bias  <= 16'h01F6;
        end else if(input_data>16'h1000)begin
            output_alpha <= 0;
            output_bias  <= 0;
        end
    end
endmodule


module fpga_exp_lookuptable_func_layer_0(
    parameter data_bit = 16
)(
    input   M_AXI_ACLK,
    input   signed [data_bit-1:0] input_data,
    output  reg  signed  [data_bit-1:0] output_alpha,
    output  reg  signed  [data-bit-1:0] output_bias
);

    wire signed [data_bit-1:0]output_alpga_wire;
    wire signed [data_bit-1:0]output_bias_wire;
    wire signed [data_bit-1:0]output_bias_find;

    exp_bias_choose_func_layer_0 exp_layer_0(
        .input_data(output_bias_find),
        .output_data(output_bias_wire)
    );

    always@(posedge M_AXI_ACLK)begin
        if(rst)begin
            output_alpha    <= 0;
            output_bias     <= 0;
        end else begin
            output_alpha    <= output_alpga_wire;
            output_bias     <= output_bias_wire;
        end
    end

    //----------------------output alpha--------------------------
    always@(*)begin
        //-------------------range(-1 , -0.875)()--------------------
        //-------------------range(-0 ,  0.125)()--------------------
        //-------------------range(-2 , -1.875)--------------------
        //-------------------range( 1 ,  1.125)()--------------------
        //1.(not exp value 1.125 , 0x480 , exp value 3.080217 0xC52)
        //2.(not exp value 1     , 0x400 , exp value 2.718282 0xADF)
        //output_alpha_wire = exp value
        //output_bias_wire  = normal_value - range normal value
        if(input_data > 16'h0480)begin
            output_alpha_wire = 16'h0C52;
            output_bias_find  = input_data - 16'h0480;
        end else if(input_data > 16'h0470 && input_data <= 16'h0480)begin
            output_alpha_wire = 16'h0C39;
            output_bias_find  = input_data - 16'h0470;
        end else if(input_data > 16'h0460 && input_data <= 16'h0470)begin
            output_alpha_wire = 16'h0C09;
            output_bias_find  = input_data - 16'h0460;
        end else if(input_data > 16'h0450 && input_data <= 16'h0460)begin
            output_alpha_wire = 16'h0BD9;
            output_bias_find  = input_data - 16'h0450; 
        end else if(input_data > 16'h0440 && input_data <= 16'h0450)begin
            output_alpha_wire = 16'h0BAA;
            output_bias_find  = input_data - 16'h0440; 
        end else if(input_data > 16'h0430 && input_data <= 16'h0440)begin
            output_alpha_wire = 16'h0B7B;
            output_bias_find  = input_data - 16'h0430; 
        end else if(input_data > 16'h0420 && input_data <= 16'h0430)begin
            output_alpha_wire = 16'h0B4E;
            output_bias_find  = input_data - 16'h0420; 
        end else if(input_data > 16'h0410 && input_data <= 16'h0420)begin
            output_alpha_wire = 16'h0B21;
            output_bias_find  = input_data - 16'h0410; 
        end else if(input_data > 16'h0400 && input_data <= 16'h0410)begin
            output_alpha_wire = 16'h0AF5;
            output_bias_find  = input_data - 16'h0400; 
        end else if(input_data > 16'h0080 && input_data <= 16'h0400)begin //next range(1 -> 0.125)
            output_alpha_wire = 16'h0488;
            output_bias_find  = input_data - 16'h0080; 
        end else if(input_data > 16'h0070 && input_data <= 16'h0080)begin
            output_alpha_wire = 16'h047F;
            output_bias_find  = input_data - 16'h0070;
        end else if(input_data > 16'h0060 && input_data <= 16'h0070)begin
            output_alpha_wire = 16'h046D;
            output_bias_find  = input_data - 16'h0060;
        end else if(input_data > 16'h0050 && input_data <= 16'h0060)begin
            output_alpha_wire = 16'h045B;
            output_bias_find  = input_data - 16'h0050;
        end else if(input_data > 16'h0040 && input_data <= 16'h0050)begin
            output_alpha_wire = 16'h044A;
            output_bias_find  = input_data - 16'h0040;
        end else if(input_data > 16'h0030 && input_data <= 16'h0040)begin
            output_alpha_wire = 16'h0439;
            output_bias_find  = input_data - 16'h0030;
        end else if(input_data > 16'h0020 && input_data <= 16'h0030)begin
            output_alpha_wire = 16'h0428;
            output_bias_find  = input_data - 16'h0020;
        end else if(input_data > 16'h0010 && input_data <= 16'h0020)begin
            output_alpha_wire = 16'h0408;
            output_bias_find  = input_data - 16'h0010;
        end else if(input_data > 16'h0000 && input_data <= 16'h0010)begin
            output_alpha_wire = 16'h0400;
            output_bias_find  = input_data - 16'h0000;
        end else if(input_data > 16'hFC80 && input_data <= 16'h0000)begin //next range(0 -> -0.875)
            output_alpha_wire = 16'h01AA;
            output_bias_find  = input_data - 16'hFC80;
        end else if(input_data > 16'hFC70 && input_data <= 16'hFC80)begin
            output_alpha_wire = 16'h01A7;
            output_bias_find  = input_data - 16'hFC70;
        end else if(input_data > 16'hFC60 && input_data <= 16'hFC70)begin
            output_alpha_wire = 16'h01A0;
            output_bias_find  = input_data - 16'hFC60;
        end else if(input_data > 16'hFC50 && input_data <= 16'hFC60)begin
            output_alpha_wire = 16'h019A;
            output_bias_find  = input_data - 16'hFC50;
        end else if(input_data > 16'hFC40 && input_data <= 16'hFC50)begin
            output_alpha_wire = 16'h0194;
            output_bias_find  = input_data - 16'hFC40;
        end else if(input_data > 16'hFC30 && input_data <= 16'hFC40)begin
            output_alpha_wire = 16'h018D;
            output_bias_find  = input_data - 16'hFC30;
        end else if(input_data > 16'hFC20 && input_data <= 16'hFC30)begin
            output_alpha_wire = 16'h0187;
            output_bias_find  = input_data - 16'hFC20;
        end else if(input_data > 16'hFC10 && input_data <= 16'hFC20)begin
            output_alpha_wire = 16'h0181;
            output_bias_find  = input_data - 16'hFC10;
        end else if(input_data > 16'hFC00 && input_data <= 16'hFC10)begin
            output_alpha_wire = 16'h017B;
            output_bias_find  = input_data - 16'hFC00;
        end else if(input_data > 16'hF880 && input_data <= 16'hFC00)begin//next range(-1 -> -1.875)
            output_alpha_wire = 16'h009D;
            output_bias_find  = input_data - 16'hF880;
        end else if(input_data > 16'hF870 && input_data <= 16'hF880)begin
            output_alpha_wire = 16'h009B;
            output_bias_find  = input_data - 16'hF870;
        end else if(input_data > 16'hF860 && input_data <= 16'hF870)begin
            output_alpha_wire = 16'h0099;
            output_bias_find  = input_data - 16'hF860;
        end else if(input_data > 16'hF850 && input_data <= 16'hF860)begin
            output_alpha_wire = 16'h0097;
            output_bias_find  = input_data - 16'hF850;
        end else if(input_data > 16'hF840 && input_data <= 16'hF850)begin
            output_alpha_wire = 16'h0094;
            output_bias_find  = input_data - 16'hF840;
        end else if(input_data > 16'hF830 && input_data <= 16'hF840)begin
            output_alpha_wire = 16'h0092;
            output_bias_find  = input_data - 16'hF830;
        end else if(input_data > 16'hF820 && input_data <= 16'hF830)begin
            output_alpha_wire = 16'h0090;
            output_bias_find  = input_data - 16'hF820;
        end else if(input_data > 16'hF810 && input_data <= 16'hF820)begin
            output_alpha_wire = 16'h008D;
            output_bias_find  = input_data - 16'hF810;
        end else if(input_data > 16'hF800 && input_data <= 16'hF810)begin
            output_alpha_wire = 16'h008B;
            output_bias_find  = input_data - 16'hF800;
        end else if(input_data <= 16'hF800)begin
            output_alpha_wire = 16'h008A;
            output_bias_find  = 16'h0000;
        end else begin
            output_alpha_wire = 16'h0000;
            output_bias_find  = 16'h0000;
        end
    end
endmodule

module exp_bias_choose_func_layer_0#(
        parameter data_bit = 16
    )(
        input   signed [data_bit-1:0] input_data,
        output  signed [data_bit-1:0] output_data
    );
    always@(*)begin
        if(input_data>16'h0340)begin
            output_data = 16'h0998;
        end else if(input_data>16'h02C0 && input_data<=16'h0340)begin
            output_data = 16'h0877;
        end else if(input_data>16'h0240 && input_data<=16'h02C0)begin
            output_data = 16'h0779;
        end else if(input_data>16'h01c0 && input_data<=16'h0240)begin
            output_data = 16'h0698;
        end else if(input_data>16'h0140 && input_data<=16'h01c0)begin
            output_data = 16'h05D1;
        end else if(input_data>16'h00C0 && input_data<=16'h0140)begin
            output_data = 16'h0522;
        end else if(input_data>16'h0040 && input_data<=16'h00C0)begin
            output_data = 16'h0488;
        end else if(input_data<=16'h0040)begin
            output_data = 16'h400;
        end else begin
            output_data = 16'hxxxx;
        end
    end
endmodule

module fpga_exp_lookuptable_func_layer_1(
    parameter data_bit = 16
)(
    input   M_AXI_ACLK,
    input   signed [data_bit-1:0] input_data,
    output  reg  signed  [data_bit-1:0] output_alpha,
    output  reg  signed  [data-bit-1:0] output_bias
);

    wire signed [data_bit-1:0]output_alpga_wire;
    wire signed [data_bit-1:0]output_bias_wire;
    wire signed [data_bit-1:0]output_bias_find;

    exp_bias_choose_func_layer_1 exp_layer_1(
        .input_data(output_bias_find),
        .output_data(output_bias_wire)
    );

    always@(posedge M_AXI_ACLK)begin
        if(rst)begin
            output_alpha    <= 0;
            output_bias     <= 0;
        end else begin
            output_alpha    <= output_alpga_wire;
            output_bias     <= output_bias_wire;
        end
    end

    //----------------------output alpha--------------------------
    always@(*)begin
        //-------------------range(-1 , -0.875)()--------------------
        //-------------------range(-0 ,  0.125)()--------------------
        //-------------------range(-2 , -1.875)--------------------
        //-------------------range( 1 ,  1.125)()--------------------
        //1.(not exp value 1.125 , 0x480 , exp value 3.080217 0xC52)
        //2.(not exp value 1     , 0x400 , exp value 2.718282 0xADF)
        //output_alpha_wire = exp value
        //output_bias_wire  = normal_value - range normal value
        if(input_data > 16'h0240)begin
            output_alpha_wire = 16'h0629;
            output_bias_find  = input_data - 16'h0240;
        end else if(input_data > 16'h0238 && input_data <= 16'h0240)begin
            output_alpha_wire = 16'h061C;
            output_bias_find  = input_data - 16'h0238;
        end else if(input_data > 16'h0230 && input_data <= 16'h0238)begin
            output_alpha_wire = 16'h0604;
            output_bias_find  = input_data - 16'h0230;
        end else if(input_data > 16'h0228 && input_data <= 16'h0230)begin
            output_alpha_wire = 16'h05EC;
            output_bias_find  = input_data - 16'h0228; 
        end else if(input_data > 16'h0220 && input_data <= 16'h0228)begin
            output_alpha_wire = 16'h05D5;
            output_bias_find  = input_data - 16'h0220; 
        end else if(input_data > 16'h0218 && input_data <= 16'h0220)begin
            output_alpha_wire = 16'h05BD;
            output_bias_find  = input_data - 16'h0218; 
        end else if(input_data > 16'h0210 && input_data <= 16'h0218)begin
            output_alpha_wire = 16'h05A7;
            output_bias_find  = input_data - 16'h0210; 
        end else if(input_data > 16'h0208 && input_data <= 16'h0210)begin
            output_alpha_wire = 16'h0590;
            output_bias_find  = input_data - 16'h0208; 
        end else if(input_data > 16'h0200 && input_data <= 16'h0208)begin
            output_alpha_wire = 16'h057A;
            output_bias_find  = input_data - 16'h0200; 
        end else if(input_data > 16'h0040 && input_data <= 16'h0200)begin //next range(1 -> 0.125)
            output_alpha_wire = 16'h0244;
            output_bias_find  = input_data - 16'h0040; 
        end else if(input_data > 16'h0038 && input_data <= 16'h0040)begin
            output_alpha_wire = 16'h023F;
            output_bias_find  = input_data - 16'h0038;
        end else if(input_data > 16'h0030 && input_data <= 16'h0038)begin
            output_alpha_wire = 16'h0236;
            output_bias_find  = input_data - 16'h0030;
        end else if(input_data > 16'h0028 && input_data <= 16'h0030)begin
            output_alpha_wire = 16'h022D;
            output_bias_find  = input_data - 16'h0028;
        end else if(input_data > 16'h0020 && input_data <= 16'h0028)begin
            output_alpha_wire = 16'h0225;
            output_bias_find  = input_data - 16'h0020;
        end else if(input_data > 16'h0018 && input_data <= 16'h0020)begin
            output_alpha_wire = 16'h021C;
            output_bias_find  = input_data - 16'h0018;
        end else if(input_data > 16'h0010 && input_data <= 16'h0018)begin
            output_alpha_wire = 16'h0214;
            output_bias_find  = input_data - 16'h0010;
        end else if(input_data > 16'h0008 && input_data <= 16'h0010)begin
            output_alpha_wire = 16'h0204;
            output_bias_find  = input_data - 16'h0008;
        end else if(input_data > 16'h0000 && input_data <= 16'h0008)begin
            output_alpha_wire = 16'h0200;
            output_bias_find  = input_data - 16'h0000;
        end else if(input_data > 16'hFE40 && input_data <= 16'h0000)begin //next range(0 -> -0.875)
            output_alpha_wire = 16'h0D5;
            output_bias_find  = input_data - 16'hFE40;
        end else if(input_data > 16'hFE38 && input_data <= 16'hFE40)begin
            output_alpha_wire = 16'h00D3;
            output_bias_find  = input_data - 16'hFE38;
        end else if(input_data > 16'hFE30 && input_data <= 16'hFE38)begin
            output_alpha_wire = 16'h00D0;
            output_bias_find  = input_data - 16'hFE30;
        end else if(input_data > 16'hFE28 && input_data <= 16'hFE30)begin
            output_alpha_wire = 16'h00CD;
            output_bias_find  = input_data - 16'hFE28;
        end else if(input_data > 16'hFE20 && input_data <= 16'hFE28)begin
            output_alpha_wire = 16'h00CA;
            output_bias_find  = input_data - 16'hFE20;
        end else if(input_data > 16'hFE18 && input_data <= 16'hFE20)begin
            output_alpha_wire = 16'h00C6;
            output_bias_find  = input_data - 16'hFE18;
        end else if(input_data > 16'hFE10 && input_data <= 16'hFE18)begin
            output_alpha_wire = 16'h00C3;
            output_bias_find  = input_data - 16'hFE10;
        end else if(input_data > 16'hFE08 && input_data <= 16'hFE10)begin
            output_alpha_wire = 16'h00C0;
            output_bias_find  = input_data - 16'hFE08;
        end else if(input_data > 16'hFE00 && input_data <= 16'hFE08)begin
            output_alpha_wire = 16'h00BD;
            output_bias_find  = input_data - 16'hFE00;
        end else if(input_data > 16'hFC40 && input_data <= 16'hFE00)begin//next range(-1 -> -1.875)
            output_alpha_wire = 16'h004E;
            output_bias_find  = input_data - 16'hFC40;
        end else if(input_data > 16'hFC38 && input_data <= 16'hFC40)begin
            output_alpha_wire = 16'h004D;
            output_bias_find  = input_data - 16'hFC38;
        end else if(input_data > 16'hFC30 && input_data <= 16'hFC38)begin
            output_alpha_wire = 16'h004C;
            output_bias_find  = input_data - 16'hFC30;
        end else if(input_data > 16'hFC28 && input_data <= 16'hFC30)begin
            output_alpha_wire = 16'h004B;
            output_bias_find  = input_data - 16'hFC28;
        end else if(input_data > 16'hFC20 && input_data <= 16'hFC28)begin
            output_alpha_wire = 16'h004A;
            output_bias_find  = input_data - 16'hFC20;
        end else if(input_data > 16'hFC18 && input_data <= 16'hFC20)begin
            output_alpha_wire = 16'h0049;
            output_bias_find  = input_data - 16'hFC18;
        end else if(input_data > 16'hFC10 && input_data <= 16'hFC18)begin
            output_alpha_wire = 16'h0048;
            output_bias_find  = input_data - 16'hFC10;
        end else if(input_data > 16'hFC08 && input_data <= 16'hFC10)begin
            output_alpha_wire = 16'h0046;
            output_bias_find  = input_data - 16'hFC08;
        end else if(input_data > 16'hFC00 && input_data <= 16'hFC08)begin
            output_alpha_wire = 16'h0045;
            output_bias_find  = input_data - 16'hFC00;
        end else if(input_data <= 16'hFC00)begin
            output_alpha_wire = 16'h0045;
            output_bias_find  = 16'h0000;
        end else begin
            output_alpha_wire = 16'h0000;
            output_bias_find  = 16'h0000;
        end
    end
endmodule

module exp_bias_choose_func_layer_1#(
        parameter data_bit = 16
    )(
        input   signed [data_bit-1:0] input_data,
        output  signed [data_bit-1:0] output_data
    );
    always@(*)begin
        if(input_data>16'h01A0)begin
            output_data = 16'h04CC;
        end else if(input_data>16'h0160 && input_data<=16'h01A0)begin
            output_data = 16'h043B;
        end else if(input_data>16'h0120 && input_data<=16'h0160)begin
            output_data = 16'h03BC;
        end else if(input_data>16'h00E0 && input_data<=16'h0120)begin
            output_data = 16'h034C;
        end else if(input_data>16'h00A0 && input_data<=16'h00E0)begin
            output_data = 16'h02E8;
        end else if(input_data>16'h0060 && input_data<=16'h00A0)begin
            output_data = 16'h0291;
        end else if(input_data>16'h0020 && input_data<=16'h0060)begin
            output_data = 16'h0244;
        end else if(input_data<=16'h0020)begin
            output_data = 16'h200;
        end else begin
            output_data = 16'hxxxx;
        end
    end
endmodule

module process_mul_element#(
        parameter data_bit = 16,
        parameter data_shift = 15
    )(
        input               rst,
        input               M_AXI_ACLK,
        input               PE_SHIFT_EN,
        input   signed      [data_bit-1:0] input_data, 
        input   signed      [data_bit-1:0] input_alpha,
        output  reg   signed[data_bit-1:0] output_data
    );

        reg     signed      [15:0]MUL_answer;
        
        always@(posedge M_AXI_ACLK)begin
            if(rst)begin
                MUL_answer <= 0;
            end else if(PE_SHIFT_EN)begin
                MUL_answer <= (input_alpha * input_bias)>>data_shift;
            end else if(!PE_SHIFT_EN)begin
                MUL_answer <= (input_alpha * input_bias)
            end else begin
                MUL_answer <= MUL_answer;
            end
        end
endmodule

module process_add_element#(
        parameter data_bit = 16,
        parameter data_shift = 15
    )(
        input               rst,
        input               M_AXI_ACLK,
        input   signed      [data_bit-1:0] input_data, 
        input   signed      [data_bit-1:0] input_bias,
        output  reg   signed[data_bit-1:0] output_data
    );
        always@(posedge M_AXI_ACLK)begin
            output_data <= (input_data + input_bias)>>1;
        end
endmodule
