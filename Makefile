
help:
	$(info make help           - show this message)
	$(info make clean          - delete synth and simulation folders)
	$(info make sim            - the same as sim_gui)
	$(info make synth          - clean, create the board project and run the synthesis (for default board))
	$(info make open           - the same as synth_gui)
	$(info make load           - the same as synth_load)
	$(info make sim_cmd        - run simulation in Modelsim (console mode))
	$(info make sim_gui        - run simulation in Modelsim (gui mode))
	$(info make synth_create   - create the board project)
	$(info make synth_build_q  - build the board project with quartus)
	$(info make synth_gui_q    - open the board project with quartus)
	$(info make synth_load_q   - program the default FPGA board with quartus)
	$(info make board_all      - run synthesis for all the supported boards)
	$(info make prog_comp_c    - compile C program and copy program.vhd to program_file)
	$(info make prog_comp_asm  - compile Assembler program and copy program.vhd to program_file)
	$(info Open and read the Makefile for details)
	@true

PWD     := $(shell pwd)
BRD_DIR  = $(PWD)/board
RUN_DIR  = $(PWD)/run
RTL_DIR  = $(PWD)/rtl
TB_DIR   = $(PWD)/tb

BOARDS_SUPPORTED ?= de0_nano de10_lite Storm_IV_E6_V2 rz_easyFPGA_A2_1
BOARD            ?= de0_nano

########################################################
# common make targets

show_pwd:
	PWD

clean: \
	sim_clean \
	board_clean \
	log_clean \
	prog_clean \
	clean_rvc

sim_all: \
	sim_cmd 

sim: sim_gui

create: synth_create

synth_q: \
	synth_clean \
	synth_create \
	synth_build_q

load_q: synth_load_q

open_q: synth_gui_q

########################################################
# simulation - Modelsim

VSIM_DIR = $(PWD)/sim_modelsim

VLIB_BIN = cd $(VSIM_DIR) && vlib
VLOG_BIN = cd $(VSIM_DIR) && vlog
VSIM_BIN = cd $(VSIM_DIR) && vsim

VSIM_OPT_COMMON += -do $(RUN_DIR)/script_modelsim.tcl -onfinish final

VSIM_OPT_CMD     = -c
VSIM_OPT_CMD    += -onfinish exit

VSIM_OPT_GUI     = -gui -onfinish stop

sim_clean:
	rm -rfd $(VSIM_DIR)
	rm -rfd log

sim_dir: sim_clean
	mkdir $(VSIM_DIR)
	mkdir log

sim_cmd: sim_dir
	$(VSIM_BIN) $(VSIM_OPT_COMMON) $(VSIM_OPT_CMD)

sim_gui: sim_dir
	$(VSIM_BIN) $(VSIM_OPT_COMMON) $(VSIM_OPT_GUI) &

########################################################
# compiling  - program

PROG_NAME ?= 00_counter
CCF	= -march=rv32i -mabi=ilp32
LDF	= -b elf32-littleriscv
CPF = ihex -O ihex
PROG_SIZE ?= 4096

prog_comp_c:
	mkdir -p program_file
	riscv-none-embed-as program/startup/boot.S -c -o program_file/boot.o $(CCF)
	riscv-none-embed-gcc -O1 program/$(PROG_NAME)/main.c -c -o program_file/main.o $(CCF)
	riscv-none-embed-gcc -O1 program/startup/vectors.c -c -o program_file/vectors.o $(CCF)
	riscv-none-embed-ld -o program_file/main.elf -Map program_file/main.map -T program/startup/program.ld program_file/boot.o program_file/main.o program_file/vectors.o $(LDF)
	riscv-none-embed-objdump -M no-aliases -S -w --disassemble-zeroes program_file/main.elf > program_file/main.lst
	riscv-none-embed-objcopy program_file/main.elf program_file/program.$(CPF)
	python program/startup/ihex2hex.py $(PROG_SIZE)

prog_comp_asm:
	mkdir -p program_file
	riscv-none-embed-gcc program/$(PROG_NAME)/main.S -c -o program_file/main.o $(CCF)
	riscv-none-embed-ld -o program_file/main.elf -Map program_file/main.map -T program/startup/program.ld program_file/main.o $(LDF)
	riscv-none-embed-objdump -M no-aliases -S -w --disassemble-zeroes program_file/main.elf > program_file/main.lst
	riscv-none-embed-objcopy program_file/main.elf program_file/program.$(CPF)
	python program/startup/ihex2hex.py $(PROG_SIZE)

prog_clean:
	rm -rfd $(PWD)/program_file

