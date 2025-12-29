# Tools:
APE_PREFIX = mise exec http:cosmocc --
CP = $(APE_PREFIX) cp.ape
MKDIR = $(APE_PREFIX) mkdir.ape
RM = $(APE_PREFIX) rm.ape
FIND = mise exec http:cosmos-find -- find
ZIP = mise exec http:cosmos-zip -- zip
CC = mise exec http:cosmocc -- cosmocc

# Params:
BUILD_DIR = build
TARGET = $(BUILD_DIR)/main.com

# Flags
CFLAGS = -Os -mtiny -mclang -DTINY -D_COSMO_SOURCE -I. -v
#CFLAGS = -Os -mtiny -mzig -DTINY -D_COSMO_SOURCE -I. -v

SRCS = main.c
OBJS = $(addprefix $(BUILD_DIR)/,$(SRCS:.c=.o))

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	@$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

$(BUILD_DIR)/%.o: %.c
	@$(MKDIR) -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	$(RM) -rf $(BUILD_DIR)
