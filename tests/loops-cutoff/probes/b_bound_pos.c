/* tests/loops-cutoff cq-8i5g probe (cq-qc70, CR §1.4, rule 14): a clone's _b bound belongs to the formal whose call-site
 * range bounded it. g's loop runs at most n trips, ending early where y runs out of low one bits; the first call
 * bounds n (x & 3, clone _b3, cutoff 3), the second bounds y and not n (its loop keeps K = 4 trips and its a_K):
 * both clones are named _b3 and are distinct clones. Each entry is checked §6 against its
 * own C program (cqcheck user). Regenerate b_bound_pos.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec b_bound_pos.c -o b_bound_pos.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int g(unsigned n, unsigned y) {
  int s = 1;
  for (unsigned i = 0; i < n && ((y | 4) >> i) & 1; i++)
    s = (s * 3) ^ (int)(y >> (s & 7));
  return s;
}
int bp_first(unsigned char k, double th) { unsigned char x = k; cq_theta(&x, th); return g(x & 3, x); }
int bp_second(unsigned k, double th) { unsigned x = k; cq_theta(&x, th); return g(x, x & 3); }
