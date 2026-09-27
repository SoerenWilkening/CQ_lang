#include <stdlib.h>
#pragma clang section bss="__DATA,__mybss"
static volatile int K = 7;
#pragma clang section bss=""
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); if (q > 3) (void)K; return cq_measure(q); }
