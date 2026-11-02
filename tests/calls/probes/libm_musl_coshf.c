/* tests/calls probe (cq-babj; CR rules 18, 19, 23 at CQ_spec f684858): musl coshf calls __expo2f, which calls the host body __math_oflowf(0) (a volatile access to its own dead local, rule 24); the twin replays that call (rule 19, cq-fl4n), not a host effect.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx -include CQ_spec/CQ.h libm_musl_coshf.c, then
 * llvm-link -S --only-needed with musl b1efda5's libm (built as CQ_spec LIBC_COVERAGE.md: -frounding-math -O1,
 * the _tools/musl_arch_cq headers) into libm_musl_coshf.O1.ll. */
float coshf(float);
float f_coshf(float a) { float x = a; cq_theta(&x, 0.3); return cq_measure(coshf(x)); }
