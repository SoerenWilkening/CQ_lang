#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < n; i++) { int p = q + i; g(p); acc += i + 1; } q = cq_theta(q, .7); int q2 = cq_theta(n, .4); if (acc > 5) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q); }
