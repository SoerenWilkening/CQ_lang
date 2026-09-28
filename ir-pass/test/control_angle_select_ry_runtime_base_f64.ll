; control_angle_select_ry_runtime_base_f64.ll — ACCEPT (bd test_C_libtooling-z0re round 2):
; the Ry-stem angle select on an UNTAINTED RUNTIME f64 base.
;
;     double t = atof(v[1]); int q = cq_theta(atoi(v[2]), .3); double r;
;     if (q > 3) r = cq_theta(t, .7); else r = cq_theta(t, .2);   // r1B probe p2as_f64
;
; Stream: `alloc_f64(t); ry_f64(h, .2); ry_f64_controlled(f, h, fl(.7 - .2))`. The fp
; base is admitted under the owner's 2026-09-28 fp ruling; the seed's bits reach
; `cqrt_alloc_f64` unchanged (no fence compares a runtime seed's VALUE).
;
; ⚠ WHY THIS IS AN IR-LEVEL PIN: see `control_angle_select_ry_runtime_base_i8.ll` — bd
; fmt3 option B (`nomerge` on `cq_theta_*`) makes the untainted-base angle select
; unreachable from C once it lands; this file keeps the lowering pinned. On the ORACLE
; (main 9a230646) it declines `rotation angle` at S3.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_measure_f64(double)

define i32 @example(double %t, i32 %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %b, double 3.000000e-01)
  %c = icmp sgt i32 %q, 3
  %ang = select i1 %c, double 0x3FE6666666666666, double 2.000000e-01
  %r = call double @cq_theta_f64(double %t, double %ang)
  %mr = call double @cq_measure_f64(double %r)
  %ir = fptosi double %mr to i32
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s = add nsw i32 %mq, %ir
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %b)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %t)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[F]], i32 %[[R]], double 0x3FDFFFFFFFFFFFFF)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[R]])

; NEG-NOT: = select
; NEG-NOT: cq_theta_
