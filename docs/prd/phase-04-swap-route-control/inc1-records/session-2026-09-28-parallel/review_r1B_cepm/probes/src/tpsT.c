#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int p = q * 3; g(p); int t = m + 1; switch (t) { case 4: q = cq_theta(q, .2); break; case 6: q = cq_theta(q, .3); break; default: break; } return cq_measure(q); }
