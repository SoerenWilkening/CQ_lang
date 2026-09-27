#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = 0; for (int i = 0; i < 3; i++) t += h(q, i); q = cq_theta(q, .7); return t + cq_measure(q); }
