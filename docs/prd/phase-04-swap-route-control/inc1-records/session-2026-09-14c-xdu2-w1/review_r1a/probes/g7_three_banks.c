#include <stdbool.h>
int main(void) { int a = 9; bool b[3]={0}, c[3]={0}, d[3]={0};
  for (int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],.5); if(b[i]) a-=3; }
  for (int i=0;i<3;++i){ if(a>=3) c[i]=cq_theta(c[i],.5); if(c[i]) a-=3; }
  for (int i=0;i<3;++i){ if(a>=3) d[i]=cq_theta(d[i],.5); if(d[i]) a-=3; }
  int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i])+cq_measure(c[i])+cq_measure(d[i]); return s; }
