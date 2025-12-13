CC = /tmp/cosmocc/bin/cosmocc
# Use tiny mode with correct flags
CFLAGS = -Os -mtiny -D_COSMO_SOURCE -I cosmopolitan -include stdbool.h

# Find sources
HTTP_SRCS := $(shell find cosmopolitan/net/http -name "*.c")
HTTPS_SRCS := $(shell find cosmopolitan/net/https -name "*.c")
MBEDTLS_SRCS := $(shell find cosmopolitan/third_party/mbedtls -name "*.c" -not -path "*/test/*")
SRCS := download.c $(HTTP_SRCS) $(HTTPS_SRCS) $(MBEDTLS_SRCS)

all: download

download: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $(SRCS)
	@mkdir -p usr/share/ssl/root
	@if [ -f /etc/ssl/certs/ca-certificates.crt ]; then \
		cp /etc/ssl/certs/ca-certificates.crt usr/share/ssl/root/ca-certificates.crt; \
	else \
		echo "Warning: /etc/ssl/certs/ca-certificates.crt not found."; \
	fi
	zip -r $@ usr
	@rm -rf usr

clean:
	rm -f download download.zip download.aarch64.elf download.com.dbg
