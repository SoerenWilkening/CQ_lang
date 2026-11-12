/* tests/calls probe, ruling Q5: scanf then getchar on one stream: the lowered side's two scans run from the same position
   and the stream advances once, by what the scan took, so getchar reads the byte after the number (" " of "7 ab"). */
#include <stdio.h>
int stdin_scan_getc(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    int a = -1;
    int r = scanf("%d", &a);
    int c = getchar();
    int d = 0;
    if (x & 2)
        d = scanf("%d", &a);
    int e = getchar();
    return cq_measure(r * 1000 + a * 10 + c + d * 100 + e * 3 + x);
}
