/* spec_fp_arg_caller.c — bd 3c6m.54 e2e smoke: the fp-ABI specialization ABI,
   driven through the full multi-TU pipeline (clang -O1 per TU -> llvm-link ->
   opt cq-lowering -> link -> run; the ONLY layer that LINKS, Rule 2/16). Proves
   the fp-ABI clone's emitted symbols — `cqrt_alloc_f80`, `cq_template_f*_f80(_hl)`,
   `cqrt_copy_f80`, the `_f80_unc` adjoints, `cqrt_measure_f80` — RESOLVE and
   signature-match at link time.

   TRACE CONTRACT (analytically audited, bd 3c6m.54): the theta mints an fp80 rail
   h0 (`cqrt_alloc_f80` + `cqrt_ry_f80`) and RAUW-to-handles it. The retargeted
   call passes h0 to the i32-signature clone `@__cq_q_lpoly_1(i32)`. The clone
   computes y=x*x (`cq_template_fmul_f80`), y*0.5 (`cq_template_fmul_f80_hl`),
   +x (`cq_template_fadd_f80`), copies the fp80 result onto a fresh |0> fp80 rail
   (`cqrt_copy_f80`), reverse-plays every op's `_unc` twin in exact reverse order,
   frees each scratch rail at proven-|0>, and returns the i32 handle. The borrowed
   theta rail h0 is read-only-preserved (never freed); the measured value rides the
   copy through `cqrt_measure_f80`. */
long double lpoly(long double x);

long double slice(void) {
    long double q = (long double)3.0L; cq_theta(&q, 0.5);
    long double y = lpoly(q);
    return cq_measure(y);
}

int main(void) { (void) slice(); return 0; }
