#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); unsigned q = cq_theta((unsigned)(m & 255), .5); int n = __builtin_popcount(q); int t = h(n, m); q = cq_theta(q, .7); return t + cq_measure(q); }
