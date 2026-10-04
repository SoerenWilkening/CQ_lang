/* spec_newcand_qsq_caller.c — bd 9paa e2e smoke: an untainted control-merge %out
   feeding a WHOLLY-NEW Phase-6 SPECIALIZATION candidate that was ALL-classical at
   round 1, driven through the full clang -O1 -> llvm-link -> opt cq-lowering ->
   link -> run pipeline. The ONLY layer that LINKS, so the only proof the round-2-
   DETECTED clone @__cq_q_qsq_1 + its bare-QQ cq_template_mul_i32 producer + its void
   _unc twin resolve and signature-match against libcq_templates / libcq_runtime
   (Rule 2/16).

   SOURCE INTENT (9paa — round-2 spec DETECTION, the detection twin of the 0vvq
   re-plan):
       q : tainted quantum condition handle
       int y = 5;  if (q>3) y = ext_f(7);     // 6.5 classical-call arm -> %out (i32)
       int z = qsq(y);                        // NEW candidate qsq(%out): 1-arg square
       measure(z);

   Contrast with spec_replan_qpow (0vvq Inc 2): there the candidate `qpow(q, y)`
   reads the theta handle `q` too, so it is a ROUND-1 candidate (frozen mask 0b01)
   the re-plan grows to 0b11. HERE `qsq(y)` reads ONLY the merge `y`, so at
   `detectSpecializations` (pre-emit) it reads NO tainted operand and never enters
   `plan6.Pending` — dugh/0vvq over-declined it `kMsgUnknownCallee`. 9paa's round-2
   `detectSpecializations` in `repropagateControlMerges` DETECTS it after `%out`
   is re-tainted, so the driver clones @__cq_q_qsq_1 with `mul v,v` lowering
   bare-QQ — the merged register `%out` read as the superposed HANDLE it is, NOT an
   `_hl` classical literal reading the qubit-handle tag (the D2 miscompile guard).

   `ext_f` and `qsq` are DECLARED (not defined) here so opt sees visible, un-inlined
   pure bodies only after the lib TUs are linked in (Rule 9). `%out`, the theta rail,
   and the clone's copy-out are LEFT ALLOCATED (measured / benign leak, Rule 6). */
int ext_f(int a);
int qsq(int v);

int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> condition handle */
    int y = 5;
    if (q > 3)                     /* tainted-condition diamond -> classical-call arm */
        y = ext_f(7);              /* pure classical call -> route-merged %out (i32) */
    int z = qsq(y);                /* NEW candidate qsq(%out): round-2 DETECTED, mask 1 */
    int zi = cq_measure(z);        /* measure the specialized result */
    return zi;
}

int main(void) { (void) slice(); return 0; }
