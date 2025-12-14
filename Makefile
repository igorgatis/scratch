CC = cosmocc
# Use tiny mode with correct flags. -I. must be before -I cosmopolitan to pick up custom config.h
# Added -DTINY to trigger mbedtls optimizations
CFLAGS = -Os -mtiny -DTINY -D_COSMO_SOURCE -I. -I cosmopolitan -include stdbool.h

# Find sources
HTTP_SRCS := $(shell find cosmopolitan/net/http -name "*.c")
HTTPS_SRCS := $(shell find cosmopolitan/net/https -name "*.c")
# Find all mbedtls sources but filter out server and write sources
MBEDTLS_SRCS := $(shell find cosmopolitan/third_party/mbedtls -name "*.c" -not -path "*/test/*")
# Exclude list
EXCLUDE_LIST := ssl_srv.c ssl_ticket.c ssl_cache.c ssl_cookie.c \
                x509_create.c x509write_crt.c x509write_csr.c \
                pkwrite.c certs.c error.c
# Filter
MBEDTLS_SRCS := $(filter-out $(addprefix %/,$(EXCLUDE_LIST)), $(MBEDTLS_SRCS))

SRCS := download.c $(HTTP_SRCS) $(HTTPS_SRCS) $(MBEDTLS_SRCS)
OBJS := $(SRCS:.c=.o)

all: download

# Download cacert.pem if not present
cacert.pem:
	wget -O cacert.pem https://curl.se/ca/cacert.pem || curl -o cacert.pem https://curl.se/ca/cacert.pem

download: $(OBJS) cacert.pem
	$(CC) $(CFLAGS) -o $@ $(OBJS)
	@mkdir -p usr/share/ssl/root
	cp cacert.pem usr/share/ssl/root/ca-certificates.crt
	zip -r $@ usr
	@rm -rf usr

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f download download.zip download.aarch64.elf download.com.dbg cacert.pem
	find . -name "*.o" -delete
	find . -type d -name ".aarch64" -exec rm -rf {} +
