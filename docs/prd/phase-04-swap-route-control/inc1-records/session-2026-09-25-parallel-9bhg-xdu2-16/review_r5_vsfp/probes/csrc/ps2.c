#include <stdlib.h>
#pragma clang section rodata="__TEXT,__myro"
static volatile double huge = 1e300;
#pragma clang section rodata=""
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); if (q > 3) (void)huge; return cq_measure(q); }
