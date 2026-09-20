#define _GNU_SOURCE
#include <dlfcn.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_FD 4096
static volatile char hypr_fds[MAX_FD] = {0};

static int (*real_connect)(int sockfd, const struct sockaddr *addr, socklen_t addrlen) = NULL;
static ssize_t (*real_write)(int fd, const void *buf, size_t count) = NULL;
static ssize_t (*real_send)(int sockfd, const void *buf, size_t len, int flags) = NULL;
static int (*real_close)(int fd) = NULL;

static void init_hooks(void) {
    if (!real_connect) {
        real_connect = dlsym(RTLD_NEXT, "connect");
        real_write = dlsym(RTLD_NEXT, "write");
        real_send = dlsym(RTLD_NEXT, "send");
        real_close = dlsym(RTLD_NEXT, "close");
    }
}

int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
    init_hooks();
    int res = real_connect(sockfd, addr, addrlen);
    if (res == 0 && addr && addr->sa_family == AF_UNIX) {
        const struct sockaddr_un *un = (const struct sockaddr_un *)addr;
        size_t len = strnlen(un->sun_path, sizeof(un->sun_path));
        if (len >= 12 && strcmp(un->sun_path + len - 12, ".socket.sock") == 0) {
            if (sockfd >= 0 && sockfd < MAX_FD) {
                hypr_fds[sockfd] = 1;
            }
        }
    }
    return res;
}

int close(int fd) {
    init_hooks();
    if (fd >= 0 && fd < MAX_FD) {
        hypr_fds[fd] = 0;
    }
    return real_close(fd);
}

static void escape_lua_string(const char *src, char *dst, size_t dst_size) {
    size_t j = 0;
    for (size_t i = 0; src[i] && j + 2 < dst_size; i++) {
        if (src[i] == '"' || src[i] == '\\') {
            dst[j++] = '\\';
        }
        dst[j++] = src[i];
    }
    dst[j] = '\0';
}

static int translate_dispatch(const void *buf, size_t count, char *out_cmd, size_t out_size) {
    if (count < 9 || memcmp(buf, "dispatch ", 9) != 0) {
        return 0;
    }

    char cmd[1024];
    if (count >= sizeof(cmd)) {
        return 0;
    }
    memcpy(cmd, buf, count);
    cmd[count] = '\0';

    while (count > 0 && (cmd[count - 1] == '\n' || cmd[count - 1] == '\r')) {
        cmd[--count] = '\0';
    }

    char *p = cmd + 9;
    while (*p == ' ') p++;
    char *dispatcher = p;
    while (*p && *p != ' ') p++;
    char *raw_arg = "";
    if (*p) {
        *p = '\0';
        raw_arg = p + 1;
        while (*raw_arg == ' ') raw_arg++;
    }

    char safe_arg[512];
    escape_lua_string(raw_arg, safe_arg, sizeof(safe_arg));

    if (strcmp(dispatcher, "workspace") == 0) {
        snprintf(out_cmd, out_size, "/dispatch hl.dsp.focus({ workspace = \"%s\" })", safe_arg);
    } else if (strcmp(dispatcher, "focusworkspaceoncurrentmonitor") == 0) {
        snprintf(out_cmd, out_size, "/dispatch hl.dsp.focus({ workspace = \"%s\", on_current_monitor = true })", safe_arg);
    } else if (strcmp(dispatcher, "togglespecialworkspace") == 0) {
        if (safe_arg[0] == '\0') {
            snprintf(out_cmd, out_size, "/dispatch hl.dsp.workspace.toggle_special()");
        } else {
            snprintf(out_cmd, out_size, "/dispatch hl.dsp.workspace.toggle_special(\"%s\")", safe_arg);
        }
    } else {
        if (safe_arg[0] == '\0') {
            snprintf(out_cmd, out_size, "/dispatch hl.dsp.%s()", dispatcher);
        } else {
            snprintf(out_cmd, out_size, "/dispatch hl.dsp.%s(\"%s\")", dispatcher, safe_arg);
        }
    }

    return 1;
}

ssize_t write(int fd, const void *buf, size_t count) {
    init_hooks();
    int is_hypr = (fd >= 0 && fd < MAX_FD && hypr_fds[fd]);
    if (!is_hypr && count >= 9 && memcmp(buf, "dispatch ", 9) == 0) {
        is_hypr = 1;
    }

    if (is_hypr) {
        char new_cmd[2048];
        if (translate_dispatch(buf, count, new_cmd, sizeof(new_cmd))) {
            size_t new_len = strlen(new_cmd);
            ssize_t written = real_write(fd, new_cmd, new_len);
            if (written < 0) return written;
            return count;
        }
    }

    return real_write(fd, buf, count);
}

ssize_t send(int sockfd, const void *buf, size_t len, int flags) {
    init_hooks();
    int is_hypr = (sockfd >= 0 && sockfd < MAX_FD && hypr_fds[sockfd]);
    if (!is_hypr && len >= 9 && memcmp(buf, "dispatch ", 9) == 0) {
        is_hypr = 1;
    }

    if (is_hypr) {
        char new_cmd[2048];
        if (translate_dispatch(buf, len, new_cmd, sizeof(new_cmd))) {
            size_t new_len = strlen(new_cmd);
            ssize_t written = real_send(sockfd, new_cmd, new_len, flags);
            if (written < 0) return written;
            return len;
        }
    }

    return real_send(sockfd, buf, len, flags);
}
