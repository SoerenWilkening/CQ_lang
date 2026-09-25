#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int acc=0; for (int i=0;i<3;i++) { int r=t; if (q2>i) r=cq_theta(t,.2); acc+=cq_measure(r); } return acc+cq_measure(q2); }
