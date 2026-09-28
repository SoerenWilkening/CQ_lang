#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); g(q); double t = (double)m * 2.0; if (t > 7.0) q = cq_theta(q, .2); return cq_measure(q); }
