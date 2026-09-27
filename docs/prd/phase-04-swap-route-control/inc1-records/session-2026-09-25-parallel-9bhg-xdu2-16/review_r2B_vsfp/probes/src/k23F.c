#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int u = q * 3; int r = (m + 1); if (u == 9) cq_phi(3.14159); q = cq_theta(q, .7); return r + cq_measure(q); }
