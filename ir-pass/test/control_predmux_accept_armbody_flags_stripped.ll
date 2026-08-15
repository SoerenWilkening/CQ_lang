; control_predmux_accept_armbody_flags_stripped.ll — ACCEPT.
; ARM: `PredMuxFlatten::moveBody`'s `I.dropPoisonGeneratingFlags()` — the ARM-BODY
; half of the flatten's speculation discipline, which had NO arm-kill fixture at
; all before this file.
;
; *** THE GAP, MEASURED: deleting that one call outright was INVISIBLE to the
; whole suite. *** `moveBody` hoists each arm instruction into the region entry —
; i.e. it SPECULATES it onto every basis state, including the ones the branch
; excluded — and drops `nsw`/`nuw`/`exact`/`nneg`/`disjoint` + poison-generating
; FMF as it goes. That drop is the same obligation `coneDefinedAfterFlagDrop` /
; `stripPoisonCone` discharge for the CONDITION cone (pinned by
; control_predmux_accept_selectform_incone_flags_stripped.ll), applied to the arm
; BODY. Nothing pinned it, so a refactor could have removed it silently: an arm
; `add nsw` hoisted with its flag intact is poison on exactly the basis states the
; speculation newly reaches.
;
; WHY THE PROBE INSTRUCTION HAS TO BE CLASSICAL, and this is the same reason the
; cone-side fixture gives: a TAINTED arm instruction is replaced by its
; `cq_template_*` and its flags vanish with it, so a tainted probe would measure
; nothing. `%cc` is classical (it reads only the parameter `%c`), survives the
; hoist verbatim, and lands in the `_hl` LITERAL slot of the tainted `add` that
; consumes it — where its flags are readable in the output.
;
; ARM-KILL, MEASURED: with `I.dropPoisonGeneratingFlags()` removed from
; `moveBody`, this module emits `%cc = add nuw nsw i32 %c, 1` and this file goes
; red; with it, `%cc = add i32 %c, 1`. The cone-side fixture is unaffected either
; way (its flagged op is in the CONDITION cone, which a different call strips), so
; the two rows pin the two halves independently — which is exactly the property
; the cone-side row's own header says a single fixture cannot deliver.
;
; This is additive: no accept or decline predicate changes, only the arm-kill
; surface.
;

; NOTE ON THE NEGATIVES BELOW. A `CHECK-NOT` for a cq DIAGNOSTIC would be VACUOUS
; here and is deliberately absent: this RUN line pipes only the OUTPUT FILE into
; FileCheck, and every `DiagnosticInfoUnsupported` goes to STDERR, so such a
; pattern could never match and would pin nothing. (Measured; and it is a tree-wide
; pattern — 51 of the 73 fixtures carrying such a line do not pipe stderr.) The
; accept assertion is carried by cq-opt's EXIT CODE, which an un-inverted run line
; already requires, plus the positive CHECKs. (Do not spell either directive token
; in this prose: lit and FileCheck parse them out of comments — that is what turned
; this block into a shell syntax error the first time it was written.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s --implicit-check-not='add nsw' --implicit-check-not='add nuw' < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp sgt i32 %q, 9
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  ; CLASSICAL, and in the ARM BODY — not in the condition cone. Only `moveBody`
  ; can strip these flags.
  %cc = add nsw nuw i32 %c, 1
  %k = add i32 %q, %cc
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The arm body is hoisted into the flattened entry with its poison-generating
; flags GONE, and the hoisted classical value reaches the template literal slot.
; The global implicit-check-not directives above carry the negative over the whole
; module, so a later reordering of these positives cannot silently close the
; window (that window bug shipped once already in the tape-fixture family).
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     %[[CC:[a-zA-Z0-9_.]+]] = add i32 %c, 1
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 %[[CC]])
; CHECK-NOT: br i1
