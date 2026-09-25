#include <stdlib.h>
double h(double a, double k);
int main(int c, char **v) { double m = atof(v[1]); int m2 = atoi(v[2]); double q = cq_theta(m, .5); double t = h(q, m); int acc = 0; for (int i = 0; i < m2; i++) { double r = t; if ((i & 1) == 0) r = cq_theta(t, .2); acc += (int)cq_measure(r); } return acc; }
