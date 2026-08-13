; lowering_libm_keep_rounders_f80.ll — bd 3c6m.56: the long-double round-family
; KEEP path (Bennett-gated). clang -O1 folds `rintl`/`nearbyintl`/`truncl` to the
; in-grid intrinsics `@llvm.{rint,nearbyint,trunc}.f80` (an fp-DATA producer at the
; long-double width); IntrinsicLowering rewrites each to its additive-producer
; template `cq_template_{rint,nearbyint,trunc}_f80(handle)`. No injected body; the
; asm-level `callq _<fn>l` is intercepted as the intrinsic BEFORE codegen (the
; floor.f80 precedent). These are legitimate keeps because Bennett.jl ships the
; reversible gate sequence — `soft_round` (round-to-nearest-even = rint/nearbyint
; under the default FP env) and `soft_trunc` (src/softfloat/fround.jl).
;
; CONTRAST (why there is NO `fmod` companion fixture here): `fmod` folds to the
; in-grid `frem` OPCODE (recognizer holds) but Bennett has NO frem/fmod gate
; sequence, so it is NOT a keep and stays a declining library cell (bd 3c6m.56 /
; 3c6m.57 frem-inversion). The e2e proofs are tests/e2e/slice_libm_keep_*.c.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cq_template_rint_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_nearbyint_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_trunc_f80(i32 %{{[a-zA-Z0-9_.]+}})
;
; CHECK-NOT: llvm.rint.f80
; CHECK-NOT: llvm.nearbyint.f80
; CHECK-NOT: llvm.trunc.f80
; CHECK-NOT: cq_template_frem

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @llvm.rint.f80(x86_fp80)
declare x86_fp80 @llvm.nearbyint.f80(x86_fp80)
declare x86_fp80 @llvm.trunc.f80(x86_fp80)

define x86_fp80 @keep_rintl(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %r = call x86_fp80 @llvm.rint.f80(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}

define x86_fp80 @keep_nearbyintl(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %r = call x86_fp80 @llvm.nearbyint.f80(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}

define x86_fp80 @keep_truncl(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %r = call x86_fp80 @llvm.trunc.f80(x86_fp80 %q)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}
