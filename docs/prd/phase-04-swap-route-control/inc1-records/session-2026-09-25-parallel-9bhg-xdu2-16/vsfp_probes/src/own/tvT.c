#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); volatile int z = q; int t = m + 1; return cq_measure(t) * 100 + cq_measure(q); }
