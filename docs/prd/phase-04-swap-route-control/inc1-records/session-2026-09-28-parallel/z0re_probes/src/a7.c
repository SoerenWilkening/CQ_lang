#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r; if (q != 5) r = cq_theta(5, .9); else r = cq_theta(q, .3); return cq_measure(r) + cq_measure(q); }
