#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = h(q, m); q ^= 5; q = cq_theta(q, .7); return r + cq_measure(q); }
