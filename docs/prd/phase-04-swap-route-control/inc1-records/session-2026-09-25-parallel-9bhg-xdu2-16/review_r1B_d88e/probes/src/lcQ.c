#include <stdlib.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int r=t; if (m>3) r=cq_theta(t,.2); if (r>5) cq_phi(.3); return cq_measure(r); }
