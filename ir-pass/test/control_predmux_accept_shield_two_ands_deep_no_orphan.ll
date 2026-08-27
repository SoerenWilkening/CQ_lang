; control_predmux_accept_shield_two_ands_deep_no_orphan.ll — ACCEPT (bd kqqv),
; and THE FIXTURE THAT PINS THE CENTRAL DESIGN CLAIM. Like its siblings it is an
; ACCEPT whose real content is a NEGATIVE: the module must lower with the whole
; condition tree swept and NO dead 4.4 select merge left behind.
;
; *** READ THE NEXT PARAGRAPH BEFORE ADDING TO THIS FILE OR CITING IT: IT DOES
; NOT KILL THE MUTANTS IT WAS COMMISSIONED TO KILL, AND THAT IS A MEASURED
; FINDING ABOUT THE DESIGN CLAIM, NOT A DEFECT IN THE FIXTURE. ***
;
; It was commissioned by bd `drln` C1, which reported the central design claim
; UNPINNED: substituting the ticket's originally-proposed
; `if (isa<Instruction>(V)) track(V);` (mutant M1) for `trackCondCone(V)` — the
; exact thing ~25 capitalized lines in `canonicalizePred` argue against — leaves
; all committed fixtures byte-identical, as does moving the call to the three
; rebuild sites (M3). C1 prescribed THIS shape as the killer, on the stated
; ground that both mutants "restore the full 5-dangling-rail leak at shield
; depth >= 2".
;
; *** THAT PRESCRIPTION IS WRONG, MEASURED. *** Built M1 and diffed it against
; the shipped plugin over five hand-built probes (this shape; `and(a, xor(b,c))`;
; a root `xor`; a shield under an xor-TRUE NOT; a shield under `and` under
; `xor`): ALL FIVE BYTE-IDENTICAL, and this fixture PASSES against M1. The reason
; is structural, so no `and`/`or`/shield shape at any depth can ever discriminate:
; `canonicalizePred` RE-ENTERS ITSELF on both `and`/`or` operands and on a
; shield's condition and live arm, so a bare entry-`track` is applied to every
; node the walk would have reached. Instrumented on this exact module,
; `canonicalizePred` is entered on ALL SEVEN nodes — `%sc`, `%a`, `%mid`, `%d`,
; `%inner`, `%b`, `%c`. The recursion IS the walk here.
;
; The two functions can diverge at exactly ONE node type: `xor`, the only
; `BinaryOperator` `trackCondCone` descends and `canonicalizePred` does not
; re-enter. That is the same hole bd `drln` B1 already documents as a
; PRE-EXISTING leak (`xor(shield, true)` is admitted because
; `isSupportedCondTree`'s xor-true arm recurses NON-Strict), and no probe yet
; found makes it strand under M1 specifically, because the xor node keeps a use
; in every shape tried. So the honest status is: THE ENTRY-WALK-VS-BARE-TRACK
; CHOICE HAS NO KNOWN BEHAVIOURAL WITNESS. `trackCondCone` is kept because it is
; contract-complete and free, not because a test can tell it apart — and the
; comment in `canonicalizePred` says so. Filed rather than argued away.
;
; WHAT THIS FIXTURE THEREFORE DOES PIN, which is real and was absent: shield
; depth 2. Every other shield fixture in the tree sits at depth 0 or 1, and the
; pre-kqqv defect (no tracking at all in `canonicalizePred`) DOES leak here — so
; this is a genuine red-green witness for the shipped change, just not a
; discriminator between the shipped change and its near-neighbours.
;
; THE SHAPE — a shield TWO `and`s deep:
;     %inner = select i1 %b, i1 %c, i1 false   ; the shield
;     %mid   = and i1 %d, %inner               ; depth 1
;     %sc    = and i1 %a, %mid                 ; depth 2 — the branch condition
; Gate arm on the TRUE successor, the polarity that routes the true-edge literal
; through `canonicalizePred` (`clang -O1` picks it half the time — Rule 9).
;
; WHY `and` AND NOT ALSO `or`, RECORDED SO THE NEXT ROUND DOES NOT RE-OPEN IT:
; `canonicalizePred` handles both inside ONE `if (Opcode == And || Opcode == Or)`
; block with a single shared recursion, so the `or` spelling exercises the same
; two `canonicalizePred` calls on the same operands and cannot fail while this
; passes. A second fixture would add a spawn (the suite is spawn-bound, not
; work-bound) for zero additional discrimination. The depth table in
; `..._nonroot_shield_no_orphan.ll` records the `or` row as measured.
;
; BOTH SHIPPED GATES ARE BLIND TO THE DEFECT THIS CATCHES, which is the whole
; reason a fixture is owed: `opt` exits 0, the verifier is clean, and
; `free_pairing_check.py` reports "0 violation(s), 0 unproven" on the leaking
; module — it counts `cqrt_alloc_*` mints, and an orphan compare flag is
; TEMPLATE-minted (bd `1739`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll --check-prefix=SWEPT

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp slt i32 %q, 100
  %c = icmp ne i32 %q, 7
  %d = icmp sgt i32 %q, 1
  %inner = select i1 %b, i1 %c, i1 false     ; the shield
  %mid = and i1 %d, %inner                   ; depth 1
  %sc = and i1 %a, %mid                      ; depth 2 — the branch condition
  br i1 %sc, label %arm, label %merge        ; arm = TRUE successor

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

; The region IS claimed and DOES lower: the shield is rewritten to `and`, so the
; flag tree is a pure and-tree over the four original compare leaves, each minted,
; uncomputed and freed, and the two phis are merged by the i32 controlled-copy.
; Without these positives the CHECK-NOTs below would pass on a module that simply
; declined.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 100)
; CHECK:     call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 7)
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_toffoli
; CHECK:     call void @cqrt_copy_i32_controlled
; CHECK:     call void @cqrt_free

; THE TWO NEGATIVES. There is no i1-typed DATA in this function, so any
; `cqrt_copy_i1_controlled` is the stranded shield's dead merge; and the flag
; network is built from `cqrt_toffoli`/`cqrt_cnot` primitives, so a
; `cq_template_and_i1` is a stranded boolean node lowered as a DATA op. Both are
; what the PRE-kqqv code (no tracking in `canonicalizePred` at all) emits here.
; They do NOT fire against mutants M1/M3 — see the header; do not re-label these
; as mutant-killers without re-measuring.
; SWEPT-NOT: cqrt_copy_i1_controlled
; SWEPT-NOT: cq_template_and_i1
