#include <stdlib.h>
int g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); g(q); int t = m + 1; int r = cq_theta(t, .1); int r2 = r; if (m > 3) r2 = cq_theta(r, .2); return cq_measure(r2) + cq_measure(q); }
