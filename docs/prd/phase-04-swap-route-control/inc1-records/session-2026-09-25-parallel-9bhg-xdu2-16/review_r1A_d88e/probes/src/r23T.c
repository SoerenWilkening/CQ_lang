#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int r = t; for (int i = 0; i < 2; i++) { if (m > 3 + i) r = cq_theta(r, .2); } return cq_measure(r); }
