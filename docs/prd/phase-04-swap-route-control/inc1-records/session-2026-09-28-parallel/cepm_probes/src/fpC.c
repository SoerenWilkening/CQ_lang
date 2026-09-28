#include <stdlib.h>
double hf(int a, double k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); double t = hf(q, (double)m); if (t > 7.0) q = cq_theta(q, .2); return cq_measure(q); }
