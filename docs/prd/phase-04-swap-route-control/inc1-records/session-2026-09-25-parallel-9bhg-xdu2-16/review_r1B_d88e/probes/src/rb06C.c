#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int main(int c, char **v) { static const int tab[8]={3,1,4,1,5,9,2,6}; int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int r=tab[t&7]; return cq_measure(q)+r; }
