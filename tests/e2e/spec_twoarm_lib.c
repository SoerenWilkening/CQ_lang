/* spec_twoarm_lib.c — the CLASSICAL library TU for the Phase 6 / issue 5po2 I1
   golden (two-arm integer select in a lifted clone). Compiles WITHOUT the CQ.h
   intrinsic surface (C18 — run_slice_multi.sh applies `-include CQ.h` to the CQ
   TU only); the tripwire below fails LOUDLY if the harness ever force-includes
   CQ.h into a lib TU.

   `helper` is the 5po2 I1 accept shape beyond the increment-1 `select(icmp,
   param, 0)`: a VISIBLE, PURELY-CLASSICAL, NON-RECURSIVE i32 if/else whose two
   arms are BOTH DERIVED (non-constant, non-factorable), so `clang -O1`
   if-converts it to `select(icmp sgt b,5, (b<<2)^9, (b+100)*3)` — a two-arm
   integer merge. Handed a TAINTED (quantum) argument, the specializer lifts it
   into `__cq_q_helper_1` and emits the full 4.4 two-copy stream (copy_T · ¬flag
   `cqrt_x` bracket · copy_F · `cqrt_x`) over an integer `cqrt_copy_i32_controlled`
   and a |0> out rail (flag kept LIVE), then Bennett-wraps it. The golden's
   PALINDROMIC reverse (both `cqrt_x` brackets replay, the flag `_unc` unmints,
   every derived-arm producer `_unc` runs, then ALL frees after the complete
   reverse) is the trace contract (Rules 2, 6, 13, 16). */

/* bd p3kd.7.8 (2026-10-07): the lifted clone now runs MAIN'S stage list, so its
   tainted select lowers through main's 4.4 merge (CondTreeEmit/SelectMergeEmit)
   and the Bennett wrap reverses it mechanically. Two trace changes, golden
   regenerated deliberately: the merge's trailing ¬flag `cqrt_x` (nothing reads
   the flag after the second copy) and its mirror at the start of the reverse are
   elided as a pair; where an arm is a constant zero, its materialized |0> rail
   is copied (a no-op) and now freed after the reverse. Every other gate is
   unchanged. The descriptions above are
   the pre-p3kd.7.8 stream. */

#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int helper(int b) {
    int a;
    if (b > 5) a = (b << 2) ^ 9;
    else       a = (b + 100) * 3;
    return a;
}
