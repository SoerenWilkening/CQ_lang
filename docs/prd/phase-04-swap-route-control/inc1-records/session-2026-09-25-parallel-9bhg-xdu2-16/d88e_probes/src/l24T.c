#include <stdlib.h>

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int r = t; for (int i = 0; i < 3; i++) { if (m > i) r = cq_theta(r, .1); } return cq_measure(r); }
