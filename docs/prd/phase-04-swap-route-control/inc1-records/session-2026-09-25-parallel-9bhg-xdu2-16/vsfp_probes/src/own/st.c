#include <stdlib.h>
__attribute__((noinline)) static int h(int a, int k) { return k + 1; }
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b + 1; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }
