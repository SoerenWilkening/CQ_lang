#include <stdlib.h>
int h(int a, int k);

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = t; switch (m) { case 1: r = cq_theta(t, .2); break; case 2: r = cq_theta(t, .4); break; default: break; } return cq_measure(r); }
