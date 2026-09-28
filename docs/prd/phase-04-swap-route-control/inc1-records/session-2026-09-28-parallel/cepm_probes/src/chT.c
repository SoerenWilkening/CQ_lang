#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); g(q); int t1 = m + 1; g(q); int t2 = t1 + 1; if (t2 > n) q = cq_theta(q, .2); return cq_measure(q); }
