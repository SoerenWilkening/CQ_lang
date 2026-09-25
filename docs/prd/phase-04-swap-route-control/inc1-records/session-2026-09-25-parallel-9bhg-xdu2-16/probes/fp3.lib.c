/* spec_fp_arg_lib.c — the CLASSICAL library TU for the bd 3c6m.54 e2e golden
   (fp-ABI specialization: a Phase-6 clone with an x86_fp80 quantum ARG and
   RETURN). Like the other spec libs it MUST compile WITHOUT the CQ.h intrinsic
   surface (C18 — run_slice_multi.sh applies `-include CQ.h` to the CQ TU only);
   the tripwire fails LOUDLY if the harness ever force-includes CQ.h into a lib TU.

   `lpoly` is `long double(long double)` — a STRAIGHT-LINE fp80 polynomial (no
   branches, so it passes `scanBody`'s single-block gate). Its fp80 arg and return
   are the quantum ABI 3c6m.54 lifts: the driver clones `@__cq_q_lpoly_1` with the
   fp80 arg AND return rewritten to i32 HANDLES (Rule 15 — a quantum value is
   always an i32 handle), lowers the fp80 arithmetic to `cq_template_f*_f80`
   producers on those handles, copies the fp80 result out with `cqrt_copy_f80`,
   and Bennett-reverse-plays the `_f80_unc` family. Exercises Q+Q (`x*x`) and
   Q+C (`*0.5L`, `+x` is Q+Q) fp80 templates. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

long double lpoly(long double x) {
    long double y = x * x;      /* Q+Q fmul_f80          */
    return y * 0.5L + x;        /* Q+C fmul_f80_hl, Q+Q fadd_f80 */
}
long double lmix(long double x, long double w) { return x * w + 0.5L; }
