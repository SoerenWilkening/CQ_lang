#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int p = q ^ 5; g(p); int t = m + 1; if (t > n) q = cq_theta(q, .2); return cq_measure(q); }
