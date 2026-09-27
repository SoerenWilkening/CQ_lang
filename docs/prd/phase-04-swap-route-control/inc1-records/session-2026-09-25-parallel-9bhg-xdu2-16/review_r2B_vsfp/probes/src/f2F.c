#include <stdlib.h>
int G;
__attribute__((noinline)) int g(int a) { G = 1; return a * 3; }
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); (void)g(q); int t = m + 1 + G; q = cq_theta(q, .7); return t + cq_measure(q); }
