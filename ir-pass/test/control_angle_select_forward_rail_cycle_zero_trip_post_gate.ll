; control_angle_select_forward_rail_cycle_zero_trip_post_gate.ll — ACCEPT (bd
; g35c's accept twin). `clang -O1` output (attributes and metadata dropped) of
;
;     volatile int cq_n = 0;
;     int slice(void) {
;       int q = 3, r = 7, n = cq_n;
;       cq_theta(&q, .5); cq_theta(&r, .25);
;       cq_theta(&r, (q == 5) ? .9 : .3);            // T: the angle select
;       int z = r;                                   // POST-gate name of r
;       for (int i = 0; i < n; i++) { cq_theta(&r, .1); z = r; }
;       z ^= 1;
;       return cq_measure(q) + cq_measure(z);
;     }
;
; and `@slice_plain`, the same with the uncontrolled `cq_theta(&r, .3)` for `T`.
;
; WHAT IT PINS. The loop's exit φ reads a POST-gate name on BOTH edges (`T`'s
; result `%6` on the zero-trip edge, the loop gate `%17` on the latch edge), so
; the record-liveness test bd g35c added for a MEMBER φ's incoming edges finds no
; rail gate between either incoming's definition and its edge, and the shape
; still lowers: one rail for `r`, `xorc(r, 1)` in the exit block on the handle,
; then the measure. The only difference from the declining
; `control_angle_select_reject_forward_rail_cycle_zero_trip_stale.ll` /
; `lowering_reject_loop_rail_record_zero_trip_merge.ll` is that φ's zero-trip
; incoming (`%6` here, the pre-gate `%3` there), and before bd g35c the two
; lowered BYTE-IDENTICALLY. Semantics: on n == 0 the source measures
; `(post-gate r) ^ 1`, which is `xorc(h_r, 1)` then `measure(h_r)`; on n > 0 the
; loop's `Ry(.1)`s land on `h_r` first. `r` itself is never read after the xor.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

@cq_n = global i32 0, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1 = load volatile i32, ptr @cq_n, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %4 = icmp eq i32 %2, 5
  %5 = select i1 %4, double 9.000000e-01, double 3.000000e-01
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %5)
  %7 = icmp sgt i32 %1, 0
  br i1 %7, label %14, label %8

8:
  %9 = phi i32 [ %6, %0 ], [ %17, %14 ]
  %10 = xor i32 %9, 1
  %11 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %13 = add nsw i32 %12, %11
  ret i32 %13

14:
  %15 = phi i32 [ %18, %14 ], [ 0, %0 ]
  %16 = phi i32 [ %17, %14 ], [ %6, %0 ]
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 1.000000e-01)
  %18 = add nuw nsw i32 %15, 1
  %19 = icmp eq i32 %18, %1
  br i1 %19, label %8, label %14
}

define i32 @slice_plain() {
  %1 = load volatile i32, ptr @cq_n, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01)
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %12, label %6

6:
  %7 = phi i32 [ %4, %0 ], [ %15, %12 ]
  %8 = xor i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %11 = add nsw i32 %10, %9
  ret i32 %11

12:
  %13 = phi i32 [ %16, %12 ], [ 0, %0 ]
  %14 = phi i32 [ %15, %12 ], [ %4, %0 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 1.000000e-01)
  %16 = add nuw nsw i32 %13, 1
  %17 = icmp eq i32 %16, %1
  br i1 %17, label %6, label %12
}

; THE EMITTED STREAM, IN ORDER, hand-derived (the by-difference angle select of
; `control_angle_select_forward_rail_cycle_frozen.ll`, then the in-place dtzb
; `xorc` on the exit φ's collapsed name). Handles are bound at their definition.
; CHECK-LABEL: define i32 @slice(
; CHECK-NEXT: %[[N:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_n
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = icmp sgt i32 %[[N]], 0
; CHECK-NEXT: br i1 %[[G]], label %[[LOOP:[a-zA-Z0-9_.]+]], label %[[EXIT:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[EXIT]]:
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[R]], i32 1)
; CHECK-NEXT: %[[MQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: %[[MR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: add nsw i32 %[[MR]], %[[MQ]]
; CHECK-NEXT: ret i32
; CHECK: {{^}}[[LOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)
;
; CHECK-LABEL: define i32 @slice_plain(
; CHECK-NEXT: %[[PN:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_n
; CHECK-NEXT: %[[PQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PQ]], double 5.000000e-01)
; CHECK-NEXT: %[[PR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PR]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PR]], double 3.000000e-01)
; CHECK-NEXT: %[[PG:[a-zA-Z0-9_.]+]] = icmp sgt i32 %[[PN]], 0
; CHECK-NEXT: br i1 %[[PG]], label %[[PLOOP:[a-zA-Z0-9_.]+]], label %[[PEXIT:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[PEXIT]]:
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[PR]], i32 1)
; CHECK-NEXT: %[[PMQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[PQ]])
; CHECK-NEXT: %[[PMR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[PR]])
; CHECK-NEXT: add nsw i32 %[[PMR]], %[[PMQ]]
; CHECK-NEXT: ret i32
; CHECK: {{^}}[[PLOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PR]], double 1.000000e-01)

; WHOLE-FILE, PURE-NEGATIVE.
; NEG-NOT: double -
;   ^ no reverse-play of either rail
; NEG-NOT: call i32 @cq_template_xor
;   ^ the xor is the in-place dtzb `xorc` on the handle, never a fresh rail
; NEG-NOT: call i32 @cq_theta_
; NEG-NOT: call i32 @cq_measure_
