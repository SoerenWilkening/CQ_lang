#include <stdio.h>
__attribute__((noinline,const)) static int f(int x){ return x*3+1; }
volatile int gk = 4; volatile int kv2 = 1; volatile int sink;
int main(void){
  int k = gk;
  int q = cq_theta(0, 0.5);
  int r = 0;
  if (q == 1) r = f(k);
  if (kv2) sink = 1;
  int a = cq_theta(0, 0.4);
  int m = 5;
  if (q == 2) { a = cq_theta(a, 0.9); m = r; }
  printf("%d %d %d\n", cq_measure(a), cq_measure(m), cq_measure(r));
  return 0;
}
