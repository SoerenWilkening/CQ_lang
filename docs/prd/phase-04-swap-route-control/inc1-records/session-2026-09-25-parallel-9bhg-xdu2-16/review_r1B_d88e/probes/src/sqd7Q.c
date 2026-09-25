#include <stdlib.h>
double h(double a, double k);
int main(int c, char **v) { double m = atof(v[1]); int m2 = atoi(v[2]); double q = cq_theta(m, .5); double t = h(q, m); double r = t; if (m2 > 3) r = cq_theta(t, .2); return (int)cq_measure(r) + (int)cq_measure(q); }
