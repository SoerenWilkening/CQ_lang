#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int b[4]; for (int i = 0; i < 4; i++) b[i] = h(q, i); int x = b[m & 3]; int r = x; if (m > 3) r = cq_theta(x, .2); return cq_measure(r); }
