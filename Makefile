CC ?= cosmocc
# Use tiny mode with correct flags. -I. must be before -I cosmopolitan to pick up custom config.h
CFLAGS = -Os -mtiny -D_COSMO_SOURCE -I. -I cosmopolitan -include stdbool.h

# Find sources
HTTP_SRCS := $(shell find cosmopolitan/net/http -name "*.c")
HTTPS_SRCS := $(shell find cosmopolitan/net/https -name "*.c")
# Find all mbedtls sources but filter out server and write sources
MBEDTLS_SRCS := $(shell find cosmopolitan/third_party/mbedtls -name "*.c" -not -path "*/test/*")
# Exclude list
EXCLUDE_LIST := ssl_srv.c ssl_ticket.c ssl_cache.c ssl_cookie.c \
                x509_create.c x509write_crt.c x509write_csr.c \
                pkwrite.c
# Filter
MBEDTLS_SRCS := $(filter-out $(addprefix %/,$(EXCLUDE_LIST)), $(MBEDTLS_SRCS))

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
