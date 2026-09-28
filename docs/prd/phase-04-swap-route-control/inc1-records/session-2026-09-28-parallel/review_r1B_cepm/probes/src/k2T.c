#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); g(q); int t = m + 1; if (q > 5) cq_phi(t * 0.1); return cq_measure(q); }
