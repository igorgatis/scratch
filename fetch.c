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
#define MAX_REDIRECTS 5

void die(const char *msg) {
    perror(msg);
    exit(1);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <url>\n", argv[0]);
        return 1;
    }

    char *current_url_str = strdup(argv[1]);
    int redirects = 0;

    while (redirects < MAX_REDIRECTS) {
        struct Url url = {0};
        char *url_mem = ParseUrl(current_url_str, -1, &url, kUrlPlus);
        if (!url_mem) {
            fprintf(stderr, "Failed to parse URL: %s\n", current_url_str);
            free(current_url_str);
            return 1;
        }

        // Validation removed as requested.

        char scheme[32] = {0};
        if (url.scheme.p && url.scheme.n < sizeof(scheme)) {
            memcpy(scheme, url.scheme.p, url.scheme.n);
        }

        char host[256] = {0};
        if (url.host.p && url.host.n < sizeof(host)) {
            memcpy(host, url.host.p, url.host.n);
        }

        char path[2048] = "/";
        if (url.path.p && url.path.n > 0) {
            size_t path_len = url.path.n;
            if (path_len >= sizeof(path)) path_len = sizeof(path) - 1;
            memcpy(path, url.path.p, path_len);
            path[path_len] = '\0';
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

        if (port == 443) {
            fprintf(stderr, "HTTPS support is not available in this build. Redirected to: %s\n", current_url_str);
            free(url_mem);
            free(current_url_str);
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
            free(current_url_str);
            return 1;
        }

        // Connect
        int sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (sockfd < 0) die("socket");

        if (connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) {
            perror("connect");
            freeaddrinfo(res);
            close(sockfd);
            free(url_mem);
            free(current_url_str);
            return 1;
        }

        freeaddrinfo(res);

        // Send Request
        char request[4096];
        int req_len = snprintf(request, sizeof(request),
                 "GET %s HTTP/1.1\r\n"
                 "Host: %s\r\n"
                 "User-Agent: cosmo-fetch/1.0\r\n"
                 "Connection: close\r\n"
                 "\r\n",
                 path, host);

        if (send(sockfd, request, req_len, 0) < 0) die("send");

        // Read Response and handle headers
        char buffer[8192]; // Buffer for headers + some body
        ssize_t n = 0;
        int total_read = 0;
        int header_ended = 0;
        int status = 0;

        // Read until we have headers or full buffer
        while (total_read < sizeof(buffer) - 1) {
            n = recv(sockfd, buffer + total_read, sizeof(buffer) - 1 - total_read, 0);
            if (n <= 0) break;
            total_read += n;
            buffer[total_read] = '\0';

            if (strstr(buffer, "\r\n\r\n")) {
                header_ended = 1;
                break;
            }
        }

        if (total_read <= 0) {
             fprintf(stderr, "Empty response or error\n");
             close(sockfd);
             free(url_mem);
             free(current_url_str);
             return 1;
        }

        // Parse status line
        if (sscanf(buffer, "HTTP/%*d.%*d %d", &status) != 1) {
             fprintf(stderr, "Invalid HTTP response\n");
             close(sockfd);
             free(url_mem);
             free(current_url_str);
             return 1;
        }

        if (status >= 300 && status < 400) {
            // Handle Redirect
            char *loc = strstr(buffer, "\nLocation:");
            if (!loc) loc = strstr(buffer, "\nlocation:");

            if (loc) {
                loc += 10; // Skip "\nLocation:"
                while (*loc == ' ' || *loc == '\t') loc++;
                char *end = strstr(loc, "\r\n");
                if (!end) end = strchr(loc, '\n');

                if (end) {
                    int len = end - loc;
                    char new_loc[2048] = {0};
                    if (len < sizeof(new_loc)) {
                        memcpy(new_loc, loc, len);
                        new_loc[len] = '\0';

                        fprintf(stderr, "Redirecting to: %s\n", new_loc);

                        // Handle relative URL (simple case)
                        if (new_loc[0] == '/') {
                           // Construct absolute URL: scheme://host[:port] + new_loc
                           char full_url[4096];
                           snprintf(full_url, sizeof(full_url), "%s://%s:%d%s", scheme, host, port, new_loc);
                           free(current_url_str);
                           current_url_str = strdup(full_url);
                        } else if (!strstr(new_loc, "://")) {
                           fprintf(stderr, "Warning: potential relative path redirect '%s' might be handled incorrectly if not absolute or root-relative.\n", new_loc);
                           free(current_url_str);
                           current_url_str = strdup(new_loc);
                        } else {
                           free(current_url_str);
                           current_url_str = strdup(new_loc);
                        }

                        close(sockfd);
                        free(url_mem);
                        redirects++;
                        continue;
                    }
                }
            }
            fprintf(stderr, "Redirect status %d but no Location header found.\n", status);
            close(sockfd);
            free(url_mem);
            free(current_url_str);
            return 1;
        } else if (status >= 200 && status < 300) {
            // Success - print body
            char *body_start = strstr(buffer, "\r\n\r\n");
            if (body_start) {
                body_start += 4;
                int headers_len = body_start - buffer;
                int body_len = total_read - headers_len;
                if (body_len > 0) {
                    write(STDOUT_FILENO, body_start, body_len);
                }
            }

            // Stream the rest
            while ((n = recv(sockfd, buffer, sizeof(buffer), 0)) > 0) {
                write(STDOUT_FILENO, buffer, n);
            }

            close(sockfd);
            free(url_mem);
            free(current_url_str);
            return 0;
        } else {
            fprintf(stderr, "HTTP Request failed with status: %d\n", status);
            close(sockfd);
            free(url_mem);
            free(current_url_str);
            return 1;
        }
    }

    fprintf(stderr, "Too many redirects\n");
    free(current_url_str);
    return 1;
}
