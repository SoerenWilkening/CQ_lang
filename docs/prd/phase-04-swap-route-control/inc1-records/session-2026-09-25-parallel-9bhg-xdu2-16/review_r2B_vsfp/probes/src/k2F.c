#include <stdlib.h>
static volatile int K = 7;
int g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int r = m + 1; int s = g(p); q = cq_theta(q, .7); return r + cq_measure(s) + cq_measure(q); }
