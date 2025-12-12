#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdbool.h>
#include "net/http/url.h"
#include "net/http/http.h"

#define MAX_HEADER_SIZE 8192

void die(const char *msg) {
    perror(msg);
    exit(1);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <url>\n", argv[0]);
        return 1;
    }

    const char *url_str = argv[1];
    struct Url url = {0};
    char *url_mem = ParseUrl(url_str, -1, &url, kUrlPlus);
    if (!url_mem) {
        fprintf(stderr, "Failed to parse URL\n");
        return 1;
    }

    if (!url.scheme.p || !url.host.p) {
        fprintf(stderr, "Invalid URL: missing scheme or host\n");
        free(url_mem);
        return 1;
    }

    char scheme[32] = {0};
    if (url.scheme.n < sizeof(scheme)) {
        memcpy(scheme, url.scheme.p, url.scheme.n);
    }

    char host[256] = {0};
    if (url.host.n < sizeof(host)) {
        memcpy(host, url.host.p, url.host.n);
    }

    char path[1024] = "/";
    if (url.path.p && url.path.n > 0) {
        if (url.path.n < sizeof(path)) {
            memcpy(path, url.path.p, url.path.n);
            path[url.path.n] = '\0';
        } else {
            fprintf(stderr, "Path too long\n");
            free(url_mem);
            return 1;
        }
    }

    // Append query params if present (basic handling)
    if (url.params.p && url.params.n > 0) {
       // Typically handled by ParseUrl by pointing path to the start including params if opaque?
       // But ParseUrl splits them.
       // We'll skip complex reconstruction for now and assume simple paths for "binaries".
    }

    int port = 80;
    if (strcasecmp(scheme, "https") == 0) {
        port = 443;
    }

    if (url.port.p && url.port.n > 0) {
        char port_str[16] = {0};
        if (url.port.n < sizeof(port_str)) {
            memcpy(port_str, url.port.p, url.port.n);
            port = atoi(port_str);
        }
    }

    // printf("Fetching %s (Host: %s, Port: %d, Path: %s)\n", url_str, host, port, path);

    if (port == 443) {
        fprintf(stderr, "HTTPS support is not available in this build.\n");
        free(url_mem);
        return 1;
    }

    // DNS Resolution
    struct addrinfo hints = {0}, *res;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    char port_s[16];
    sprintf(port_s, "%d", port);

    int err = getaddrinfo(host, port_s, &hints, &res);
    if (err != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(err));
        free(url_mem);
        return 1;
    }

    // Connect
    int sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (sockfd < 0) die("socket");

    if (connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) die("connect");

    freeaddrinfo(res);

    // Send Request
    char request[2048];
    snprintf(request, sizeof(request),
             "GET %s HTTP/1.1\r\n"
             "Host: %s\r\n"
             "User-Agent: cosmo-fetch/1.0\r\n"
             "Connection: close\r\n"
             "\r\n",
             path, host);

    if (send(sockfd, request, strlen(request), 0) < 0) die("send");

    // Read Response and strip headers
    char buffer[4096];
    ssize_t n;
    int header_ended = 0;
    char header_buffer[MAX_HEADER_SIZE];
    int header_len = 0;

    while ((n = recv(sockfd, buffer, sizeof(buffer), 0)) > 0) {
        if (!header_ended) {
            int copy_len = n;
            if (header_len + copy_len > MAX_HEADER_SIZE) {
                copy_len = MAX_HEADER_SIZE - header_len;
            }
            memcpy(header_buffer + header_len, buffer, copy_len);
            int searched = header_len;
            header_len += copy_len;

            // Search for \r\n\r\n
            char *end = NULL;
            // Only search in the new part + 3 chars back
            int start_search = searched > 3 ? searched - 3 : 0;
            for (int i = start_search; i < header_len - 3; i++) {
                if (header_buffer[i] == '\r' && header_buffer[i+1] == '\n' &&
                    header_buffer[i+2] == '\r' && header_buffer[i+3] == '\n') {
                    end = header_buffer + i;
                    break;
                }
            }

            if (end) {
                header_ended = 1;
                int header_size = (end - header_buffer) + 4;
                // Determine how much body data is in the current chunk
                // The chunk in `buffer` corresponds to `header_buffer` tail.
                // We need to find where `end` maps to in `buffer`.
                // end points to \r of the sequence.
                // address of end relative to header_buffer start
                int offset_in_total = end - header_buffer;
                int body_start_in_buffer = offset_in_total + 4 - (header_len - n);

                if (body_start_in_buffer < n) {
                    write(STDOUT_FILENO, buffer + body_start_in_buffer, n - body_start_in_buffer);
                }
            } else {
                if (header_len == MAX_HEADER_SIZE) {
                     fprintf(stderr, "Header too large\n");
                     exit(1);
                }
            }
        } else {
            write(STDOUT_FILENO, buffer, n);
        }
    }

    if (n < 0) die("recv");

    close(sockfd);
    free(url_mem);
    return 0;
}
