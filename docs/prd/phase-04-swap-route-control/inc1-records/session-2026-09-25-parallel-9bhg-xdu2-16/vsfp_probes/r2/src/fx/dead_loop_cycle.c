#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int a = 5; int s = m; bool b0[3]; for (int i = 0; i < 3; ++i) { if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); } if (b0[i]) a -= 3; if (b0[i]) s -= 7; } int t = h(s, m); return t + cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a); }
