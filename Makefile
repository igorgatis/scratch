ZIG_FLAGS := -O ReleaseSmall
#ZIG_FLAGS := -O ReleaseSmall -target aarch64-linux-musl
#ZIG_FLAGS := -O ReleaseSmall -static
#ZIG_FLAGS := -O ReleaseSmall -target aarch64-freestanding 

OUT := build/$(shell uname -s)/$(shell uname -m)
SRCS := src/main.zig src/foo.zig
OBJS := $(patsubst src/%.zig,$(OUT)/%.o,$(SRCS))

.PHONY: build
build: $(OUT)/main

$(OUT)/%.o: src/%.zig
	@mkdir -p $(dir $@)
	zig build-obj $(ZIG_FLAGS) -femit-bin=$@ -femit-asm=$(@:.o=.s) $<
	@ls -lh $@

$(OUT)/main: $(OBJS)
	zig build-exe $(ZIG_FLAGS) -femit-bin=$@ $<
	@ls -lh $@

.PHONY: clean
clean:
	git clean -f -x -d

.PHONY: rebuild
rebuild: clean build

.PHONY: docker
docker:
	docker build -t minzig .
	docker run -it --rm -v $$PWD:/app -w /app minzig 

.PHONY: docker-rebuild
docker-rebuild:
	docker build -t minzig . --no-cache
	$(MAKE) docker
