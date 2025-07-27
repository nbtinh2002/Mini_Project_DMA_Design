//DMA FIFO:
//	+ A buffer between the read and write paths
//	+ pushs data into FIFO
//	+ pulls data from FIFO
module fifo #(
	// Width of data and address fifo
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4
)(
	// Clock and reset
    input	clk,	
    input 	rst_n,		
	// Interact with read_axi4_interface module
    input [DATA_WIDTH-1:0] 	data_in,	// Data write
    input					wen,		// Write enable
    output 					fifo_full,  // FIFO full
	// Interact with write_axi4_interface module
    input 					ren,  		// Read enable
    output 					fifo_empty,	// FIFO empty
    output reg [DATA_WIDTH-1:0] data_out//Data read
);

    localparam DEPTH = 1 << ADDR_WIDTH; // length of fifo memory: 2^ADDR_WIDTH

    reg [DATA_WIDTH-1:0] fifo_mem[0:DEPTH-1]; //fifo memory 
    reg [ADDR_WIDTH:0] wr_ptr; //pointer write register(extra bit for overflow)
    reg [ADDR_WIDTH:0] rd_ptr; //pointer read register(extra bit for overflow)

    // FULL and EMPTY flag of FIFO
    assign fifo_full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
						(wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    assign fifo_empty = (wr_ptr == rd_ptr);

    // Write to FIFO
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 'b0;
        end else if (wen && !fifo_full) begin
            fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
            wr_ptr <= wr_ptr + 1;                       
        end
    end

    // Read from FIFO
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 'b0;
        end else if (ren && !fifo_empty) begin
			data_out <= fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end

endmodule


