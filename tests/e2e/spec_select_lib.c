/* spec_select_lib.c — the CLASSICAL library TU for the Phase 6 / issue 5po2
   golden. Compiles WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh
   applies `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at
   compile if the harness ever force-includes CQ.h into a lib TU.

   `foo` is the 5po2 accept shape: a VISIBLE, PURELY-CLASSICAL, NON-RECURSIVE,
   single-basic-block i32 body whose ONLY control is a tainted `select` — the
   `clang -O1` lowering of `int a=0; if(b<5) a+=b; return a` is
   `select(icmp slt b,5, b, 0)`. Handed a TAINTED (quantum) argument, the
   specializer lifts it into `__cq_q_foo_1`, emits the select as a controlled-XOR
   copy `out = flag ? b : 0`, and Bennett-wraps it. The golden's reverse (the
   self-inverse `cqrt_copy_i32_controlled` re-applied to zero the out rail, then
   the compare `_unc` to unmint the flag, then BOTH frees AFTER the complete
   reverse) is the trace contract for a lifted in-body control select
   (Rules 2, 6, 13, 16). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int foo(int b) {
    int a = 0;
    if (b < 5) a += b;
    return a;
}
