#include <stdlib.h>
int hf(double a, int k);
int main(int c, char **v) { int m = atoi(v[1]); double d = cq_theta((double)m, .5); double e = d * 2.0; int t = hf(e, m); d = cq_theta(d, .7); return t + (int)cq_measure(d); }
