#include <stdlib.h>
int main(int c, char **v) { double m = atof(v[1]); int m2 = atoi(v[2]); double q = cq_theta(m, .5); double t = (q + m); double r = t; switch (m2) { case 1: r = cq_theta(t, .1); break; case 4: r = cq_theta(t, .4); break; case 7: r = cq_theta(t, .7); break; } return (int)cq_measure(r); }
