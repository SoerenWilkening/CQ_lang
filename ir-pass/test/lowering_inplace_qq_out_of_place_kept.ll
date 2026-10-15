; lowering_inplace_qq_out_of_place_kept.ll — the quantum-quantum add/xor shapes
; that STAY OUT OF PLACE under bd test_C_libtooling-r2j3.33 (dm7f.51 step 1),
; each for a stated reason, and each byte-identical to the pre-r2j3.33 lowering
; (measured: old vs new cq-opt on this module). See InPlaceQQ.h (E1)-(E4).
;
;   @live_old       `int t0 = t; t ^= a; ... cq_measure(t0 + 1)` — the old `t`
;                   is read AFTER the xor, so it is LIVE (E1): the fresh rail is
;                   an entangling copy, which is the program (design D5).
;   @temp_result    `int s = (t + a) * 3; cq_measure(s)` — both operands dead,
;                   but the add's result is a TEMPORARY the spine discharges
;                   after its reader (E4): out of place IS in place followed by
;                   its own adjoint at the result's death; in place would leave
;                   the dead sum on `t`'s rail with nothing to undo it.
;   @dependent_src  `int f = q > 5; if (q > 5) cq_phi(.25); cq_measure(q + f)`
;                   — the source `f` is a function of the old `q` (E3), so once
;                   `q` is relabelled `f` can never be uncomputed: in place only
;                   trades the old-`q` record for an `f` record.
;   @self_xor       hand IR `xor %x, %x` (clang folds it to 0; the pass must not
;                   rely on that): an operand read twice is never dead (E1) and
;                   aliases the target (E3); the `0` is a fresh rail.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOGATE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @live_old()
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[A]], i32 %[[T]])
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[X]])
; CHECK:       call i32 @cq_template_add_i32_hl(i32 %[[T]], i32 1)
;
; CHECK-LABEL: define i32 @temp_result()
; CHECK:       %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT:  call i32 @cq_template_mul_i32_hl(i32 %[[S]], i32 3)
; CHECK-NEXT:  call void @cq_template_add_i32_unc(i32 %[[S]],
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S]])
;
; CHECK-LABEL: define i32 @dependent_src()
; CHECK:       %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(
; CHECK-NEXT:  %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[Q]], i32 %[[F]])
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[R]])
;
; CHECK-LABEL: define i32 @self_xor()
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK:       %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[H]], i32 %[[H]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[Z]], double 2.500000e-01)
;
; NOGATE-NOT: !cq.inplace.qq
; NOGATE-NOT: cq.qq.dead

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @live_old() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = xor i32 %2, %1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %7 = add nsw i32 %6, %5
  %8 = add nsw i32 %2, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %10 = add nsw i32 %7, %9
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define i32 @temp_result() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = add nsw i32 %2, %1
  %4 = mul nsw i32 %3, 3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %5
}

define i32 @dependent_src() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %4

3:                                                ; preds = %0
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %4

4:                                                ; preds = %3, %0
  %5 = zext i1 %2 to i32
  %6 = add nsw i32 %1, %5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %7
}

declare void @cq_phi(double noundef) local_unnamed_addr


define i32 @self_xor() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = xor i32 %1, %1
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 2.500000e-01)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 %4
}
