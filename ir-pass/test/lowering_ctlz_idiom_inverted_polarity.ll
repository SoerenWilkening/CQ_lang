; lowering_ctlz_idiom_inverted_polarity.ll — ACCEPT (bd ww4c Inc 1, the Z5
; polarity probe). Rule 9: `clang -O1` routinely inverts branch polarity and
; swaps successors, so the exit test is often spelled as the NEGATION with the
; loop as the FALSE successor. Z5 normalises the CONTINUE condition rather than
; pattern-matching the branch as written:
;
;     continue-on-true  : icmp sgt %sh, 0 ; br i1 %c, label %loop, label %exit
;     continue-on-false : icmp sle %sh, 0 ; br i1 %c, label %exit, label %loop   <- HERE
;
; Both denote `continue while %sh > 0`, and both must accept.
;
; THE THING THIS FIXTURE GUARDS AGAINST is the third spelling, which looks almost
; identical and is a DIFFERENT loop:
;     icmp sgt %sh, 0 ; br i1 %c, label %exit, label %loop
; That one continues while %sh <= 0 and does not terminate (0 shifts to 0, -1 to
; -2 …). It has no closed form here and MUST decline — see
; lowering_ctlz_idiom_reject_inverted_successors.ll, which is exactly this
; fixture with the predicate left un-negated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
;
; CHECK: call i32 @cq_template_shl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK: call i32 @cq_template_ctlz_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK: call i32 @cq_template_and_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 31)
; CHECK: call i32 @cq_template_sub_i32_lh(i32 -1023, i32 %{{[a-zA-Z0-9_.]+}})
;
; CLEAN-NOT: = phi
; CLEAN-NOT: br i1
; The intrinsic CALL is gone (the now-unused `declare` is left behind, as it is
; for every other lowered intrinsic — cf. lowering_intrinsic_ctlz_i32.ll).
; CLEAN-NOT: call {{.*}}@llvm.ctlz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inverted_polarity(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %done = icmp sle i32 %sh, 0
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}
