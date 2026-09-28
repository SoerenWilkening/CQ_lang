#include <stdlib.h>
double h(double a, double k);
int main(int c, char **v) { double m=atof(v[1]); int n=atoi(v[2]); double q=cq_theta(m,.5); double t=h(q, m); int q2=cq_theta(n,.3); double r=t; if (q2>3) r=cq_theta(t,.2); return (int)cq_measure(r)+cq_measure(q2); }
