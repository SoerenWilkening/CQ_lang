/* classical_call_under_control_caller.c — the CQ translation unit for the Phase
   6.5 e2e golden (test_C_libtooling-mvna.11, WI-5.7): a PURE CLASSICAL call under
   QUANTUM CONTROL with CLASSICAL inputs (DD-7 / PRD §2.13). The clone-ORTHOGONAL
   Phase-6 capability — it depends ONLY on the cleared swap-route Phase-4 path, not
   on clone-on-taint.

   SOURCE INTENT: `q` is theta-tainted (the condition register). The diamond
       int y = q;
       if (q > 5) y = ext_f(7);   // pure classical call, CLASSICAL constant arg
       measure y;
   has a 2-incoming merge phi [q (tainted, straight-through), ext_f(7) (a direct
   classical call result)]. Because `ext_f` is PURE and its argument is classical,
   `ext_f(7)` runs CLASSICALLY: the call is HOISTED into the pred (inert — its
   result on the inactive branch is computed-and-discarded), and its i32 result is
   routed into the controlled register by the 4.4-style controlled-XOR copy merge
   over the FLATTENED diamond — mint the flag from the icmp, alloc the |0> out
   rail, copy the cond-TRUE value (the call result, materialized via cqrt_alloc)
   on the flag, X-bracket + copy the cond-FALSE value (q, the identity) on ¬flag,
   icmp_inv strip, the ONE cqrt_free (the flag). NO clone (@__cq_q_), NO cqrt_cswap,
   NO reverse-play, NO input-tainting, ZERO controlled rotations.

   `ext_f` is DECLARED (not defined) here, so it is a direct call to a visible,
   un-inlined, pure body ONLY after classical_call_under_control_lib.c is linked in
   (the structural guarantee that opt sees the readnone body — Rule 9). This is the
   ONLY layer that LINK-proves the hoisted classical call + cqrt_copy_i32_controlled
   + the materialized alloc all resolve and signature-match through the multi-file
   pipeline (Rule 2). q, %out, and the materialized scratch are LEFT ALLOCATED
   (freeing an operand entangled with %out via the copy is a hidden measurement —
   Rule 6/8); EXACTLY ONE free (the flag). */
int ext_f(int a);

int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> condition handle (alloc, ry)   */
    int y = q;
    if (q > 5)                     /* tainted-condition diamond                 */
        y = ext_f(7);              /* pure classical call -> route-merged result */
    return cq_measure(y);          /* reads the route-merged answer (out)        */
}

int main(void) { (void) slice(); return 0; }
