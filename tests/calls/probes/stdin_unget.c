/* tests/calls probe, ruling Q5 (cq-wjysl): ungetc pushes a byte back into the one stream, the next read takes it first;
   a push-back under a quantum predicate (none where it reads 0), a second push-back fails, fgets reads the pushed byte as
   the head of its line, ungetwc then getwchar. */
#include <stdio.h>
#include <wchar.h>
int stdin_unget(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    int c1 = getchar();
    int u1 = ungetc('Q', stdin);
    int u2 = ungetc('R', stdin);
    int c2 = getchar();
    int u3 = 0;
    if (x & 1)
        u3 = ungetc('S', stdin);
    char b[8] = {0};
    fgets(b, 5, stdin);
    wint_t w = ungetwc(L'T', stdin);
    wint_t c3 = getwchar();
    int m = cq_measure(u3 * 11 + x);
    return m + c1 + u1 * 3 + u2 * 5 + c2 * 7 + b[0] * 13 + b[1] * 17 + b[3] * 19 + (int)w + (int)c3 * 23;
}
