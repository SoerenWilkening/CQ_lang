#include <stdlib.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m+1); int q2=cq_theta(n,.3); int acc=0;
 { int r=t; if (q2>0) r=cq_theta(t,.2); acc+=cq_measure(r); }
 { int r=t; if (q2>1) r=cq_theta(t,.2); acc+=cq_measure(r); }
 { int r=t; if (q2>2) r=cq_theta(t,.2); acc+=cq_measure(r); }
 return acc+cq_measure(q2); }
