/* tests/calls probe (cq-h8vd): with -cq-k=expf=9 the declared clone of llvm.exp.f32 takes expf's K, 9.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec libm_flag.c -o libm_flag.O1.ll */
#include "CQ.h"
#include <math.h>
float k4(float a) { float x = a; cq_theta(&x, 1.0); return cq_measure(expf(x)); }
