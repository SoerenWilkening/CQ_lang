; control_predmux_accept_selectform_incone_flags_stripped.ll — ACCEPT (bd u1rp).
; THE POSITIVE CONTROL that keeps the half-1 narrowing honest.
;
; A tightening that ALSO stops doing the work it must do is a new miscompile, not
; a fix. `coneDefinedAfterFlagDrop` admits this cone only on the promise that the
; poison-generating annotations WILL be dropped, so every node the proof visited
; must still be stripped. This is the exact sibling of
; control_predmux_accept_selectform_seed_flags_preserved.ll: the SAME instruction
; shape (`add nsw nuw` on a classical value), differing ONLY in which side of the
; `cq_theta` leaf it sits on.
;
;     seed_flags_preserved   %seed = add nsw nuw ...   BELOW the rotation  -> KEPT
;     this fixture           %cc   = add nsw nuw ...   INSIDE the cone     -> STRIPPED
;
; Neither fixture alone constrains the walk: a strip that touches nothing passes
; the first, a strip that touches everything passes the second. Only the pair
; pins the boundary, and the boundary IS the ticket.
;
; *** THIS FILE IS A CONTROL, AND IT IS GREEN ON THE PRE-CHANGE PLUGIN TOO. ***
; Say so plainly, because a reviewer measured exactly that and was right to
; flag it: this fixture is absent from the BASE-vs-SHIP corpus diff, so it pins
; NOTHING about the bd u1rp change by differential. That is what a control is
; for — its job is to fail if the narrowing ever goes too far, not to witness
; that the narrowing happened. Its discriminating power is demonstrated by
; arm-kill instead: deleting the strip's mutation (`I->dropPoisonGenerating-
; Annotations()`) turns THIS file red while the seed-flags fixture stays green.
;
; The in-cone node has to be CLASSICAL to be observable at all — a TAINTED cone
; instruction is replaced by its `cq_template_*` and its flags vanish with it, so
; a tainted control would measure nothing. A classical operand of a mixed compare
; leaf survives into the `_hl` LITERAL slot, where we can read it.
;
; The negative half is a GLOBAL implicit-check-not rather than a positional
; not-directive, because the claim is "no poison-generating flag survives
; ANYWHERE in the output" and a positional one covers only the span between two
; CHECKs. (Do not write the bare not-directive spelling in prose here — FileCheck
; parses it out of a comment and fails with "found empty check string".)
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='select i1'  --implicit-check-not='add nsw' --implicit-check-not='add nuw' < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctpop.i32(i32)

define i32 @probe(i32 %u, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  ; TWO flagged ops at DIFFERENT depths, and the depths are the point.
  ;
  ; %cc sits DIRECTLY under the compare. %below sits UNDERNEATH the curated
  ; intrinsic, so it is reachable only if the walk RECURSES THROUGH a curated
  ; call rather than treating it as a leaf. An arm-kill that turns every call
  ; into a leaf leaves %cc stripped (it was never behind the call) and %below
  ; UNSTRIPPED — so without %below this fixture cannot see that arm at all.
  ; Measured: with only %cc present, the "all calls are leaves" mutant stayed
  ; GREEN.
  %below = add nsw nuw i32 %c, 1
  %pc = call i32 @llvm.ctpop.i32(i32 %below)
  %cc = add nsw nuw i32 %pc, 1
  %b = icmp sgt i32 %q, %cc
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

; THE ASSERTION: `%cc` survives with BOTH flags gone. The global
; implicit-check-not above carries the negative; this pins the positive form, so
; a strip that deleted the instruction outright could not pass either.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:      %[[BELOW:[a-zA-Z0-9_.]+]] = add i32 %c, 1
; CHECK-NEXT: %[[PC:[a-zA-Z0-9_.]+]] = call i32 @llvm.ctpop.i32(i32 %[[BELOW]])
; CHECK-NEXT: %[[CC:[a-zA-Z0-9_.]+]] = add i32 %[[PC]], 1

; A curated intrinsic node is INTERIOR, not a leaf — the walk must recurse
; through it to have reached %cc at all. The classical call survives verbatim
; into emission (it is not tainted, so no template replaces it) and lands in the
; `_hl` LITERAL slot.
; CHECK:      call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 %[[CC]])
; CHECK:      call void @cqrt_toffoli(
