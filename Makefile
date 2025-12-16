# Makefile for Hello World APE

# Paths to tools (adjust if necessary)
ZIG ?= /tmp/zig/zig
COSMOCC_DIR ?= /tmp/cosmocc
CC ?= $(COSMOCC_DIR)/bin/x86_64-unknown-cosmo-cc
OBJCOPY ?= $(COSMOCC_DIR)/bin/x86_64-linux-cosmo-objcopy

# Output directory
BUILD_DIR = builder

# Targets
TARGET = $(BUILD_DIR)/hello.com
ELF = $(BUILD_DIR)/hello.elf
OBJ = $(BUILD_DIR)/hello.o

# Flags
ZIG_FLAGS = build-obj -target x86_64-freestanding -fno-stack-check -lc -O ReleaseSmall

.PHONY: all clean run dir

all: dir $(TARGET)

dir:
	mkdir -p $(BUILD_DIR)

$(TARGET): $(ELF)
	$(OBJCOPY) -SO binary $< $@
	chmod +x $@

$(ELF): $(OBJ)
	$(CC) -Os -o $@ $<

$(OBJ): hello.zig
	$(ZIG) $(ZIG_FLAGS) -femit-bin=$@ $<

run: $(TARGET)
	./$(TARGET)

clean:
	rm -rf $(BUILD_DIR)
