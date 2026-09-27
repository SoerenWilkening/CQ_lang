#include <stdio.h>
#include <stdlib.h>
__attribute__((naked, noinline)) int ident(int a) {
  __asm__("movl %edi, %eax\n\tret");
}
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int r = ident(q);
  printf("ident=%d\n", r);
  return cq_measure(q);
}
