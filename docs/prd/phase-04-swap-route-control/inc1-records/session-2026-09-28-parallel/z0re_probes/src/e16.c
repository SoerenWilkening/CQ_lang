#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int r = q; if (q == s) r = cq_theta(q, .2); return cq_measure(r); }
