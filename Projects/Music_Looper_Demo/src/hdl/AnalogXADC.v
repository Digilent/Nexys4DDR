`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2015 01:43:34 PM
// Design Name: 
// Module Name: AnalogXADC
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


module AnalogXADC(
    output reg [15:0] aux_data,
    output reg [15:0] temp_data,
    input vauxp3,
    input vauxn3,
    input CLK100MHZ
    );
    
    



wire enable;  
wire ready;
wire [15:0] data_o; 
reg [6:0] Address_in;

initial Address_in = 7'h13; 
         
xadc_wiz_0  XLXI_7 (.daddr_in(Address_in), //addresses can be found in the artix 7 XADC user guide DRP register space
                      .dclk_in(CLK100MHZ), 
                      .den_in(enable), 
                      .di_in(0), 
                      .dwe_in(0), 
                      .busy_out(),                    
                     
                      .vauxp3(vauxp3),
                      .vauxn3(vauxn3),
                      
                      .vn_in(0), 
                      .vp_in(0), 
                      .alarm_out(), 
                      .do_out(data_o), 
                      .eoc_out(enable),
                      .eos_out(),
                      .channel_out(),
                      .drdy_out(ready));
                      

      
////assigning different values out from xadc
always @(posedge(CLK100MHZ))
begin
if(ready == 1'b1)
begin
    if(Address_in == 7'h13) //audio in
    begin
        aux_data <= {data_o[15:4],4'b0000};
        Address_in <= 7'h00; //change to temp read
    end
    else //temperature in
    begin
        temp_data <= data_o;
        Address_in <= 7'h13;            
    end        
end      
end
      
 
 
endmodule
