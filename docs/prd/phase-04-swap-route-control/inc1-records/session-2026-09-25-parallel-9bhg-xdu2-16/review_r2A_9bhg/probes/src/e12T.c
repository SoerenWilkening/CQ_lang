#include <stdlib.h>
#include <stdio.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; int a[4] = {0,0,0,0}; a[m & 3] = t; return a[(m+1) & 3] + a[m & 3]; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return cq_measure(x) * 10 + x; }
