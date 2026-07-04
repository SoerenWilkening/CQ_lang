/* spec_replan_qpow_caller.c — bd 0vvq (Increment 2) e2e smoke: an untainted
   control-merge %out feeding a Phase-6 SPECIALIZATION candidate whose frozen mask
   is RE-PLANNED to Q+Q, driven through the full clang -O1 -> llvm-link -> opt
   cq-lowering -> link -> run pipeline. The ONLY layer that LINKS, so the only proof
   the re-planned clone @__cq_q_qpow_11 + its bare-QQ cq_template_*_i32 producers +
   their void _unc twins resolve and signature-match against libcq_templates /
   libcq_runtime (Rule 2/16).

   SOURCE INTENT (0vvq Inc 2 — the spec-clone frozen-plan case dugh over-declined):
       q : tainted quantum condition handle
       int y = 5;  if (q>3) y = ext_f(7);     // 6.5 classical-call arm -> %out (i32)
       int z = qpow(q, y);                    // spec candidate qpow(q, %out)
       measure(z);

   At `detectSpecializations` (pre-emit) the merge phi `y` is data-untainted, so
   `qpow(q, y)` is frozen mask `0b01` (only arg0 the theta handle is quantum). dugh
   re-taints `%out` in round 2; the frozen `_hl` clone would read the `%out` qubit
   HANDLE as a classical literal (the D2 verify-clean silent miscompile). Increment
   2's `replanReseedSpecialization` recomputes the mask to `0b11` BEFORE the step-14
   driver clones, so @__cq_q_qpow_11 lowers `mul` and `add` bare-QQ over two quantum
   handles — the merged register treated as the superposed value it is.

   `ext_f` and `qpow` are DECLARED (not defined) here so opt sees visible,
   un-inlined pure bodies only after the lib TUs are linked in (Rule 9). `%out`, the
   theta rail, and the clone's copy-out are LEFT ALLOCATED (measured / benign leak,
   Rule 6). */
int ext_f(int a);
int qpow(int base, int exp);

int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);          /* taint q -> condition handle */
    int y = 5;
    if (q > 3)                     /* tainted-condition diamond -> classical-call arm */
        y = ext_f(7);              /* pure classical call -> route-merged %out (i32) */
    int z = qpow(q, y);            /* spec candidate qpow(q, %out): re-planned 01 -> 11 */
    int zi = cq_measure(z);        /* measure the specialized result */
    return zi;
}

int main(void) { (void) slice(); return 0; }
