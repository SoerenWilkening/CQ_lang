#include "CQ.h"
/* cq-e5lj (CR rules 14, 21): a K-loop trip the C program does not run walks a pointer past a local struct: the
   load reads |0> whatever the record layout; main stopped at "a walked access beyond a slot record". */
struct S { int a; int b; };
int rec_walk(int x0, double th, int u) {
  struct S s; s.a = u; s.b = 2;
  int x = x0 & 7; cq_theta(&x, th);
  s.a = x;
  int *p = &s.a; int acc = 0;
  while (x > 0) { acc += *p; p++; x--; }
  return cq_measure(acc);
}
