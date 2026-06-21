; lowering_reject_io_controlled_nested.ll — DECLINE (Phase 7.6 Increment 2): a
; DEEPER control nest around an I/O sink. A genuine depth-2 CFG `if (q > 5) { if
; (r > 3) printf("%d", q); }` reconverges at a SHARED merge with THREE predecessors
; (entry, mid, arm). The inner `br` looks like a single-sink diamond in isolation,
; but its merge is not the clean 2-predecessor Tier-0 join — flattening it would
; leave the outer `if (q > 5)` wrapping a half-lowered region — so it declines
; LOUDLY (over-decline is safe; the deeper nest is beyond Tier-0, PRD-7.6 §5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge

mid:                                              ; preds = %entry
  %c2 = icmp sgt i32 %r0, 3
  br i1 %c2, label %arm, label %merge

arm:                                              ; preds = %mid
  %s = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %entry, %mid, %arm
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}

; CHECK: error{{.*}}cq I/O output sink: conditional output is not a lowerable single-sink if(q) diamond
