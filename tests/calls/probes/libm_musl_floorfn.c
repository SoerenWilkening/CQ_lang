/* tests/calls probe (cq-57ju; CR rule 23 ruling 2026-11-02): musl b1efda5 floor called as a function (-fno-builtin) from a
 * plain caller: the clone of the -frounding-math body has only plain templates and no mode or flags parameter.
 * Regenerate: clang -O1 -fno-builtin -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I CQ_spec libm_musl_floorfn.c, then
 * llvm-link -S with musl floor into libm_musl_floorfn.O1.ll. */
#include "CQ.h"
#include <math.h>
double f_floorfn(double a) { double x = a; cq_theta(&x, 0.3); return cq_measure(floor(x)); }
