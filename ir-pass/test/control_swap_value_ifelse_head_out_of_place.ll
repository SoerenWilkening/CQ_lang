; control_swap_value_ifelse_head_out_of_place.ll — ACCEPT spec whose WHOLE POINT
; is a DISPOSITION, not a symbol set: the hoisted chain HEAD is lowered OUT OF
; PLACE, so the value merge's two `cqrt_copy_<W>_controlled` sources denote
; DISTINCT physical registers.
;
; WHY THIS FIXTURE EXISTS (bd test_C_libtooling-3qlq Inc 2, Rule-13 round-1
; review finding F-V1-5). Since Inc 2 `SwapRouteEmit::emitValueRegion` HOISTS
; each arm's chain onto the ORIGINAL routed register `Q` and merges with two
; controlled copies. `ArithLowering`'s M-C (`classifyInPlaceReassignment`)
; converts a tainted `add`/`sub`/`xor` into an IN-PLACE `cqrt_addc`/`cqrt_xorc`
; and RAUWs the result to the PARENT's handle. If it ever fired on a chain HEAD
; — whose parent is `Q` — the merge would silently lose an arm:
;   * DIAMOND (`@diamond_add_head`): the second copy is `copy_controlled(f, Q,
;     out)` verbatim, so an in-place head makes BOTH copies read the same rail:
;     `out = f ? R(p) : R(p)`. ONE conversion is enough to break it.
;   * IF/ELSE (`@ifelse_add_heads`): both heads read `Q`, so two conversions
;     collapse both copy sources onto `Q`: `out = f ? p : p`, both arms lost.
; Neither is visible to `opt -verify`, to a golden byte-diff (the gate multiset
; is unchanged), or to `free_pairing_check.py` (nothing is freed dirty). The
; ONLY thing standing behind it on this path is M-C's G6/G7 pair: the earlier
; head is refused by G6 (a later user of `Q` exists — the second copy, or the
; sibling arm's head) and the later head by G7. `SelectClassify`'s gate 6 is the
; equivalent property for a `?:`, and the `br`-value path does not run it.
;
; SO THIS FIXTURE IS THE TRIPWIRE FOR AN OUT-OF-FILE CHANGE. It is named in
; `ArithLowering.cpp`'s G6/G7 comment as consumer 2; the `At == bo` widening
; contemplated there in `priorUseIsSettled` would move the if/else case. If you
; relax either clause, re-derive this file before taking it.
;
; ONE-LINK chains deliberately: with a longer chain the head's result is
; consumed by a later link on a FRESH rail, so an in-place head would still
; leave the two copy sources distinct and the collision would not show. Both
; functions are HAND IR because `clang -O1` folds a one-link arm to a tainted
; `select` (`SelectClassify`'s own front door, which runs gate 6).
;
; MEASURED: subject 8c526d9 rc=0, both heads `cq_template_add_i32_hl` (out of
; place), ZERO `cqrt_addc_i32` in the module.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ifelse_add_heads(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armT, label %armF
armT:
  %a1 = add i32 %p, 4
  br label %merge
armF:
  %b1 = add i32 %p, 9
  br label %merge
merge:
  %pm = phi i32 [ %a1, %armT ], [ %b1, %armF ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

define i32 @diamond_add_head(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %p, 5
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; BOTH heads out of place, and the two copy sources are the two DISTINCT fresh
; rails. Contiguous so an inserted gate cannot hide between them.
; CHECK-LABEL: define i32 @ifelse_add_heads(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 4)
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 9)
; CHECK-NEXT: %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[F2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OUT]])

; The diamond: the SECOND copy reads the source register itself, so the first
; copy's source must NOT be that same register.
; CHECK-LABEL: define i32 @diamond_add_head(
; CHECK:      %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double 5.000000e-01)
; CHECK-NEXT: %[[P2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P2]], double 2.500000e-01)
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P2]], i32 5)
; CHECK-NEXT: %[[FLAG2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q2]], i32 5)
; CHECK-NEXT: %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[FLAG2]], i32 %[[T2]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAG2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[FLAG2]], i32 %[[P2]], i32 %[[OUT2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FLAG2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG2]], i32 %[[Q2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FLAG2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OUT2]])

; WHOLE-FILE, PURE-NEGATIVE. The first line is THE assertion of this fixture: no
; in-place reassignment anywhere in the module. The rest are the family's
; standing negatives (no route, no work rail, no residual diamond).
; NOROUTE-NOT: call void @cqrt_addc_i32(
; NOROUTE-NOT: call void @cqrt_xorc_i32(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: call i32 @cq_theta

; FOUR controlled copies in the module, two per region — never three (a
; duplicated copy is the identity on its branch and would otherwise pass).
; CCNT-COUNT-4: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
