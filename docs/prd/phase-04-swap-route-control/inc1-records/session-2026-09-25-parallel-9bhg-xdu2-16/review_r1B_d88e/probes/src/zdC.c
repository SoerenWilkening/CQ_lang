#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=t; if (q2==t) r=cq_theta(q2,.2); return cq_measure(r)+cq_measure(q2); }
