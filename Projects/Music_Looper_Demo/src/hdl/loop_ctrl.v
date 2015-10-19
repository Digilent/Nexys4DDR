`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2015 03:30:05 PM
// Design Name: 
// Module Name: loop_ctrl
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


module loop_ctrl(
    input clk100,
    input rst,
    
    input [3:0] btns, //btns = [back, stop/delete, play/record, next]
    
    output reg [7:0] playing,
    output reg [7:0] recording,
    
    output reg [7:0] active,
    output reg delete,
    output reg [2:0] delete_bank,
    input delete_clear,
    output reg [2:0] bank,
    
    input [22:0]current_max,
    output reg set_max,
    
    output reg reset_max
    );

//State Machine states
    parameter DEFAULT = 4'b0000;
    parameter PLAY =   4'b0001;
    parameter RECORD = 4'b0010;
    parameter DELETE = 4'b0011;
    parameter STOP =   4'b0100;
    parameter PBTNDB = 4'b0101;
    parameter PDELBTNDB = 4'b0110;
    parameter DELETEOTHERS = 4'b0111;
    parameter DEFAULT_DB = 4'b1000;
    
    `define BACK 0
    `define STOP 1
    `define PLAY 2
    `define FORWARD 3
 
    initial delete = 1'b0;
    initial delete_bank = 1'b0;
    initial playing = 4'b0000;
    initial recording = 4'b0000;
    initial active = 4'b0000;
    initial bank = 3'b000;
    
    reg [3:0] pstate = DEFAULT;
    reg [3:0] nstate = DEFAULT;
    
//Delete counter stuff
    parameter count_max = 150000000;
    
    reg delay_en = 0;
    reg delay_done = 0;
    reg [27:0] counter=0;
    
   
    //Main State Machine
always @ (posedge (clk100))
    begin
        if (rst == 1)begin
            pstate <= DEFAULT;
            reset_max <= 1;
            set_max <= 0;
            active <= 4'b0000;
            delay_en <= 0;
            playing <= 4'b0000;
            recording <= 4'b0000;
            delete <= 1'b0;
            delete_bank <= 1'b0;
            bank<=3'b000;
        end
    else begin
        if(delete_clear)delete<=1'b0;
        case (pstate)
            DEFAULT: begin
                reset_max <= 0;
                set_max <= 0;
                
                if((btns[`BACK] == 1))begin //Back bank button
                    bank<=bank-1;    
                    pstate <= DEFAULT_DB;
                end
                else if (btns[`FORWARD] == 1) begin //Forward bank button pressed
                    bank<=bank+1;
                    pstate <= DEFAULT_DB;
                end
                else if (btns[`STOP] == 1) begin
                    pstate <= STOP;
                end
                else if (btns[`PLAY] == 1) begin
                    if (active[bank] == 0) //The current bank is not recorded on yet
                        pstate <= RECORD;  //So record onto it
                    else begin //The current bank is recorded on already
                        if (playing[bank] == 0)//If the current bank is not playing
                            pstate <= PLAY;
                        else //The current bank is playing already
                            pstate <= RECORD;
                    end
                    
                end
            end //End DEFAULT
            
            DEFAULT_DB: begin
                if (btns==0) //Wait until button is released
                    pstate <= DEFAULT;
            end
            
            PLAY: begin
                playing[bank] <= 1;
                recording[bank] <= 0;
                set_max<=0;
                if(btns[`PLAY] == 0)begin
                    pstate <= nstate;    
                end
            end
            
            RECORD: begin   //Play button is held down still
                recording[bank] <= 1;
                playing[bank] <= 0;
                
                if(btns[`PLAY] == 0)begin //Play button is released, go to the db state
                    pstate <= PBTNDB;
                end
                else if(btns[`STOP])begin
                    pstate <= DELETE;
                end
            end
            
            PBTNDB: begin   //Play button is released, still recording
                if (btns[`STOP]==1)//Stop button pressed, delete the bank
                    pstate<=DELETE;
                else if(btns[`PLAY] == 1)begin //Play button is pressed again
                    active[bank] <= 1;  //This bank is now active
                    if(current_max == 0)begin //If there is no other banks recorded on (max is 0 still) delete the other banks!
                        set_max <= 1;//Set the max flag
                        delete_bank<=bank+1;//Delete the other banks
                        delete<=1;//Turn on delete
                        nstate <=DELETEOTHERS;//After the play state, we will go to the DELETEOTHERS state instead of default
                    end
                    pstate<=PLAY;//Then go to PLAY state to start the track
                end
            end
            
            DELETEOTHERS: begin
                nstate<=DEFAULT;//Reset nstate
                if (delete==0)begin//If done deleting
                    delete_bank=delete_bank+1;//Increment delete_bank
                    if (active[delete_bank]==0)begin//If the new bank isn't recorded on
                        delete<=1;//Delete the old data on that bank
                    end
                    else//If the new bank is recorded on, we know it is the first loop, so return
                        pstate<= DEFAULT;
                end
            end
            
            DELETE: begin
                delete <= 1;
                delete_bank <= bank;
                recording[bank] <= 0;
                active[bank] <= 0;
                pstate <= PDELBTNDB;            
            end
            
            PDELBTNDB: begin
                if(active == 8'b00000000)begin//All of the banks are erased
                    reset_max <= 1;//Reset_max flag is set for one cycle
                end
                if (btns[`STOP]==0)//Debounce, wait until the stop button is released
                    pstate<=DEFAULT;
            end
            
            STOP: begin
                delay_en <= 1;//Start delay counter
                playing[bank] <= 0;//Stop playing the bank
                if(btns[`STOP] == 0)begin //If the stop button is released before 1.5 seconds
                    delay_en <= 0;//Stop and reset the delete counter
                    pstate <= DEFAULT;//Return to DEFAULT
                end
                else if(delay_done == 1)begin //If the stop button is held for 1.5 seconds, delete
                    delay_en <= 0;//Turn off the delete counter
                    pstate <= DELETE;//Delete the bank
                end
            end
            
        endcase
    end//End else if reset
end
 
//Delete hold timer
    
always @(posedge (clk100))begin
    if(delay_en==0)begin
        counter <= 0;
        delay_done <= 0;
    end
    
    else if(counter < count_max) begin
        counter <= counter + 1;
        delay_done <= 0;
    end
    
    else begin
        counter <= 0;
        delay_done <= 1;
    end
end   
    

endmodule
