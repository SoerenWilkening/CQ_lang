; control_predmux_reject_selectform_load_in_cone.ll — DECLINE.
; ARM: `definedOpAfterFlagDrop`'s refusal of a `load` inside a poison-SHIELDED
; select-form cone (PredMuxFlatten.cpp:228-286 — no Load clause, no GEP clause,
; falls through to `return false` = `ConeNode::Fail`).
;
; *** THIS FIXTURE DOES NOT EXIST TO PIN AN OVER-DECLINE. IT PINS THE ONLY
; ORDER-INDEPENDENT FENCE PROTECTING THE ONE READER WHOSE VERDICT
; `stripPoisonCone`'S FLAG DROP MOVES IN THE DECLINE -> ACCEPT DIRECTION. ***
;
; THE CHAIN, because nothing else in the tree records it and the fence is
; invisible from the code it protects:
;
;   1. `stripPoisonCone` (PredMuxFlatten.cpp:2388) calls
;      `dropPoisonGeneratingAnnotations()` on every `Interior` node of a claimed
;      shielded cone (:2408). Those instructions may have users OUTSIDE the cone.
;   2. `Fp80Union.cpp:838-841` (`PaddingWalk::eval`) reads
;      `hasNoSignedWrap()`/`hasNoUnsignedWrap()`/`isExact()` as BLOCKERS — on true
;      it does `return I`, which is a loud decline. Remove the flag and it falls
;      through to the divergence transfer and may `return nullptr` = ACCEPT.
;      That is an inverter, and it is the ONLY direct reader of a dropped fact in
;      the whole pass (`grep -rnE 'hasNoSignedWrap|hasNoUnsignedWrap|isExact\(\)'
;      ir-pass/src ir-pass/include` returns exactly those two lines).
;   3. Two independent fences stop it. ORDERING: `PaddingWalk` is instantiated
;      only at Fp80Union.cpp:1385/:1393, both inside `promoteFp80Union`, whose
;      fixpoint (CQLoweringPass.cpp:170) completes before the first
;      `flattenPredMuxRegions` (:194). NOTHING PINS THAT ORDERING — no assertion,
;      no test. THIS FIXTURE PINS THE OTHER ONE.
;   4. The order-independent fence: `PaddingWalk`'s ONLY non-zero divergence seed
;      is `setD(LI, M)` at Fp80Union.cpp:776, guarded by
;      `dyn_cast<LoadInst>(I)` + `LoadAt.find(LI)` — a straddle load. Every other
;      `setD` is a transfer or sets zero, and the blocker at :838 is reached only
;      AFTER the `Da.isZero() && Db.isZero()` early exit. So the blocker only ever
;      examines straddle-load-derived values — and a cone containing a load is
;      `Fail`, never claimed, never stripped. The two sets are disjoint.
;
; SO: GROW `definedOpAfterFlagDrop` A LOAD CLAUSE AND THIS FENCE VANISHES
; SILENTLY, leaving only the unpinned pipeline ordering between the flag drop and
; a decline-to-accept flip in the fp80 padding analysis. That is what this row
; exists to make loud. It is also why bd 2qvr's proposal to loosen the select
; route to the phi route's speculation-safety standard — which admits loads —
; cannot simply inherit the closure: see the constraint recorded on that ticket.
;
; ARM-KILL, so this row cannot be satisfied by some other site's guard (the bd
; xy9n lesson: a fixture CAN be satisfied by a different fence). Replacing ONLY
; the `load` with a genuine `Interior` node — `%ld = add i32 %c, 1` over an
; `i32 noundef %c` parameter, leaving every other line byte-identical — ACCEPTS:
; `opt` exit 0, 5 `cqrt_toffoli`. Both an internal-global and an external-global
; load decline. So the load is what moves the verdict, not the surrounding shape.
;
; The gate is `E6-condtree` — `isSupportedCondTree`'s select-form clause
; (PredMuxFlatten.cpp:739-752), which is where `coneDefinedAfterFlagDrop` runs.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; DBG: leave @probe entry=entry merge=merge gate=E6-condtree

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@g = internal global i32 7, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %ld = load i32, ptr @g, align 4      ; the LOAD — cone leaf, refused
  %b = icmp sgt i32 %q, %ld            ; the SHIELDED operand
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge
arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge
merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}
