; lowering_fp80_union_seed_constglobal.ll — ACCEPT (bd 3c6m.55 Inc 1, Lever
; A.1b): promoteFp80Union admits an fp80 union SEED derived through a scalar-fp
; load from READ-ONLY CONSTANT GLOBAL memory — the openlibm `__polevll` Horner
; coefficient tables (`@P`/`@Q` in expl). Such a load is a constant-rooted
; classical value LLVM merely cannot fold because the element index is dynamic:
; here the pointer is the real Horner shape, a LOOP-CARRIED
; `phi ptr [@P, entry], [gep i8 %p, 16, loop]` (exercising the cycle-safe
; gep/phi pointer resolution in `isConstGlobalFpLoad`); @qtbl exercises the
; direct constant-gep form. Admitted in WIDENED (opportunistic) mode only — the
; strict predicate stays byte-identical, so a §4.1 walk failure on such a
; candidate drops it silently instead of widening the loud kMsgFp80Padding
; surface. The helper is CLASSICAL (arg-derived) — the pre-specialization
; register-form canonicalization path (bd vqlq); the union accesses are outside
; the loop (acyclic ✓). The quantum anchor keeps the module off the passthrough
; early-out.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

@P = internal unnamed_addr constant [3 x x86_fp80] [x86_fp80 0xK3FF2844E6EAF225F424E, x86_fp80 0xK3FF9F83688665163F39E, x86_fp80 0xK3FFEFFFFFFFFFFFFFFFE], align 16
@qtbl = internal unnamed_addr constant [2 x x86_fp80] [x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK40008000000000000000], align 16

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare x86_fp80 @llvm.fmuladd.f80(x86_fp80, x86_fp80, x86_fp80)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

; u.e = __polevll(x, P, 2) (Horner over @P, loop-carried coefficient pointer);
; return (int)u.bits.expsign — the expl k-scaling GET after a polynomial seed.
define i32 @helper_horner(x86_fp80 noundef %x) {
entry:
  %u = alloca %union.IEEEl2bits, align 16
  br label %loop

loop:
  %p = phi ptr [ @P, %entry ], [ %pn, %loop ]
  %i = phi i32 [ 2, %entry ], [ %in, %loop ]
  %acc = phi x86_fp80 [ 0xK3FFF8000000000000000, %entry ], [ %fma, %loop ]
  %c = load x86_fp80, ptr %p, align 16
  %fma = call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %acc, x86_fp80 %x, x86_fp80 %c)
  %pn = getelementptr inbounds i8, ptr %p, i64 16
  %in = add nsw i32 %i, -1
  %done = icmp eq i32 %in, 0
  br i1 %done, label %exit, label %loop

exit:
  store x86_fp80 %fma, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; u.e = qtbl[k] * x (direct constant-gep coefficient read).
define i32 @helper_direct(x86_fp80 noundef %x) {
entry:
  %u = alloca %union.IEEEl2bits, align 16
  %c = load x86_fp80, ptr getelementptr inbounds (i8, ptr @qtbl, i64 16), align 16
  %s = fmul x86_fp80 %c, %x
  store x86_fp80 %s, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; both unions promote to classical register form (the union memory is gone; the
; seed relabels via `bitcast x86_fp80 -> i80`); the classical Horner loop and
; its @P loads survive untouched; the anchor lowers normally:
; CHECK:     call double @cqrt_measure_f64(
; CHECK:     define i32 @helper_horner(
; CHECK-NOT: alloca
; CHECK:     load x86_fp80, ptr %p
; CHECK:     bitcast x86_fp80 %{{[a-z0-9.]+}} to i80
; CHECK:     define i32 @helper_direct(
; CHECK-NOT: alloca
; CHECK:     bitcast x86_fp80 %{{[a-z0-9.]+}} to i80
; CHECK-NOT: store x86_fp80
