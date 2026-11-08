/* tests/loops-cutoff probe (CR rules 9, 14; cq-quhmu): musl printf_core's shape. A K-loop exits into its exit arm, which holds a
 * classically bounded loop with a quantum exit (the nl_type scan); that loop's exit block `inval` is also entered from the K-loop's
 * trips (a byte 0 in the format). The `inval` paths of the trips were left to the walker, which read their predicate after the
 * K-loop's last trip: a return through `%` gave -1 (vprintf returned -1 for "%d|").
 * Regenerate arm_tail.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec -include CQ.h arm_tail.c -o arm_tail.O1.ll */
#include <stddef.h>
int at_errno;
__attribute__((noinline)) static int scan(const char *s, int *nl) {
    unsigned l10n = 0;
    size_t i;
    for (;;) {
        char c = *s;
        if (c == '.') break;
        if (c == 0) goto inval;
        if (c == '$') l10n = 1;
        if (c == '%') return 0;
        s++;
    }
    if (!l10n) return 2;
    for (i = 1; i <= 9 && !nl[i]; i++)
        ;
    if (i <= 9) goto inval;
    return 1;
inval:
    at_errno = 22;
    return -1;
}
int arm_tail(int x) {
    int nl[10] = {0};
    char f[4] = {'a', 0, '.', 0};
    cq_theta(&x, 0.3);
    nl[x & 7] = 1;
    f[1] = "%\0.$"[(x >> 3) & 3];
    return cq_measure(scan(f, nl));
}
