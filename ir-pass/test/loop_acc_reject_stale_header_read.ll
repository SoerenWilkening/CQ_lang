; loop_acc_reject_stale_header_read.ll — DECLINE (bd test_C_libtooling-01po.19.18):
; the SEEDED ACCUMULATOR is fenced by the Case-A record-liveness fence, not by a
; fence of its own (R12: `staleRailRecordRead` sees the QQ step as a gate on the
; rail through `inPlaceValueRailOperand`).
;     int c = 0, old = 0;
;     for (i < n) { old = c; c += q; }      // -O1: `old` is the header φ
;     return cq_measure(old) + cq_measure(c);
; After the loop `old` names the register's state BEFORE the last trip's step,
; but the rolled register has been moved by it: the read is stale. The in-place
; form has no copy of that state, so the module fails loudly at the read. (A
; copy-before-step lowering is the general remedy; until it exists, loud.)
;
; A RUNTIME trip count `n`, so the Lever-B force-unroll pre-pass (constant trip
; counts only) cannot turn the loop into straight-line code first.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @stale_old(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %c = phi i32 [ 0, %entry ], [ %cn, %loop ]
  %cn = add nuw nsw i32 %c, %q
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:
  %m0 = call i32 @cq_measure_si32(i32 %c)
  %m1 = call i32 @cq_measure_si32(i32 %cn)
  %s = add i32 %m0, %m1
  ret i32 %s
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
