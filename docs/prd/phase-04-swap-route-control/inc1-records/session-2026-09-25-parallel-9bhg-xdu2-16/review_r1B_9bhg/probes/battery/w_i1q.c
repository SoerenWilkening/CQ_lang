#include <stdlib.h>
_Bool hw(int a, int k);
__attribute__((noinline)) _Bool fw(int m) { int q = cq_theta(m, .5); return hw(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q2 = cq_theta(n, .25); if (fw(m)) q2 = q2 + 1; return cq_measure(q2); }
