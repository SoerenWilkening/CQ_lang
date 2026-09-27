#include <stdlib.h>
#include <stdbool.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int a = f(m); bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; } return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a); }
