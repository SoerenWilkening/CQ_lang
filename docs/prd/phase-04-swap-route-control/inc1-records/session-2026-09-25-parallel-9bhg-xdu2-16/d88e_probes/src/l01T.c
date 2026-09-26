#include <stdlib.h>

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int r = t; if (m > 3) r = cq_theta(t, .2); return cq_measure(r); }
