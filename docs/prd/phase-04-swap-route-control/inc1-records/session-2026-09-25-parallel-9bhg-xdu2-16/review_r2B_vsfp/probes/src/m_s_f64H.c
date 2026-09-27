#include <stdlib.h>
double hd(double a, double k); double g2d(double a, double b);
int main(int argc, char **argv) { double m = (double)atoi(argv[1]); double n = (double)atoi(argv[2]); double q = cq_theta(m, .5); double q2 = cq_theta(n, .25); double t1 = m + 1; double t2 = hd(m, q2); double u = g2d(t1, t2); return (int)cq_measure(u); }
