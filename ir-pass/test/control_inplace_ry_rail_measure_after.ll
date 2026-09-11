; control_inplace_ry_rail_measure_after.ll — ACCEPT: the rail is measured AFTER
; the region and the merge value is read as data (`r * 3`, probe `t23`).
;
; It is the DISCRIMINATOR for rung (ii): a measurement of the condition register
; that the control read can NEVER follow is downstream of the region and owns the
; register from there on, exactly as for a compare. `railMeasuredBeforeReadPoint`
; asks `isPotentiallyReachable(measure, readPoint)` — not dominance and not
; position — so this accepts while
; `control_inplace_ry_reject_rail_measured_before.ll`, one line apart in the
; source, declines.;
; ⚠ SHARED GROUND, TRUE OF EVERY `control_inplace_ry_rail_*` ACCEPT AND STATED
; ONCE PER FILE RATHER THAN GUESSED (bd test_C_libtooling-l4x4, sub-increment
; l4x4.b; SCOPE §2.1 / §2.7):
;   * THE FLAG IS THE REGISTER. `classifyArms` admits a bare `_Bool` condition
;     (`isCondRailLeaf` — a `cq_theta_i1` result) and `emitInPlaceRotationRegion`
;     sets `Flag = Cond`, so NOTHING IS MINTED (`NOMINT`), NOTHING IS STRIPPED,
;     and the register is NEVER FREED (`FCNT`) — after `Ry(θ)|0⟩` it is not `|0⟩`,
;     so a `cqrt_free` would be a hidden measurement (Rule 6). It is LEFT
;     ALLOCATED, which is the REQUIRED direction: the same Rule-6-safe leak the
;     COMPARE form already gives its own condition register (probe `t11c`).
;   * NO `cqrt_x` ON A USER REGISTER, EVER (`NOX`) — bd `3qlq.4`'s invariant.
;   * THE CONTROL IS ONE QUBIT. `isCondRailLeaf` is a `cq_theta_i1` result, hence
;     a `cqrt_alloc_i1` — exactly the width a minted compare flag has. Nothing
;     about `cqrt_ry_<W>_controlled`'s tensored semantics changes; l4x4.b changes
;     WHO arg-0 is and nothing else.
;   * THE ROTATED RAIL IS FROZEN by `ChainWalk::railCarriesControlledRotation`,
;     which derives it from the emitted gate's own ARG-1 use. ARG-0 — the user's
;     register — is NOT frozen by that predicate and must not be: it is not an
;     in-place gate on it (`isInPlaceGateOn` requires arg-1 == H) and the generic
;     `_controlled` bail refuses it, so `isTerminalHandle` says "not a terminal"
;     and `preservesBasisUnderRecord`'s disqualify list keeps it out of the M-B
;     interior. That asymmetry is the whole disposition of `b` (SCOPE §2.7, H-9).
;   * RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4, which both decline
;     `bare i1 register condition` at `classifyArms`' first gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t23_rail_measure_after.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t23_rail_measure_after.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %1, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ %2, %0 ]
  %7 = mul nsw i32 %6, 3
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %9 = zext i1 %8 to i32
  %10 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %11 = add nsw i32 %10, %9
  ret i32 %11
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %1, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %5

5:                                                ; preds = %0, %3
  %6 = phi i32 [ %4, %3 ], [ %2, %0 ]
  %7 = mul nsw i32 %6, 3
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 3)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[B]])
;
; ---------------------------------------------------------------------------
; THE NEGATIVES ARE WHOLE-FILE AND PURE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 lesson:
; a POSITIVE directive inside a prefix WINDOWS every negative one of that
; prefix, so every count lives in its own CNT prefix and no `-NOT` shares a
; prefix with a positive). `NOX` is THE NON-NEGOTIABLE: bd `3qlq.4`'s invariant
; is "never a `cqrt_x` on a user register", and the rail path has no ancilla to
; put one on either, so the whole-file form is both stronger and true.
; NOX-NOT: call void @cqrt_x(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = phi
; NOMINT-NOT: cq_template_icmp
; CRCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; RYCNT-COUNT-4: call void @cqrt_ry_{{[a-z0-9]+}}(
; RYCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}(
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
