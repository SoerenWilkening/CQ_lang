#include <stdlib.h>
#include <stdbool.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .3); int r = f(m); for (int i = 0; i < 3; i++) { if (q2 > i) cq_phi(r * .1); } return cq_measure(q2); }
