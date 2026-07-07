; lowering_reject_qram_guarded_store_nested.ll — DECLINE (g5gi boundary): a guarded
; Shadow store NESTED inside ANOTHER tainted diamond —
;   if (q < 3) { if (i < 2) { arr[k] = 7; } }
; The store's block sits inside an OUTER tainted-control region, so accepting the
; inner diamond standalone would guard the store on the INNER condition ONLY,
; silently dropping the outer guard (a verify-clean wrong unitary). g5gi widens the
; SWAPPED and MULTI-store shapes but NOT deeper nests — those need the iw81.14 block
; path-predicate OR-reduction (issue item 3). The nested store therefore still
; declines LOUDLY: `guardedShadowStoreShape`'s control-dependence check
; (`instUnderTaintedControl(BI)`) is false for the inner br, so the carve renders
; NotQram and the tainted store/gep falls to the generic taint-escape decline
; (over-declining is safe — Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @nested(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %k = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %fo = icmp slt i32 %q, 3
  br i1 %fo, label %mid, label %merge

mid:
  %fi = icmp slt i32 %i, 2
  br i1 %fi, label %arm, label %merge

arm:
  %sk = sext i32 %k to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sk
  store i32 7, ptr %g, align 4
  br label %merge

merge:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: cq taint escape: tainted value reaches an unsupported instruction
