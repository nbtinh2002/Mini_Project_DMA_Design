module apb_interface(
    input               clk,
    input               rst_n,

    // Controller interface
    input               dma_done,
    output reg          dma_start,
    output reg  [15:0]  size_dtrans,
    output reg  [31:0]  src_reg,
    output reg  [31:0]  dst_reg,

    // APB interface
    input               psel,
    input               penable,
    input               pwrite,
    input       [7:0]   paddr,
    input       [31:0]  pwdata,
    output reg  [31:0]  prdata,
    output reg          pready
);

    reg         dma_busy;
    reg [31:0]  ctrl_reg;

    wire        write_en = psel && penable && pwrite && !dma_busy;
    wire        read_en  = psel && penable && !pwrite;

    // Write and Read registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg    <= 0;
            src_reg     <= 0;
            dst_reg     <= 0;
            prdata      <= 0;
        end else begin
            if (write_en) begin
                case (paddr)
                    8'h00: ctrl_reg <= pwdata;
                    8'h08: src_reg  <= {pwdata[31:2], 2'b00};
                    8'h0C: dst_reg  <= {pwdata[31:2], 2'b00};
                    default:;
                endcase
            end
            if (read_en) begin
                case (paddr)
                    8'h00: prdata <= ctrl_reg;
                    8'h04: prdata <= {{30{1'b0}}, dma_done, dma_busy};
                    8'h08: prdata <= src_reg;
                    8'h0C: prdata <= dst_reg;
                    default: prdata <= 32'b0;
                endcase
            end
        end
    end

    // DMA start pulse + transfer size
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_start   <= 0;
            size_dtrans <= 0;
        end else if (!dma_busy && write_en && paddr == 8'h00 && pwdata[0]) begin
            dma_start   <= 1;
            size_dtrans <= pwdata[31:16];
        end else begin
            dma_start <= 0;
        end
    end

    // DMA busy flag
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dma_busy <= 0;
        else if (dma_start)
            dma_busy <= 1;
        else if (dma_done)
            dma_busy <= 0;
    end

    // PREADY generation (1-cycle pulse)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pready <= 0;
        else
            pready <= (psel && penable);
    end

endmodule
