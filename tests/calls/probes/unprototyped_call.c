/* tests/calls probe (cq-3fzuf, CR rule 18): a call through an unprototyped declaration (C17 `int g();`) in one translation
 * unit, the definition `int g(void)` in another. After llvm-link the call is `call i32 (...) @g()` against a callee of
 * type `i32 ()`: the same direct call, which every part of the pass must see as one.
 * Regenerate: for t in CALLER CALLEE; do clang -O1 -S -emit-llvm -std=c17 -target x86_64-apple-macosx16.0.0 -I ../../../spec
 *   -D$t unprototyped_call.c -o $t.ll; done; llvm-link -S CALLER.ll CALLEE.ll -o unprototyped_call.O1.ll */
#include "CQ.h"
#ifdef CALLEE
int ctr;
__attribute__((noinline)) int g(void) { return ++ctr; }
#else
int g();
int up(int x) {
  int q = x;
  cq_theta(&q, 0.5);
  int r = g();
  return cq_measure(q + r);
}
#endif
