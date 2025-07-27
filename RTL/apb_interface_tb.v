`timescale 1ns/1ps

module apb_interface_tb;

reg clk;
reg rst_n;
reg psel;
reg penable;
reg pwrite;
reg [7:0] paddr;
reg [31:0] pwdata;
wire [31:0] prdata;
wire pready;

reg dma_done;
wire dma_start;
wire [15:0] size_dtrans;
wire [31:0] src_reg;
wire [31:0] dst_reg;

// Instantiate DUT
apb_interface uut(
    .clk(clk),
    .rst_n(rst_n),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pready(pready),
    .dma_done(dma_done),
    .dma_start(dma_start),
    .size_dtrans(size_dtrans),
    .src_reg(src_reg),
    .dst_reg(dst_reg)
);

//Automatic task to configure register
task configure_registers;
    input [31:0] src_addr;
    input [31:0] dst_addr;
    input [31:0] ctrl_val;
    
    begin
        // Ghi vào src_reg (Địa chỉ 8'h08)
        $display("Time %0t: Configuring src_reg with address 0x%H", $time, src_addr);
        psel = 1'b1;
        #10;
        penable = 1'b1;
        pwrite = 1'b1;
        paddr = 8'h08;
        pwdata = src_addr;
        #20;
        psel = 1'b0;
        penable = 1'b0;
        pwrite = 1'b0;
        #20;

        // Ghi vào dst_reg (Địa chỉ 8'h0C)
        $display("Time %0t: Configuring dst_reg with address 0x%H", $time, dst_addr);
        psel = 1'b1;
        #10;
        penable = 1'b1;
        pwrite = 1'b1;
        paddr = 8'h0C;
        pwdata = dst_addr;
        #20;
        psel = 1'b0;
        penable = 1'b0;
        pwrite = 1'b0;
        #20;

        // Ghi vào ctrl_reg (Địa chỉ 8'h00)
        $display("Time %0t: Configuring ctrl_reg with value 0x%H", $time, ctrl_val);
        psel = 1'b1;
        #10;
        penable = 1'b1;
        pwrite = 1'b1;
        paddr = 8'h00;
        pwdata = ctrl_val;
        #20;
        psel = 1'b0;
        penable = 1'b0;
        pwrite = 1'b0;
        #50; // Giữ nguyên delay cuối cùng
    end
endtask
// Clock generator
initial begin
    clk = 1;
    forever #5 clk = ~clk;
end


initial begin
    $dumpfile("apb_interface_tb.vcd");
    $dumpvars(0, apb_interface_tb);
	// Init
	psel 	= 0;
	penable = 0;
	pwrite	= 0;
	paddr	= 0;
	pwdata	= 0;
	dma_done= 0;
	
	// Async reset active low
	rst_n = 0;
	#30;
	rst_n = 1;
	configure_registers(32'hC0000155, 32'hC00003D5, 32'b11000000000001000000000000000001);
	#40;
	dma_done =1;
	#10;
	dma_done = 0;
	#10;
	configure_registers(32'hD0000100, 32'hD0000200, 32'h00000003);
	#10;
    $finish;
end

endmodule

