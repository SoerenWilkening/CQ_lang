#include <stdlib.h>
void g(int a);
__attribute__((noinline)) int F(int m, int n) { int q = cq_theta(m, .5); g(q); int t = n + 1; return t + 100 * cq_measure(q); }
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int t = F(m, n); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2); }
