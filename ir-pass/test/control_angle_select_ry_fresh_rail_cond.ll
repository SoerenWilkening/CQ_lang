; control_angle_select_ry_fresh_rail_cond.ll — ACCEPT (bd test_C_libtooling-dm7f.54,
; CQ_FINDINGS F4, reporter t4.c lines 1-2): a Ry ANGLE SELECT on a FRESH |0>
; target under a bare `_Bool` condition.
;
;     bool q0 = 0, q1 = 0; int c = 0;
;     cq_theta(&q0, 1.0); c += q0;
;     cq_theta(&q1, c == 0 ? 0.3 : 0.7);   // -O1: select i1 %q0, .7, .3
;
; `c == 0` over `c = zext q0` folds to the RAIL itself with the arms swapped, and
; `q1`'s seed is the LITERAL `false`. Before dm7f.54 this declined `rotation
; angle` (the literal seed, drbq.13). The call site carries `nomerge` (every
; direct `cq_theta_*` call clang emits from CQ.h does), so SimplifyCFG cannot
; have sunk two thetas into this one (`angleSelectLiteralSeedAdmissible`); the
; module is the user's ternary, and the target is a fresh rail.
;
; THE STREAM, X-bracket form (owner ruling angle-select-xbracket 2026-10-13) on
; a CNOT COPY of the register (`CondTreeEmit`'s `CopyRailRoot`), never on `q0`:
;   bf = alloc_i1(0); cnot(q0, bf)                   ; bf = q0 on every branch
;   h1 = alloc_i1(0); ry_c(bf, h1, .7); x(bf); ry_c(bf, h1, .3); x(bf)
;   cnot(q0, bf); free(bf)                           ; bf back to 0: proven |0>
; ANALYTIC: |q0=1> -> q1 = Ry(.7)|0>, |q0=0> -> q1 = Ry(.3)|0>, i.e. the source's
; `c == 0 ? .3 : .7`. Each angle reaches exactly one gate; q0 sees only control
; slots and is not freed (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %q0 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %ang = select i1 %q0, double 0x3FE6666666666666, double 3.000000e-01
  %q1 = call i1 @cq_theta_i1(i1 false, double %ang) #0
  %m0 = call i1 @cq_measure_i1(i1 %q0)
  %m1 = call i1 @cq_measure_i1(i1 %q1)
  %z0 = zext i1 %m0 to i32
  %z1 = zext i1 %m1 to i32
  %s = add i32 %z0, %z1
  ret i32 %s
}

attributes #0 = { nomerge nounwind }

; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[A]], double 1.000000e+00)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])
; CHECK-NOT:  call void @cqrt_free(

; NEG-NOT: = select
; NEG-NOT: cq_theta_
