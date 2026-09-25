#include <stdlib.h>
int main(int c, char **v) { double m = atof(v[1]); int m2 = atoi(v[2]); double q = cq_theta(m, .5); double t = (q + m); double r = t; int x = 0; if (m2 > 3) r = cq_theta(t, .2); else x = (int)cq_measure(t); return (int)cq_measure(r) + x; }
