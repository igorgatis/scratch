# Tools:
APE_PREFIX = mise exec http:cosmocc --
CP = $(APE_PREFIX) cp.ape
MKDIR = $(APE_PREFIX) mkdir.ape
RM = $(APE_PREFIX) rm.ape
FIND = mise exec http:cosmos-find -- find
ZIP = mise exec http:cosmos-zip -- zip
CC = mise exec http:cosmocc -- cosmocc

# Params:
OUT = build
TARGET = $(OUT)/main.com

# Flags
CFLAGS = -Os -mtiny -mclang -DTINY -D_COSMO_SOURCE -I. -v

SRCS = main.c
OBJS = $(addprefix $(OUT)/,$(SRCS:.c=.o))

.PHONY: all
all: $(TARGET)

$(OUT)/%.o: %.c
	@$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ -c $<

$(TARGET): $(OBJS)
	@$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	$(RM) -rf $(OUT)
