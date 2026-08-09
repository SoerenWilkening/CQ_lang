; control_predmux_accept_selectform_seed_flags_preserved.ll — ACCEPT (bd u1rp).
; THE RED-GREEN FOR HALF 1: stripPoisonCone's walk must not exceed the proof's.
;
; `coneDefinedAfterFlagDrop` treats a `cq_theta`/`cq_phi` result as a DEFINED
; LEAF and stops there WITHOUT operand recursion — poison does not propagate
; through a call's return value, so the poison chain is cut at the rotation and
; nothing below it can make the shielded cone poisonous. The strip used to have
; no such leaf case: it recursed straight past the rotation into the CLASSICAL
; SEED subtree and dropped `nsw`/`nuw` off instructions the whitelist REFUSES and
; the proof NEVER VISITED. On the pre-fix plugin `%seed` below came out
; `add i32 %u, 1`.
;
; This fixture pins the narrowed walk from the outside: the region must still
; claim and flatten (so this is ALSO the positive control — the narrowing must
; not cost an accept), and `%seed`'s flags must SURVIVE into the output because
; the proof never authorised touching them.
;
; PAIRED WITH control_predmux_accept_selectform_incone_flags_stripped.ll, which
; is the SAME instruction shape on the OTHER side of the rotation leaf and must
; still be stripped. Read the two together; either one alone can be satisfied by
; a wrong walk.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s \
; RUN:  --implicit-check-not='br i1' --implicit-check-not='select i1'
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:  | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)

define i32 @probe(i32 %u, i32 %c) {
entry:
  ; BELOW the rotation leaf — outside the proof's walk, so outside the strip's.
  %seed = add nsw nuw i32 %u, 1
  %q = call i32 @cq_theta_si32(i32 %seed, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @llvm.ctlz.i32(i32 %q, i1 false)   ; TOTAL — defined at %q == 0
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  ; TWO merge phis, deliberately: the single-phi form dies at the W-witness gate
  ; before the cone proof is ever consulted, and a probe that dies there proves
  ; nothing (bd memory [[predmux-purity-is-not-definedness-3c6m142]]).
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; THE ASSERTION. Both flags survive, and the seed still feeds the allocator —
; so the narrowing left the value wiring alone and only stopped MUTATING it.
; LLVM prints the flags in canonical `nuw nsw` order regardless of source order.
; CHECK:      %[[SEED:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %u, 1
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[SEED]])

; And the region really did flatten — otherwise the CHECK above is vacuous,
; because an unclaimed region never calls stripPoisonCone at all.
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ctlz_i32(i32 %[[Q]])
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R]], i32 0)
; CHECK:      %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
