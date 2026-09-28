#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < 4; i++) { g(q); acc += i + m + 1; } if (acc > n) q = cq_theta(q, .2); return cq_measure(q); }
