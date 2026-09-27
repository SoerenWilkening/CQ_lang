#include <stdlib.h>
#include <stdio.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; return t > 5; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return cq_measure(x) * 10 + x; }
