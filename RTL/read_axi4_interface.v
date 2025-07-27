//DMA read FSM:
//	+ interact with AXI4 ram to get data from source address
//	+ save data to fifo 
module read_axi4_interface(
	// Clock and reset
	input	clk,
	input 	rst_n,

	//control signal from Controller
	input 		 start_read,
	input [15:0] r_size_data,
	input [31:0] raddr_reg,
	output reg	 read_done,

	//FIFO interface
	input		 	fifo_full,
	output reg		wen,
	output reg[31:0]data_in,

	//Interact with AXI4 slave
		//AR channel
	output reg		axi_arvalid,
	output reg[31:0]axi_araddr,
	input 			axi_arready,
		//R channel
	input			axi_rvalid,
	input [31:0]	axi_rdata,
	output reg		axi_rready
	);

reg [1:0] r_state;
reg [16:0] read_cnt;
localparam R_IDLE = 0, R_ADDR = 1, R_DATA = 2;

//DMA read FSM logic
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		read_done	<= 0;
		wen			<= 0;
		data_in		<= 0;
        axi_arvalid <= 0;
        axi_araddr  <= 0;
        axi_rready 	<= 0;
		read_cnt	<= 0;
		r_state		<= R_IDLE;
    end else begin
		wen			<= 0;
		read_done	<= 0;
        case(r_state)
			R_IDLE: begin
        			axi_arvalid <= 0;
        			axi_araddr  <= 0;
					read_cnt	<= 0;
					if(start_read) begin
						r_state	<= R_ADDR;
					end
			end
            R_ADDR: begin
					axi_araddr	<= raddr_reg + read_cnt;
					if(!axi_arvalid) begin
						axi_arvalid	<= 1;
					end
					if(axi_arvalid&&axi_arready) begin
						axi_arvalid	<= 0;	
						r_state		<= R_DATA;
					end
			end
           	R_DATA: begin
					if(axi_rvalid&&!fifo_full) begin
						axi_rready	<= 1;
						data_in		<= axi_rdata;
					end 
					if(axi_rvalid&&axi_rready&&(!fifo_full)) begin
						wen			<= 1;
						axi_rready	<= 0;
						read_cnt	<= read_cnt + 4;
						if(read_cnt+4 < r_size_data) begin
							r_state		<= R_ADDR;
						end else begin
							read_done	<= 1;
							r_state		<= R_IDLE;
						end
					end 
			end
			default:begin
					r_state <= R_IDLE;
					end
        endcase
	end
end
endmodule

