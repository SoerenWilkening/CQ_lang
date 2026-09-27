#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = m * 3 + 1; q = cq_theta(q, .7); return cq_measure(q) + cq_measure(r); }
