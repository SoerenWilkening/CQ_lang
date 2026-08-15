; control_predmux_accept_selectform_bare_arg.ll — ACCEPT (bd 615s).
; ARM: the SCOPE of the bd 615s Argument clause — and, deliberately, THE HALF OF
; bd 615s THAT IS STILL OPEN.
;
; *** THIS FILE PINS A KNOWN-UNSOUND ACCEPT ON PURPOSE. *** `classifyConeNode`
; still returns `Leaf` for a BARE `Argument`, i.e. still calls it "defined". That
; is literally false in exactly the way the attributed form is: a caller may pass
; `poison` to any parameter, and the flatten's `select(a, b, false)` -> `and(a, b)`
; canonicalization then OBSERVES the shielded `%b` on basis states the source's
; short circuit excluded. Nothing about bd 615s Option 1 changes that.
;
; WHY IT IS NOT ALSO CLOSED — AND THE HONEST ANSWER IS NOT "IT IS TOO EXPENSIVE".
;
; *** AN EARLIER DRAFT OF THIS PARAGRAPH CARRIED A COST NUMBER THAT WAS WRONG BY
; ~14x, IN THE DIRECTION THAT DISCOURAGES CLOSING THE HOLE. The Rule-13 round
; measured it; do not restore it. *** It read: "28 of the 49 shielded select-forms
; in the corpus reach a bare Argument … refusing bare arguments would decline 28
; real select-forms outright." Two things are wrong with that. The corpus is
; `ir-pass/test` — THIS PASS'S OWN HAND-WRITTEN FIXTURES, not real code — and 19
; of the 28 are exit-code-inverted DECLINE rows that already decline for other
; reasons.
; And a SHAPE census is not a FENCE measurement; the census tool's own header says
; so in as many words.
;
; THE FENCE MEASUREMENT, by arm-kill (every `Argument` -> `Fail`), comparing exit
; code AND emitted IR per module:
;
;     ir-pass/test         3 of 1048 change, all exit 0 -> 1:
;                            control_predmux_accept_selectform_bare_arg   (THIS file)
;                            control_predmux_accept_selectform_incone_flags_stripped
;                            control_predmux_accept_selectform_retattr_dropped
;     e2e stage-1 modules  0 of 220 change
;
; and the non-`noundef`-only arm gives the identical 3 / 0. So the PRE-EXISTING
; accept lost by closing the populated half is TWO fixture rows and ZERO real code
; — and adding `noundef` to those two rows' parameters (what `clang -O1` would have
; emitted anyway) makes both accept again with byte-identical lowering.
;
; SO THE HALF IS OPEN BECAUSE THIS WORK WAS SCOPED TO OPTION 1 BY OWNER RULING,
; not because closing it is expensive. State it that way round.
;
; The ground the residual currently rests on is itself narrower than it reads:
; "`clang -O1` stamps `noundef` on real parameters" holds for 428/428 openlibm and
; 60/60 e2e stage-1 formal parameters, but NOT for a RECORD-TYPED parameter coerced
; to an integer — clang deliberately omits `noundef` there (the struct padding may
; be undef), and such a parameter was measured reaching an ACCEPTED shielded cone
; from ordinary C: `struct{int a,b;}` by value gives
; `define i32 @probe(i64 %0, i32 noundef %1)` whose shielded cone is
; `icmp` <- `trunc nuw` <- `lshr` <- the bare `%0`. No correctness consequence was
; exhibited for it — an `Argument` is ONE register at the ABI boundary, so it
; cannot produce the bd u1rp per-use divergence, which needs a literal `undef`
; Constant in two lowered gate slots — but the RULING's stated reason does not
; cover that shape. bd 615s carries all of these numbers.
;
; *** DO NOT LET control_predmux_reject_selectform_nofpclass_arg.ll BE QUOTED AS
; HAVING CLOSED THE ARGUMENT-LEAF CLASS. *** A fixture with that name will be read
; that way by the next reader unless a file says otherwise. This is that file.
;
; GREEN ON BOTH PLUGINS — it is a control, absent from the BASE-vs-SHIP
; differential by construction. Its power is arm-kill in the OTHER direction:
; widen the clause from "attributed Argument" to "any Argument" and THIS row goes
; red while both `_arg` decline rows stay green, which is exactly the signal a
; future widening should have to face.
;
; DERIVATION: control_predmux_reject_selectform_range_arg.ll with the `range(i32
; 0, 10)` attribute removed and nothing else changed. That pair is the whole
; measurement.
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
; RUN: %filecheck %s < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %cc = add i32 %c, 1
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

; The region IS claimed and flattened: the shielded select becomes a `cqrt_toffoli`
; conjunction over the two compare rails, `%cc` rides into the `_hl` literal slot,
; and the diamond is gone.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     %[[CC:[a-zA-Z0-9_.]+]] = add i32 %c, 1
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 %[[CC]])
; CHECK:     call void @cqrt_toffoli(
; CHECK-NOT: br i1
