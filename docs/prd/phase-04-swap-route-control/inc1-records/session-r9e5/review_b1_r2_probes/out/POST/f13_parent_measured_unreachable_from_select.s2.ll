; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/f13_parent_measured_unreachable_from_select.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r2_probes/out/POST/f13_parent_measured_unreachable_from_select.s1.ll"

@g = global i32 0

declare i64 @cq_theta_si64(i64, double)

declare i64 @cq_measure_si64(i64)

define i32 @main() {
entry:
  %h = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1(i32 %h, double 2.000000e-01)
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
  %g = load volatile i32, ptr @g, align 4
  %cc = icmp sgt i32 %g, 7
  br i1 %cc, label %L, label %R

L:                                                ; preds = %entry
  %m2 = call i1 @cqrt_measure_i1(i32 %h)
  %zz = zext i1 %m2 to i32
  ret i32 %zz

R:                                                ; preds = %entry
  %bf = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %bf)
  %selop1 = call i32 @cqrt_alloc_i32(i32 9)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h, i32 %bf)
  call void @cqrt_free(i32 %bf)
  %m3 = call i32 @cqrt_measure_i32(i32 %out)
  ret i32 %m3
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)
