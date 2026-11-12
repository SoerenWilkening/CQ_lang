/* tests/loops-cutoff cq-tntm (CR rule 14: "The cutoff is min(K, B) ... `a_K` is kept only when B > K or no bound is
 * known"): B = 0 is a known bound. cnt's loop is header-tested (-O1's tail recursion); the call bounds m to [0, 1]
 * (clone _b1), so its header runs at most once and no body runs: the clone makes no trip (no mul template) and keeps no
 * a_K. Checked §6 against its own C program (cqcheck user). Regenerate b_bound_zero.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec b_bound_zero.c -o b_bound_zero.O1.ll */
#include "CQ.h"
__attribute__((noinline)) unsigned cnt(unsigned m, unsigned s) {
  if (m > 1) return cnt(m - 1, s * 3 + m);
  return s;
}
unsigned pf_b0(unsigned k, double th) { unsigned x = k; cq_theta(&x, th); return cq_measure(cnt(x & 1, x)); }
