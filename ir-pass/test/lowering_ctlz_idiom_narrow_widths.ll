; lowering_ctlz_idiom_narrow_widths.ll — ACCEPT ×2 (bd ww4c Inc 1). Not in the
; PRD §10 matrix; added so that every width Z9 admits — {i8, i16, i32, i64} — is
; covered by a positive, not just the two the PRD names. PRD §4.5(3) makes the
; mask a correctness property ("a width-hardcoded mask is a silent miscompile at
; every other width"), and a rule asserted at two of four widths is asserted at
; two of four widths.
;
; i8  -> mask 7,  C0 = 5   -> emitted constant 4
; i16 -> mask 15, C0 = -8  -> emitted constant -9
;
; Both widths ship `ctlz` (tools/intrinsic_table.yaml:136) and all three of
; shl/and/sub in the shapes this emits — verified with `nm -g` on
; build/runtime/libcq_templates.a, so no new frozen symbol appears here either.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CLEAN %s < %t.cqd0.ll
;
; Operands CAPTURED, not wildcarded (bd ww4c.4). This matters MOST here: i8/i16
; have no e2e golden, so lit is the only layer that pins these two widths at all.
; CHECK: %[[S8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i8_hl(i32 %{{[a-zA-Z0-9_.]+}}, i8 1)
; CHECK: %[[Z8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i8(i32 %[[S8]])
; CHECK: %[[M8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i8_hl(i32 %[[Z8]], i8 7)
; CHECK: %[[C8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i8_lh(i8 4, i32 %[[M8]])
; CHECK: call i8 @cqrt_measure_i8(i32 %[[C8]])
;
; CHECK: %[[S16:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i16_hl(i32 %{{[a-zA-Z0-9_.]+}}, i16 1)
; CHECK: %[[Z16:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i16(i32 %[[S16]])
; CHECK: %[[M16:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i16_hl(i32 %[[Z16]], i16 15)
; CHECK: %[[C16:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i16_lh(i16 -9, i32 %[[M16]])
; CHECK: call i16 @cqrt_measure_i16(i32 %[[C16]])
;
; CLEAN-NOT: = phi
; CLEAN-NOT: br i1
; The intrinsic CALL is gone (the now-unused `declare` is left behind, as it is
; for every other lowered intrinsic — cf. lowering_intrinsic_ctlz_i32.ll).
; CLEAN-NOT: call {{.*}}@llvm.ctlz

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8 @cq_theta_si8(i8, double)
declare i8 @cq_measure_si8(i8)
declare i16 @cq_theta_si16(i16, double)
declare i16 @cq_measure_si16(i16)

define i8 @scan8(i8 %u) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %n = phi i8 [ 5, %entry ], [ %dec, %loop ]
  %x = phi i8 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i8 %n, -1
  %sh = shl nuw i8 %x, 1
  %pos = icmp sgt i8 %sh, 0
  br i1 %pos, label %loop, label %exit, !llvm.loop !0

exit:                                             ; preds = %loop
  %m = call i8 @cq_measure_si8(i8 %dec)
  ret i8 %m
}

define i16 @scan16(i16 %u) {
entry:
  %q = call i16 @cq_theta_si16(i16 %u, double 2.500000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %n = phi i16 [ -8, %entry ], [ %dec, %loop ]
  %x = phi i16 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i16 %n, -1
  %sh = shl nuw i16 %x, 1
  %pos = icmp sgt i16 %sh, 0
  br i1 %pos, label %loop, label %exit, !llvm.loop !2

exit:                                             ; preds = %loop
  %m = call i16 @cq_measure_si16(i16 %dec)
  ret i16 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}
!2 = distinct !{!2, !1}
