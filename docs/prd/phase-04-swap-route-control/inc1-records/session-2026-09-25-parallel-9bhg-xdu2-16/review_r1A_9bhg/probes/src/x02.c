#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);

__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int a[4] = {0,0,0,0}; a[m & 3] = t; return a[(m + 1) & 3]; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m) * 2; }
