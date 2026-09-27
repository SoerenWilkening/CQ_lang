#include <stdlib.h>
double hd(double a, double k);
__attribute__((noinline)) double f(double m) { double q = cq_theta(m, .5); return hd(q, m); }
int main(int c, char **v) { double m = atoi(v[1]); double r = f(m); return (int)cq_measure(r); }
