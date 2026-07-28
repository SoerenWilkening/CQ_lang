; lowering_uncompute_dead_merge_outrail.ll — Phase 5 WI-4 DD-4 lock (PRD §2.2 /
; IMPLEMENTATION §4 WI-4). A tainted-condition `select` whose merged result is
; DEAD (never measured, never returned). Phase 4 (SelectMergeEmit) lowers it to
; the controlled-XOR copy merge: a |0> OUT-rail `%out = cqrt_alloc(0)`, two
; `cqrt_copy_<W>_controlled` into it, the flag stripped + freed. The out-rail and
; the copied operand `q` are ENTANGLED and LEFT ALLOCATED (Rule 6/8 — never a
; dirty free).
;
; The whole-DAG uncompute driver must NEITHER uncompute NOR (under the WI-5
; silent→loud flip) DECLINE this rail: it is Phase-4-owned. `ControlOwnedRails`
; (the explicit DD-4 set the emitter populates at its `cqrt_alloc` site) subtracts
; `%out` BEFORE terminal selection, so `recoverDataDag` never bottoms out on it.
; This pins that the dead value-merge out-rail stays allocated with NO `_unc`, NO
; second free, and `opt` EXIT 0 (no spurious decline).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck --check-prefix=UNC %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %u0, i32 %v0, i32 %z) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp sgt i32 %y, 5                       ; condition on the DISTINCT theta %y
  %sel = select i1 %c, i32 %q, i32 %z             ; DEAD merged result — never read
  ret void
}

; The controlled-XOR copy merge fires: |0> out-rail + two controlled copies into it:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_free(i32 %[[F]])
;
; The dead out-rail is Phase-4-owned: NO data-uncompute adjoint of the merge / the
; entangled operand, and NO free of the out-rail (left allocated, the §16.5 leak):
; bd `8txa`: the flag STRIP is itself a `_unc` now, so the pre-8txa blanket
; `CHECK-NOT: _unc` cannot be restored verbatim. Pin the exact population
; instead — EXACTLY ONE `_unc` call in the module, and it is the compare
; strip. Strictly stronger than the blanket form for the double-strip case
; (a second strip on an already-freed rail is a UAF + wrong unitary), and
; it still forbids any DATA uncompute (that would be a second `_unc` call).
; UNC-COUNT-1: call void @cq_template_{{[if]}}cmp_{{[a-zA-Z0-9_]+}}_unc(
; UNC-NOT:     call {{.*}}_unc(
; CHECK-NOT: cqrt_free(i32 %[[OUT]])
;
; Exactly ONE free (the flag only) — the out-rail and both theta rails leak, never
; a dirty free; and opt exits 0 (the positive run lines are not negated):
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
