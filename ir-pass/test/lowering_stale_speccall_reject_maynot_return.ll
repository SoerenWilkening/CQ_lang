; lowering_stale_speccall_reject_maynot_return.ll — ACCEPT since bd test_C_libtooling-57ch.4 (the moved-call termination proof) (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; `callProvablyReturns` (StaleReadRegion.h) proves the MOVED call returns from its
; trusted body: acyclic, only `br`/`ret`, every instruction returns normally. That
; is the "the clone is a finite circuit" trigger below. A CROSSED call that may not
; return is a different question, ruled by the owner on 2026-10-13
; (`callTerminationCrossable`: `nounwind` and no `returns_twice` call in the module;
; lowering_stale_speccall_reject_crossed_maynot_return_callee.ll accepts,
; lowering_stale_speccall_reject_crossed_maynot_return_setjmp.ll declines).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[0-9]+]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_stale_speccall_reject_maynot_return.ll — DECLINE (bd test_C_libtooling-r2j3.6):
; a stale lifted call that LLVM cannot prove returns. Hand IR: the callee's summary
; omits `willreturn` (what -O1 infers for a body whose loop it cannot bound), its body
; is the straight-line `x * 3 + 1` the specializer lifts.
;
; Moving such a call above a `cq_measure` would make the measurement depend on the
; call returning, which the source does not; StaleReadPlacement.h clause (c) asks
; `isGuaranteedToTransferExecutionToSuccessor` of the read itself and refuses, and the
; stale fence declines with its one string. Conservative (a lifted body is a finite
; circuit once lifted); kept loud.
; RETIREMENT TRIGGER (L7): a placement that takes "the clone is a finite circuit" as
; the call's termination proof flips this file to an accept.
;

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %4 = tail call i32 @f(i32 noundef %1)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { noinline nounwind memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
