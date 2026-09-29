#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int b[2]; b[0] = q; b[1] = h(q, m); int s = cq_measure(b[n & 1]); return s + cq_measure(q); }
