/* tests/calls probe, ruling Q5: reading past the end of the stream: fread takes what is left, then fgets returns null
   with the buffer as it was, getchar and scanf see end of file, on both sides. */
#include <stdio.h>
int stdin_eof(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    char big[64] = {0}, b[4] = {'q', 'q', 'q', 0};
    size_t n = fread(big, 1, sizeof big, stdin);
    char *p = fgets(b, 4, stdin);
    int c = getchar(), v = 5;
    int r = scanf("%d", &v);
    return cq_measure((int)n * 1000 + (p != 0) * 500 + b[0] + c * 3 + r * 7 + v + big[0] + big[19] + x);
}
