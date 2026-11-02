/* tests/calls probe (cq-57ju; CR rule 19 ruling 2026-11-02, cq-fl4n): a host call with classical arguments, a
 * classical result and no gate under a quantum predicate stays the host call, executed unguarded, its result
 * merged like any classical arm value; the volatile local inside it is nothing (rule 24). */
#include "CQ.h"
static __attribute__((noinline)) int helper(int k) { volatile int t = k * 7; return t + 1; }
static __attribute__((noinline)) int other(int k) { return k * k - 2; }
int hc_arm(int a, int k) { int x = a; cq_theta(&x, 0.6); int r = x; if (x > k) r = helper(3); return cq_measure(r); }
int hc_both(int a, int k) { int x = a; cq_theta(&x, 0.6); int r = x > k ? helper(k) : other(k); return cq_measure(r + x); }
