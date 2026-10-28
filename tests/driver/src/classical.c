/* No CQ.h call anywhere: the pass must return this module byte-identical. */
#include <stdio.h>
#include <string.h>

struct acc { int n; double s[8]; };

static int collatz(unsigned x) {
    int n = 0;
    while (x != 1) { x = (x & 1) ? 3 * x + 1 : x / 2; n++; }
    return n;
}

int classical_work(int k, const char *s) {
    struct acc a = {0};
    for (int i = 0; i < 8; i++) a.s[i] = i * 0.5 + k;
    switch (k & 3) {
    case 0: a.n = collatz((unsigned)k + 7); break;
    case 1: a.n = (int)strlen(s); break;
    default: a.n = k * 3;
    }
    if (a.n > 100) printf("big %d\n", a.n);
    return a.n + (int)a.s[k & 7];
}
