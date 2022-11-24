//////////////////////////////////////////////////////////////////////////////////
`define VIVADO_MODE
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/22 15:20:21
// Design Name: 
// Module Name: Input_Buffer_A
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

module Input_Buffer #(
    parameter WORD_SIZE = 16,
    parameter OFF_TO_ON_ADDRESS_SIZE = 13,
    parameter SRAM_ADDRESS_SIZE = 9
    )(
    input clk,
    input rst,
    input [SRAM_ADDRESS_SIZE-1:0] Bank_addr_0,
    input [SRAM_ADDRESS_SIZE-1:0] Bank_addr_1,
    input [SRAM_ADDRESS_SIZE-1:0] Bank_addr_2,
    input wr,
    input [WORD_SIZE-1:0] data,
    input [1:0] ibuf_iaddr_bank_sel,
    input rd,
    output wire [WORD_SIZE-1:0] q_Bank_0,
    output wire [WORD_SIZE-1:0] q_Bank_1,
    output wire [WORD_SIZE-1:0] q_Bank_2
    );

reg [2:0] wr_sel;
`ifdef VIVADO_MODE
 Singal_Port_Memory_34x12 Bank_0(
  .clka(clk),
  .wea(wr_sel[0]),
  .addra(Bank_addr_0),
  .dina(data),
  .douta(q_Bank_0)
);

 Singal_Port_Memory_34x12 Bank_1(
  .clka(clk),
  .wea(wr_sel[1]),
  .addra(Bank_addr_1),
  .dina(data),
  .douta(q_Bank_1)
);

 Singal_Port_Memory_34x12 Bank_2(
  .clka(clk),
  .wea(wr_sel[2]),
  .addra(Bank_addr_2),
  .dina(data),
  .douta(q_Bank_2)
);
`else
 SRAM_SP_ADV Bank_0(
  .CLK      (clk),
  .CEN      (1'b1),
  .WEN      (wr_sel[0]),
  .A        (Bank_addr_0),
  .D        (data),
  .Q        (q_Bank_0),
  .EMA      (3'd0)
);

 SRAM_SP_ADV Bank_1(
  .CLK      (clk),
  .CEN      (1'b1),
  .WEN      (wr_sel[1]),
  .A        (Bank_addr_1),
  .D        (data),
  .Q        (q_Bank_1),
  .EMA      (3'd0)
);

 SRAM_SP_ADV Bank_2(
  .CLK      (clk),
  .CEN      (1'b1),
  .WEN      (wr_sel[2]),
  .A        (Bank_addr_2),
  .D        (data),
  .Q        (q_Bank_2),
  .EMA      (3'd0)
);
`endif
always@(*) begin
     if(rd)
        wr_sel = 0;
     else if(wr && ibuf_iaddr_bank_sel == 2'b00)
        wr_sel = 3'b001;
     else if(wr && ibuf_iaddr_bank_sel == 2'b01)
        wr_sel = 3'b010;
     else if(wr && ibuf_iaddr_bank_sel == 2'b10)
        wr_sel = 3'b100;
     else
        wr_sel = 0;
end

endmodule