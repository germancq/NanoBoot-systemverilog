/**
 * @Author: German Cano Quiveu <germancq>
 * @Date:   2018-11-13T12:23:25+01:00
 * @Email:  germancq@dte.us.es
 * @Filename: search_nanofs.v
 * @Last modified by:   germancq
 * @Last modified time: 2019-02-26T12:13:46+01:00
 */



`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05.10.2017 17:47:33
// Design Name:
// Module Name: search_nanofs
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


module search_nanofs(
    input clk,
    input reset,
    input start,
    input [31:0] begin_address,
    input [31:0] offset,
    output logic err,
    output logic success,
    output logic [31:0] start_reg,

    input [7:0] filename [15:0],
    //spi
    output logic spi_r_block,
    output logic spi_r_byte,
    input spi_busy,
    input spi_err,
    output [31:0] spi_block_addr,
    input [7:0] spi_data_out,
    //debug
    //input btn_debug,
    output [4:0] debug_leds,
    output [31:0] debug_7_seg
    );


logic [7:0] flags_reg;
logic flags_reg_cl;
logic flags_reg_w;
register #(.DATA_WIDTH(8)) r0(
    .clk (clk),
	.cl (flags_reg_cl),
	.w (flags_reg_w),
	.din (spi_data_out),
	.dout (flags_reg)
);

genvar i;

logic [0:0] next_dir_cl [3:0];
logic [0:0] next_dir_w [3:0];
logic [31:0] next_dir;

generate
    for (i = 0;i<4 ;i=i+1 ) begin
        register #(.DATA_WIDTH(8)) r_next_block_i(
            .clk (clk),
            .cl (next_dir_cl[i]),
            .w (next_dir_w[i]),
            .din (spi_data_out),
            .dout (next_dir[(i<<3)+7:(i<<3)])
        );
    end
endgenerate

logic [0:0] child_dir_cl [3:0];
logic [0:0] child_dir_w [3:0];
logic [31:0] child_dir;

generate
    for (i = 0;i<4 ;i=i+1 ) begin
        register #(.DATA_WIDTH(8)) r_child_block_i(
            .clk (clk),
            .cl (child_dir_cl[i]),
            .w (child_dir_w[i]),
            .din (spi_data_out),
            .dout (child_dir[(i<<3)+7:(i<<3)])
        );
    end
endgenerate




logic [7:0] filename_len_reg;
logic filename_len_reg_cl;
logic filename_len_reg_w;
register #(.DATA_WIDTH(8)) r9(
    .clk (clk),
	.cl (filename_len_reg_cl),
	.w (filename_len_reg_w),
	.din (spi_data_out),
	.dout (filename_len_reg)
);

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

/*
reg rom_en;
reg [7:0]rom_addr;
wire [7:0] rom_data;
rom_nanofs rom0(
    .clk (clk),
	.en(rom_en),
	.addr(rom_addr),
	.data(rom_data)
);*/

logic [4:0] next_state;
logic [4:0] current_state;

localparam IDLE = 5'h12;
localparam SETUP = 5'h1;
localparam READ_BLOCK = 5'h2;
localparam WAIT_BLOCK = 5'h3;
localparam READ_DATA = 5'h4;
localparam READ_BYTE = 5'h5;
localparam WAIT_BYTE = 5'h6;
localparam CHECK_FLAGS = 5'h7;
localparam COMPARE_FILENAME = 5'h8;
localparam FOUND_FILE = 5'h9;
localparam READ_BYTE_FROM_ROM = 5'ha;
localparam COMPARE_BYTE = 5'hb;
localparam READ_BYTE_FROM_SD = 5'hc;
localparam WAIT_BYTE_FROM_SD = 5'hd;
localparam CHANGE_BLOCK = 5'he;
localparam WAIT_CHANGE_BLOCK = 5'hf;
localparam SUCCESS = 5'h10;
localparam ERROR = 5'h11;


logic [31:0] current_address;
logic spi_block_addr_cl;
logic spi_block_addr_w;
register #(.DATA_WIDTH(32)) r10(
    .clk (clk),
	.cl (spi_block_addr_cl),
	.w (spi_block_addr_w),
	.din (current_address + offset),
	.dout (spi_block_addr)
);

assign debug_7_seg = {spi_data_out,counter_bytes_out[7:0],spi_block_addr[15:0]};
//NS
always_comb
begin

    next_state = current_state;
    current_address = begin_address;
    rst_bytes_counter = 0;
    spi_r_block = 0;
    spi_r_byte = 0;

    success = 0;
    err = 0;
    up_bytes = 0;
    //rom_en = 0;
    //rom_addr = 8'h00;

    flags_reg_cl = 0;
    flags_reg_w = 0;
    next_dir_cl[0] = 0;
    next_dir_w[0] = 0;
    next_dir_cl[1] = 0;
    next_dir_w[1] = 0;
    next_dir_cl[2] = 0;
    next_dir_w[2] = 0;
    next_dir_cl[3] = 0;
    next_dir_w[3] = 0;
    child_dir_cl[0] = 0;
    child_dir_w[0] = 0;
    child_dir_cl[1] = 0;
    child_dir_w[1] = 0;
    child_dir_cl[2] = 0;
    child_dir_w[2] = 0;
    child_dir_cl[3] = 0;
    child_dir_w[3] = 0;
    filename_len_reg_cl = 0;
    filename_len_reg_w = 0;
    spi_block_addr_cl = 0;
    spi_block_addr_w = 0;

    start_reg = 32'h00000000;

    case(current_state)
        IDLE:
            begin
                spi_block_addr_cl = 1;
                filename_len_reg_cl = 1;
                flags_reg_cl = 1;
                next_dir_cl[0] = 1;
                next_dir_cl[1] = 1;
                next_dir_cl[2] = 1;
                next_dir_cl[3] = 1;
                child_dir_cl[0] = 1;
                child_dir_cl[1] = 1;
                child_dir_cl[2] = 1;
                child_dir_cl[3] = 1;
                rst_bytes_counter = 1;
                if(start == 1'b1)
                    next_state = SETUP;
            end
        SETUP:
            begin
                spi_block_addr_w = 1;
                next_state = CHANGE_BLOCK;
            end
        CHANGE_BLOCK:
            begin
                rst_bytes_counter = 1;
                next_state = WAIT_CHANGE_BLOCK;
            end
        WAIT_CHANGE_BLOCK:
            begin
                 if(spi_busy == 1'b0)
                    next_state = READ_BLOCK;
            end
        READ_BLOCK:
            begin
                spi_r_block = 1;
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
                current_address = child_dir;
                case(counter_bytes_out)
                    32'h0:flags_reg_w = 1;
                    32'h1:next_dir_w[0] = 1;
                    32'h2:next_dir_w[1] = 1;
                    32'h3:next_dir_w[2] = 1;
                    32'h4:next_dir_w[3] = 1;
                    32'h5:child_dir_w[0] = 1;
                    32'h6:child_dir_w[1] = 1;
                    32'h7:child_dir_w[2] = 1;
                    32'h8:child_dir_w[3] = 1;
                    32'h9,31'ha,31'hb,31'hc:;
                    32'hd:filename_len_reg_w = 1;
                    default:next_state = CHECK_FLAGS;
                endcase
            end
        CHECK_FLAGS:
            begin
                spi_r_block = 1;
                spi_block_addr_w = 1;
                rst_bytes_counter = 1;
                current_address = child_dir;

                if(flags_reg == 8'h00)
                    next_state = COMPARE_FILENAME;

                else if(flags_reg == 8'h01)
                    begin
                        next_state = CHANGE_BLOCK;
                    end
                else
                    next_state = ERROR;

            end
        COMPARE_FILENAME:
            begin
                spi_r_block = 1;
               if(counter_bytes_out == filename_len_reg)
                    next_state = FOUND_FILE;
               else
                    next_state = READ_BYTE_FROM_ROM;
            end
        FOUND_FILE:
            begin
                start_reg[31:0] = child_dir[31:0];
                next_state = SUCCESS;
            end
        READ_BYTE_FROM_ROM:
            begin
                spi_r_block = 1;
                //rom_en = 1;
                //rom_addr = counter_bytes_out[7:0];
                next_state = COMPARE_BYTE;
            end
        COMPARE_BYTE:
            begin
                //rom_en = 1;
                spi_r_block = 1;
                if(filename[counter_bytes_out] == spi_data_out)
                    next_state = READ_BYTE_FROM_SD;
                else
                    begin
                        if(child_dir==32'h00000000)
                            next_state = ERROR;
                        else
                            begin
                                next_state = CHANGE_BLOCK;
                            end
                    end
            end
        READ_BYTE_FROM_SD:
            begin
                spi_r_block = 1;
                spi_r_byte = 1;
                up_bytes = 1;

                next_state = WAIT_BYTE_FROM_SD;
            end
        WAIT_BYTE_FROM_SD:
            begin
                spi_r_block = 1;
                if(spi_busy == 1'b0)
                begin
                    next_state = COMPARE_FILENAME;
                end

            end
        SUCCESS:
            begin
                start_reg[31:0] = child_dir[31:0];
                success = 1;
            end
        ERROR:
            begin
                err = 1;
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
        default:;
    endcase
end

always_ff @(posedge clk)
begin
    if(reset == 1'b1)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

assign debug_leds[4:0] = current_state;

endmodule
