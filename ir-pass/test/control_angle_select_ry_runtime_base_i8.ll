; control_angle_select_ry_runtime_base_i8.ll — ACCEPT (bd test_C_libtooling-z0re round 2):
; the Ry-stem angle select on an UNTAINTED RUNTIME base at the i8 width, with the
; `!=`-canonicalised orientation.
;
;     signed char t = atoi(v[1]); int q = cq_theta(atoi(v[2]), .3); signed char r;
;     if (q != 3) r = cq_theta(t, .7); else r = cq_theta(t, .2);   // r1B probe as_i8
;
; `-O1` canonicalises `!=` to `icmp eq` and swaps the select arms: `select (q == 3),
; .2, .7`, so A = .2 (flag set), B = .7, and the by-difference stream is
; `alloc_i8(t); ry_i8(h, .7); ry_i8_controlled(f_eq, h, fl(.2 - .7))` — f = 0 (q != 3)
; Ry(.7), f = 1 Ry(.7 + (.2 - .7)) = Ry(.2) up to one ulp, inside S1's 2^-40 fence.
;
; WHY AN IR-LEVEL PIN (round 2): the if/else spelling above reaches S3 only because
; SimplifyCFG MERGES the two thetas, and bd fmt3 option B (`nomerge` on `cq_theta_*`,
; landed after z0re, 2026-09-29) stops that merge for direct calls. ⚠ CORRECTED (Rule-13 r2 F-r2-1): the round-2
; spelling of this paragraph said the admission then becomes UNREACHABLE FROM C — false.
; The TERNARY spelling `r = cq_theta(t, (q != 3) ? .7 : .2);` gives this same IR with no
; merge and is untouched by `nomerge`. This file pins the lowering independently of
; which C spelling reaches it, alongside `control_angle_select_ry_runtime_base.ll` (i32)
; and `…_runtime_base_f64.ll`. Body: the probe's stage-1 IR, minimised. On the ORACLE
; (main 9a230646) it declines `rotation angle` at S3.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i8 @cq_theta_si8(i8, double)
declare i32 @cq_measure_si32(i32)
declare i8 @cq_measure_si8(i8)

define i32 @example(i32 %a, i32 %b) {
entry:
  %t = trunc i32 %a to i8
  %q = call i32 @cq_theta_si32(i32 %b, double 3.000000e-01)
  %c = icmp eq i32 %q, 3
  %ang = select i1 %c, double 2.000000e-01, double 0x3FE6666666666666
  %r = call i8 @cq_theta_si8(i8 %t, double %ang)
  %mr = call i8 @cq_measure_si8(i8 %r)
  %mr32 = sext i8 %mr to i32
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s = add nsw i32 %mq, %mr32
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %b)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %t)
; CHECK-NEXT: call void @cqrt_ry_i8(i32 %[[R]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i8_controlled(i32 %[[F]], i32 %[[R]], double 0xBFDFFFFFFFFFFFFF)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i8 @cqrt_measure_i8(i32 %[[R]])
; CHECK-NEXT: sext i8
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])

; NEG-NOT: = select
; NEG-NOT: cq_theta_
; NEG-NOT: cqrt_x(
