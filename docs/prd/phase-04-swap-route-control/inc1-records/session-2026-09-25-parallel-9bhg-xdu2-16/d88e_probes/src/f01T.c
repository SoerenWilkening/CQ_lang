#include <stdlib.h>
double hf(double a, double k);

int main(int c, char **v) { double m = atof(v[1]); double q = cq_theta(m, .5); double t = m + 1.0; double r = t; if (m > 3) r = cq_theta(t, .2); return (int) cq_measure(r); }
