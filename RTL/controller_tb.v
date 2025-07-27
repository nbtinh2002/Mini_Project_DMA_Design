`timescale 1ns/1ps

module controller_tb;
    reg clk;
    reg	rst_n;

    // Interact with apb_interface module
    reg         dma_start;           // 1-pulse từ apb
    reg	[15:0]  size_dtrans;
    reg [31:0]  src_reg;
    reg [31:0]  dst_reg;
    wire		dma_done;

    // Interact with read_axi4_interface module
    wire        start_read;
    wire [15:0] r_size_data;
    wire [31:0] raddr_reg;
	reg         read_done;

    // Interact with write_axi4_interface module
    wire        start_write;
    wire [15:0] w_size_data;
    wire [31:0] waddr_reg;
    reg         write_done;

  // Instantiate DUT
  controller uut (
    .clk(clk),
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

  // Clock generator
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    $dumpfile("controller_tb.vcd");
    $dumpvars(0, controller_tb);

    clk         = 1;
    rst_n       = 0;
    dma_start   = 0;
    size_dtrans = 0;
    src_reg     = 0;
    dst_reg     = 0;
    read_done   = 0;
    write_done  = 0;
    // Reset
    #20;
    rst_n = 1;

    // Trigger DMA start
    @(posedge clk);
    size_dtrans = 16'h0010;
    src_reg     = 32'hA000_0000;
    dst_reg     = 32'hB000_0000;
       
	@(posedge clk) dma_start = 1;
    @(posedge clk) dma_start = 0;
	repeat(5) @(posedge clk);

	@(posedge clk) read_done = 1;
    @(posedge clk) read_done = 0;
	repeat(5) @(posedge clk);

	@(posedge clk) write_done = 1;
    @(posedge clk) write_done = 0;
	repeat(5) @(posedge clk);
    $finish;
  end
endmodule
