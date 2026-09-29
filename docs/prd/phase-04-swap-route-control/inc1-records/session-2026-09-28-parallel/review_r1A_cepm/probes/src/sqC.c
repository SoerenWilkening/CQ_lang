#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = n; switch (q) { case 3: t = h(q, n); break; case 5: t = h(q, m); break; default: break; } return cq_measure(t) + cq_measure(q); }
