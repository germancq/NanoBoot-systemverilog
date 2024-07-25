/**
 * @Author: German Cano Quiveu <germancq>
 * @Date:   2018-12-07T12:37:17+01:00
 * @Email:  germancq@dte.us.es
 * @Filename: execute_nanofs_multiblock.v
 * @Last modified by:   germancq
 * @Last modified time: 2019-02-26T12:14:26+01:00
 */


 module execute_nanofs_multiblock(
     input clk,
     input reset,
     input start,
     input [31:0] offset,
     input [31:0] begin_address,
     input req_byte,
     output logic busy,
     output logic end_of_file,
     output [7:0] byte_data,
     //spi
     output logic spi_r_multi_block,
     output logic spi_r_byte,
     input spi_busy,
     input spi_err,
     output [31:0] spi_block_addr,
     input [7:0] spi_data_out,
     //debug
     //input btn_debug,
     output [4:0] debug_leds
     //output [31:0] debug_7_seg
     );

     logic [4:0] current_state;
     logic [4:0] next_state;

     localparam IDLE = 5'h0;
     localparam SETUP = 5'h1;
     localparam CHANGE_BLOCK = 5'h2;
     localparam WAIT_CHANGE_BLOCK = 5'h3;
     localparam READ_BLOCK = 5'h4;
     localparam WAIT_BLOCK = 5'h5;
     localparam READ_DATA = 5'h6;
     localparam READ_BYTE_PROGRAM = 5'h8;
     localparam CHECK_COUNTER = 5'h9;
     localparam WAIT_REQ = 5'ha;
     localparam CHECK_NEXT_BLOCK = 5'hb;
     localparam CHECK_UP_BLOCK = 5'h11;
     localparam READ_BYTE = 5'hc;
     localparam WAIT_BYTE = 5'hd;
     localparam READ_BYTE_1 = 5'he;
     localparam WAIT_BYTE_1 = 5'hf;
     localparam FINISH = 5'h10;
     localparam UP_PROGRAM_COUNTER = 5'h12;

     logic [7:0] program_byte;
     logic program_byte_cl;
     logic program_byte_w;
     register #(.DATA_WIDTH(8)) r0(
         .clk (clk),
         .cl (program_byte_cl),
         .w (program_byte_w),
         .din (spi_data_out),
         .dout (program_byte)
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

     
     logic [0:0] block_len_cl [3:0];
     logic [0:0] block_len_w [3:0];
     logic [31:0] block_len;

     generate
        for (i = 0;i<4 ;i=i+1 ) begin
            register #(.DATA_WIDTH(8)) r_block_len_i(
                .clk (clk),
                .cl (block_len_cl[i]),
                .w (block_len_w[i]),
                .din (spi_data_out),
                .dout (block_len[(i<<3)+7:(i<<3)])
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

     logic up_program;
     logic [31:0] counter_program_out;
     logic rst_program_counter;
     counter #(.DATA_WIDTH(32)) counter1(
        .clk(clk),
        .rst(rst_program_counter),
        .up(up_program),
        .down(1'b0),
        .din(32'h0),
        .dout(counter_program_out)
     );

     logic [31:0] current_address;
     logic spi_block_addr_reset;
     logic spi_block_addr_ld;
     logic spi_block_addr_up;
     counter #(.DATA_WIDTH(32)) counter2(
         .clk (clk),
         .rst (spi_block_addr_reset | spi_block_addr_ld),
         .up (spi_block_addr_up),
         .down(1'b0),
         .din (current_address + offset),
         .dout (spi_block_addr)
     );
     //assign debug_7_seg = {spi_data_out,counter_bytes_out[7:0],spi_block_addr[15:0]};
     assign byte_data = program_byte;

     always_comb
     begin
         next_state = current_state;
         current_address = begin_address;
         busy = 1;
         end_of_file = 0;
         spi_r_multi_block = 0;
         spi_r_byte = 0;

         up_bytes = 0;
         rst_bytes_counter = 0;

         up_program = 0;
         rst_program_counter = 0;

         block_len_cl[3] = 0;
         block_len_w[3] = 0;
         block_len_cl[2] = 0;
         block_len_w[2] = 0;
         block_len_cl[1] = 0;
         block_len_w[1] = 0;
         block_len_cl[0] = 0;
         block_len_w[0] = 0;
         next_dir_cl[3] = 0;
         next_dir_w[3] = 0;
         next_dir_cl[2] = 0;
         next_dir_w[2] = 0;
         next_dir_cl[1] = 0;
         next_dir_w[1] = 0;
         next_dir_cl[0] = 0;
         next_dir_w[0] = 0;
         program_byte_cl = 0;
         program_byte_w = 0;

         spi_block_addr_reset = 0;
         spi_block_addr_ld = 0;
         spi_block_addr_up = 0;

         case (current_state)
             IDLE:
                 begin
                     rst_bytes_counter = 1;
                     rst_program_counter = 1;

                     block_len_cl[3] = 1;
                     block_len_cl[2] = 1;
                     block_len_cl[1] = 1;
                     block_len_cl[0] = 1;
                     next_dir_cl[3] = 1;
                     next_dir_cl[2] = 1;
                     next_dir_cl[1] = 1;
                     next_dir_cl[0] = 1;
                     program_byte_cl = 1;

                     spi_block_addr_reset = 1;

                     if(start == 1'b1)
                         next_state = SETUP;
                 end
             SETUP:
                 begin
                     spi_block_addr_ld = 1;
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
                     spi_r_multi_block = 1;
                     next_state = WAIT_BLOCK;
                 end
             WAIT_BLOCK:
                 begin
                     spi_r_multi_block = 1;
                     if(spi_busy == 1'b0)
                     begin
                         if(counter_program_out == 32'h0000000)
                             next_state = READ_DATA;
                             
                         else
                             next_state = READ_BYTE_PROGRAM;
                     end
                 end
             READ_DATA:
                 begin
                     spi_r_multi_block = 1;
                     
                     next_state = READ_BYTE;

                     case(counter_bytes_out)
                         32'h0:next_dir_w[0] = 1;
                         32'h1:next_dir_w[1] = 1;
                         32'h2:next_dir_w[2] = 1;
                         32'h3:next_dir_w[3] = 1;
                         32'h4:block_len_w[0] = 1;
                         32'h5:block_len_w[1] = 1;
                         32'h6:block_len_w[2] = 1;
                         32'h7:block_len_w[3] = 1;
                         default:next_state = READ_BYTE_PROGRAM;
                     endcase
                 end
             READ_BYTE_PROGRAM:
                 begin

                     spi_r_multi_block = 1;
                     program_byte_w = 1;
                     next_state = CHECK_COUNTER;

                 end
             CHECK_COUNTER:
                 begin
                     spi_r_multi_block = 1;
                     if (counter_program_out == block_len+1)
                         next_state = CHECK_NEXT_BLOCK;
                     else
                         next_state = WAIT_REQ;
                 end
             WAIT_REQ:
                 begin
                     spi_r_multi_block = 1;
                     busy = 0;
                     if(req_byte == 1'b1)
                         next_state = READ_BYTE_1;
                 end
             CHECK_UP_BLOCK:
                 begin
                     spi_block_addr_up = 1;
                     next_state = CHANGE_BLOCK;
                 end
             CHECK_NEXT_BLOCK:
                 begin

                     if(next_dir == 32'h00000000)
                         next_state = FINISH;
                     else
                         begin
                             rst_program_counter = 1;
                             current_address = next_dir;
                             spi_block_addr_ld = 1;
                             next_state = CHANGE_BLOCK;
                         end

                 end
 	          UP_PROGRAM_COUNTER:
           		begin
           			up_program = 1;
           			next_state = CHANGE_BLOCK;
           		end
             READ_BYTE:
                 begin
                     spi_r_multi_block = 1;
                     spi_r_byte = 1;
                     
                     up_bytes = 1;
                     

                     next_state = WAIT_BYTE;
                 end
             WAIT_BYTE:
                 begin
                     spi_r_multi_block = 1;
                     if(spi_busy == 1'b0)
                     begin
                         next_state = READ_DATA;
                     end
                 end
             READ_BYTE_1:
                 begin
                     spi_r_multi_block = 1;
                     spi_r_byte = 1;
                     up_bytes = 1;
                     up_program = 1;

                     next_state = WAIT_BYTE_1;
                 end
             WAIT_BYTE_1:
                 begin
                     spi_r_multi_block = 1;
                     if(spi_busy == 1'b0)
                     begin
                         next_state = READ_BYTE_PROGRAM;
                     end
                 end
             FINISH:
                 begin
                     end_of_file = 1;
                     busy = 0;
                 end
             default:
               begin
                 rst_bytes_counter = 1;
               end
         endcase

     end

     always_ff @(posedge clk)
     begin
         if(reset)
             current_state <= IDLE;
         else
             current_state <= next_state;
     end

     assign debug_leds = current_state;

 endmodule
