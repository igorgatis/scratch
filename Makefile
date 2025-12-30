# Tools:
MISE_X_COSMOCC = mise exec http:cosmocc --
CP = $(MISE_X_COSMOCC) cp.ape
MKDIR = $(MISE_X_COSMOCC) mkdir.ape
RM = $(MISE_X_COSMOCC) rm.ape
FIND = mise exec http:cosmos-find -- find
ZIP = mise exec http:cosmos-zip -- zip
CC = $(MISE_X_COSMOCC) cosmocc
FIXUPOBJ = $(MISE_X_COSMOCC) fixupobj
ZIG = mise exec zig -- zig

# Params:
OUT = build
TARGET = $(OUT)/main.com

# Flags
CFLAGS = -Os -mtiny -mclang -DTINY -D_COSMO_SOURCE -I. -v
ZIGFLAGS = -O Debug
# ZIGFLAGS_X86_64 = $(ZIGFLAGS) -target x86_64-linux-musl
# ZIGFLAGS_AARCH64 = $(ZIGFLAGS) -target aarch64-linux-musl
ZIGFLAGS_X86_64 = $(ZIGFLAGS) -target x86_64-freestanding
ZIGFLAGS_AARCH64 = $(ZIGFLAGS) -target aarch64-freestanding

SRCS = main.c
OBJS = $(addprefix $(OUT)/,$(SRCS:.c=.o))

.PHONY: all
all: $(TARGET)

$(OUT)/%.o: %.zig
	@$(MKDIR) -p $(dir $@)/.aarch64
	$(ZIG) build-obj $(ZIGFLAGS_X86_64) -femit-bin=$@ $<
	$(FIXUPOBJ) $@
	$(ZIG) build-obj $(ZIGFLAGS_AARCH64) -femit-bin=$(dir $@).aarch64/$(notdir $@) $<
	$(FIXUPOBJ) $(dir $@).aarch64/$(notdir $@)

$(OBJS): $(MAKEFILE_LIST)

$(TARGET): $(OBJS)
	@$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	$(RM) -rf $(OUT)

.PHONY: rebuild
rebuild: clean all
