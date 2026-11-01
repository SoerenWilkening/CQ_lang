/* tests/calls probe (cq-h8vd): the trailing K of a rule 27 declared clone of an LLVM math intrinsic is the libm
 * function's K: CQ_K(sin, 53), CQ_K(atan2, 77). Lowering only: cqcheck user cannot read llvm.used yet (cq-tntm).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec libm_k.c -o libm_k.O1.ll */
#include "CQ.h"
#include <math.h>
CQ_K(sin, 53)
CQ_K(atan2, 77)
double k1(double a, double y) { double x = a; cq_theta(&x, 1.0); return cq_measure(sin(x) + atan2(x, y)); }
