//DMA controller:
//	+ receive address forward to two FSM(read and write)
//	+ control logic to start read FSM and write FSM
//	+ infrom current state of DMA process to apb_interface
module controller(
	// Clock and reset
    input	clk,
    input   rst_n,

    // Interact with apb_interface module
    input               dma_start, // 1-pulse từ apb
    input       [15:0]  size_dtrans,
    input       [31:0]  src_reg,
    input       [31:0]  dst_reg,
    output reg          dma_done,

    // Interact with read_axi4_interface module
    output reg          start_read,
    output reg  [15:0]  r_size_data,
    output reg  [31:0]  raddr_reg,
	input               read_done,


    // Interact with write_axi4_interface module
    output reg          start_write,
    output reg  [15:0]  w_size_data,
    output reg  [31:0]  waddr_reg,
    input               write_done
);

localparam [31:0] IDLE = 0, WAIT_DONE = 1;
reg state;
reg read_completed;
localparam [31:0] RAM_LIMIT = 32'h0001_0000;
// Controller logic for DMA process
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dma_done	<= 0;
		start_read	<= 0;
		r_size_data	<= 0;
		raddr_reg	<= 0;
		start_write	<= 0;
		w_size_data	<= 0;
		waddr_reg	<= 0;
		state		<= IDLE;
		read_completed	<= 0;
	end else begin
		dma_done	<= 0;
		start_read	<= 0;
		start_write	<= 0;
		case(state)
			IDLE: begin
					read_completed	<= 0;
					if(dma_start&&(dst_reg+size_dtrans<RAM_LIMIT)&&(src_reg+size_dtrans<RAM_LIMIT)) begin
						start_read	<= 1;
						start_write	<= 1;
						r_size_data	<= size_dtrans;
						w_size_data	<= size_dtrans;
						raddr_reg	<= src_reg;
						waddr_reg	<= dst_reg;
						state		<= WAIT_DONE;
					end else begin
						dma_done	<= 1;
					end
			end
			WAIT_DONE: begin
					start_read		<= 0;
					start_write		<= 0;
					if(read_done) begin
						read_completed	<= 1;
					end
					if(write_done&&read_completed) begin
						dma_done	<= 1;
						state		<= IDLE;
					end
					
			end
			default:;
		endcase
	end
end
endmodule



