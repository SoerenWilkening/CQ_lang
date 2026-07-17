; lowering_fp80_union_seed_impurecall_drop.ll — DROP probe (bd adia): the
; pure-callee seed admit is EXACT `isSpeculatablePureCallee` membership. A
; callee that touches memory (a store — not a pure function of its
; arguments) fails the proof, so the seed walk drops the candidate and the
; union stays IN MEMORY (the opportunistic-mode silent drop — today's
; outcome, never a new loud surface; the helper is classical so the module
; still lowers through the anchor). The discriminating twin of
; lowering_fp80_union_seed_purecall.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }
@gv = global x86_fp80 0xK00000000000000000000

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

define x86_fp80 @impurefloor(x86_fp80 %x) {
entry:
  %c = fcmp olt x86_fp80 %x, 0xK00000000000000000000
  br i1 %c, label %neg, label %done
neg:
  store x86_fp80 %x, ptr @gv
  %n = fsub x86_fp80 %x, 0xK3FFF8000000000000000
  br label %done
done:
  %p = phi x86_fp80 [ %n, %neg ], [ %x, %entry ]
  ret x86_fp80 %p
}

define i32 @helper(x86_fp80 noundef %x) {
entry:
  %u = alloca %union.IEEEl2bits, align 16
  %px = call x86_fp80 @impurefloor(x86_fp80 %x)
  store x86_fp80 %px, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; The union does NOT promote — the alloca and the fp80 seed store survive.
; CHECK: define i32 @helper(x86_fp80 noundef %x)
; CHECK: %u = alloca %union.IEEEl2bits
; CHECK: store x86_fp80 %px, ptr %u
; CHECK-NOT: bitcast x86_fp80 %px to i80
