; lowering_reject_io_controlled_compound_cond.ll — DECLINE (Phase 7.6 Increment
; 2): a NON-HOMOGENEOUS control nest around an I/O sink. `clang -O1` folds a
; short-circuit `if (q > 5 && r > 3) printf("%d", q)` into a `select i1`-compound
; branch condition. The arm IS a single recognized sink, but the controlling
; condition is NOT a single comparison (`CmpInst`) — there is no one flag to mint
; — so the Tier-0 controlled tape write declines LOUDLY (over-decline is safe;
; deeper/compound controlled I/O is beyond Tier-0, PRD-7.6 §5). NO tape write, no
; flatten, no silent accept.
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
  %c2 = icmp sgt i32 %r0, 3
  %and = select i1 %c1, i1 %c2, i1 false
  br i1 %and, label %arm, label %merge

arm:                                              ; preds = %entry
  %s = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}

; CHECK: error{{.*}}cq I/O output sink: conditional output is not a lowerable single-sink if(q) diamond
