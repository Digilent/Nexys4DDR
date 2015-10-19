`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc
// Engineer: Thomas Kappenman
// 
// Create Date:    01:55:33 09/09/2014 
// Design Name: Looper
// Module Name:    looper1_1.v 
// Project Name: Looper Project
// Target Devices: Nexys4 DDR
// Tool versions: Vivado 2015.1
// Description: This project turns your Nexys4 DDR into a guitar/piano/aux input looper. Plug input into XADC3
//
// Dependencies: 
//
// Revision: 
//  0.01 - File Created
//  1.0 - Finished with 8 external buttons on JC, 4 memory banks
//  1.1 - Changed addressing, bug fixes
//  1.2 - Moved to different control scheme using 4 onboard buttons, banks doubled to 8 banks, 3 minutes each
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module looper1_1(

//XADC guitar input
    input vauxp3,
    input vauxn3,
   
    input BTNL,
    input BTNR,
    input BTND,
    input BTNC,
    input JC1,
    
    input CLK100MHZ,
    input rstn,
    //input [3:0]sw,
    
    
    output wire [7:0] LED,
    output wire LED16_R,
    output wire LED17_G,   
    output AUD_PWM,
    output AUD_SD,
    
    output [7:0]an,
    output [6:0]seg,
    
    //memory signals
    output   [12:0] ddr2_addr,
    output   [2:0] ddr2_ba,
    output   ddr2_ras_n,
    output   ddr2_cas_n,
    output   ddr2_we_n,
    output   ddr2_ck_p,
    output   ddr2_ck_n,
    output   ddr2_cke,
    output   ddr2_cs_n,
    output   [1:0] ddr2_dm,
    output   ddr2_odt,
    inout    [15:0] ddr2_dq,
    inout    [1:0] ddr2_dqs_p,
    inout    [1:0] ddr2_dqs_n
);
   
    wire rst;
    assign rst = ~rstn;
   
    parameter tenhz = 10000000;
    
    // Max_block = 64,000,000 / 8 = 8,000,000 or 0111 1010 0001 0010 0000 0000
    // 22:0
    //8 banks
    
    wire playb;
    assign playb = BTNC || JC1;//Play button = JC1 OR BTNC, foot button place on JC1
    
    wire [3:0]buttons_i;
    assign buttons_i = {BTNR, playb, BTND, BTNL};
    
    reg [22:0] max_block=0;
    reg [26:0] timercnt=0;
    reg [11:0] timerval=0;
        
    wire set_max;
    wire reset_max;
    wire [7:0]p;//Bank is playing
    wire [7:0]r;//Bank is recording
    wire del_mem;//Clear delete flag
    wire delete;//Delete flag
    wire [2:0] delete_bank;//Bank to delete
    wire [2:0] mem_bank;//Bank
    wire write_zero;//Used when deleting
    wire [22:0]current_block;//Block address
    wire [3:0] buttons_db;//Debounced buttons
    wire [7:0] active;//Bank is recorded on
    
    wire [2:0] current_bank;
    
    wire [26:0] mem_a;
    assign mem_a[26] = 1'b0;
    assign mem_a [25:0] = (current_block<<3)+mem_bank; //Address is block*8 + banknumber
    //So address cycles through 0 - 1 - 2 - 3 - 4 - 5 - 6 - 7, then current block is inremented by 1 and mem_bank goes back to 0: mem_a = 8
    wire [15:0] mem_dq_i;
    wire [15:0] mem_dq_o;
    wire [15:0] mem_dq;
    wire mem_cen;
    wire mem_oen;
    wire mem_wen;
    wire mem_ub;
    wire mem_lb;
    assign mem_ub = 0;
    assign mem_lb = 0;
    
    wire [15:0] chipTemp;
    wire [15:0] aux_in;
    wire data_flag;
    reg [15:0] sound_data;
    wire data_ready;
    
    wire mix_data;
    wire [22:0] block44KHz;
    
    assign LED[7:0] = active[7:0];
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////
////    clk_wiz instantiation and wiring
//////////////////////////////////////////////////////////////////////////////////////////////////////////
    clk_wiz_0 clk_1
    (
        // Clock in ports
        .clk_in1(CLK100MHZ),
        // Clock out ports  
        .clk_out1(clk_out_100MHZ),
        .clk_out2(clk_out2_200MHZ),
        // Status and control signals        
        .locked()            
    );     
          
//////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Timer shown on Seven Segment
////////////////////////////////////////////////////////////////////////////////////////////////////////// 
   
    always @(posedge(clk_out_100MHZ))begin
        if (p|r)begin
            if (block44KHz==0)begin
                timerval<=0;
                timercnt<=0;
            end
            else if(timercnt<tenhz)timercnt<=timercnt+1;
            else begin
                timercnt<=0;
                timerval<=timerval+1;
            end
        end
        else begin
            timercnt<=0;
            timerval<=0;
        end
    end

//////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Max block address set and reset
//////////////////////////////////////////////////////////////////////////////////////////////////////////

    always @ (posedge(clk_out_100MHZ))begin
        if(reset_max == 1)begin
            max_block <= 0;
        end
        else if(set_max == 1)begin
            max_block <= current_block;
        end
    end
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Looper control
////////////////////////////////////////////////////////////////////////////////////////////////////////

    debounce dbuttons(
        .clock(clk_out_100MHZ),
        .reset(rst),
        .button(buttons_i),
        .out(buttons_db)
    );
      
      
    loop_ctrl mainControl(
        .clk100(clk_out_100MHZ),
        .rst(rst),
        .btns(buttons_db),
        .playing(p),
        .recording(r),
        .active(active),
        .delete(delete),
        .delete_bank(delete_bank),
        .delete_clear(del_mem),
        .bank(current_bank),
        .current_max(max_block),
        .set_max(set_max),
        .reset_max(reset_max)
    );

      
    //Recording light
    assign LED16_R = ( r == 4'b0000 ) ? 0 : 1;
    assign LED17_G = ( p == 4'b0000 ) ? 0 : 1;
      
        
      
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Memory instantiation
//////////////////////////////////////////////////////////////////////////////////////////////////////// 

    Ram2Ddr Ram(
        .clk_200MHz_i          (clk_out2_200MHZ),
        .rst_i                 (rst),
        .device_temp_i         (chipTemp[11:0]),
        // RAM interface
        .ram_a                 (mem_a),
        .ram_dq_i              (mem_dq_i),
        .ram_dq_o              (mem_dq_o),
        .ram_cen               (mem_cen),
        .ram_oen               (mem_oen),
        .ram_wen               (mem_wen),
        .ram_ub                (mem_ub),
        .ram_lb                (mem_lb),
        // DDR2 interface
        .ddr2_addr             (ddr2_addr),
        .ddr2_ba               (ddr2_ba),
        .ddr2_ras_n            (ddr2_ras_n),
        .ddr2_cas_n            (ddr2_cas_n),
        .ddr2_we_n             (ddr2_we_n),
        .ddr2_ck_p             (ddr2_ck_p),
        .ddr2_ck_n             (ddr2_ck_n),
        .ddr2_cke              (ddr2_cke),
        .ddr2_cs_n             (ddr2_cs_n),
        .ddr2_dm               (ddr2_dm),
        .ddr2_odt              (ddr2_odt),
        .ddr2_dq               (ddr2_dq),
        .ddr2_dqs_p            (ddr2_dqs_p),
        .ddr2_dqs_n            (ddr2_dqs_n)
    );
          
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Memory Controller
//////////////////////////////////////////////////////////////////////////////////////////////////////// 

    mem_ctrl mem_controller(
        .clk_100MHz(clk_out_100MHZ),
        .rst(rst),
        
        .playing(p),
        .recording(r),
        
        .delete(delete),
        .delete_bank(delete_bank),
        .max_block(max_block),
        .delete_clear(del_mem),
        .RamCEn(mem_cen),
        .RamOEn(mem_oen),
        .RamWEn(mem_wen),
        .write_zero(write_zero),
        .get_data(data_flag),
        .data_ready(data_ready),
        .mix_data(mix_data),
        
        .addrblock44khz(block44KHz),
        .mem_block_addr(current_block),
        .mem_bank(mem_bank));
                            
      //Data in is assigned the latched data input from sound_data, or .5V (16'h7444) if write zero is on      
      assign mem_dq_i = (write_zero==0) ?  sound_data : 16'h7FFF;

////////////////////////////////////////////////////////////////////////////////////////////////////////
//XADC instantiation
////////////////////////////////////////////////////////////////////////////////////////////////////////
  
    AnalogXADC xadc(
        .aux_data(aux_in),  
        .temp_data(chipTemp),
        .vauxp3(vauxp3),
        .vauxn3(vauxn3),
        .CLK100MHZ(clk_out_100MHZ)
    );

////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Data in latch
//////////////////////////////////////////////////////////////////////////////////////////////////////// 


    //Latch audio data input when data_flag goes high
    always@(posedge(clk_out_100MHZ))begin 
        if (data_flag==1)begin
            sound_data<=aux_in;
            end
    end
 
////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Data mixing and output to PWM
////////////////////////////////////////////////////////////////////////////////////////////////////////    
    
    reg [10:0] PWM;
    reg [19:0] mix;
    reg [15:0] mem_dq_o_b;
        
    integer CH0=0;
    integer CH1=0;
    integer CH2=0;
    integer CH3=0;
    integer CH4=0;
    integer CH5=0;
    integer CH6=0;
    integer CH7=0;
    
    integer mixer=0;
    integer aux=0;
    
    always@(posedge(clk_out_100MHZ))begin
        mem_dq_o_b<=mem_dq_o;
    end
    
    always @ (posedge(clk_out_100MHZ))begin
        if(data_ready==1)begin
            case(mem_bank)
                0: begin
                    if (p[0])
                        CH0=mem_dq_o_b-32767;
                    else
                        CH0=0;
                end
                1: begin
                    if(p[1])
                        CH1=mem_dq_o_b-32767;
                    else
                        CH1=0;
                end
                2: begin
                    if(p[2])
                        CH2=mem_dq_o_b-32767;
                    else
                        CH2=0;
                end
                3: begin
                    if(p[3])
                        CH3=mem_dq_o_b-32767;
                    else
                        CH3=0;
                end
                4: begin
                    if(p[4])
                        CH4=mem_dq_o_b-32767;
                    else
                        CH4=0;
                end
                5: begin
                    if(p[5])
                        CH5=mem_dq_o_b-32767;
                    else
                        CH5=0;
                end
                6: begin
                    if(p[6])
                        CH6=mem_dq_o_b-32767;
                    else
                        CH6=0;
                end
                7: begin
                    if(p[7])
                        CH7=mem_dq_o_b-32767;
                    else
                        CH7=0;
                end
                default:begin
                end
            endcase
        end
    end
    
    reg [1:0] mixer_state=0;
            //Mixer State Machine
    always @ (posedge(clk_out_100MHZ))begin
        case(mixer_state)
            //Idle state
            0: begin
                if (mix_data==1)begin
                        mixer_state<=1;
                        aux<=aux_in-32767;
                    end
                else
                    mixer_state<=0;
            end
            1: begin
                mixer=CH0+CH1+CH2+CH3+CH4+CH5+CH6+CH7+aux+(32767*(1+p[0]+p[1]+p[2]+p[3]+p[4]+p[5]+p[6]+p[7]));
                mixer_state<=2;
            end
            2: begin
                mix<=mixer;
                mixer_state<=3;
                end
            3: begin
                PWM<=mix[19:9];
                mixer_state<=0;    
            end
        endcase
    end
    
    assign AUD_SD = 1'b1;
    
    pwm_module pwm(
        .clk(clk_out_100MHZ),
        .PWM_in(PWM),
        .PWM_out(AUD_PWM)
    );

////////////////////////////////////////////////////////////////////////////////////////////////////////
////    Seven segment display
////////////////////////////////////////////////////////////////////////////////////////////////////////    

    DigitToSeg sevenSeg(
       .timer(timerval),
       .r(r),
       .p(p),
       .active(active),
       .bank(current_bank),
       .mclk(clk_out_100MHZ), 
       .rst(rst),
       .an(an), 
       .dp(),
       .seg(seg)
    );
 
endmodule