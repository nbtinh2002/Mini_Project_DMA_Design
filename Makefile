#----------------------------------------------------------------
# Makefile đơn giản hóa cho mô phỏng Verilog với Icarus + GTKWave
#----------------------------------------------------------------

# Top-level
TOP_TB		?= dma_controller_tb
#TOP_TB		?= fifo_tb
#TOP_TB		?= write_axi4_interface_tb
#TOP_TB		?= read_axi4_interface_tb
#TOP_TB		?= controller_tb
#TOP_TB     ?= apb_interface_tb

# Folder
RTL_DIR    := ./RTL
VCD        := $(TOP_TB).vcd
BIN        := simv.out

# Sources
RTL_SRCS   := $(filter-out $(RTL_DIR)/*_tb.v, $(wildcard $(RTL_DIR)/*.v))

# Command
IVERILOG   := iverilog
VVP        := vvp
GTKWAVE    := gtkwave
all: clean compile run wave

# Biên dịch
compile:
	@echo "[Compile] Compiling..."
	$(IVERILOG) -o $(BIN) -g2012 -I$(RTL_DIR) -s $(TOP_TB) $(RTL_SRCS)

# Mô phỏng
run: compile
	@echo "[Run] Running simulation..."
	$(VVP) $(BIN)

# Waveform
wave: run
	@echo "[Waveform] Launching GTKWave..."
	GTK_DEBUG=none $(GTKWAVE) $(VCD) > /dev/null 2>&1 &
# Dọn dẹp
clean:
	@echo "[Clean] Cleaning up..."
	rm -rf *.vcd *.out $(BIN) $(LOG_DIR)

.PHONY: clean compile run wave
