#include <stdlib.h>
void g(int a);
int g3(int x);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); g(q); int t = m + 1; if (g3(t) > 3) q = cq_theta(q, .2); return cq_measure(q); }
