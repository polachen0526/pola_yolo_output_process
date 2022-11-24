`timescale 1ns / 1ps
module lookup_table_sigmoid#(
    //WORD_SIZE version
    parameter       DATA_IWIDTH     =   6,	//64 NUM
	parameter       DATA_OWIDTH     =	16
)(
	input           [(DATA_IWIDTH)-1:0]             idata,
    output	reg	    [(DATA_OWIDTH)-1:0]             odata
);
    always @ ( * ) begin
        case ( idata )
			6'h20 : odata = 16'h024d;	//x = 000-4 : y = 0.0179862
			6'h21 : odata = 16'h029a;	//x = -3.875 : y = 0.0203324
			6'h22 : odata = 16'h02f0;	//x = -3.75 : y = 0.0229774
			6'h23 : odata = 16'h0352;	//x = -3.625 : y = 0.0259574
			6'h24 : odata = 16'h03c0;	//x = 0-3.5 : y = 0.0293122
			6'h25 : odata = 16'h043c;	//x = -3.375 : y = 0.033086
			6'h26 : odata = 16'h04c7;	//x = -3.25 : y = 0.0373269
			6'h27 : odata = 16'h0563;	//x = -3.125 : y = 0.0420877
			6'h28 : odata = 16'h0612;	//x = 000-3 : y = 0.0474259
			6'h29 : odata = 16'h06d5;	//x = -2.875 : y = 0.0534033
			6'h2a : odata = 16'h07b0;	//x = -2.75 : y = 0.0600867
			6'h2b : odata = 16'h08a5;	//x = -2.625 : y = 0.0675467
			6'h2c : odata = 16'h09b5;	//x = 0-2.5 : y = 0.0758582
			6'h2d : odata = 16'h0ae4;	//x = -2.375 : y = 0.085099
			6'h2e : odata = 16'h0c34;	//x = -2.25 : y = 0.0953495
			6'h2f : odata = 16'h0da8;	//x = -2.125 : y = 0.106691
			6'h30 : odata = 16'h0f42;	//x = 000-2 : y = 0.119203
			6'h31 : odata = 16'h1104;	//x = -1.875 : y = 0.132964
			6'h32 : odata = 16'h12f3;	//x = -1.75 : y = 0.148047
			6'h33 : odata = 16'h150e;	//x = -1.625 : y = 0.164516
			6'h34 : odata = 16'h1759;	//x = 0-1.5 : y = 0.182426
			6'h35 : odata = 16'h19d5;	//x = -1.375 : y = 0.201813
			6'h36 : odata = 16'h1c81;	//x = -1.25 : y = 0.2227
			6'h37 : odata = 16'h1f5e;	//x = -1.125 : y = 0.245085
			6'h38 : odata = 16'h226c;	//x = 000-1 : y = 0.268941
			6'h39 : odata = 16'h25a8;	//x = -0.875 : y = 0.294215
			6'h3a : odata = 16'h2910;	//x = -0.75 : y = 0.320821
			6'h3b : odata = 16'h2ca0;	//x = -0.625 : y = 0.348645
			6'h3c : odata = 16'h3053;	//x = 0-0.5 : y = 0.377541
			6'h3d : odata = 16'h3423;	//x = -0.375 : y = 0.407333
			6'h3e : odata = 16'h380a;	//x = -0.25 : y = 0.437824
			6'h3f : odata = 16'h3c01;	//x = -0.125 : y = 0.468791
			6'h00 : odata = 16'h4000;	//x = 00000 : y = 0000.5
			6'h01 : odata = 16'h43fe;	//x = 0.125 : y = 0.531209
			6'h02 : odata = 16'h47f5;	//x = 00.25 : y = 0.562177
			6'h03 : odata = 16'h4bdc;	//x = 0.375 : y = 0.592667
			6'h04 : odata = 16'h4fac;	//x = 000.5 : y = 0.622459
			6'h05 : odata = 16'h535f;	//x = 0.625 : y = 0.651355
			6'h06 : odata = 16'h56ef;	//x = 00.75 : y = 0.679179
			6'h07 : odata = 16'h5a57;	//x = 0.875 : y = 0.705785
			6'h08 : odata = 16'h5d93;	//x = 00001 : y = 0.731059
			6'h09 : odata = 16'h60a1;	//x = 1.125 : y = 0.754915
			6'h0a : odata = 16'h637e;	//x = 01.25 : y = 0.7773
			6'h0b : odata = 16'h662a;	//x = 1.375 : y = 0.798187
			6'h0c : odata = 16'h68a6;	//x = 001.5 : y = 0.817574
			6'h0d : odata = 16'h6af1;	//x = 1.625 : y = 0.835484
			6'h0e : odata = 16'h6d0c;	//x = 01.75 : y = 0.851953
			6'h0f : odata = 16'h6efb;	//x = 1.875 : y = 0.867036
			6'h10 : odata = 16'h70bd;	//x = 00002 : y = 0.880797
			6'h11 : odata = 16'h7257;	//x = 2.125 : y = 0.893309
			6'h12 : odata = 16'h73cb;	//x = 02.25 : y = 0.904651
			6'h13 : odata = 16'h751b;	//x = 2.375 : y = 0.914901
			6'h14 : odata = 16'h764a;	//x = 002.5 : y = 0.924142
			6'h15 : odata = 16'h775a;	//x = 2.625 : y = 0.932453
			6'h16 : odata = 16'h784f;	//x = 02.75 : y = 0.939913
			6'h17 : odata = 16'h792a;	//x = 2.875 : y = 0.946597
			6'h18 : odata = 16'h79ed;	//x = 00003 : y = 0.952574
			6'h19 : odata = 16'h7a9c;	//x = 3.125 : y = 0.957912
			6'h1a : odata = 16'h7b38;	//x = 03.25 : y = 0.962673
			6'h1b : odata = 16'h7bc3;	//x = 3.375 : y = 0.966914
			6'h1c : odata = 16'h7c3f;	//x = 003.5 : y = 0.970688
			6'h1d : odata = 16'h7cad;	//x = 3.625 : y = 0.974043
			6'h1e : odata = 16'h7d0f;	//x = 03.75 : y = 0.977023
			6'h1f : odata = 16'h7d65;	//x = 3.875 : y = 0.979668
            default : odata = 16'h0000;
        endcase
    end
endmodule
