#include <stdlib.h>
void g(int a);
int g4(int a, int b);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); g(q); int t = m + 1; int u = g4(t, q); return cq_measure(u) + cq_measure(q); }
