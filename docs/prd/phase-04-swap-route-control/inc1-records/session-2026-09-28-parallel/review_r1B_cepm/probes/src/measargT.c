#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .4); int x = cq_measure(q); g(q); int t = m + 1; if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + x; }
