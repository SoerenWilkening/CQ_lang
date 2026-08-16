; control_predmux_accept_selectform_retattr_dropped.ll — ACCEPT (bd u1rp half 2).
; THE THIRD POISON-ANNOTATION FAMILY: call RETURN ATTRIBUTES.
;
; `Instruction::hasPoisonGeneratingAnnotations()` names THREE families — flags,
; metadata, and call return attributes (`range`/`nonnull`/`align`). The strip
; used to drop two. A lying `range` makes the call return POISON, which is
; exactly what `coneDefinedAfterFlagDrop` promised the drop would remove, so the
; gap broke the claim's literal guarantee.
;
; THE CHANNEL IS REACHABLE, and the first draft of the source note denying that
; was falsified with a run. A TAINTED curated intrinsic is replaced by its
; `cq_template_*` and takes its attributes with it — but a CLASSICAL one in a
; MIXED compare leaf (`icmp sgt i32 %q_tainted, %r_classical`) is neither
; replaced nor declined: it survives verbatim into the emitted module, attribute
; and all. Stock `clang -O1` emits precisely this from
; `q > 3 && q > __builtin_popcount(c)`, and real code has it — of 39
; poison-shielded select-forms across 251 openlibm TUs at -O1, `sqrt`'s carries
; `tail call range(i32 12, 33) i32 @llvm.ctlz.i32(...)` inside the shielded cone.
;
; WHY THIS SHIPS ONLY NOW: widening the DROP over the OLD walk would have
; extended a known over-reach (it recursed past the rotation into classical seed
; code). An earlier attempt at this half alone was reverted for that reason and
; the revert was right. Narrow the walk first, then widen the drop — the ORDER is
; the ticket. See control_predmux_accept_selectform_seed_flags_preserved.ll.
;
; The negative half is a GLOBAL implicit-check-not: the claim is that NO
; poison-generating return attribute survives anywhere in the output, and a
; positional CHECK-NOT would only cover the span between two CHECKs.
;
; bd 615s INCREMENT 2 NOTE: the `noundef` on `@probe`'s parameters is load-bearing
; and was added by that increment, not by the original author of this row.
; `classifyConeNode` now treats an `Argument` as a defined cone leaf IFF it carries
; `noundef` -- the direct LLVM proof that the value has no undef/poison bits -- so
; without it this row's shielded cone would (correctly) fail the proof and the
; region would go unclaimed. It is exactly what `clang -O1` emits for a real
; parameter, and the lowering with it is BYTE-IDENTICAL to this file's committed
; pre-increment output (measured, module-name lines aside). Do not remove it.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='select i1'  --implicit-check-not='range(' < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; The DECLARATION deliberately carries a poison-generating return attribute the
; call site does not, so the normalisation CHECK below observes something real.
; A canonical declaration here would make that check vacuous — it would pass
; whether or not LLVM normalised anything.
declare range(i32 0, 33) i32 @llvm.ctpop.i32(i32)

define i32 @probe(i32 noundef %u, i32 noundef %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  ; A CLASSICAL curated call with a poison-generating CALL-SITE return
  ; attribute, inside the shielded cone.
  %pc = call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %c)
  %b = icmp sgt i32 %q, %pc
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

; bd 94on(a) — the DECLARATION-level channel is closed by construction, and this
; line records the measurement rather than an argument. `getRetAttr` falls back
; from the call site to the declaration while the drop writes only the call site,
; so a lying declaration-level `range` would be invisible to both — but it cannot
; arise here: the cone's call clause admits only `isCuratedReversibleIntrinsic`,
; which requires a real `IntrinsicInst`, and LLVM 19 NORMALISES intrinsic
; declarations at parse time. Verified with stock `opt -passes=verify` and NO
; plugin over all eight curated stems. The declaration is emitted in canonical
; form no matter what a hand-written input says, and LLVM prints declarations
; before function bodies.
; CHECK:      declare i32 @llvm.ctpop.i32(i32)

; THE ASSERTION: the call survives (it is classical — nothing replaces it) and
; the `range` is gone, carried by the global implicit-check-not above. Matching
; the call positively as well means a strip that deleted it could not pass.
; CHECK:      %[[PC:[a-zA-Z0-9_.]+]] = call i32 @llvm.ctpop.i32(i32 %c)

; The region really did flatten, so the assertions above are not vacuous, and
; the surviving classical value really does land in the `_hl` LITERAL slot.
; CHECK:      call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[PC]])
; CHECK:      call void @cqrt_toffoli(
