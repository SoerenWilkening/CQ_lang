; control_mixed_value_io_reject_twobase.ll — DECLINE (Phase 7.2 Increment 2): a
; mixed value+I/O diamond whose value merge φ is a TWO-BASE / COMPUTED multiplexer
; (incomings are tainted SSA values %k and %q, not constants) — the exp2 shape the
; owner conservatively DECLINED in 65wb.5. The arm holds a recognized I/O sink, but
; the value effect is NOT the safe constant data-mux: a computed incoming can carry
; relative PHASE, and an XOR copy of a phase DEPHASES it (Rule 7 — the P0
; 0.585→0.500 leak). Only a CONSTANT-incoming φ (a pure basis value, no phase) is
; lowerable here (see control_mixed_value_io.ll); a computed φ DECLINES LOUDLY (the
; ConstantInt gate in the mixed recognizer), over-decline is always safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %p = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %sel = phi i32 [ %k, %arm ], [ %q, %entry ]   ; COMPUTED incomings, not constants
  %m = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK: error{{.*}}cq I/O output sink: conditional output is not a lowerable single-sink if(q) diamond
; CHECK-NOT: cqrt_copy_i32_controlled
; CHECK-NOT: cqrt_tape_write_i32_controlled
