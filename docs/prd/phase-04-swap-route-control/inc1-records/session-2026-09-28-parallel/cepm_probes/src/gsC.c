#include <stdlib.h>
int h(int a, int k);
int G;
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); if (q > 5) G = h(q, m); return cq_measure(q) + G; }
