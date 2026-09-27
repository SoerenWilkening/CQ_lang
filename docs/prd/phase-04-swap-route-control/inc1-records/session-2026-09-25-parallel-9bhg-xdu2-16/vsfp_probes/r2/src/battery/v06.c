#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q1 = cq_theta(m, .5); int q2 = cq_theta(q1, .7); int t = h(q1, m); return t + cq_measure(q2); }
