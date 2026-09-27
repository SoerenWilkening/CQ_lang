#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m & 7, .5); int p = m; if (q > 3) p = 100 / n; int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }
