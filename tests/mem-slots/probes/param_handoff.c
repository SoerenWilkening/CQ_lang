#include "CQ.h"
/* cq-2cl6 (CR rules 18, 20): a clone hands its caller's slot object (a pointer formal) on to a clone that writes
   it (musl frexpl's recursive frexpl(x * 0x1p120, e) then *e -= 120). The inner call runs on a frame copy of the
   cells; the outer clone's clone cell (cloneCellOf) takes the call's new handle as the cell's value.
   Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec param_handoff.c -o param_handoff.O1.ll
   then append the CHECK / USERCHECK lines below the IR. */
__attribute__((noinline)) static int inner(int x, int *e) {
  if (x > 3) { *e = x - 3; return x >> 1; }
  return x;
}
/* the cell written by the call under a quantum predicate, then read and written again (frexpl's shape) */
__attribute__((noinline)) static int outer(int x, int *e) {
  if (x < 100) {
    if (x != 0) {
      int r = inner(x * 2, e);
      *e = *e - 1;
      return r;
    }
    *e = 0;
    return x;
  }
  return x + 1;
}
int param_handoff_pred(int x0, int th) {
  int x = x0; cq_theta(&x, th);
  int e = 7;
  int r = outer(x, &e);
  return cq_measure(r) * 1000 + cq_measure(e);
}
/* an unconditional handoff through a pure forward, then an update of the cell */
__attribute__((noinline)) static int fwd(int x, int *e) { return inner(x, e); }
__attribute__((noinline)) static int upd(int x, int *e) {
  int r = fwd(x + 1, e);
  *e += 5;
  return r;
}
int param_handoff_plain(int x0, int th) {
  int x = x0; cq_theta(&x, th);
  int e = 2;
  int r = upd(x, &e);
  return cq_measure(r) * 1000 + cq_measure(e);
}
/* a quantum-depth recursion handing the pointer down its levels (B = 3 <= K) */
__attribute__((noinline)) static int rec(unsigned n, int x, int *e) {
  if (n != 0) {
    int r = rec(n - 1, x * 2, e);
    *e -= 1;
    return r;
  }
  *e = 0;
  return x;
}
int param_handoff_rec(int x0, int th, int k) {
  int x = x0; cq_theta(&x, th);
  int e = 9;
  int r = rec(x & 3, x, &e) + k;
  return cq_measure(r) * 1000 + cq_measure(e);
}
/* the formal points to either of two objects (two call sites: a rule 21 slot triple, musl frexpl's pointer over
   powl's and powil's exponents); the frame copy crosses as a triple of its own */
__attribute__((noinline)) static int inner2(int x, int *e) {
  if (x & 1) *e = x + 3;
  return x ^ 5;
}
__attribute__((noinline)) static int outer2(int x, int *e) {
  int r = inner2(x, e);
  if (x > 5) *e = *e * 3;
  return r;
}
int param_handoff_two(int x0, int th, int k) {
  int x = x0; cq_theta(&x, th);
  int a = k, b = k + 1;
  int r = outer2(x, &a) + outer2(x + 1, &b);
  return cq_measure(r) * 1000000 + cq_measure(a) * 1000 + cq_measure(b);
}
/* a slot triple formal's cell read and written under a quantum predicate (a clone cell: its load reads the
   cell's value, not the caller's memory, which holds the clone's slot result) */
__attribute__((noinline)) static int scale(int x, int *e) {
  if (x > 5) *e = *e * 3;
  return x ^ 5;
}
int triple_clone_cell(int x0, int th, int k) {
  int x = x0; cq_theta(&x, th);
  int a = k, b = k + 1;
  int r = scale(x, &a) + scale(x + 1, &b);
  return cq_measure(r) * 1000000 + cq_measure(a) * 1000 + cq_measure(b);
}
