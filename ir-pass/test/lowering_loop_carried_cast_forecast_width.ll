; lowering_loop_carried_cast_forecast_width.ll — ACCEPT (bd test_C_libtooling-01po.3,
; review round 3 F1; decline -> accept). `mintsOutOfPlaceTemplateRail`
; (LoopLowering.cpp) FORECASTS whether `lowerOps` will mint an out-of-place rail
; for a tainted op. For a cast it read the source width off `getSrcTy()`, while
; `lowerOps` emits the cast from the source's `HandleWidth` record. For a laundered
; i32 handle the two disagreed: the forecast saw `sext i32 -> i32` (no template,
; "mints nothing") where `lowerOps` mints `cq_template_sext_i16_to_i32`. The
; forecast now asks `logicalOperandWidth` (R12, the one spelling).
;
; The shape is the hoisted-cast rolled loop of
; control_phase_kickback_mixed_short_sext_leak_control.ll: `-O1` hoists
; `(int)q` out of the loop, the loop reads its bits and carries a rotated `r`, and
; `q` is rotated after the loop:
;
;     short r = cq_theta(s2, 0.3);
;     for (int i = 0; i < 3; i++) { if (q & (1 << i)) <arm>; r = <r rotated>; }
;     q = cq_theta(q, 0.9);
;     return cq_measure(q) + cq_measure(r);
;
; with `q` a LAUNDERED i16 handle in two functions and a plain theta in the
; control:
;   @merge_out      q = (c > 2) ? a : b    (a 4.4 select-merge `%out`), arm cq_phi
;   @break_answer   q = an i16 value-arm `break` answer (`%cq.brk.out`), arm
;                   `r = cq_theta(r, 0.1)` (controlled Ry), no unconditional Ry
;   @theta_control  q = cq_theta(s, 0.5), arm cq_phi (the shipped shape: its
;                   source is not laundered, so the old and new forecast agree)
;
; The forecast's consumer here is `invariantRegisterRootsImpl` clause (ii-a): an
; out-of-loop template rail read only inside the loop is admitted with an
; EXIT-discharge obligation. With the i32 forecast the hoisted `sext` of a laundered
; `q` was not recognised as a rail, so the loop was not admitted and the module was
; refused. MEASURED on the pre-fix build (cq-opt c4726cae), one function at a time:
;   @merge_out     "cq loop lowering: rolled body leaks a rail entangled with a
;                   rotated register"
;   @break_answer  "cq controlled lowering: control flow inside a loop body under
;                   quantum control"
; The pre-fix direction is therefore an OVER-DECLINE, not an over-accept. (Shapes
; where the cast sits INSIDE the carried loop, so that conjunct (3) of
; `declineDephasingUnmarkedLoopRails` would skip it, were tried: four
; carried-accumulator variants with a later in-place rotation all decline at
; control emission, "control flow under quantum control", on both builds.)
;
; With the fixed forecast each function gets the CORRECT DISCHARGE, read in the
; lowered IR: the hoisted `sext_i16_to_i32` rail is minted before the loop, read
; by the per-trip `and` (whose `and`/`icmp` rails are uncomputed and freed in the
; same trip), and undone by `sext_i16_to_i32_unc` + `cqrt_free` at the loop exit
; BEFORE the `cqrt_ry_i16` on `q` (EXIT prefixes). The laundered functions also
; print the ruled warning "non-diagonal gate over a live derived record" (the Ry
; on `q` while `q` is itself a basis copy of a/b or of the break rail, bd lyyf);
; that warning is independent of this fix and is not checked here.
;
; Stage-1 IR: clang -O1 of the C in each comment (attributes trimmed, renamed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

; short a = cq_theta(s,.5), b = cq_theta(t,.25); int c = cq_theta(k,.75);
; short q = (c > 2) ? a : b;   short r = cq_theta(s2,.3);
; for (int i = 0; i < 3; i++) { if (q & (1 << i)) cq_phi(0.2); r = cq_theta(r,.1); }
; q = cq_theta(q, 0.9);  return cq_measure(q) + cq_measure(r);
define i32 @merge_out(i16 noundef signext %0, i16 noundef signext %1, i32 noundef %2, i16 noundef signext %3) {
  %5 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef 5.000000e-01) #0
  %6 = tail call signext i16 @cq_theta_si16(i16 noundef signext %1, double noundef 2.500000e-01) #0
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 7.500000e-01) #0
  %8 = icmp sgt i32 %7, 2
  %9 = select i1 %8, i16 %5, i16 %6
  %10 = tail call signext i16 @cq_theta_si16(i16 noundef signext %3, double noundef 3.000000e-01) #0
  %11 = sext i16 %9 to i32
  br label %19

