#include <stdlib.h>
#include <stdbool.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int x = f(m); int q2 = cq_theta(n, .3); if ((q2 > 3) && (x > 2)) cq_phi(.5); return cq_measure(q2); }