########################################################
# riscv-compliance test
# RV32I full test list
RVC_LIST      ?= I-ADD-01 I-ADDI-01 I-AND-01 I-ANDI-01 I-AUIPC-01 I-BEQ-01 I-BGE-01 I-BGEU-01 I-BLT-01 I-BLTU-01 I-BNE-01 I-CSRRC-01 I-CSRRCI-01 I-CSRRS-01 I-CSRRSI-01 I-CSRRW-01 I-CSRRWI-01 I-DELAY_SLOTS-01 I-EBREAK-01 I-ECALL-01 I-ENDIANESS-01 I-FENCE.I-01 I-IO I-JAL-01 I-JALR-01 I-LB-01 I-LBU-01 I-LH-01 I-LHU-01 I-LUI-01 I-LW-01 I-MISALIGN_JMP-01 I-MISALIGN_LDST-01 I-NOP-01 I-OR-01 I-ORI-01 I-RF_size-01 I-RF_width-01 I-RF_x0-01 I-SB-01 I-SH-01 I-SLL-01 I-SLLI-01 I-SLT-01 I-SLTI-01 I-SLTIU-01 I-SLTU-01 I-SRA-01 I-SRAI-01 I-SRL-01 I-SRLI-01 I-SUB-01 I-SW-01 I-XOR-01 I-XORI-01
# RV32I reducted test list
RVC_LIST_TEST ?= I-ADD-01 I-ADDI-01 I-AND-01 I-ANDI-01 I-AUIPC-01 I-BEQ-01 I-BGE-01 I-BGEU-01 I-BLT-01 I-BLTU-01 I-BNE-01 I-CSRRC-01 I-CSRRCI-01 I-CSRRS-01 I-CSRRSI-01 I-CSRRW-01 I-CSRRWI-01 I-DELAY_SLOTS-01                        I-ENDIANESS-01              I-IO I-JAL-01 I-JALR-01 I-LB-01 I-LBU-01 I-LH-01 I-LHU-01 I-LUI-01 I-LW-01 I-MISALIGN_JMP-01 I-MISALIGN_LDST-01 I-NOP-01 I-OR-01 I-ORI-01 I-RF_size-01 I-RF_width-01 I-RF_x0-01 I-SB-01 I-SH-01 I-SLL-01 I-SLLI-01 I-SLT-01 I-SLTI-01 I-SLTIU-01 I-SLTU-01 I-SRA-01 I-SRAI-01 I-SRL-01 I-SRLI-01 I-SUB-01 I-SW-01 I-XOR-01 I-XORI-01
# RISC V pass test
RVC_PASS      ?= I-ADD-01 I-ADDI-01 I-AND-01 I-ANDI-01 I-AUIPC-01 I-BEQ-01 I-BGE-01 I-BGEU-01 I-BLT-01 I-BLTU-01 I-BNE-01 I-CSRRC-01 I-CSRRCI-01 I-CSRRS-01 I-CSRRSI-01 I-CSRRW-01 I-CSRRWI-01 I-DELAY_SLOTS-01                        I-ENDIANESS-01              I-IO I-JAL-01 I-JALR-01 I-LB-01 I-LBU-01 I-LH-01 I-LHU-01 I-LUI-01 I-LW-01 I-MISALIGN_JMP-01 I-MISALIGN_LDST-01 I-NOP-01 I-OR-01 I-ORI-01 I-RF_size-01 I-RF_width-01 I-RF_x0-01 I-SB-01 I-SH-01 I-SLL-01 I-SLLI-01 I-SLT-01 I-SLTI-01 I-SLTIU-01 I-SLTU-01 I-SRA-01 I-SRAI-01 I-SRL-01 I-SRLI-01 I-SUB-01 I-SW-01 I-XOR-01 I-XORI-01
# RISC V test with errors
RVC_ERR       ?=                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
# RISC V not test
RVC_NT        ?= I-EBREAK-01 I-ECALL-01 I-FENCE.I-01
# RISC V current test
RVC_TEST      ?= I-ADD-01

RVC_PROG_SIZE ?= 4096

FORMAL_VER_INSTR = $@

sim_rvc: sim_dir
	python program\startup\run_rvc_gen.py $(RVC_TEST)
	$(VSIM_BIN) -do $(RUN_DIR)/rvc_run.tcl -onfinish final -c -onfinish exit

sim_rvc_gui: sim_dir
	python program\startup\run_rvc_gen.py $(RVC_TEST)
	$(VSIM_BIN) -do $(RUN_DIR)/rvc_run.tcl -gui -onfinish stop

