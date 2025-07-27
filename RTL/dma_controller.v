//DMA controller
//	+ Receives configuration from the CPU via the APB bus
//	+ Transfers data from source to destination memory via AXI4, using FIFO buffer.
//	+ DMA process with parallel data read and write
module dma_controller(
	// Clock and reset
	input	clk,
	input	rst_n,
	
	// DMA APB interface
	input		psel,
	input		penable,
	input		pwrite,
	input [7:0]	paddr,
	input [31:0]pwdata,
	output reg [31:0]	prdata,
	output reg			pready,

	//DMA AXI4 Interface
		//Read address: AR channel
	output reg			axi_arvalid,
	output reg 	[31:0]	axi_araddr,
	input				axi_arready,
		//Read data: R channel
	input 				axi_rvalid,
	input		[31:0]	axi_rdata,
	output reg			axi_rready,
		//Write address: AW channel
	output reg			axi_awvalid,
	output reg	[31:0]	axi_awaddr,
	input				axi_awready,
		//Write data : W channel
	output reg			axi_wvalid,
	output reg  [3:0]	axi_wstrb,
	output reg	[31:0]	axi_wdata,
	input				axi_wready,
		//Response: B channel
	input				axi_bvalid,
	output reg			axi_bready
);

// Connection between apb_interface and controller
wire 		dma_start, dma_done;
wire [15:0] size_dtrans;
wire [31:0] src_reg, dst_reg;

// Connection between controller and read_axi4_interface
wire 		start_read;
wire [15:0]	r_size_data;
wire [31:0] raddr_reg;
wire		read_done;

// Connection between controller and write_axi4_interface
wire 		start_write;
wire [15:0]	w_size_data;
wire [31:0] waddr_reg;
wire		write_done;

// Connection between fifo and read/write_axi4_interface
wire		wen, ren;
wire		fifo_full;
wire		fifo_empty;
wire [31:0] data_in;
wire [31:0] data_out;

	//DMA apb_interface module
	apb_interface app_intf0(.clk(clk), 		
							.rst_n(rst_n) ,
							.dma_done(dma_done),	
							.dma_start(dma_start),	
							.size_dtrans(size_dtrans),
							.src_reg(src_reg),		
							.dst_reg(dst_reg),
							.psel(psel),		
							.penable(penable),
							.pwrite(pwrite),
    						.paddr(paddr),
    						.pwdata(pwdata),
    						.prdata(prdata),
    						.pready(pready)
						);

	//DMA controller module
	controller ctrl0(.clk(clk),
					.rst_n(rst_n),
					.dma_start(dma_start),
					.size_dtrans(size_dtrans),
					.src_reg(src_reg),
					.dst_reg(dst_reg),
					.dma_done(dma_done),
					.start_read(start_read),
					.r_size_data(r_size_data),
					.raddr_reg(raddr_reg),
					.read_done(read_done),
					.start_write(start_write),
					.w_size_data(w_size_data),
					.waddr_reg(waddr_reg),
					.write_done(write_done)
				);
	//DMA read_axi4_interface module
	read_axi4_interface	rd_axi40(	.clk(clk),
									.rst_n(rst_n),
									.start_read(start_read),
									.r_size_data(r_size_data),
									.raddr_reg(raddr_reg),
									.read_done(read_done),
									.fifo_full(fifo_full),
									.wen(wen),
									.data_in(data_in),
									.axi_arvalid(axi_arvalid),
									.axi_araddr(axi_araddr),
									.axi_arready(axi_arready),
									.axi_rvalid(axi_rvalid),
									.axi_rdata(axi_rdata),
									.axi_rready(axi_rready)
								);
	
	//DMA fifo module
	fifo fifo0 (	.clk(clk),
    				.rst_n(rst_n),    
					.data_in(data_in),
   					.wen(wen),
    				.fifo_full(fifo_full),
    				.ren(ren),
    				.fifo_empty(fifo_empty),
    				.data_out(data_out)
				);
	
	//DMA write_axi4_interface module
	write_axi4_interface wr_axi40(	.clk(clk),
									.rst_n(rst_n),
    								.start_write(start_write),
    								.w_size_data(w_size_data),
   									.waddr_reg(waddr_reg),
    								.write_done(write_done),
    								.fifo_empty(fifo_empty),
    								.data_out(data_out),
    								.ren(ren),
    								.axi_awvalid(axi_awvalid),
    								.axi_awaddr(axi_awaddr),
    								.axi_awready(axi_awready),
    								.axi_wvalid(axi_wvalid),
    								.axi_wstrb(axi_wstrb),
    								.axi_wdata(axi_wdata),
    								.axi_wready(axi_wready),
    								.axi_bvalid(axi_bvalid),
    								.axi_bready(axi_bready)
								);
endmodule
