#include <stdlib.h>
int h(int a, int k);

int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int r; if (m > 3) r = cq_theta(t, .2); else { r = cq_theta(t, .7); r = cq_theta(r, .1); } return cq_measure(r); }
