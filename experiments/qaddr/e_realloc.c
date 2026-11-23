#include <stdlib.h>
/* realloc through a pointer chosen by a quantum bit: the size header at p - 8 (CR rule 16) must be inside the bound. */
int main(void) {
    unsigned char *a = malloc(40), *b = malloc(72);
    for (int i = 0; i < 40; i++) a[i] = i + 1;
    for (int i = 0; i < 72; i++) b[i] = 100 - i;
    unsigned char q = 1; cq_theta(&q, 0.0);
    unsigned char *p = (q & 1) ? a : b;
    unsigned char *r = realloc(p, 96);
    return (int)cq_measure(r[30] & 127);
}