rvc_test:
	mkdir -p rvc_log
	python program\startup\rvc_test.py $(RVC_TEST)

prog_comp_rvc_sifive_formal:
	mkdir -p program_file/$(RVC_TEST)
	riscv-none-embed-gcc \
	program/riscv-compliance/riscv-test-suite/rv32i/src/$(RVC_TEST).S \
	-Iprogram/riscv-compliance/riscv-target/sifive-formal/formalspec-env/p \
	-Iprogram/riscv-compliance/riscv-target/sifive-formal/formalspec-env/ \
	-Iprogram/riscv-compliance/riscv-target/sifive-formal/ -c \
	-o program_file/main.o $(CCF)
	riscv-none-embed-ld -o program_file/main.elf -Map program_file/main.map -T program/startup/rvc.ld program_file/main.o $(LDF)
	riscv-none-embed-objdump -M no-aliases -S -w --disassemble-zeroes program_file/main.elf > program_file/main.lst
	riscv-none-embed-objcopy program_file/main.elf program_file/program.$(CPF)
	python program/startup/ihex2hex.py $(RVC_PROG_SIZE)

formal_ver: \
	prog_comp_rvc_sifive_formal \
	sim_rvc \
	rvc_test

formal_ver_all: $(RVC_LIST_TEST)

$(RVC_LIST_TEST):
	mkdir -p program_file/$(FORMAL_VER_INSTR)
	riscv-none-embed-gcc \
	program/riscv-compliance/riscv-test-suite/rv32i/src/$(FORMAL_VER_INSTR).S \
	-Iprogram/riscv-compliance/riscv-target/sifive-formal/formalspec-env/p \
	-Iprogram/riscv-compliance/riscv-target/sifive-formal/formalspec-env/ \
	-Iprogram/riscv-compliance/riscv-target/sifive-formal/ -c \
	-o program_file/main.o $(CCF)
	riscv-none-embed-ld -o program_file/main.elf -Map program_file/main.map -T program/startup/rvc.ld program_file/main.o $(LDF)
	riscv-none-embed-objdump -M no-aliases -S -w --disassemble-zeroes program_file/main.elf > program_file/main.lst
	riscv-none-embed-objcopy program_file/main.elf program_file/program.$(CPF)
	python program/startup/ihex2hex.py $(RVC_PROG_SIZE)
	python program\startup\run_rvc_gen.py $(FORMAL_VER_INSTR)
	$(VSIM_BIN) -do $(RUN_DIR)/rvc_run.tcl -onfinish final -c -onfinish exit
	mkdir -p rvc_log
	python program\startup\rvc_test.py $(FORMAL_VER_INSTR)

clean_rvc:
	rm -rfd $(PWD)/program/riscv-compliance
	rm -rfd $(PWD)/run/rvc*
	rm -rfd $(PWD)/rvc_log

copy_rvc:
	git clone https://github.com/riscv/riscv-compliance program/riscv-compliance

########################################################
# synthesis - default board only

MAKEFILE_PATH   = $(PWD)/board
SYNTH_DIR       = $(PWD)/synth_$(BOARD)
SYNTH_TEMPLATE  = $(BRD_DIR)/$(BOARD)
CABLE_NAME 	   ?= "USB-Blaster"

synth_clean:
	rm -rfd $(SYNTH_DIR)

synth_create: synth_clean
	cp -r  $(SYNTH_TEMPLATE) $(SYNTH_DIR)

synth_build_q:
	quartus_sh --flow compile $(PWD)/synth_$(BOARD)/$(BOARD)

synth_gui_q:
	quartus $(PWD)/synth_$(BOARD)/$(BOARD).qpf &

synth_load_q:
	quartus_pgm -c $(CABLE_NAME) -m JTAG -o "p;synth_$(BOARD)/$(BOARD).sof"

########################################################
# synthesis - all the supported boards

BOARD_NAME         = $@
BOARD_TEMPLATE_DIR = $(BRD_DIR)/$(BOARD_NAME)
BOARD_BUILD_DIR    = $(PWD)/synth_$(BOARD_NAME)

$(BOARDS_SUPPORTED):
	rm -rfd $(BOARD_BUILD_DIR)
	cp -r  $(BOARD_TEMPLATE_DIR) $(BOARD_BUILD_DIR)
	make -C $(BOARD_BUILD_DIR) create
	make -C $(BOARD_BUILD_DIR) build

board_all: $(BOARDS_SUPPORTED)

board_clean:
	rm -rfd $(PWD)/synth_*

########################################################
# log dir

log_clean:
	rm -rfd $(PWD)/log/*
