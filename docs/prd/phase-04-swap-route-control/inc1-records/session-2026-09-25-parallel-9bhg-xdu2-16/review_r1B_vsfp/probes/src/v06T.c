#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q1 = cq_theta(m, .5); int q2 = cq_theta(q1, .7); int t = m + 1; return t + cq_measure(q2); }
