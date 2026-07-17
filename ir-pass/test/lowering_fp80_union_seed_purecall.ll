; lowering_fp80_union_seed_purecall.ll — ACCEPT (bd adia, 3c6m.55 Lever C):
; promoteFp80Union admits an fp80 union SEED derived through a call to a
; VISIBLE, acyclic, all-speculatable PURE fp body — the plain -O1 openlibm
; shape where `expl` keeps `floorl` OUTLINED and seeds its k-scaling unions
; from `px = floorl(...)`. The callee proof is the SHARED
; `isSpeculatablePureCallee` (the same predicate PredMux's E4 speculates on,
; Rule 14): a pure total terminating function of its operands is a legitimate
; fp derivation, exactly like the curated-intrinsic case. Admitted in WIDENED
; (opportunistic, AdmitArgDerived) mode only — the strict predicate stays
; byte-identical, and the proof passes only after the callee's own unions
; promoted (its body must be load/store-free), so the fixpoint cascade
; converges naturally. The quantum anchor keeps the module off the
; passthrough early-out.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

; A pure acyclic fp body (the floorl stand-in): branches + phi + fp arith.
define x86_fp80 @purefloor(x86_fp80 %x) {
entry:
  %c = fcmp olt x86_fp80 %x, 0xK00000000000000000000
  br i1 %c, label %neg, label %done
neg:
  %n = fsub x86_fp80 %x, 0xK3FFF8000000000000000
  br label %done
done:
  %p = phi x86_fp80 [ %n, %neg ], [ %x, %entry ]
  ret x86_fp80 %p
}

; u.e = purefloor(x); return u.bits.exp — the expl k-scaling GET whose seed
; cone crosses the outlined pure call.
define i32 @helper(x86_fp80 noundef %x) {
entry:
  %u = alloca %union.IEEEl2bits, align 16
  %px = call x86_fp80 @purefloor(x86_fp80 %x)
  store x86_fp80 %px, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; The union promotes to register form: the call result is bitcast-extracted
; directly and the alloca is gone.
; CHECK: define i32 @helper(x86_fp80 noundef %x)
; CHECK-NOT: alloca
; CHECK: %[[PX:.*]] = call x86_fp80 @purefloor(x86_fp80 %x)
; CHECK: bitcast x86_fp80 %[[PX]] to i80
