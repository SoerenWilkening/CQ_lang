#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); for (int i = 0; i < 3; i++) { g(q); int t = i + m + 1; if (q > t) cq_phi(0.2); else cq_phi(0.3); } return cq_measure(q); }
