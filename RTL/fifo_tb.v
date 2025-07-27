module fifo_tb;
    localparam DATA_WIDTH = 32; 
    reg 					clk;
    reg 					rst_n;
    reg 					wen;
	reg						ren;
    reg	[DATA_WIDTH-1:0]	data_in;
	wire[DATA_WIDTH-1:0]	data_out; 
    wire 					fifo_full;
	wire					fifo_empty; 

    // Instantiate the FIFO under test
    fifo uut (	.clk(clk),	.rst_n(rst_n),
				.wen(wen),	.ren(ren),
				.data_in(data_in),
				.data_out(data_out),
				.fifo_full(fifo_full),
				.fifo_empty(fifo_empty)
				);

    // Task to write data to FIFO
    task write_fifo(input integer loop);
        for (integer i = 0; i < loop; i = i + 1) begin
            if (!fifo_full) begin
                @(posedge clk);
                wen = 1;
                data_in = $random;
                $display("WRITE at %d --> %d", uut.wr_ptr[3:0], data_in); 
                @(posedge clk);
                wen = 0;
            end else begin
                i = i - 1; 
                $display("FULL!");
				@(!fifo_full);
            end
        end
    endtask

    // Task to  read data from FIFO
    task read_fifo(input integer loop);
        for (integer i = 0; i < loop; i = i + 1) begin
            if (!fifo_empty) begin
                @(posedge clk);
                @(posedge clk); 
                @(posedge clk); 
                @(posedge clk); 
                ren = 1;
                $display("READ: at %d <-- %d", uut.rd_ptr[3:0], uut.data_out);
                @(posedge clk); 
                ren = 0;
            end else begin
                i = i - 1; // Decrement counter to retry this read later
                $display("EMPTY!");
                @(!fifo_empty);
            end
        end
    endtask

    // Clock generation
	initial begin
		clk = 1;
    	forever #5 clk = ~clk; 
	end

    // Initial block for reset and primary stimulus
    initial begin
		$dumpfile("fifo_tb.vcd");
		$dumpvars(0, fifo_tb);
        rst_n = 0; 
        wen = 0;
        ren = 0;
        data_in = 0;

        #20 rst_n = 1; 
    end
    initial begin
        @(posedge clk); // wait 1 cycle for rst signal
        write_fifo(40); // Attempt to write 40 items

        #200 $finish; // End simulation after 200ns after writes
    end
    initial begin
        @(posedge clk); // wait 1 cycle for rst signal
        read_fifo(40); // Attempt to read 40 items
    end

endmodule
