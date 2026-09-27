#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int x = f(m); bool bb[3]; for (int i = 0; i < 3; ++i) bb[i] = cq_theta((bool)((x >> i) & 1), .5); return cq_measure(bb[0]) + cq_measure(bb[1]) + cq_measure(bb[2]); }
