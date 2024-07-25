/**
 * @ Author: German Cano Quiveu, germancq
 * @ Create Time: 2019-12-03 18:53:17
 * @ Modified by: Your name
 * @ Modified time: 2019-12-05 13:16:07
 * @ Description:
 */

module top(
    input sys_clk_pad_i,
    input rst, //btn central
    input next_data, //btn right
    input start, //btn up

    output busy, //LED 0
    output end_of_file, //LED 1
    output file_not_found, //LED 2
    output err, //LED 3

    output sclk,
    output mosi,
    input miso,
    output cs,
    output SD_RESET,
    output SD_DAT_1,
    output SD_DAT_2,
    
    output [6:0] seg,
    output [7:0] AN
);


    assign SD_RESET = 1'b0;
    assign SD_DAT_1 = 1'b1;
    assign SD_DAT_2 = 1'b1;

    logic [7:0] filename [15:0];
    assign filename[0] =  8'h6C;
    assign filename[1] =  8'h69;
    assign filename[2] =  8'h6E;
    assign filename[3] =  8'h75;
    assign filename[4] =  8'h78;
    assign filename[5] =  8'h2E;
    assign filename[6] =  8'h62;
    assign filename[7] =  8'h69;
    assign filename[8] =  8'h6E;
    assign filename[9] =  8'h00;
    assign filename[10] =  8'h00;
    assign filename[11] =  8'h00;
    assign filename[12] =  8'h00;
    assign filename[13] =  8'h00;
    assign filename[14] =  8'h00;
    assign filename[15] =  8'h00;

    logic next_data_pulse;
    pulse_button up_button_impl(
        .clk(sys_clk_pad_i),
        .rst(rst),
        .button(next_data),
        .pulse(next_data_pulse)
    );

    logic [31:0] display_din;

    nanofs_wrapper #(.N(32)) adapter_nanofs(
        .clk(sys_clk_pad_i),
        .rst(rst),

        .start(start),
        .filename(filename), //16 caracteres max
        .next_data(next_data_pulse),
        .busy(busy),
        .data_out(display_din),
        .end_of_file(end_of_file),

        .file_not_found(file_not_found),
        .err(err),

        //spi//
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .sclk_speed(5'h7),

        .debug()
    );

    display #(.N(32)) display_inst(
        .clk(sys_clk_pad_i),
        .rst(rst),
        .div_value(32'd18),
        .din(display_din),
        .an(AN),
        .seg(seg)
    );


endmodule : top