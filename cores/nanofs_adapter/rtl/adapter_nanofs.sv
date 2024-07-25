module adapter_nanofs #(parameter N = 32)
(
    input clk,
    input rst,
    input start,

    input busy_nanofs,
    output logic next_byte_nanofs,
    input [7:0] nanofs_data,

    input next_data,
    output logic busy,
    output [N-1:0] data_out
);


    genvar i;

    logic [0:0] reg_data_cl [(N>>3)-1:0];
    logic [0:0] reg_data_w [(N>>3)-1:0];

    generate
        for (i=0 ;i<(N>>3);i=i+1) begin
            register #(.DATA_WIDTH(8)) reg_data_i(
                .clk(clk),
                .cl(reg_data_cl[i]),
                .w(reg_data_w[i]),
                .din(nanofs_data),
                .dout(data_out[(i<<3)+7:(i<<3)])
            );
        end
    endgenerate


    logic counter_rst;
    logic counter_up;
    logic [31:0] counter_o;
    counter #(.DATA_WIDTH(32)) counter_impl(
        .clk(clk),
        .rst(counter_rst),
        .up(counter_up),
        .down(1'b0),
        .din(32'h0),
        .dout(counter_o)
    );


    logic [1:0] current_state;
    logic [1:0] next_state;
    localparam IDLE = 2'h0; 
    localparam WAIT_NANOFS = 2'h1; 
    localparam READ_BYTE = 2'h2; 
    localparam DATA_READY = 2'h3; 


    always_comb begin
        
        next_state = current_state;

        busy = 1'b1;
        next_byte_nanofs = 1'b0;

        counter_rst = 1'b0;
        counter_up = 1'b0;

        reg_data_cl = '{default:0};
        reg_data_w = '{default:0};

        case(current_state)
            IDLE : 
                begin
                    counter_rst = 1'b1;
                    if (start == 1'b1) begin
                        next_state = WAIT_NANOFS;
                    end
                end    
            WAIT_NANOFS :
                begin
                    if (busy_nanofs == 1'b0) begin
                        if(counter_o == (N>>3)) begin
                            next_state = DATA_READY;
                        end
                        else begin
                            next_state = READ_BYTE;
                        end
                    end
                end    
            READ_BYTE :
                begin
                    reg_data_w[counter_o] = 1'b1;
                    counter_up = 1'b1;
                    next_byte_nanofs = 1'b1;

                    next_state = WAIT_NANOFS;
                end        
            DATA_READY : 
                begin
                    busy = 0;
                    counter_rst = 1'b1;
                    if(next_data == 1'b1) begin
                        next_state = WAIT_NANOFS;
                    end
                end    
                
            default:;
        endcase

    end

    always_ff @(posedge clk)
    begin
        if(rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

endmodule : adapter_nanofs