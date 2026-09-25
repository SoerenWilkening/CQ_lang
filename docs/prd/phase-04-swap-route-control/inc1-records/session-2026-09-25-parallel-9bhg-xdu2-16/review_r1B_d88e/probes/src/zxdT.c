#include <stdlib.h>

int main(int c, char **v) { double m=atof(v[1]); int n=atoi(v[2]); double q=cq_theta(m,.5); double t=(m+1.0); int q2=cq_theta(n,.3); double r=t; if (q2>3) r=cq_theta(t,.2); return (int)cq_measure(r)+cq_measure(q2); }
