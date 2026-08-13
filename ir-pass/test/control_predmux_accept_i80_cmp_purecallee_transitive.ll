; control_predmux_accept_i80_cmp_purecallee_transitive.ll — ACCEPT (bd 3c6m.14.1).
;
; SURFACE S5 — the pure-callee proof's OWN recursion. `@leaf` is squeaky clean
; (one call + one fadd); the i80 `_hl` compare is one level down, in `@deep`.
; Pre-change the proof failed at the inner body and the failure propagated
; outward through the recursion, so the OUTER call left the region:
;   CQ_PREDMUX_DBG: pure-callee deep fails at:   %eq = icmp eq i80 %man, ...
;   CQ_PREDMUX_DBG: pure-callee leaf fails at call:   %d = call x86_fp80 @deep(...)
;   CQ_PREDMUX_DBG: leave @probe ... gate=E4-dataflow at:   %r = call x86_fp80 @leaf(...)
; That three-line cascade is why S5 is listed as its own surface rather than
; folded into S1: the widened clause fires on a function the region never names,
; two frames below the instruction that was being judged.
;
; It also pins the transitive SPECIALIZATION that follows (Phase 6.3): one clone
; per level, the inner one reversed inside the outer wrap by its synthesized
; void twin `@__cq_q_deep_1_unc`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='phi x86_fp80' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: env CQ_PREDMUX_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG --allow-empty

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

; The i80 compare lives HERE, two frames below the claim.
define x86_fp80 @deep(x86_fp80 %v) {
e:
  %bc = bitcast x86_fp80 %v to i80
  %man = and i80 %bc, 18446744073709551615
  %eq = icmp eq i80 %man, 9223372036854775808
  %r = select i1 %eq, x86_fp80 %v, x86_fp80 0xK3FFF8000000000000000
  ret x86_fp80 %r
}

; Otherwise-clean OUTER callee: every instruction was already on the grid.
define x86_fp80 @leaf(x86_fp80 %v) {
e:
  %d = call x86_fp80 @deep(x86_fp80 %v)
  %s = fadd x86_fp80 %d, 0xK3FFF8000000000000000
  ret x86_fp80 %s
}

define x86_fp80 @probe(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %arm, label %norm

arm:
  %r = call x86_fp80 @leaf(x86_fp80 %q)
  %k1 = fadd x86_fp80 %r, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                  ; 2 merge phis = the W3 claim witness
  %z = phi x86_fp80 [ %k1, %arm ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %r, %arm ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; The claim: the outer call is speculated and the diamond is flattened. BOTH
; copy sources of the caller merge are bound — a Rule-13 lens caught the first
; draft asserting only a bare `call void @cqrt_copy_f80_controlled(`, under which
; an arm inversion in the caller passed green.
; CHECK:       %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:       %[[K2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f80_hl(i32 %[[Q]], x86_fp80 0xK40008000000000000000)
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_leaf_1(i32 %[[Q]])
; CHECK:       %[[K1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f80_hl(i32 %[[R]], x86_fp80 0xKBFFE8000000000000000)
; CHECK:       %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f80_hl(i32 %[[Q]], x86_fp80 0xK3FFE8000000000000000)
; CHECK:       %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:       call void @cqrt_copy_f80_controlled(i32 %[[F1]], i32 %[[K1]], i32 %[[OUT]])
; CHECK:       call void @cqrt_x(i32 %[[F1]])
; CHECK:       call void @cqrt_copy_f80_controlled(i32 %[[F1]], i32 %[[K2]], i32 %[[OUT]])

; One clone per level; the inner clone's result is uncomputed inside the outer
; wrap by its void twin, from the SAME argument, before its rail is freed.
; CHECK-LABEL: define internal i32 @__cq_q_leaf_1(i32 %v)
; CHECK:         %[[D:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_deep_1(i32 %v)
; CHECK:         %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f80_hl(i32 %[[D]], x86_fp80 0xK3FFF8000000000000000)
; CHECK:         call void @cq_template_fadd_f80_hl_unc(i32 %[[S]], i32 %[[D]], x86_fp80 0xK3FFF8000000000000000)
; CHECK:         call void @__cq_q_deep_1_unc(i32 %[[D]], i32 %v)
; CHECK:         call void @cqrt_free(i32 %[[D]])

; The compare, in the inner clone, reading the MASKED word — and the select it
; feeds, with BOTH arms named and ordered (flag=1 takes the parameter %v, ¬flag
; takes the 1.0 literal rail). The first draft checked only the compare chain, so
; an inversion of THIS select also passed green.
; CHECK-LABEL: define internal i32 @__cq_q_deep_1(i32 %v)
; CHECK:         %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %v)
; CHECK:         %[[MAN:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %[[CAST]], i80 18446744073709551615)
; CHECK:         %[[EQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i80_hl(i32 %[[MAN]], i80 9223372036854775808)
; CHECK:         %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:         call void @cqrt_copy_f80_controlled(i32 %[[EQ]], i32 %v, i32 %[[SEL]])
; CHECK:         call void @cqrt_x(i32 %[[EQ]])
; CHECK:         %[[ONE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFF8000000000000000)
; CHECK:         call void @cqrt_copy_f80_controlled(i32 %[[EQ]], i32 %[[ONE]], i32 %[[SEL]])
; CHECK:         call void @cq_template_icmp_eq_i80_hl_unc(i32 %[[EQ]], i32 %[[MAN]], i80 9223372036854775808)

; CHECK-LABEL: define internal void @__cq_q_deep_1_unc(i32 %out, i32 %v)

; Red-green: all three cascade lines were printed pre-change.
; DBG-NOT: pure-callee deep fails
; DBG-NOT: pure-callee leaf fails
; DBG-NOT: leave @probe
