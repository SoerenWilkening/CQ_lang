/* slice_control_select.c — Phase 4.4 e2e smoke (WI-4, test_C_libtooling-polz.4):
   the RSSA tainted-`select` controlled-XOR copy merge, the only test layer that
   LINKS and so the ONLY proof that 4.4's new runtime symbol
   cqrt_copy_<W>_controlled (WI-2) resolves and signature-matches against
   libcq_runtime (Rule 2, Rule 16) — verify-clean and "runs without crashing"
   prove neither.

   SOURCE INTENT (the canonical §15 shape — a tainted-condition integer-data
   ternary, the simplest Phase-4 control shape: ONE SSA instruction, no diamond):
       q : tainted quantum handle (condition register, cq_theta == Ry)
       x : classical integer (the false operand)
       sel = (q > 5) ? q : x;
       measure sel

   At -O1 SimplifyCFG speculates the ternary into a single `select i1 %c, q, x`
   (NO br-diamond, NO phi); ControlDetect routes it to SelectMergeEmit, which
   lowers the §5a controlled-XOR copy merge: mint the flag from the icmp -> alloc
   the |0> result rail -> cqrt_copy_<W>_controlled the TRUE operand (q) on the
   flag -> X-bracket and cqrt_copy_<W>_controlled the FALSE operand (x,
   materialized to a fresh handle via cqrt_alloc because it is a classical value)
   on ¬flag -> icmp_sgt_i32_hl_unc strip -> the ONE cqrt_free (the flag) ->
   RAUW %sel -> %out. The merge is a COPY, NOT a route: NO cqrt_cswap, NO rail
   route, NO phi, NO RegionFlatten, NO reverse-play, ZERO controlled ROTATIONS
   (a CNOT-copy of a basis label is correct here precisely because both operands
   are basis-valued; Rule 7 / §16.7 — a coherent operand declines, not lowers).

   EXACTLY ONE free (the flag). q, %out, and the materialized scratch are LEFT
   ALLOCATED (never freed): %out carries the answer, and q / the scratch are
   entangled with %out through the copy, so freeing either is a hidden
   measurement that collapses the superposition (Rule 6 / Rule 8). Contrast the
   method-B value diamond (slice_control_value_diamond), which DOES free the
   work rail after reverse-play — a select has no rail to reverse-play.

   WHY THE TRACE IS DETERMINISTIC: the runtime is trace-only and the select is
   straight-line (no branch), so every emitted gate fires unconditionally
   regardless of q's value; cqrt_measure returns 0 (no simulation). WHY A
   CONSTANT FALSE OPERAND (x = 9): at -O1 `main` inlines this trivial `slice`, so
   the EXECUTED trace is main's inlined copy with x folded to the literal 9 —
   exercising the classical-operand materialization path (cqrt_alloc_i32(9)); the
   true operand q stays a bare handle (materialize is the identity on a quantum
   handle, no alloc). The golden pins the trace captured from REAL linked output
   (templates BEFORE runtime — load-bearing link order). cq_theta / cq_measure
   resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    int x = 9;
    cq_theta(&q, 0.5);             /* taint q -> condition handle (alloc, ry)   */
    int sel = (q > 5) ? q : x;     /* tainted select -> controlled-XOR copy merge*/
    return cq_measure(sel);        /* reads the copied-out answer (out)          */
}
int main(void) { (void) slice(); return 0; }
