#include <stdlib.h>
int h(int a, int k);

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int t2 = m + 3; int x = m; if (t2 > 3) x = m + 5; int r = t; if (m > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(x); }
