#include <stdio.h>
int f(int a){
  cq_theta(&a, 1.0);
  if(a&1) puts("h"); else puts("k");
  return cq_measure(a);
}
