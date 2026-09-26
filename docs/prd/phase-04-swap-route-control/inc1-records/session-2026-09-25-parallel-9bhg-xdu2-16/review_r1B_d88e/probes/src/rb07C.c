#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int b[4]={0,0,0,0}; b[n&3]=t; int r=b[m&3]; return cq_measure(q)+r; }
