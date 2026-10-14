; lowering_uncompute_dead_merge_outrail.ll — Phase 5 WI-4 DD-4 lock (PRD §2.2 /
; IMPLEMENTATION §4 WI-4), REVISED by bd test_C_libtooling-r2j3.32. A tainted-
; condition `select` whose merged result is DEAD (never measured, never returned).
; Phase 4 (SelectMergeEmit) lowers it to the controlled-XOR copy merge: a |0>
; OUT-rail `%out = cqrt_alloc(0)`, two `cqrt_copy_<W>_controlled` into it under the
; flag.
;
; The whole-DAG uncompute driver must still NEITHER uncompute NOR (under the WI-5
; silent→loud flip) DECLINE this rail: it is Phase-4-owned, and `ControlOwnedRails`
; subtracts `%out` BEFORE terminal selection, so `recoverDataDag` never bottoms out
; on it — no DATA `_unc` anywhere (pinned below).
;
; WHAT CHANGED (bd r2j3.32): the rail is no longer LEFT ALLOCATED. The merge-rail
; discharge (MergeRailDischarge.h) runs after every partition; with no reader at
; all, it re-emits the copy core in reverse right after the forward core, under
; the SAME flag (the copies are CNOT-class involutions), defers the flag strip to
; after that, and frees `%out` at a proven |0>. The copied operand `q` is never
; written by any of it. Before r2j3.32 the leaked `%out` was a live CNOT record of
; `y` and `q`, which dephased any later non-diagonal gate on either.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=UNC %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %u0, i32 %v0, i32 %z) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp sgt i32 %y, 5                       ; condition on the DISTINCT theta %y
  %sel = select i1 %c, i32 %q, i32 %z             ; DEAD merged result — never read
  ret void
}

; The controlled-XOR copy merge fires: |0> out-rail + two controlled copies into
; it, then (bd r2j3.32) the same core reversed, the deferred strip, the frees:
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q:[a-zA-Z0-9_.]+]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %z)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Z]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Z]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: ret void
;
; NO data-uncompute adjoint of the merge or of the entangled operand: EXACTLY ONE
; `_unc` call in the module, the compare strip (bd `8txa`: the strip is itself an
; `_unc`, so the pre-8txa blanket `CHECK-NOT: _unc` cannot be restored verbatim;
; a second strip on an already-freed rail would be a UAF + wrong unitary, and any
; DATA uncompute would be a second `_unc` call).
; UNC-COUNT-1: call void @cq_template_{{[if]}}cmp_{{[a-zA-Z0-9_]+}}_unc(
; UNC-NOT:     call {{.*}}_unc(
;
; Exactly TWO frees — the flag and (bd r2j3.32) the reversed out-rail; both theta
; rails still leak, never a dirty free; and opt exits 0 (the positive run lines
; are not negated):
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
