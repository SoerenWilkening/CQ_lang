#include <stdlib.h>
__attribute__((noinline)) int F(int m) { int q = cq_theta(m, .5); int u = m + 1; q = cq_theta(q, .7); return u + cq_measure(q); }
int main(int c, char **v) { int m = atoi(v[1]); return F(m); }
