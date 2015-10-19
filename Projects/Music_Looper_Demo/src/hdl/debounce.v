`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2015 09:14:14 PM
// Design Name: 
// Module Name: debounce
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


module debounce(
    input clock,//100MHz clock
    input reset,
    input [3:0] button,//Buttons to debounce
    output reg [3:0]out
);

reg [12:0] cnt0=0, cnt1=0, cnt2=0, cnt3=0;
reg [3:0] IV = 0;

//parameter dbTime = 19;
parameter dbTime = 4000;

always @ (posedge(clock))begin
    if(reset==1)begin
        cnt0<=0;
        cnt1<=0;
        cnt2<=0;
        cnt3<=0;
        out<=0;
    end
    else begin
        if(button[0]==IV[0]) begin 
            if (cnt0==dbTime) begin
                out[0]<=IV[0];
                end
            else begin
                cnt0<=cnt0+1;
                end
        end
        else begin
            cnt0<=0;
            IV[0]<=button[0];
            end
        if(button[1]==IV[1]) begin 
            if (cnt1==dbTime) begin
                out[1]<=IV[1];
            end
            else begin
                cnt1<=cnt1+1;
            end
        end
        else begin
            cnt1<=0;
            IV[1]<=button[1];
        end
        if(button[2]==IV[2]) begin 
            if (cnt2==dbTime) begin
                out[2]<=IV[2];
            end
            else begin
                cnt2<=cnt2+1;
            end
        end
        else begin
            cnt2<=0;
            IV[2]<=button[2];
        end
        if(button[3]==IV[3]) begin 
            if (cnt3==dbTime) begin
                out[3]<=IV[3];
            end
            else begin
                cnt3<=cnt3+1;
            end
        end
        else begin
            cnt3<=0;
            IV[3]<=button[3];
        end
    end
end
endmodule