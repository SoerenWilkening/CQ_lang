#include "CQ.h"
/* cq-e5lj (CR rules 20, 26): records at a run-time offset. A struct with an array field indexed at run time, and a
   local array of structs taint keeps whole (an aggregate field), are records whose run-time access names one field
   of a run of same-type fields (recordRun); main stopped at "a slot record accessed at a run-time offset" and
   "an array of structs holding handles". */
struct S { int n; int v[4]; };
int rec_rt(int k, int x0, double th) {
  struct S s;
  s.n = 3;
  for (int i = 0; i < 4; i++) s.v[i] = i;
  int x = x0; cq_theta(&x, th);
  s.v[k & 3] = x;
  return cq_measure(s.v[k & 3]) + cq_measure(s.v[(k + 1) & 3]) + s.n;
}
struct P { int a; int b[2]; };
int aos_nested(int k, int x0, double th) {
  struct P p[3];
  for (int i = 0; i < 3; i++) { p[i].a = i; p[i].b[0] = 0; p[i].b[1] = 1; }
  int x = x0; cq_theta(&x, th);
  p[k % 3].b[1] = x;
  return cq_measure(p[k % 3].b[1]) + cq_measure(p[(k+1) % 3].a);
}
int rec_rt2(int k, int x0, double th, int m) {
  struct S s;
  s.n = m;
  for (int i = 0; i < 4; i++) s.v[i] = i;
  int x = x0; cq_theta(&x, th);
  s.v[k & 3] = x;
  int r = 0;
  for (int i = 0; i < (m & 3); i++) r += s.n;
  return cq_measure(s.v[k & 3]) + cq_measure(s.v[(k + 1) & 3]) + r;
}
