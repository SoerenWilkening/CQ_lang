; control_inplace_ry_rail_stateprep_negated_inf_angle.ll — ACCEPT: a NON-FINITE
; CONSTANT angle (`+inf`) on a NEGATED rail-condition STATE PREP.
;
;     _Bool b; cq_theta(&b, .5); int r = 5; if (!b) cq_theta(&r, __builtin_inf());
;
; The controlled state prep duplicates the angle the way the negated in-place arm
; does: `cqrt_alloc_<W>(SEED); cqrt_ry_<W>(h_r, θ); cqrt_ry_<W>_controlled(h_b,
; h_r, −θ)`. It was the fourth member of l4x4.b round-1 finding F-1's class and
; declined a non-finite constant θ. RETIRED by bd dm7f.6 round-1 F-B1 under owner
; ruling 2026-10-13 (`owner-ruling-nonfinite-angle-identity`): a non-finite
; rotation is the identity, so the `b = 1` branch's `Ry(+inf)·Ry(−inf)` is `I·I`
; and the seed stays |5⟩, as the source says.
;
; THIS FILE WAS `control_inplace_ry_reject_rail_stateprep_negated_inf_angle.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %merge, label %arm

arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 0x7FF0000000000000)
  br label %merge

merge:
  %rm = phi i32 [ 5, %entry ], [ %rt, %arm ]
  %mb = call i1 @cq_measure_i1(i1 %b)
  %zb = zext i1 %mb to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zb
  ret i32 %s
}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 0x7FF0000000000000)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double 0xFFF0000000000000)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  call void @cqrt_ry_
; CHECK-NOT:  call void @cqrt_x(
