; control_inplace_ry_cond_register_flag_kept_negated.ll — ACCEPT: the Ry on the
; condition's own register sits on the FALSE edge (bd test_C_libtooling-dm7f.4).
; CASE: KEPT (the compare reads the rotated register; the strip is impossible).
;
;     int q = u; cq_theta(&q, .5);
;     if (q > 5) { } else cq_theta(&q, .9);   // -O1 hands this over exactly so
;     return cq_measure(q);
;
; POLARITY (R8): `-O1` keeps the compare and swaps the successors, so the arm is
; the false successor and fires on NOT f. The flag is a minted ANCILLA, so the
; compare path's own negation applies unchanged: a self-inverse `cqrt_x(f)` pair
; around the one controlled gate. Nothing but that controlled Ry touches the user
; register q; the Ry-additivity spelling (`ry(h,θ); ry_controlled(h_b,h,−θ)`) is
; for a `_Bool` RAIL condition, where the control IS a user register and may not
; be bracketed.
;
; TRACE: f = [x>5]; x(f) gives [x<=5]; cry fires on x <= 5; x(f) restores
; f = [x>5]. So q gets Ry(.9) exactly on the source's else branch, and f, the
; pre-Ry predicate, is left allocated (never stripped, never freed: R5). One M-A
; warning at the gate (owner ruling lyyf).
;
; The CHECK-NEXT chain pins the bracket as a PAIR around the one gate, the
; compare path's shipped spelling.
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
  br i1 %c, label %merge, label %arm
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %qt, %arm ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[H]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32
