#include <stdlib.h>
int h(int a, int k);
int ext_f(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = h(q, y); int acc = 0; for (int i = 0; i < 8; i++) { if (t > i) break; acc += i; } return acc + cq_measure(q) + cq_measure(y); }
