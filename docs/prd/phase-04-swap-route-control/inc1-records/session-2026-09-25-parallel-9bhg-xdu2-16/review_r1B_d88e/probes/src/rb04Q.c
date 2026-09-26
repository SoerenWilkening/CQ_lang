#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=m; switch(q2){case 1: r=t; break; case 2: r=t+1; break; case 5: r=t+2; break;} return cq_measure(r)+cq_measure(q2); }
