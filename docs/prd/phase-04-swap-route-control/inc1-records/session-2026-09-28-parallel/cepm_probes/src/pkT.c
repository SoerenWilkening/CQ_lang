#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); if (q > 5) { g(q); cq_phi(0.4); } return cq_measure(q); }
