/* Read-only Darwin process metadata for the existing-client host boundary. */
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/proc.h>
#include <libproc.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

static void quoted(const char *s) {
    putchar('"');
    for (; *s; ++s) {
        unsigned char c = (unsigned char)*s;
        if (c == '"' || c == '\\') { putchar('\\'); putchar(c); }
        else if (c < 32) printf("\\u%04x", c);
        else putchar(c);
    }
    putchar('"');
}
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    char *end = NULL; errno = 0;
    long pid = strtol(argv[1], &end, 10);
    if (errno || !*argv[1] || *end || pid <= 0 || pid > 2147483647L) return 2;
    struct kinfo_proc p = {0}; size_t size = sizeof(p);
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, (int)pid};
    if (sysctl(mib, 4, &p, &size, NULL, 0) || size != sizeof(p)) return 1;
    if (p.kp_eproc.e_pcred.p_ruid != getuid()) return 3;
    char path[PROC_PIDPATHINFO_MAXSIZE] = {0};
    if (proc_pidpath((int)pid, path, sizeof(path)) <= 0) return 1;
    printf("{\"pid\":%ld,\"uid\":%u,\"birth\":\"%lld:%d\",\"caught\":%s,\"executable\":",
        pid, (unsigned)getuid(), (long long)p.kp_proc.p_starttime.tv_sec,
        (int)p.kp_proc.p_starttime.tv_usec,
        (p.kp_proc.p_sigcatch & sigmask(SIGUSR1)) ? "true" : "false");
    quoted(path); puts("}");
    return 0;
}
