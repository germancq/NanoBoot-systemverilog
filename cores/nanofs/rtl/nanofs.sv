/**
 * @Author: German Cano Quiveu <germancq>
 * @Email:  germancq@dte.us.es
 * @Filename: nanofs.v
 */


 module nanofs(
 	input clk,
 	input reset,
 	input start,
 	
	input enable_mbr,

 	output logic adapter_rst,
 	output logic adapter_start,
	input next_byte,
	output busy,
	output [7:0] byte_data,
 	output end_of_file,
 	
 	
 	
 	output logic file_not_found,
 	output logic err,
    
	input [7:0] filename [15:0],
 	input cmd_18,

 	//spi
    input   spi_busy,
	output  [31:0] spi_block_addr,
	input   [7:0] spi_data_out,
	output  spi_r_block,
	output  spi_r_byte,
	output  spi_r_multi_block,
	output  logic spi_rst,
	input   spi_err,

 	output logic idle_signal,
 	output logic finish_signal,

 	output [31:0] debug_data
   //input btn_debug

 );

 logic [31:0] begin_nanofs_partition;



 logic [31:0] mbr_start_reg;
 logic mbr_nanofs_reset;
 logic mbr_nanofs_start;
 logic mbr_nanofs_err;
 logic mbr_nanofs_success;
 logic mbr_to_spi_block;
 logic mbr_to_spi_byte;
 logic [31:0]mbr_to_spi_address;
 look_up_mbr_partition mbr0(
	.clk (clk),
	.reset (mbr_nanofs_reset),
	.err_signal (mbr_nanofs_err),
	.success (mbr_nanofs_success),
	.start (mbr_nanofs_start),
	.start_reg (mbr_start_reg),
	//spi
	.spi_r_block (mbr_to_spi_block),
	.spi_r_byte (mbr_to_spi_byte),
	.spi_busy (spi_busy),
	.spi_err (spi_err),
	.spi_block_addr(mbr_to_spi_address),
	.spi_data_out(spi_data_out),
	.debug_leds ()
  );


 logic [31:0] init_start_reg;
 logic init_nanofs_reset;
 logic init_nanofs_start;
 logic init_nanofs_err;
 logic init_nanofs_success;
 logic init_to_spi_block;
 logic init_to_spi_byte;
 logic [31:0]init_to_spi_address;
 init_nanofs init0(
 	.clk (clk),
 	.reset (init_nanofs_reset),
 	.err_signal (init_nanofs_err),
 	.success (init_nanofs_success),
 	.start (init_nanofs_start),
 	.begin_address(begin_nanofs_partition),
 	.start_reg (init_start_reg),
 	//spi
 	.spi_r_block (init_to_spi_block),
 	.spi_r_byte (init_to_spi_byte),
 	.spi_busy (spi_busy),
 	.spi_err (spi_err),
 	.spi_block_addr(init_to_spi_address),
 	.spi_data_out(spi_data_out),
 	.debug_leds ()
 );


 logic [31:0] search_start_reg;
 //reg [31:0] search_begin_address;
 logic search_nanofs_reset;
 logic search_nanofs_start;
 logic search_nanofs_err;
 logic search_nanofs_success;
 logic search_to_spi_block;
 logic search_to_spi_byte;
 logic [31:0]search_to_spi_address;
 search_nanofs search0(
 	.clk (clk),
 	.reset (search_nanofs_reset),
 	.err (search_nanofs_err),
 	.success (search_nanofs_success),
 	.offset(begin_nanofs_partition),
 	.start (search_nanofs_start),
 	.begin_address(init_start_reg),
 	.start_reg (search_start_reg),
	.filename(filename), 
 	//spi
 	.spi_r_block (search_to_spi_block),
 	.spi_r_byte (search_to_spi_byte),
 	.spi_busy (spi_busy),
 	.spi_err (spi_err),
 	.spi_block_addr(search_to_spi_address),
 	.spi_data_out(spi_data_out),
 	.debug_leds (),
 	.debug_7_seg ()
 	//.btn_debug(btn_debug)
 );


 logic execute_nanofs_reset;
 logic execute_nanofs_start;
 logic execute_to_spi_block;
 logic execute_to_spi_byte;
 logic [31:0]execute_to_spi_address;

 logic busy_single;
 logic busy_multi;

 logic eof_single;
 logic eof_multi;

 logic [7:0] data_single;
 logic [7:0] data_multi;

 logic block_single;
 logic block_multi;

 logic rbyte_single;
 logic rbyte_multi;

 logic [31:0] addr_multi;
 logic [31:0] addr_single;

 execute_nanofs_multiblock execute0(
 	.clk (clk),
 	.reset (execute_nanofs_reset | (~cmd_18)),
 	.start (execute_nanofs_start & cmd_18),
 	.offset(begin_nanofs_partition),
 	.begin_address(search_start_reg),
 	.req_byte(next_byte),
 	.busy(busy_multi),
 	.end_of_file(eof_multi),
 	.byte_data (data_multi),
 	//spi
 	.spi_r_multi_block (block_multi),
 	.spi_r_byte (rbyte_multi),
 	.spi_busy (spi_busy),
 	.spi_err (spi_err),
 	.spi_block_addr(addr_multi),
 	.spi_data_out(spi_data_out),
 	//.btn_debug(btn_debug),
 	.debug_leds (),
 	.debug_7_seg ()
 );

 execute_nanofs execute1(
 	.clk (clk),
 	.reset (execute_nanofs_reset | cmd_18),
 	.start (execute_nanofs_start & (~cmd_18)),
 	.offset(begin_nanofs_partition),
 	.begin_address(search_start_reg),
 	.req_byte(next_byte),
 	.busy(busy_single),
 	.end_of_file(eof_single),
 	.byte_data (data_single),
 	//spi
 	.spi_r_block (block_single),
 	.spi_r_byte (rbyte_single),
 	.spi_busy (spi_busy),
 	.spi_err (spi_err),
 	.spi_block_addr(addr_single),
 	.spi_data_out(spi_data_out),
 	//.btn_debug(btn_debug),
 	.debug_leds (),
 	.debug_7_seg ()
 );


 mux #(.DATA_WIDTH(1)) mux_cmd18_1(
     .a(busy_single),
     .b(busy_multi),
     .c(busy),
     .sel(cmd_18)
 );

 mux #(.DATA_WIDTH(1)) mux_cmd18_2(
     .a(eof_single),
     .b(eof_multi),
     .c(end_of_file),
     .sel(cmd_18)
 );

 mux #(.DATA_WIDTH(8)) mux_cmd18_3(
     .a(data_single),
     .b(data_multi),
     .c(byte_data),
     .sel(cmd_18)
 );

 mux #(.DATA_WIDTH(32)) mux_cmd18_4(
     .a(addr_single),
     .b(addr_multi),
     .c(execute_to_spi_address),
     .sel(cmd_18)
 );

 mux #(.DATA_WIDTH(1)) mux_cmd18_5(
     .a(rbyte_single),
     .b(rbyte_multi),
     .c(execute_to_spi_byte),
     .sel(cmd_18)
 );



 logic [1:0] sel_mux;



 mux_4 #(.DATA_WIDTH(1)) mux1(
     .a(mbr_to_spi_block),
     .b(init_to_spi_block),
     .c(search_to_spi_block),
     .d(block_single),
     .sel(sel_mux),
     .e (spi_r_block)
 );

 mux_4 #(.DATA_WIDTH(1)) mux2(
     .a(mbr_to_spi_byte),
     .b(init_to_spi_byte),
     .c(search_to_spi_byte),
     .d(execute_to_spi_byte),
     .sel(sel_mux),
     .e (spi_r_byte)
 );

 mux_4 #(.DATA_WIDTH(32)) mux3(
     .a(mbr_to_spi_address),
     .b(init_to_spi_address),
     .c(search_to_spi_address),
     .d(execute_to_spi_address),
     .sel(sel_mux),
     .e (spi_block_addr)
 );



 mux_4 #(.DATA_WIDTH(1)) mux4(
     .a(0),
     .b(0),
     .c(0),
     .d(block_multi),
     .sel(sel_mux),
     .e (spi_r_multi_block)
 );

  assign begin_nanofs_partition = enable_mbr==1 ? mbr_start_reg : 32'h0;


 //assign debug_data = spi_block_addr;

 logic [3:0] current_state;
 logic [3:0] next_state;

 localparam IDLE = 4'h0;
 localparam RESET_SPI = 4'h1;
 localparam PRE_MBR_NANOFS = 4'h2;
 localparam MBR_NANOFS = 4'h3;
 localparam PRE_INIT_NANOFS = 4'h4;
 localparam INIT_NANOFS = 4'h5;
 localparam PRE_SEARCH_NANOFS = 4'h6;
 localparam SEARCH_NANOFS = 4'h7;
 localparam PRE_EXECUTE_NANOFS = 4'h8;
 localparam EXECUTE_NANOFS = 4'h9;
 localparam ERROR = 4'hA;
 localparam NOT_FILE = 4'hB;
 localparam END_FSM = 4'hC;

 always_comb
 begin
	sel_mux = 2'b00;

	adapter_rst = 1'b0;
	adapter_start = 1'b1;

	spi_rst = 1'b0;

	idle_signal = 1'b0;
	finish_signal = 1'b0;

 	next_state = current_state;
	mbr_nanofs_start = 1'b0; 
	mbr_nanofs_reset = 1'b0; 
 	init_nanofs_start = 1'b0;
 	init_nanofs_reset = 1'b0;
 	search_nanofs_start = 1'b0;
    search_nanofs_reset = 1'b0;
    execute_nanofs_start = 1'b0;
    execute_nanofs_reset = 1'b0;
 	err = 1'b0;
 	file_not_found = 1'b0;
 	case(current_state)
 		IDLE:
 			begin
 				idle_signal = 1'b1;
 				
 				adapter_rst = 1'b1;
 				adapter_start = 1'b0;
				mbr_nanofs_reset = 1'b1; 
 			    init_nanofs_reset = 1'b1;
 			    search_nanofs_reset = 1'b1;
 			    execute_nanofs_reset = 1'b1;
				spi_rst = 1'b1;
 				if(start == 1'b1)
 					next_state = RESET_SPI;
 			end
		RESET_SPI:
			begin
				if(spi_busy == 1'b0) begin
					if(enable_mbr == 1'b1) begin
						next_state = PRE_MBR_NANOFS;
					end
					else begin
						next_state = PRE_INIT_NANOFS;
					end
				end
			end	 
		PRE_MBR_NANOFS :
			begin
				sel_mux = 2'b00;
				next_state = MBR_NANOFS;
			end	
		MBR_NANOFS :
			begin
				mbr_nanofs_start = 1'b1;
				sel_mux = 2'b00;

				if(mbr_nanofs_success) begin
					next_state = PRE_INIT_NANOFS;
				end
				if(mbr_nanofs_err) begin
					next_state = ERROR;
				end
			end	
 		PRE_INIT_NANOFS:
 		    begin
 		      
               sel_mux = 2'b01;
               next_state = INIT_NANOFS;
 		    end
 		INIT_NANOFS:
 			begin
 			    
 				init_nanofs_start = 1'b1;
 				
 				sel_mux = 2'b01;

 				if(init_nanofs_success)
 				    next_state = PRE_SEARCH_NANOFS;
 				else if(init_nanofs_err)
 				    next_state = ERROR;

 			end
 		PRE_SEARCH_NANOFS:
 		     begin
 		          
 		          sel_mux = 2'b10;

 		          next_state = SEARCH_NANOFS;
 		     end
 		SEARCH_NANOFS:
 		      begin
 		          
 		          sel_mux = 2'b10;
 		          search_nanofs_start = 1'b1;
                  


                   if(search_nanofs_success)
                       next_state = PRE_EXECUTE_NANOFS;
                   else if(search_nanofs_err)
                       next_state = NOT_FILE;

 		      end
		PRE_EXECUTE_NANOFS:
			begin
					
					sel_mux = 2'b11;
					next_state = EXECUTE_NANOFS;
			end
		EXECUTE_NANOFS:
				begin
					
					sel_mux = 2'b11;
					
					execute_nanofs_start = 1'b1;
					if(end_of_file)
						next_state = END_FSM;
				end
		END_FSM:
				begin
					finish_signal = 1'b1;
					
				end
		ERROR:
				begin
						err = 1'b1;
				end
		NOT_FILE:
				begin
					file_not_found = 1'b1;
					err = 1'b1;
				end
		default:next_state = IDLE;
 	endcase
 end

 always_ff @(posedge clk)
 begin

 	if(reset == 1'b1)
 		current_state <= IDLE;
 	else
 		current_state <= next_state;
 end

 
 assign debug_data = current_state;

 endmodule : nanofs





