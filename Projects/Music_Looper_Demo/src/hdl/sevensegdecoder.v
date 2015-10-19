`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:55:33 09/09/2014 
// Design Name: 
// Module Name:    sevensegdecoder 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sevensegdecoder(

	input [4:0] nIn,
	output reg [6:0] ssOut  
);

always @(nIn)
    case (nIn)
      5'h0: ssOut = 7'b1000000;
      5'h1: ssOut = 7'b1111001;
      5'h2: ssOut = 7'b0100100;
      5'h3: ssOut = 7'b0110000;
      5'h4: ssOut = 7'b0011001;
      5'h5: ssOut = 7'b0010010;
      5'h6: ssOut = 7'b0000010;
      5'h7: ssOut = 7'b1111000;
      5'h8: ssOut = 7'b0000000;
      5'h9: ssOut = 7'b0011000;
      5'hA: ssOut = 7'b0001000;
      5'hB: ssOut = 7'b0000011;
      5'hC: ssOut = 7'b1000110;
      5'hD: ssOut = 7'b0100001;
      5'hE: ssOut = 7'b0000110;
      5'hF: ssOut = 7'b0001110;
      5'h10: ssOut = 7'b0101111;
      5'h11: ssOut = 7'b0001100;
      5'h12: ssOut = 7'b0000110;
      5'h13: ssOut = 7'b1111111;
      default: ssOut = 7'b1001001;
    endcase

endmodule
