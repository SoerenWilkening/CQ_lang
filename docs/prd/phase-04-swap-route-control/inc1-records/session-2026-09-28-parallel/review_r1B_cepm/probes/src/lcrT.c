#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); for (int i = 0; i < 3; i++) { g(q); int t = i + n + 1; if (t > 2) q = cq_theta(q, .1); } return cq_measure(q); }
