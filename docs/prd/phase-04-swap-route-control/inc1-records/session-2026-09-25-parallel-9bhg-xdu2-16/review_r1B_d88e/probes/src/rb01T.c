#include <stdlib.h>
#include <stdio.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int q2=cq_theta(n,.3); int r=0; if (q2>3) r=(m+1); return cq_measure(r)+cq_measure(q2); }
