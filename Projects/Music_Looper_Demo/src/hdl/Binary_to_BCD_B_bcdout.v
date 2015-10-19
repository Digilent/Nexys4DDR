`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:33:23 06/15/2014 
// Design Name: 
// Module Name:    bin_to_decimal 
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
module bin_to_decimal(

	input [11:0] B,
	output reg [15:0] decimals
	);
	
	integer i;

always @(B)
begin
    decimals = 0;
    for(i = 11; i >= 0; i = i-1)
    begin
        if (decimals[15:12]>4)decimals[15:12]=decimals[15:12]+3;
        if (decimals[11:8]>4)decimals[11:8]=decimals[11:8]+3;
        if (decimals[7:4]>4)decimals[7:4]=decimals[7:4]+3;
        if (decimals[3:0]>4)decimals[3:0]=decimals[3:0]+3;
	   
        decimals = {decimals[14:0], B[i]};
    end         
end
endmodule
