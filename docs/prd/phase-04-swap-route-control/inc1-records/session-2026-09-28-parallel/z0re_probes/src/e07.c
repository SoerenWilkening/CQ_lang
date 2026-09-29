#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q0 = cq_theta(n, .4); int s = cq_measure(q0); int q = cq_theta(m, .5); int r = s; if (q > 3) r = cq_theta(s, .2); return cq_measure(r) + cq_measure(q); }
