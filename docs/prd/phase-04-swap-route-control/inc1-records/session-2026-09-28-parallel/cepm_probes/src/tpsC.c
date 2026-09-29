#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int p = q * 3; int t = h(p, m); switch (t) { case 4: q = cq_theta(q, .2); break; case 6: q = cq_theta(q, .3); break; default: break; } return cq_measure(q); }
