/* tests/calls probe, ruling Q5 (cq-wjysl): feof and ferror see the one stream: feof is 0 until a read runs into its end,
   1 after, 0 after clearerr; getw reads an int's 4 bytes; pread reads at an offset and consumes nothing (decision: an offset
   read does not move the stream, as it does not move the file offset). */
#include <stdio.h>
#include <unistd.h>
int stdin_feof(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    char at[4] = {0};
    ssize_t p = pread(0, at, 3, 2);
    int w = getw(stdin);
    int e0 = feof(stdin);
    char big[64];
    size_t n = fread(big, 1, sizeof big, stdin);
    int e1 = feof(stdin), r1 = ferror(stdin);
    clearerr(stdin);
    int e2 = feof(stdin);
    int c = 0;
    if (x & 1)
        c = getchar();
    int e3 = feof(stdin);
    return cq_measure((int)p + at[0] * 3 + at[2] * 5 + w + e0 * 7 + (int)n * 11 + e1 * 13 + r1 * 17 + e2 * 19 + c + e3 * 23 + x);
}
