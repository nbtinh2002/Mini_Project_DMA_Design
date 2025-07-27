`timescale 1ns/1ps

module read_axi4_interface_tb;

reg clk;
reg rst_n;
reg start_read;
reg [15:0] r_size_data;
reg [31:0] raddr_reg;
wire read_done;

// FIFO interface
reg fifo_full;
wire		wen;
wire [31:0] data_in;

// AXI4 interface
wire        axi_arvalid;
wire [31:0] axi_araddr;
reg         axi_arready;

reg         axi_rvalid;
reg [31:0]  axi_rdata;
wire        axi_rready;

// Instantiate DUT
read_axi4_interface dut (
    .clk(clk),
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

// Fake memory (simulate AXI4 RAM)
reg [31:0] mem [0:255]; // 256 x 32-bit = 1KB

// Clock generation
initial begin
	clk = 0;
	forever #5 clk = ~clk;
end

// AXI Read logic simulation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_arready <= 0;
        axi_rvalid  <= 0;
        axi_rdata   <= 0;
    end else begin
        // Simulate AR handshake
		if (!axi_arready && axi_arvalid) begin
                axi_arready <= 1; 
            end else begin
                axi_arready <= 0; 
            end

        //axi_arready <= axi_arvalid;

        // Simulate R handshake
        if (axi_arvalid && axi_arready) begin
            // Read data from mem
            axi_rvalid <= 1;
            axi_rdata  <= mem[axi_araddr[9:2]];  // assuming word-aligned access
        end else if (axi_rvalid && axi_rready) begin
            axi_rvalid <= 0;
        end
    end
end
integer i;
// Simulation sequence
initial begin
    // Dump waveform
    $dumpfile("read_axi4_interface_tb.vcd");
    $dumpvars(0, read_axi4_interface_tb);

    // Reset and init
	// Init memory
    for (i = 0; i < 256; i = i + 1) begin
        mem[i] = 32'hA000_0000 + i; // Example data
    end

    rst_n = 0;
    fifo_full = 0;
    axi_arready = 0;
    axi_rvalid  = 0;
    axi_rdata   = 0;
    raddr_reg   = 32'h0000_000A;  // start addr
    r_size_data = 16'h000C;       // 12 bytes = 3 words
    start_read  = 0;

    
    #20;
    rst_n = 1;
    #10;

    // Start DMA read
    start_read = 1;
    #10;
    start_read = 0;

    #250;

    // Start DMA read
    start_read = 1;
    #10;
    start_read = 0;
	#70;
	fifo_full = 1;
	#40;
	fifo_full =0;
#100;	
    $finish;
end

endmodule
