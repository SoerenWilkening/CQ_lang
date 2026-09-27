#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m & 7, .5); int p = m, s = 7; if (q > 3) { p = 100 / n; s = 5; } int t = m + 1; return t + cq_measure(s) + cq_measure(q); }
