/* tests/calls probe (cq-xhv4, 169's ilogb_1_unc): a clone with a quantum-exit loop keeps rule 14's overflow
 * predicate a_K per activation; its twin, which only uncomputes the forward's result, computes no a_K of its own.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec twin_kept_overflow.c -o twin_kept_overflow.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int lz(unsigned v) { int e = 0; while (v && !(v & 1u)) { v >>= 1; e++; } return e; }
int tk(unsigned a, double th) { unsigned x = a; cq_theta(&x, th); return cq_measure(lz(x) > 2); }
