#include <stdlib.h>
int g(int a, int b);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int s = g(p, q); q = cq_theta(q, .7); return cq_measure(s) + cq_measure(q); }
