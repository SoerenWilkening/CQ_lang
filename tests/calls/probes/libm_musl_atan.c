/* tests/calls probe (cq-57ju; CR rules 18, 19, 23, rulings 2026-11-02): a plain clang -O1 caller (no -fno-builtin, no
 * -frounding-math) of musl b1efda5 atan, linked with its injected body (built as CQ_spec LIBC_COVERAGE.md: -frounding-math
 * -O1, the _tools/musl_arch_cq headers) and the helpers fabs, __math_{oflow,uflow,xflow,invalid,divzero}.
 * llvm.atan.f64 binds to the body (cq-odjk); its fpexcept.ignore ops are plain templates and the clone takes no mode
 * and no flags (cq-75n4); a classical host call under a quantum predicate is unguarded (cq-fl4n).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I CQ_spec libm_musl_atan.c, then llvm-link -S with
 * the musl modules into libm_musl_atan.O1.ll. */
#include "CQ.h"
#include <math.h>
double f_atan(double a) { double x = a; cq_theta(&x, 0.3); return cq_measure(atan(x)); }
