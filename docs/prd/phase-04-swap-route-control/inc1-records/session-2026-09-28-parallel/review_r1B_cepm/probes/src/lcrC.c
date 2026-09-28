#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); for (int i = 0; i < 3; i++) { int t = h(q, i + n); if (t > 2) q = cq_theta(q, .1); } return cq_measure(q); }
