#include <stdlib.h>

int G;
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; int t2 = m + 3; int r = t; if (m > 3) r = cq_theta(t, .2); G = cq_measure(r); return t2; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return x + G; }
