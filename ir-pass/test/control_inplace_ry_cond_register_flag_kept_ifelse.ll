; control_inplace_ry_cond_register_flag_kept_ifelse.ll — ACCEPT: both arms of an
; if/else rotate the condition's own register (bd test_C_libtooling-dm7f.4).
;
;     int q = u; cq_theta(&q, .5);
;     if (q > 5) cq_theta(&q, .3); else cq_theta(&q, .7);
;     return cq_measure(q);
;
; `nomerge` on every `cq_theta_*` (CQ.h) keeps the two arms apart, so `-O1` hands
; this over as an if/else, not as an angle select. Both arms pass R3 (one base)
; and both overlap the condition through `Prov`, so the region keeps ONE flag.
;
; TRACE: f = [x>5]; cry(f, q, .3) fires on x > 5; x(f); cry(f, q, .7) fires on
; x <= 5; x(f) restores f. M-beta chains the second gate onto the first, so both
; act on q's one rail in emission order, and each branch sees exactly its own
; rotation. The mint reads the pre-Ry basis because it precedes both gates. f is
; left allocated (R5). M-A warns once per gate, so twice.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --implicit-check-not=cqrt_free --implicit-check-not=_unc < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  br label %merge
else:
  %qe = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; WARN-COUNT-2: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; (0.7 has no exact short decimal, so LLVM prints the same double in hex.)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32
