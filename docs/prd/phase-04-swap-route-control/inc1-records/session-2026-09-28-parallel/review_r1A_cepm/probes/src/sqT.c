#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = n; switch (q) { case 3: g(q); t = n + 1; break; case 5: g(q); t = m + 1; break; default: break; } return cq_measure(t) + cq_measure(q); }
