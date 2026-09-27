#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); static const int T[8] = {3,1,4,1,5,9,2,6}; return T[t & 7]; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return cq_measure(x) * 10 + x; }
