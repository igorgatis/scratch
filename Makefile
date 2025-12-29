# Tools:
APE_PREFIX = mise exec http:cosmocc --
MKDIR = $(APE_PREFIX) mkdir.ape
RM = $(APE_PREFIX) rm.ape
FIND = mise exec http:cosmos-find -- find
ZIP = mise exec http:cosmos-zip -- zip
CC = mise exec http:cosmocc -- cosmocc
FIXUPOBJ = mise exec http:cosmocc -- fixupobj



# Paths to tools (adjust if necessary)
ZIG ?= mise exec zig -- zig
# CC ?= $(COSMOCC_DIR)/bin/x86_64-unknown-cosmo-cc
# CC = mise exec http:cosmocc -- cosmocc
CC = mise exec zig -- zig cc
#OBJCOPY ?= $(COSMOCC_DIR)/bin/x86_64-linux-cosmo-objcopy
#OBJCOPY = mise exec zig -- zig objcopy
COSMOCC = mise exec http:cosmocc -- cosmocc
# Flags
ZIG_FLAGS = build-obj -O ReleaseSmall
#ZIG_FLAGS = build-obj -O ReleaseSmall
# ZIG_FLAGS = build-obj -O ReleaseSmall -cflags \
#     -D__COSMOPOLITAN__ -D__COSMOCC__ -D__FATCOSMOCC__ \
#     -DTINY -D_COSMO_SOURCE \
#     -fno-semantic-interposition -Wno-implicit-int \
#     -mno-tls-direct-seg-refs -fno-pie -nostdinc \
#     -isystem "$(shell mise where http:cosmocc)/include" \
#     -I. \
# 	--

CFLAGS = -Os -mtiny -mclang -DTINY -D_COSMO_SOURCE -I. -I cosmopolitan -include stdbool.h -v

BUILD_DIR = build
TARGET = $(BUILD_DIR)/hello.com

C_SRCS := 
ZIG_SRCS := hello.zig

C_OBJS := $(addprefix $(BUILD_DIR)/c/,$(C_SRCS:.c=.o))
ZIG_OBJS := $(addprefix $(BUILD_DIR)/zig/,$(ZIG_SRCS:.zig=.o))

.PHONY: all clean

all: $(TARGET)

# $(TARGET): $(ELF)
# 	$(OBJCOPY) -SO binary $< $@
# 	chmod +x $@

# $(ELF): $(OBJ)
# 	$(CC) -Os -o $@ $<

# $(ZIG_OBJS): hello.zig
# 	$(ZIG) $(ZIG_FLAGS) -femit-bin=$@ $<

$(TARGET): $(C_OBJS) $(ZIG_OBJS)
	$(COSMOCC) $(CFLAGS) -o $@ $<

$(BUILD_DIR)/zig/%.o: %.zig
	@$(MKDIR) -p $(dir $@).aarch64
	$(ZIG) $(ZIG_FLAGS) -target x86_64-freestanding -femit-bin=$@ $<
	$(FIXUPOBJ) $@
	$(ZIG) $(ZIG_FLAGS) -target aarch64-freestanding -femit-bin=$(dir $@).aarch64/$(notdir $@) $<
	$(FIXUPOBJ) $(dir $@).aarch64/$(notdir $@)

$(BUILD_DIR)/c/%.o: %.c
	@$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR)
