#include <stdlib.h>
__attribute__((noinline)) int f(int s, int m) { int q = cq_theta(m, .5); int r = s; if (q > 3) r = cq_theta(s, .2); return cq_measure(r) + cq_measure(q); }
int main(int c, char **v) { return f(atoi(v[2]), atoi(v[1])); }