12:
  %13 = tail call signext i16 @cq_theta_si16(i16 noundef signext %9, double noundef 9.000000e-01) #0
  %14 = tail call signext i16 @cq_measure_si16(i16 noundef signext %13) #1
  %15 = sext i16 %14 to i32
  %16 = tail call signext i16 @cq_measure_si16(i16 noundef signext %27) #1
  %17 = sext i16 %16 to i32
  %18 = add nsw i32 %17, %15
  ret i32 %18

19:
  %20 = phi i32 [ 0, %4 ], [ %28, %26 ]
  %21 = phi i16 [ %10, %4 ], [ %27, %26 ]
  %22 = shl nuw nsw i32 1, %20
  %23 = and i32 %22, %11
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %26, label %25

25:
  tail call void @cq_phi(double noundef 2.000000e-01) #1
  br label %26

26:
  %27 = tail call signext i16 @cq_theta_si16(i16 noundef signext %21, double noundef 1.000000e-01) #0
  %28 = add nuw nsw i32 %20, 1
  %29 = icmp eq i32 %28, 3
  br i1 %29, label %12, label %19, !llvm.loop !0
}
; CHECK-LABEL: define i32 @merge_out(
; CHECK:      %[[MO:out[0-9]*]] = call i32 @cqrt_alloc_i16(i16 0)
; CHECK:      %[[MC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i16_to_i32(i32 %[[MO]])
; CHECK:      call void @cq_template_sext_i16_to_i32_unc(i32 %[[MC]], i32 %[[MO]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[MC]])
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[MO]], double 9.000000e-01)
; CHECK:      %[[MA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[MC]],
; CHECK:      call void @cq_template_and_i32_hl_unc(i32 %[[MA]], i32 %[[MC]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[MA]])
; (The loop block follows the exit block in the output, so no `ret` after it.)

; short p = cq_theta(ps,.5), q = cq_theta(s,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; short r = cq_theta(s2,.3);
; for (int i = 0; i < 3; i++) { if (q & (1 << i)) r = cq_theta(r,.1); }
; q = cq_theta(q, 0.9);  return cq_measure(q) + cq_measure(r);
define i32 @break_answer(i16 noundef signext %0, i16 noundef signext %1, i16 noundef signext %2, i32 noundef %3) {
  %5 = tail call signext i16 @cq_theta_si16(i16 noundef signext %1, double noundef 5.000000e-01) #0
  %6 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef 2.500000e-01) #0
  %7 = icmp sgt i32 %3, 0
  br i1 %7, label %8, label %16

8:
  %9 = phi i32 [ %13, %8 ], [ 0, %4 ]
  %10 = phi i16 [ %11, %8 ], [ %6, %4 ]
  %11 = xor i16 %10, 5
  %12 = icmp eq i16 %11, %5
  %13 = add nuw nsw i32 %9, 1
  %14 = icmp eq i32 %13, %3
  %15 = select i1 %12, i1 true, i1 %14
  br i1 %15, label %16, label %8

16:
  %17 = phi i16 [ %6, %4 ], [ %11, %8 ]
  %18 = tail call signext i16 @cq_theta_si16(i16 noundef signext %2, double noundef 3.000000e-01) #0
  %19 = sext i16 %17 to i32
  br label %27

20:
  %21 = tail call signext i16 @cq_theta_si16(i16 noundef signext %17, double noundef 9.000000e-01) #0
  %22 = tail call signext i16 @cq_measure_si16(i16 noundef signext %21) #1
  %23 = sext i16 %22 to i32
  %24 = tail call signext i16 @cq_measure_si16(i16 noundef signext %36) #1
  %25 = sext i16 %24 to i32
  %26 = add nsw i32 %25, %23
  ret i32 %26

27:
  %28 = phi i32 [ 0, %16 ], [ %37, %35 ]
  %29 = phi i16 [ %18, %16 ], [ %36, %35 ]
  %30 = shl nuw nsw i32 1, %28
  %31 = and i32 %30, %19
  %32 = icmp eq i32 %31, 0
  br i1 %32, label %35, label %33

33:
  %34 = tail call signext i16 @cq_theta_si16(i16 noundef signext %29, double noundef 1.000000e-01) #0
  br label %35

35:
  %36 = phi i16 [ %34, %33 ], [ %29, %27 ]
  %37 = add nuw nsw i32 %28, 1
  %38 = icmp eq i32 %37, 3
  br i1 %38, label %20, label %27, !llvm.loop !0
}
; CHECK-LABEL: define i32 @break_answer(
; CHECK:      %[[BO:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i16(i16 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[BC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i16_to_i32(i32 %[[BO]])
; CHECK:      call void @cq_template_sext_i16_to_i32_unc(i32 %[[BC]], i32 %[[BO]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BC]])
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[BO]], double 9.000000e-01)
; CHECK:      %[[BA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[BC]],
; CHECK:      call void @cqrt_ry_i16_controlled(
; CHECK:      call void @cq_template_and_i32_hl_unc(i32 %[[BA]], i32 %[[BC]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[BA]])

; short q = cq_theta(s,.5), r = cq_theta(s2,.3);
; for (int i = 0; i < 3; i++) { if (q & (1 << i)) cq_phi(0.2); r = cq_theta(r,.1); }
; q = cq_theta(q, 0.9);  return cq_measure(q) + cq_measure(r);
define i32 @theta_control(i16 noundef signext %0, i16 noundef signext %1) {
  %3 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef 5.000000e-01) #0
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext %1, double noundef 3.000000e-01) #0
  %5 = sext i16 %3 to i32
  br label %13

6:
  %7 = tail call signext i16 @cq_theta_si16(i16 noundef signext %3, double noundef 9.000000e-01) #0
  %8 = tail call signext i16 @cq_measure_si16(i16 noundef signext %7) #1
  %9 = sext i16 %8 to i32
  %10 = tail call signext i16 @cq_measure_si16(i16 noundef signext %21) #1
  %11 = sext i16 %10 to i32
  %12 = add nsw i32 %11, %9
  ret i32 %12

13:
  %14 = phi i32 [ 0, %2 ], [ %22, %20 ]
  %15 = phi i16 [ %4, %2 ], [ %21, %20 ]
  %16 = shl nuw nsw i32 1, %14
  %17 = and i32 %16, %5
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %20, label %19

19:
  tail call void @cq_phi(double noundef 2.000000e-01) #1
  br label %20

20:
  %21 = tail call signext i16 @cq_theta_si16(i16 noundef signext %15, double noundef 1.000000e-01) #0
  %22 = add nuw nsw i32 %14, 1
  %23 = icmp eq i32 %22, 3
  br i1 %23, label %6, label %13, !llvm.loop !0
}
; CHECK-LABEL: define i32 @theta_control(
; CHECK:      %[[TQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i16(i16 %0)
; CHECK:      %[[TC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i16_to_i32(i32 %[[TQ]])
; CHECK:      call void @cq_template_sext_i16_to_i32_unc(i32 %[[TC]], i32 %[[TQ]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[TC]])
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[TQ]], double 9.000000e-01)
; CHECK:      ret i32

declare i16 @cq_theta_si16(i16 noundef signext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i16 @cq_measure_si16(i16 noundef signext)
declare void @cq_phi(double noundef)

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
