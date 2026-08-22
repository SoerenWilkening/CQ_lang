; lowering_ctlz_idiom_chained.ll — ACCEPT ×2 (bd ww4c.4). THE RE-PROPAGATE PIN:
; two idiom loops in SEQUENCE where the second's entry value is the FIRST's
; escaping counter.
;
; WHY THIS SHAPE AND NOT `..._both_loops.ll`. That fixture already proves the
; driver's `while (recognizeCtlzIdiomLoops(...))` turns twice — but its two loops
; sit in MUTUALLY EXCLUSIVE ARMS and are independent, so it would still pass if
; the re-propagate between claims did nothing. Here the second loop is claimable
; ONLY AFTER the first claim is re-propagated:
;
;   * at the first call, `%dec1` is derived from ConstantInts alone — it is
;     CLASSICAL, so Z8 fails for %loop2 and only %loop1 is claimed;
;   * the driver then runs `taint = propagate(M, wd)`, which makes the substituted
;     `sub` (and hence %loop2's entry value) TAINTED;
;   * the second call claims %loop2.
;
; So this fixture is the direct assertion of the mechanism CtlzIdiomPrepass.h
; states as the reason the cells lower at all: the rewrite CONVERTS A CONTROL
; DEPENDENCE INTO A DATA DEPENDENCE. Delete the re-propagate from the driver and
; the second chain below disappears while every other ctlz fixture stays green.
;
; It also exercises the one-claim-per-call contract's real point — each claim
; sees FRESH dominance/taint/LoopInfo state — across a dependency, not merely
; across two independent loops.
;
; The two seeds are deliberately different (-1022 and 100) so each emitted
; constant identifies its own loop: C0-1 = -1023 and 99.
;
; RUN: env CQ_SPEC_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.spec.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=IMMARG %s < %t.spec.ll
;
; BOTH claims emit the literal `i1 false` (PRD §4.5(1)).
; IMMARG: call i32 @llvm.ctlz.i32(i32 %{{[a-zA-Z0-9_.]+}}, i1 false)
; IMMARG: call i32 @llvm.ctlz.i32(i32 %{{[a-zA-Z0-9_.]+}}, i1 false)
; IMMARG-NOT: i1 true
;
; Chain 1, captured end to end...
; CHECK: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK: %[[Z1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i32(i32 %[[S1]])
; CHECK: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Z1]], i32 31)
; CHECK: %[[C1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_lh(i32 -1023, i32 %[[M1]])
;
; ...and chain 2 CONSUMES chain 1's result, which is the whole point: the capture
; below is what proves the dependency survived the rewrite intact.
; CHECK: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %[[C1]], i32 1)
; CHECK: %[[Z2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i32(i32 %[[S2]])
; CHECK: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Z2]], i32 31)
; CHECK: %[[C2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_lh(i32 99, i32 %[[M2]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[C2]])
;
; Both loops are GONE.
; CLEAN-NOT: = phi
; CLEAN-NOT: br i1
; CLEAN-NOT: call {{.*}}@llvm.ctlz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @chained(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop1

loop1:                                            ; preds = %entry, %loop1
  %ix1 = phi i32 [ -1022, %entry ], [ %dec1, %loop1 ]
  %x1 = phi i32 [ %q, %entry ], [ %sh1, %loop1 ]
  %dec1 = add nsw i32 %ix1, -1
  %sh1 = shl nuw i32 %x1, 1
  %p1 = icmp sgt i32 %sh1, 0
  br i1 %p1, label %loop1, label %mid

mid:                                              ; preds = %loop1
  br label %loop2

; %dec1 — loop1's escapee — is loop2's entry value. UNTAINTED at the first call.
loop2:                                            ; preds = %mid, %loop2
  %ix2 = phi i32 [ 100, %mid ], [ %dec2, %loop2 ]
  %x2 = phi i32 [ %dec1, %mid ], [ %sh2, %loop2 ]
  %dec2 = add nsw i32 %ix2, -1
  %sh2 = shl nuw i32 %x2, 1
  %p2 = icmp sgt i32 %sh2, 0
  br i1 %p2, label %loop2, label %exit

exit:                                             ; preds = %loop2
  %m = call i32 @cq_measure_si32(i32 %dec2)
  ret i32 %m
}
