/**
 * @ Author: German Cano Quiveu, germancq
 * @ Create Time: 2019-12-02 17:07:00
 * @ Modified by: Your name
 * @ Modified time: 2020-02-04 13:13:01
 * @ Description:
 */

module nanofs_wrapper #(parameter N=32, 
                        parameter ENABLE_MBR = 1'b1,
                        parameter USE_READ_MULTIBLOCK = 1'b0)
(
    input clk,
    input rst,

    input start,
    input [7:0] filename [15:0], //16 caracteres max
    input next_data,
    output busy,
    output [N-1:0] data_out,
    output end_of_file,

    output file_not_found,
    output err,

    //spi//
    output sclk,
    output cs,
    output mosi,
    input miso,
    input [4:0] sclk_speed,

    output[31:0] debug
);

    wire spi_busy;
    wire [31:0] spi_block_addr;
    wire [7:0] spi_data_out;
    wire spi_r_block;
    wire spi_r_byte;
    wire spi_r_multi_block;
    wire spi_rst;
    wire spi_err;
    sdspihost spi0(
        .clk	(clk),
        .reset (spi_rst),
        .busy (spi_busy),
        .err (spi_err),
        .crc_err(),
        .r_block (spi_r_block),
        .r_multi_block(spi_r_multi_block),
        .r_byte(spi_r_byte),
        .w_block(0),
        .w_byte(0),
        .block_addr(spi_block_addr),
        .data_out(spi_data_out),
        .data_in(),
        .sclk_speed(sclk_speed),
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk),
        .ss(cs),
        .debug(debug)
    );


    logic adapter_rst;
    logic adapter_start;
    logic nanofs_busy;
    logic nanofs_next_byte;
    logic [7:0] nanofs_data;

    nanofs nanofs_inst(
        .clk(clk),
        .reset(rst),
        .start(start),
        
        .end_of_file(end_of_file),
        .filename(filename),
        .cmd_18(USE_READ_MULTIBLOCK),
        .enable_mbr(ENABLE_MBR),

        .file_not_found(file_not_found),
        .err(err),

        //adapter
        .adapter_rst(adapter_rst),
        .adapter_start(adapter_start),
        .byte_data(nanofs_data),
        .busy(nanofs_busy),
        .next_byte(nanofs_next_byte),

        //spi
        .spi_busy(spi_busy),
        .spi_err(spi_err),
        .spi_rst(spi_rst),
        .spi_r_block(spi_r_block),
        .spi_r_multi_block(spi_r_multi_block),
        .spi_r_byte(spi_r_byte),
        .spi_block_addr(spi_block_addr),
        .spi_data_out(spi_data_out),

        .debug_leds(),
        .finish_signal(),
        .idle_signal(),
        .debug_data(debug)
    );


    adapter_nanofs #(.N(N)) adapter_impl(
        .clk(clk),
        .rst(adapter_rst),
        .start(adapter_start),

        .busy_nanofs(nanofs_busy),
        .next_byte_nanofs(nanofs_next_byte),
        .nanofs_data(nanofs_data),

        .next_data(next_data),
        .busy(busy),
        .data_out(data_out)
    );



    endmodule : nanofs_wrapper