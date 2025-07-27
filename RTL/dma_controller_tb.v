
`timescale 1ns/1ps

module dma_controller_tb;
    reg clk = 0;
    reg rst_n = 0;

    always #5 clk = ~clk;

    // --- APB Bus ---
    wire        psel;
    wire        penable;
    wire        pwrite;
    wire [7:0]  paddr;
    wire [31:0] pwdata;
    wire [31:0] prdata;
    wire        pready;

    reg         apb_start;
    reg         apb_rw;
    reg  [7:0]  apb_addr;
    reg  [31:0] apb_wdata;
    wire [31:0] apb_rdata;
    wire        apb_idle;
    wire        apb_busy;

    // AXI Write Address Channel
    wire        axi_awvalid;
    wire [31:0] axi_awaddr;
    wire        axi_awready;

    // AXI Write Data Channel
    wire        axi_wvalid;
    wire [31:0] axi_wdata;
    wire [3:0]  axi_wstrb;
    wire        axi_wready;

    // AXI Write Response Channel
    wire        axi_bvalid;
    wire        axi_bready;

    // AXI Read Address Channel
    wire        axi_arvalid;
    wire [31:0] axi_araddr;
    wire        axi_arready;

    // AXI Read Data Channel
    wire        axi_rvalid;
    wire [31:0] axi_rdata;
    wire        axi_rready;

    dma_controller dma_inst (
    .clk(clk),
    .rst_n(rst_n),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .axi_awvalid(axi_awvalid),
    .axi_awaddr(axi_awaddr),
    .axi_awready(axi_awready),
    .axi_wvalid(axi_wvalid),
    .axi_wdata(axi_wdata),
    .axi_wstrb(axi_wstrb),
    .axi_wready(axi_wready),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    .axi_arvalid(axi_arvalid),
    .axi_araddr(axi_araddr),
    .axi_arready(axi_arready),
    .axi_rvalid(axi_rvalid),
    .axi_rdata(axi_rdata),
    .axi_rready(axi_rready)
);
apb_master apb_m (
    .clk(clk),
    .rst_n(rst_n),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .start(apb_start),
    .rw(apb_rw),
    .addr(apb_addr),
    .wdata(apb_wdata),
    .rdata(apb_rdata),
    .idle(apb_idle),
    .busy(apb_busy)
);
axi4_ram_slave mem (
    .clk(clk),
    .rst_n(rst_n),
    .awvalid(axi_awvalid),
    .awaddr(axi_awaddr),
    .awready(axi_awready),
    .wvalid(axi_wvalid),
    .wdata(axi_wdata),
    .wstrb(axi_wstrb),
    .wready(axi_wready),
    .bvalid(axi_bvalid),
    .bready(axi_bready),
    .arvalid(axi_arvalid),
    .araddr(axi_araddr),
    .arready(axi_arready),
    .rvalid(axi_rvalid),
    .rdata(axi_rdata),
    .rready(axi_rready)
);

    task automatic apb_write(input [7:0] addr, input [31:0] data);
        @(posedge clk);
        while (!apb_idle) @(posedge clk);
        apb_addr  = addr;
        apb_wdata = data;
        apb_rw    = 1;
        apb_start = 1;
        @(posedge clk);
        apb_start = 0;
        while (!apb_idle) @(posedge clk);
    endtask

    task automatic run_dma_test(
        input [31:0] src_addr,
        input [31:0] dst_addr,
        input [15:0] size
    );
        integer i;
        apb_write(4'h8, src_addr);
        apb_write(4'hC, dst_addr);
        apb_write(4'h0, {size, 16'h0001}); // Start = 1

        #10000;

        for (i = 0; i < (size + 3) / 4; i = i + 1) begin
            int src_idx = (src_addr >> 2) + i;
            int dst_idx = (dst_addr >> 2) + i;
            if (dma_controller_tb.mem.mem[dst_idx] !== dma_controller_tb.mem.mem[src_idx]) begin
                $display("[ERROR] Mismatch at word %0d: src[%h]=%h dst[%h]=%h", i,src_addr,
                         dma_controller_tb.mem.mem[src_idx],dst_addr, dma_controller_tb.mem.mem[dst_idx]);
                $fatal;
            end
        end
        $display("[PASS] DMA transferred and verified %0d bytes from %08x to %08x.", size, src_addr, dst_addr);
    endtask

    initial begin
        $display("[TB] Starting DMA Test");
        $dumpfile("dma_controller_tb.vcd");
        $dumpvars(0, dma_controller_tb);
        $dumpvars(0, dma_controller_tb.dma_inst);
        $dumpvars(0, dma_controller_tb.apb_m);
        $dumpvars(0, dma_controller_tb.mem);

        rst_n = 0;
        #50;
        rst_n = 1;

        // Test Case 1: Aligned, 64 bytes
        run_dma_test(32'h00000000, 32'h00008000, 64);

        // Test Case 2: Aligned, 256 bytes
        run_dma_test(32'h00004000, 32'h0000C000, 256);
		 
		//Teset Case 3:Aligned, 14 bytes
		//run_dma_test(32'h00000200, 32'h0000fffa, 10);	

		run_dma_test(32'h00000200, 32'h00000C00, 14);



        //$display("[ALL PASS] All test cases passed.");
        $finish;
    end
endmodule

