/* tests/loops-cutoff cq-zge7 probe: a clone's _b bound below SCEV's constant maximum trip count. f's unsigned i32
 * trip count has SCEV maximum 0xFFFFFFFF; the call site f(x & 3, x) bounds n to 3 (clone _b3), so CR rule 14's
 * cutoff is min(K, 3) = 3 and the clone keeps no a_K. The second call (bound 7 > K) keeps K = 4 trips.
 * Regenerate b_bound_i32.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec b_bound_i32.c -o b_bound_i32.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int f(unsigned n, unsigned y) { int s = 1; for (unsigned i = 0; i < n; i++) s = (s * 3) ^ (y >> (s & 7)); return s; }
int bb_i32(unsigned char k) { unsigned char x = 0; cq_theta(&x, 1.0); return f(x & 3, x) + f((x >> 2) & 7, x + k); }
