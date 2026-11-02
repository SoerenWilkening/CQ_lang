/* tests/calls probe (cq-babj; CR rules 18, 19, 23 at CQ_spec f684858): musl acosh calls log, whose body has a classical fpexcept.ignore sitofp; the twin of the log clone replays it as the plain op it is (rule 23), not a host effect.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx -include CQ_spec/CQ.h libm_musl_acosh.c, then
 * llvm-link -S --only-needed with musl b1efda5's libm (built as CQ_spec LIBC_COVERAGE.md: -frounding-math -O1,
 * the _tools/musl_arch_cq headers) into libm_musl_acosh.O1.ll. */
double acosh(double);
double f_acosh(double a) { double x = a; cq_theta(&x, 0.3); return cq_measure(acosh(x)); }
