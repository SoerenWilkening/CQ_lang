#include <stdlib.h>
void g(int a);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); g(q); int t = m + 1; return t + cq_measure(q); }
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int x = f(m); int q2 = cq_theta(n, .4); if (x > 5) q2 = cq_theta(q2, .3); return cq_measure(q2); }
