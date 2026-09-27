#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(m + 1, .3); p = cq_theta(p, .4); return cq_measure(q) + cq_measure(p); }
