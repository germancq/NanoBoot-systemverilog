`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2018 15:55:16
// Design Name: 
// Module Name: look_up_mbr_partition
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


module look_up_mbr_partition(
    input clk,
	input reset,
	output logic err_signal,
	output logic success,
	input start,
	output [31:0] start_reg,
	////spi////////
	output logic spi_r_block,
	output logic spi_r_byte,
	input spi_busy,
	input spi_err,
	output [31:0] spi_block_addr,
	input [7:0] spi_data_out,
	///debug//////////////
	output [3:0] debug_leds
    );
    
    genvar i;


    logic [0:0] boot_sign_cl [1:0];
    logic [0:0] boot_sign_w [1:0];
    logic [15:0] boot_sign;
    generate
        for (i=0 ;i<2 ;i=i+1 ) begin
            register #(.DATA_WIDTH(8)) r_boot_sign_i(
                .clk (clk),
                .cl (boot_sign_cl[i]),
                .w (boot_sign_w[i]),
                .din (spi_data_out),
                .dout (boot_sign[(i<<3)+7:(i<<3)])
            );
        end
    endgenerate


    logic [0:0] sector_part_cl [3:0];
    logic [0:0] sector_part_w [3:0];
    generate
        for (i=0 ;i<4 ;i=i+1 ) begin
            register #(.DATA_WIDTH(8)) r_sector_part_i(
                .clk (clk),
                .cl (sector_part_cl[i]),
                .w (sector_part_w[i]),
                .din (spi_data_out),
                .dout (start_reg[(i<<3)+7:(i<<3)])
            );
        end
    endgenerate
    
   
    
    
    logic up_bytes;
    logic [31:0] counter_bytes_out;
    logic rst_bytes_counter;
    counter #(.DATA_WIDTH(32)) counter0(
       .clk(clk),
       .rst(rst_bytes_counter),
       .up(up_bytes),
       .down(1'b0),
       .din(32'h0),
       .dout(counter_bytes_out)
    );
    
    
    logic [3:0] next_state;
    logic [3:0] current_state;
    
    localparam IDLE = 4'h0;
    localparam INIT_SD = 4'h1;
    localparam READ_BLOCK = 4'h2;
    localparam WAIT_BLOCK = 4'h3;
    localparam READ_DATA = 4'h4;
    localparam READ_BYTE = 4'h5;
    localparam WAIT_BYTE = 4'h6;
    localparam CHECK_MBR = 4'h7;
    localparam SUCCESS = 4'h8;
    localparam ERROR = 4'h9;
    
    
    assign spi_block_addr = 32'h00000000;
    
    
    //NS
    always_comb
    begin
    
        next_state = current_state;

        rst_bytes_counter = 0;
        spi_r_block = 0;
        spi_r_byte = 0;
        success = 0;
        err_signal = 0;
        up_bytes = 0;
        
        boot_sign_cl[0] = 0;
        boot_sign_w[0] = 0;
        
        boot_sign_cl[1] = 0;
        boot_sign_w[1] = 0;
        
        sector_part_cl[0] = 0;
        sector_part_w[0] = 0;
        
        sector_part_cl[1] = 0;
        sector_part_w[1] = 0;
        
        sector_part_cl[2] = 0;
        sector_part_w[2] = 0;
        
        sector_part_cl[3] = 0;
        sector_part_w[3] = 0;
        
        
        case(current_state)
            IDLE:
                begin
        
                    boot_sign_cl[0] = 1;
                    boot_sign_cl[1] = 1;
                    sector_part_cl[0] = 1;
                    sector_part_cl[1] = 0;
                    sector_part_cl[2] = 0;
                    sector_part_cl[3] = 0;
                    
                    rst_bytes_counter = 1;
                    if(start == 1'b1)
                        next_state = INIT_SD;
                end
            INIT_SD:
                begin
                    if(spi_busy == 1'b0)
                        next_state = READ_BLOCK;
                end
            READ_BLOCK:
                begin
                    spi_r_block = 1;
                    //spi_block_addr = actual_block;
    
                    next_state = WAIT_BLOCK;
                end    
            WAIT_BLOCK:
                begin
                    spi_r_block = 1;            
                    if(spi_busy == 1'b0)
                        next_state = READ_DATA;
                end
            READ_DATA:
                begin
                    spi_r_block = 1;
                    next_state = READ_BYTE;    
                    case(counter_bytes_out)
                        32'h1C6:sector_part_w[0] = 1;
                        32'h1C7:sector_part_w[1] = 1;
                        32'h1C8:sector_part_w[2] = 1;
                        32'h1C9:sector_part_w[3] = 1;
                        32'h1FE:boot_sign_w[0] = 1;
                        32'h1FF:boot_sign_w[1] = 1;
                        32'h200:next_state = CHECK_MBR;
                        default:;
                    endcase                        
                end
            CHECK_MBR:
                begin
                    
                    if(boot_sign == 16'hAA55)
                        next_state = SUCCESS;
                    else
                        next_state = ERROR;
                      
                end
            SUCCESS:
                begin
                    success = 1;
                end
            ERROR:
                begin
                    err_signal = 1;
                end
            READ_BYTE:
                begin
                    spi_r_block = 1;
                    spi_r_byte = 1;
                    up_bytes = 1;
    
                    next_state = WAIT_BYTE;
                end
            WAIT_BYTE:
                begin
                    spi_r_block = 1;
                    if(spi_busy == 1'b0)
                    begin
                        next_state = READ_DATA;
                    end                       
                end
            default:
              begin
                  spi_r_block = 1;
              end    
        endcase
    end
    
    always_ff @(posedge clk)
    begin
    
        if(reset == 1'b1)
            current_state <= IDLE; 
        else
            current_state <= next_state;
        
    end
    
    assign debug_leds[3:0] = current_state;

    
endmodule



