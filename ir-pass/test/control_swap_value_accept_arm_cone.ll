; control_swap_value_accept_arm_cone.ll — ACCEPT: the value arm's CLASSICAL CONE
; is hoisted with the chain (bd test_C_libtooling-fn1q, increment 1).
;
; `if (q > 5) { p += (k*3 + 7) ^ 5; }` — the arm holds the Q+C chain link AND the
; four classical instructions that compute its classical operand. Before this
; increment every one of those four was a STRAY OP and the region declined
; `impure value arm`; `valueArmIsPureChain` now proves them classical, pure,
; non-escaping and speculatable, records them on the region as `ShadowCone`, and
; `emitValueRegion` hoists them into the pred AHEAD of the chain.
;
; ⚠ WHY THIS SHAPE IS NOT EXOTIC. `clang -O1` SINKS a branch-invariant classical
; computation INTO the arm (Rule 9), so the C source `int t = (k*3+7)^5; if (c) p
; += t;` arrives here in exactly this form — measured, and it is why the owner's
; own `example/grover/grover_oracle_uncompute.c` family declined. The IR-level
; twin whose cone is already in the pred is
; control_swap_value_accept_arm_cone_prehoisted_twin.ll, and its lowered stream is
; BYTE-IDENTICAL to this one; that pair IS the correctness instrument here, since
; the cone emits no gate at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Counts live in their own whole-file prefixes — a positive COUNT inside a
; negative prefix WINDOWS every negative after it (the bd drbq Inc-4 lens).
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CONECNT < %t.cqd0.ll
@k = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %kk = load i32, ptr @k, align 4   ; CONE: a global scalar load — dereferenceable
  %k1 = mul i32 %kk, 3              ; CONE
  %k2 = add i32 %k1, 7              ; CONE
  %k3 = xor i32 %k2, 5              ; CONE — the chain link's classical operand
  %v1 = add i32 %p, %k3             ; the Q+C CHAIN link
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; THE WHOLE STREAM, CONTIGUOUS. `CHECK-NEXT` adjacency from the first alloc to the
; measure is the contract, not decoration: symbol ORDER cannot see an insertion,
; adjacency can (the Inc-2 round-1 review's finding F-V2-5, and it applies with
; extra force here because the cone lines are the ones a regression would move).
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; THE CONE, HOISTED INTO THE PRED IN BLOCK ORDER, still ORDINARY CLASSICAL IR.
; It mints no handle, allocates no rail and emits no gate — pinning it here is
; what says the hoist happened rather than the ops having been dropped (Rule 5:
; a silently dropped arm op is the stray rule's original hazard).
; CHECK-NEXT: %[[KK:[a-zA-Z0-9_.]+]] = load i32, ptr @k
; CHECK-NEXT: %[[K1:[a-zA-Z0-9_.]+]] = mul i32 %[[KK]], 3
; CHECK-NEXT: %[[K2:[a-zA-Z0-9_.]+]] = add i32 %[[K1]], 7
; CHECK-NEXT: %[[K3:[a-zA-Z0-9_.]+]] = xor i32 %[[K2]], 5
; the hoisted chain link, reading the hoisted cone value as its CLASSICAL operand
; — `_hl`, so the classical side stays a plain i32 and is never allocated a rail
; (the "do NOT promote a classical operand to a qubit handle" prohibition).
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 %[[K3]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: ret i32 %[[M]]

; NO ROUTE, NO CONTROLLED TWIN OF THE ARM'S OWN GATE, and no rail minted for the
; classical cone — the merge is a controlled BASIS COPY into a fresh |0> rail.
; This prefix is PURE: no positive directive may be added to it.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cq_template_add_i32_hl_controlled
; NOROUTE-NOT: cqrt_alloc_i32(i32 %k3
; NOROUTE-NOT: cqrt_alloc_i32(i32 %kk
; NOROUTE-NOT: cqrt_rz

; EXACT COUNTS, one symbol per whole-file prefix.
; ⚠ THE `call ` PREFIX IS LOAD-BEARING: a bare symbol name also matches the
; module's `declare` line, which made the first spelling of this prefix fail on a
; correct stream.
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT: call void @cqrt_copy_i32_controlled(
; The cone is hoisted ONCE and not duplicated per copy slot — a cone cloned into
; both merge arms would be invisible to every prefix above (both would still
; match) and is exactly the shape a careless hoist produces.
; CONECNT-COUNT-1: load i32, ptr @k
; CONECNT-NOT: load i32, ptr @k
