; control_phase_kickback_ifelse_tail_armfalse.ll — ACCEPT. The ONLY shape that
; exercises ALL THREE branches of the merge-tail polarity ternary at once
; (Rule-13 round-1 finding F-L1-2; bd test_C_libtooling-3qlq Inc 1 part A).
;
; A genuine IF/ELSE (so `ShadowFalse` is non-empty) PLUS a merge-tail
; `phi double` whose incoming list is [ArmFalse, Arm] — the SWAPPED order. Three
; of the emitter's polarity branches were shipped with zero coverage: the
; `ShadowFalse` arm, the tail-φ `In == R.ArmFalse ? false` branch, and a tail-φ
; whose non-`Arm` incoming comes FIRST.
;
; ⚠ HAND-WRITTEN IR — see `control_phase_kickback_ifelse.ll` for why `clang -O1`
; cannot produce an if/else diamond for this construct. The condition register is
; made OPAQUE here (`%q = volatile-load + add`) so nothing folds it.
;
; THE EMITTED ORDER, and every one of the four segments is a different branch of
; the polarity logic:
;   1. `rz(0.9)`               — `Shadow`, `ArmNegated == false` ⇒ no bracket.
;   2. `x; rz(0.5); x`         — `ShadowFalse` ⇒ bracket UNCONDITIONALLY.
;   3. `x; rz(0.11); x`        — tail φ, incoming `%af` == `R.ArmFalse` ⇒
;                                `FiresOnOne = false` ⇒ bracket.
;   4. `rz(0.3)`               — tail φ, incoming `%at` == `R.Arm` ⇒
;                                `FiresOnOne = !ArmNegated = true` ⇒ no bracket.
;
; IT ALSO PINS F-L1-3: the shipped comment said "ONE BRACKET PAIR PER ARM" and
; was being read as PER REGION. FOUR `cqrt_x` here, because a bracketed tail
; incoming carries its OWN pair independently of the arm's. Correct (an
; involution) and not what the comment claimed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; CHECK: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 9.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 5.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 1.100000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ACNT-COUNT-4: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; FOUR — one pair per ARM, plus one per BRACKETED TAIL INCOMING (F-L1-3).
; XCNT-COUNT-4: call void @cqrt_x(
; XCNT-NOT: call void @cqrt_x(

; NOROUTE is WHOLE-FILE and PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: phi double

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@off = global i32 3, align 4
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare void @cq_phi(double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr
declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr
declare double @cq_measure_f64(double noundef) local_unnamed_addr

define i32 @slice() local_unnamed_addr {
entry:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %o = load volatile i32, ptr @off, align 4
  %q = add nsw i32 %o, %t
  %c = icmp eq i32 %q, 5
  br i1 %c, label %at, label %af
at:
  tail call void @cq_phi(double noundef 9.000000e-01)
  br label %mrg
af:
  tail call void @cq_phi(double noundef 5.000000e-01)
  br label %mrg
mrg:
  %a = phi double [ 1.100000e-01, %af ], [ 3.000000e-01, %at ]
  tail call void @cq_phi(double noundef %a)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  ret i32 %m
}
define i32 @main() local_unnamed_addr { %r = call i32 @slice() ret i32 0 }
