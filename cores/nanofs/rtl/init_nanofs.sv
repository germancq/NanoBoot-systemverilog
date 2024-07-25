/**
 * @Author: German Cano Quiveu <germancq>
 * @Date:   2018-11-13T12:23:25+01:00
 * @Email:  germancq@dte.us.es
 * @Filename: init_nanofs.v
 * @Last modified by:   germancq
 * @Last modified time: 2018-11-13T12:38:24+01:00
 */



//comprueba bloque 0, superblock para que sea nanofs
module init_nanofs(
	input clk,
	input reset,
	output logic err_signal,
	output logic success,
	input start,
	input [31:0] begin_address,
	output [31:0] start_reg,
	//spi
	output logic spi_r_block,
	output logic spi_r_byte,
	input spi_busy,
	input spi_err,
	output [31:0] spi_block_addr,
	input [7:0] spi_data_out,
	output [3:0] debug_leds
);


wire [7:0] magic_number_0,magic_number_1;
wire [7:0] block_size;
wire [7:0] begin_reg_0,begin_reg_1,begin_reg_2,begin_reg_3;

logic block_size_cl;
logic block_size_w;
register #(.DATA_WIDTH(8)) r0(
    .clk (clk),
	.cl (block_size_cl),
	.w (block_size_w),
	.din (spi_data_out),
	.dout (block_size)
);

genvar i;


logic [0:0] magic_number_cl [1:0];
logic [0:0] magic_number_w [1:0];
logic [15:0] magic_number;
generate
	for (i=0 ; i<2 ;i=i+1) begin
		register #(.DATA_WIDTH(8)) r_magic_number_i(
			.clk (clk),
			.cl (magic_number_cl[i]),
			.w (magic_number_w[i]),
			.din (spi_data_out),
			.dout (magic_number[(i<<3)+7:(i<<3)])
		);
	end
endgenerate


logic [0:0] begin_reg_cl [3:0];
logic [0:0] begin_reg_w [3:0];
generate
	for (i=0 ; i<4 ;i=i+1) begin
		register #(.DATA_WIDTH(8)) r_begin_reg_i(
			.clk (clk),
			.cl (begin_reg_cl[i]),
			.w (begin_reg_w[i]),
			.din (spi_data_out),
			.dout (start_reg[(i<<3)+7:(i<<3)])
		);
	end
endgenerate


logic [3:0] next_state;
logic [3:0] current_state;

localparam IDLE = 4'h0;
localparam READ_BLOCK = 4'h1;
localparam WAIT_BLOCK = 4'h2;
//superblock
localparam READ_DATA = 4'h3;
localparam READ_BYTE = 4'h4;
localparam WAIT_BYTE = 4'h5;
localparam CHECK_SUPERBLOCK = 4'h6;
localparam SUCCESS = 4'h7;
localparam ERROR = 4'h8;
localparam SPI_ERR = 4'h9;

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

assign spi_block_addr = begin_address;


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

	block_size_cl = 0;
	block_size_w = 0;

	magic_number_cl[0] = 0;
    magic_number_w[0] = 0;

    magic_number_cl[1] = 0;
    magic_number_w[1] = 0;

    begin_reg_cl[0] = 0;
    begin_reg_w[0] = 0;

    begin_reg_cl[1] = 0;
    begin_reg_w[1] = 0;

    begin_reg_cl[2] = 0;
    begin_reg_w[2] = 0;

    begin_reg_cl[3] = 0;
    begin_reg_w[3] = 0;


	case(current_state)
		IDLE:
			begin

				block_size_cl = 1;
				magic_number_cl[0] = 1;
				magic_number_cl[1] = 1;
				begin_reg_cl[0] = 0;
				begin_reg_cl[1] = 0;
				begin_reg_cl[2] = 0;
				begin_reg_cl[3] = 0;

				rst_bytes_counter = 1;
				if(start == 1'b1)
				    next_state = READ_BLOCK;
			end
		READ_BLOCK:
			begin
			 if(spi_busy == 1'b0)
			 begin
				spi_r_block = 1;
                next_state = WAIT_BLOCK;
             end
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
				    32'h0:magic_number_w[0] = 1;
				    32'h1:magic_number_w[1] = 1;
				    32'h2:block_size_w = 1;
				    32'h3:;
				    32'h4:begin_reg_w[0] = 1;
				    32'h5:begin_reg_w[1] = 1;
				    32'h6:begin_reg_w[2] = 1;
				    32'h7:begin_reg_w[3] = 1;
				    default:next_state = CHECK_SUPERBLOCK;
				endcase
			end
		CHECK_SUPERBLOCK:
			begin
				if(magic_number == 16'h4e61 && block_size == 8'h01)
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
		SPI_ERR:
			begin
				
				err_signal = 1;
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
