; lowering_predmux_speccall_flatten_qrom.ll — ACCEPT (bd 20xt.4 Inc 2, blocker c):
; the pending-spec pure-callee proof (`isSpeculatablePureCalleeBody`, PredMux E4)
; now admits a const-global tainted-index QROM READ (`tbl[id]`) inside the callee
; body. `isSpeculatableDataflow` reuses the taint-blind `qromReadShapeInScope`
; (the SAME `matchQramAccess` structure the emitter re-proves — Rule 14, so the
; admit can never STRUCTURALLY diverge from what lowers): the immutable-global
; load is a pure, side-effect-free function of its arguments, so admitting it
; proves the callee is a pure total function whose CALL is speculatable exactly
; like every other arm op. The bounds/mask obligation stays the clone's job (the
; hoist keeps the callee's own control intact — nothing is speculated out of it).
;
; This is the atan2l->inner-atanl payoff: `atanl` reads `atanhi[id]`/`atanlo[id]`.
; Modelled on lowering_predmux_speccall_flatten.ll (an all-arithmetic pure body),
; extended with the QROM read. Under quantum control every basis state runs every
; arm, so the flatten hoists the call unconditional, the Phase-6 clone Bennett-
; wraps it (the straight-line clone body's read lowers via Inc-1's
; `lowerQramReads(inBennettClone=true)`), and the 4.4 copy merge selects the
; result under the compound edge predicate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
@T = internal unnamed_addr constant [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; A pure body whose ONLY memory access is a const-global tainted-index read.
define i32 @purefn(i32 %a) {
  %m = and i32 %a, 3
  %idx = zext i32 %m to i64
  %p = getelementptr inbounds [4 x i32], ptr @T, i64 0, i64 %idx
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, %a
  ret i32 %r
}

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
; The speculated call is retargeted to the Bennett clone, unconditional in the
; flattened straight line; the merge lowers to the controlled-copy mux.
; CHECK: %[[V:.*]] = call i32 @__cq_q_purefn_1(i32 %[[H:.*]])
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %[[V]], i32 %{{.*}})
;
; The clone: array-handle birth at entry (a CLASSICAL resource token, never
; freed), the masked index, the qram load, the add consumer, then the Bennett
; stream — copy-out, reverse (add_unc, LOAD_unc, and_unc), the scratch frees.
; CHECK: define internal i32 @__cq_q_purefn_1(i32 %a)
; CHECK: %[[ARR:.*]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK: %[[IDX:.*]] = call i32 @cq_template_and_i32_hl(i32 %a, i32 3)
; CHECK: %[[LV:.*]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[IDX]])
; CHECK: call void @cqrt_qram_load_i32_unc(i32 %[[LV]], i32 %[[ARR]], i32 %[[IDX]])
;
; The original memory access is gone; the array handle leaks (never freed); the
; load's `_unc` is the reverse form, never a fresh-minting `_inv`.
; CHECK-NOT: load i32
; CHECK-NOT: cqrt_free(i32 %[[ARR]])
; CHECK-NOT: cqrt_qram_load_i32_inv
