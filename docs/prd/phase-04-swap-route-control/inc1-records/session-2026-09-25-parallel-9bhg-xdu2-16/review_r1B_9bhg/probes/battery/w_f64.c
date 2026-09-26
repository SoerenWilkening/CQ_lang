#include <stdlib.h>
double hw(double a, double k);
__attribute__((noinline)) double fw(double m) { double q = cq_theta(m, .5); return hw(q, m); }
int main(int argc, char **argv) { double m = (double)atoi(argv[1]); double n = (double)atoi(argv[2]); double q2 = cq_theta(n, .25); double u = q2 + fw(m); return (int)cq_measure(u); }
