////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 14.7
//  \   \         Application : sch2hdl
//  /   /         Filename : Top.vf
// /___/   /\     Timestamp : 12/01/2014 17:59:05
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: sch2hdl -intstyle ise -family spartan3e -verilog C:/Users/samue_000/Documents/FPGA/Projects/Stopwatch/sevensegdecoder/Top.vf -w C:/Users/samue_000/Documents/FPGA/Projects/Stopwatch/sevensegdecoder/Top.sch
//Design Name: Top
//Device: spartan3e
//Purpose:
//    This verilog netlist is translated from an ECS schematic.It can be 
//    synthesized and simulated, but it should not be modified. 
//
`timescale 1ns / 1ps

module DigitToSeg(
           input [11:0] timer, 
           input [7:0] r,
           input [7:0] p,
           input [7:0] active,
           input [2:0] bank,
           input mclk, 
           input rst,
           output [7:0] an, 
           output dp,
           output [6:0]seg
           );
           
    wire [15:0] BCD;
    wire [4:0] dig4;
    wire [4:0] dig5;
    wire [4:0] dig6;
    wire [4:0] dig7;
//    assign dig4 = (r[3]==1)? 5'h10 : (p[3]==1)? 5'h11: (active[3]==1) ? 5'h5: 5'h12;
//    assign dig5 = (r[2]==1)? 5'h10 : (p[2]==1)? 5'h11: (active[2]==1) ? 5'h5: 5'h12;
//    assign dig6 = (r[1]==1)? 5'h10 : (p[1]==1)? 5'h11: (active[1]==1) ? 5'h5: 5'h12;
//    assign dig7 = (r[0]==1)? 5'h10 : (p[0]==1)? 5'h11: (active[0]==1) ? 5'h5: 5'h12;


    assign dig4 = (r[bank]==1)? 5'h10 : (p[bank]==1)? 5'h11: (active[bank]==1) ? 5'h5: 5'h12;
    assign dig5 = 5'h13;
    assign dig6 = {2'b00, bank};
    assign dig7 = 5'hB;
    
    wire segClk;
    wire [4:0] number;
    wire [2:0] select;
   
    bin_to_decimal bintodecimal (
        .B(timer),
        .decimals(BCD)
    );
   
    sevensegdecoder  charSelect (.nIn(number[4:0]), 
        .ssOut(seg[6:0]));
    mux4_4bus  sevensegmux (.I0({1'b0,BCD[3:0]}), 
        .I1({1'b0,BCD[7:4]}), 
        .I2({1'b0,BCD[11:8]}), 
        .I3({1'b0,BCD[15:12]}),
        .I4(dig4[4:0]), 
        .I5(dig5[4:0]), 
        .I6(dig6[4:0]), 
        .I7(dig7[4:0]),  
        .Sel(select[2:0]), 
        .Y(number[4:0]));
                      
    segClkDevider  seg_clk_div (.clk(mclk), 
        .rst(rst), 
        .clk_div(segClk));

    counter3bit  counter (.clk(segClk), 
        .rst(rst), 
        .Q(select[2:0]));
    decoder_3_8  segdecoder (.I(select[2:0]),
        .dp(dp), 
        .an(an[7:0]));
                        
  
endmodule
