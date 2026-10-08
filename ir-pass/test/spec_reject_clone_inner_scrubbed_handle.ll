; spec_reject_clone_inner_scrubbed_handle.ll — DECLINE (bd test_C_libtooling-r2j3.19).
; taint_reject_scrubbed_handle_branch.ll's subject ONE LIFT LEVEL DOWN. `h` reads its
; quantum argument only through an EMPTY diamond and returns the classical `k + 1`.
; `predictReturnTainted(h, 01)` treats any tainted conditional terminator as a tainted
; return, so inside the outer clone `__cq_q_h5_01` the call's result is predicted
; QUANTUM and main's control chain builds its condition flag on it. The inner drain
; then builds `__cq_q_h_01`, whose flatten removes the diamond, so it returns a
; classical value and `scrubForwardCone` untaints the result after the gate read it.
; Before r2j3.19 nothing re-asked inside a clone (the module-level fence reads only
; module taint): the chain's `cq_template_icmp_sgt_i32_hl` read the integer `k + 1`
; as a register. The l3oi fence now runs on the clone's taint after its drain.
;
; This is the main-level twin's loud backstop, not a design limit: a predictor that
; asks whether the branch reaches the return retires this subject (CLAUDE.md L8; the
; same trigger as taint_reject_scrubbed_handle_branch.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function __cq_q_h5_01 {{.*}}: cq taint escape: classical call result used as a quantum register

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h5(i32 noundef %6, i32 noundef %5) #4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  ret i32 %8
}

declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %c = icmp eq i32 %0, 0
  br i1 %c, label %arm, label %join
arm:
  br label %join
join:
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

define i32 @h5(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @h(i32 noundef %0, i32 noundef %1) #4
  %4 = icmp sgt i32 %3, 3
  %5 = add nsw i32 %0, 5
  %6 = select i1 %4, i32 %5, i32 %0
  ret i32 %6
}

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) }
attributes #2 = { "no-trapping-math"="true" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable }
attributes #4 = { nounwind }
