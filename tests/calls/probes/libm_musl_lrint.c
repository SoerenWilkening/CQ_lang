/* tests/calls probe (cq-babj; CR rules 18, 19, 23 at CQ_spec f684858): clang -O1 turns lrint/lround/nearbyint calls into llvm.lrint/llvm.lround/llvm.nearbyint; rule 18 binds each to the injected libm body of the same name (taint lifts it, as spine classes it).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx -include CQ_spec/CQ.h libm_musl_lrint.c, then
 * llvm-link -S --only-needed with musl b1efda5's libm (built as CQ_spec LIBC_COVERAGE.md: -frounding-math -O1,
 * the _tools/musl_arch_cq headers) into libm_musl_lrint.O1.ll. */
long lrint(double); long lround(double); double nearbyint(double); float nearbyintf(float);
long f_lrint(double a) { double x = a; cq_theta(&x, 0.3); return cq_measure(lrint(x)); }
long f_lround(double a) { double x = a; cq_theta(&x, 0.3); return cq_measure(lround(x)); }
double f_nearbyint(double a) { double x = a; cq_theta(&x, 0.3); return cq_measure(nearbyint(x)); }
float f_nearbyintf(float a) { float x = a; cq_theta(&x, 0.3); return cq_measure(nearbyintf(x)); }
