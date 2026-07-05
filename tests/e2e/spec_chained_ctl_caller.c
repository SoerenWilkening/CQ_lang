/* spec_chained_ctl_caller.c — bd afmv e2e smoke: CHAINED onward control feeding a ROUND-1
   Phase-6 spec candidate, the fix for the yn71-introduced verify-clean silent miscompile the
   9paa Rule-13 workflow discovered. Driven through the full clang -O1 -> llvm-link -> opt
   cq-lowering -> link -> run pipeline (the ONLY layer that LINKS, Rule 2/16).

   SOURCE INTENT:
       q : tainted quantum condition handle
       int y = 5;  if (q>5)  y = ext_f(7);    // region 1: 6.5 classical-call arm -> %out1
       int w = 6;  if (y>50) w = ext_f(7);    // region 2: cond reads %out1 -> yn71 %out2 rail
       int z = gg(w, q);                      // ROUND-1 Pending gg(w=%out2, q); mask 0b10 frozen
       m1 = measure(z);
       m2 = measure(y);                       // keeps region-1 merge live -> materialize BOTH rails

   THE MISCOMPILE (pre-afmv): gg is a round-1 Pending candidate (reads the theta handle q), so
   its mask was frozen 0b10 while `w` (region-2 merge) was data-untainted. yn71's
   `detectAndLowerOnwardControl` lowers region 2 in round 2 to %out2 (a quantum rail), but the
   re-plan's reseed set was frozen BEFORE that fixpoint, so gg's stale 0b10 mask was never
   re-widened. `declineTaintEscapes` CARVED gg (it is Pending) rather than declining, so the
   step-262 driver cloned @__cq_q_gg_10 with `cq_template_mul_i32_hl(q, %out2)` — reading the
   superposed %out2 rail's i32 HANDLE-TAG as a classical literal (q*7, a wrong unitary).

   THE FIX (afmv): the reseed set is computed AFTER the yn71 control fixpoint, so %out2 is in
   it; `replanReseedSpecialization` re-widens gg's mask 0b10 -> 0b11 and the driver clones
   @__cq_q_gg_11 with a bare-QQ `cq_template_mul_i32` over TWO quantum handles — the trace line
   `cq_template_mul_i32(h0, h7)` (q * %out2, both HANDLES) is the contract, NOT `_hl`.

   `ext_f` and `gg` are DECLARED (not defined) here so opt sees visible un-inlined pure bodies
   only after the lib TUs are linked in (Rule 9). The two rails, the theta rail, and the
   clone's copy-out are LEFT ALLOCATED (measured / benign leak, Rule 6). */
int ext_f(int a);
int gg(int a, int b);

int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);          /* taint q -> condition handle */
    int y = 5;
    if (q > 5)                     /* region 1: tainted-condition classical-call arm -> %out1 */
        y = ext_f(7);
    int w = 6;
    if (y > 50)                    /* region 2: cond reads %out1 -> lowered by yn71 -> %out2 */
        w = ext_f(7);
    int z = gg(w, q);              /* round-1 Pending gg(w=%out2, q): mask 0b10 -> RE-WIDENED 0b11 */
    int m1 = cq_measure(z);
    int m2 = cq_measure(y);        /* keep region-1 merge live so both rails materialize */
    return m1 + m2;
}

int main(void) { (void) slice(); return 0; }
