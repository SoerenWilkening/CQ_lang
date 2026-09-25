#include <stdlib.h>
int h(int a, int k);

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = t; _Bool b = cq_theta((_Bool)0, .3); for (int i = 0; i < 3; i++) { if (b) r = cq_theta(r, .1); } return cq_measure(r) + cq_measure(b); }
