#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; volatile int z = p; int t = m + 1; return t + cq_measure(q); }
