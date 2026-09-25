#include <stdlib.h>

int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = m + 1; int r = t; for (int i = 0; i < 1000; i++) { int q2 = cq_theta(n + i, .3); if (q2 > 3) cq_phi(.2); r = cq_theta(r, .1); } return cq_measure(r); }
