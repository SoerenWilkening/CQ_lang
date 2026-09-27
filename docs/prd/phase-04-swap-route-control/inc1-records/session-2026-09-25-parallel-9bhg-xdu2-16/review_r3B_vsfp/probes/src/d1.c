#include <stdlib.h>
static volatile int K = 1;
__attribute__((noinline)) static void f(int x, int *out) { *out = x * 3; }
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int t = (q > 3) ? K : 0; int r = 0; if (t) { int o; f(q, &o); r = o; } return cq_measure(r) + cq_measure(q); }
