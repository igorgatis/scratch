#define _COSMO_SOURCE
#include "cosmopolitan/net/https/fetch.h"
#include "cosmopolitan/libc/stdio/append.h"
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

int download_file(const char *url, const char *output_filename) {
    char *data = NULL;
    fprintf(stderr, "Downloading %s...\n", url);
    int status = AppendFetch(&data, url);
    if (status != 200) {
        fprintf(stderr, "Failed to download %s: status %d\n", url, status);
        if (data) free(data);
        return -1;
    }

    FILE *fp = fopen(output_filename, "wb");
    if (!fp) {
        perror("fopen");
        if (data) free(data);
        return -1;
    }

    // Use appendz to get the length of the data buffer
    size_t len = 0;
    if (data) {
        struct appendz z = appendz(data);
        len = z.i;
    }

    if (len > 0) {
        if (fwrite(data, 1, len, fp) != len) {
            perror("fwrite");
            fclose(fp);
            if (data) free(data);
            return -1;
        }
    }

    fclose(fp);
    if (data) free(data);
    fprintf(stderr, "Saved to %s (%zu bytes)\n", output_filename, len);
    return 0;
}

int main() {
    const char *mise_url = "https://github.com/jdx/mise/releases/download/v2025.12.4/mise-v2025.12.4-linux-x64";
    const char *unzip_url = "https://cosmo.zip/pub/cosmos/bin/unzip";

    if (download_file(mise_url, "mise") != 0) {
        return 1;
    }

    if (download_file(unzip_url, "unzip") != 0) {
        return 1;
    }

    return 0;
}
