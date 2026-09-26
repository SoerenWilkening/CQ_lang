#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);

__attribute__((noinline)) long f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return (long)t << 3; }
int main(int c, char **v) { int m = atoi(v[1]); return (int)f(m); }
