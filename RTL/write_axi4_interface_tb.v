`timescale 1ns/1ps

module write_axi4_interface_tb;
reg			clk;
reg			rst_n;
reg			start_write;
reg [15:0]	w_size_data;
reg [31:0]	waddr_reg;
wire		write_done;
//FIFO interface
reg 		fifo_empty;
reg [31:0]	data_out;
wire		ren;
//Interact with AXI4 slave
wire		axi_awvalid;
wire[31:0] 	axi_awaddr;
reg			axi_awready;
wire		axi_wvalid;
wire [3:0] 	axi_wstrb;
wire[31:0] 	axi_wdata;
reg			axi_wready;
reg			axi_bvalid;
wire		axi_bready;
    // Instantiate DUT
    write_axi4_interface dut (
        .clk(clk),
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
reg [31:0] mem[0:256];
wire [13:0] awidx = axi_awaddr[15:2]; 
// AXI Write channel stimulus
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        axi_awready <= 0;
        axi_wready  <= 0;
        axi_bvalid  <= 0;
    end else begin
        // Write Address channel
        if (axi_awvalid && !axi_awready) begin
            axi_awready <= 1;
        end else begin
            axi_awready <= 0;
        end

        // Write Data channel
        if (axi_wvalid && !axi_wready) begin
            axi_wready <= 1;
            if (axi_wstrb[0]) mem[awidx][7:0]   <= axi_wdata[7:0];
            if (axi_wstrb[1]) mem[awidx][15:8]  <= axi_wdata[15:8];
            if (axi_wstrb[2]) mem[awidx][23:16] <= axi_wdata[23:16];
            if (axi_wstrb[3]) mem[awidx][31:24] <= axi_wdata[31:24];
            $display("AXI WRITE -> addr: 0x%0h (index %0d), data: 0x%h", axi_awaddr, awidx, axi_wdata);
            axi_bvalid <= 1;
        end else begin
            axi_wready <= 0;
        end

        // Write Response channel
        if (axi_bvalid && axi_bready) begin
            axi_bvalid <= 0;
        end
    end
end

// Clock generation
initial begin
   clk = 1;
   forever #5 clk = ~clk;
end
// In kết quả sau khi write_done
always @(posedge clk) begin
    if (write_done) begin
        $display("====== Dumping Memory After Write ======");
        for (integer i = 0; i < 256; i = i + 1) begin
            $display("mem[%0d] = 0x%08h", i, mem[i]);
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 32'h12345678;
    end else if (ren) begin
        data_out <= data_out + 32'h11111111;  // hoặc dùng $random nếu muốn
    end
end
// Stimulus
    initial begin
        $dumpfile("write_axi4_interface_tb.vcd");
        $dumpvars(0, write_axi4_interface_tb);

        // Initialize
        rst_n = 0;
        fifo_empty = 0;
        data_out = 32'h12345678;
        axi_awready = 0;
        axi_wready = 0;
        axi_bvalid = 0;
		start_write = 0;
        w_size_data = 16'h000E;     // 3 words = 14 bytes
        waddr_reg = 31'h0000_0004;
        #10;
        rst_n = 1;


        // Start write
        start_write = 1;
        #10;
        start_write = 0;
		#400;
		start_write = 1;
        #10;
        start_write = 0;
		#120;
		fifo_empty = 1;
		#50;
		fifo_empty = 0;
        // Change FIFO data every cycle when ren is high
		end
           

    // Stop simulation after some time
    initial begin
        #800;
        $finish;
    end

endmodule
