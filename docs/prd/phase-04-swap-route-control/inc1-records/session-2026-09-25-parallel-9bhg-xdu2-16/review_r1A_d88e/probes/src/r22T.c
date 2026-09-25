#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int s = 0; for (int i = 0; i < 2; i++) { int t = m + i + 1; int r = t; if (m > 3) r = cq_theta(t, .2); s += cq_measure(r); } return s; }
