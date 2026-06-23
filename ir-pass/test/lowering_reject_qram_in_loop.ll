; lowering_reject_qram_in_loop.ll — DECLINE (Phase 7.5 Inc 1): a tainted-index READ
; of a const-global table INSIDE a loop. 7.5 lowers STRAIGHT-LINE tainted-index
; memory only (§2.11); a QRAM access in a loop needs the 7.3 bounded-loop unroll
; (not yet done), so it is NOT carved by the QROM accept predicate and keeps
; declining at the generic taint-escape guard. The loop bound here is CLASSICAL and
; there is NO tainted loop-carried phi (the loaded value is measured each iteration),
; so it is the LOOP gate — not the tainted-control or classical-mux guards — that
; declines this. PRD-7.5 §5/§6 (the 7.3 boundary).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @loopread(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]   ; classical loop counter (untainted)
  %idx = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %idx
  %v = load i32, ptr %g                            ; tainted-index read INSIDE the loop
  %m = call i32 @cq_measure_si32(i32 %v)           ; sink — no tainted loop-carried phi
  %inext = add i32 %i, 1
  %c = icmp slt i32 %inext, %n                     ; classical condition
  br i1 %c, label %loop, label %exit
exit:
  ret void
}

; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
