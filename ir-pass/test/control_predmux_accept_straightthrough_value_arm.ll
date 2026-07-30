; control_predmux_accept_straightthrough_value_arm.ll — ACCEPT (bd 0rwu, W7).
; WAS control_swap_reject_straightthrough_value_arm.ll, a DECLINE fixture; this
; is the ONE disposition W7 moved in the whole 930-fixture suite, and the move
; was deliberate and adjudicated (not a regenerated baseline). Read the whole
; header before changing anything here.
;
; `if (q != 0) q = q + 1; measure(q);`. The else edge folds to `0` exactly like
; the accepted a8c0 phase case, but the arm changes q's VALUE (`add q, 1`), so
; `phi [q+1, 0]` is a genuine many-to-one value mux (q == 0 -> 0, q != 0 -> q+1),
; NOT a phase in place.
;
; WHAT IS UNCHANGED — the original safety property, which was the whole point of
; the old fixture and is still enforced: `straightThroughConstFoldHandle` still
; returns null here (the arm's phase-spine `Base` is the `add`, not the compare's
; handle `q`), so the a8c0 re-anchor STILL never turns a value collapse into a
; wrong phase arm (Rule 7). That property is asserted by the two
; `--implicit-check-not` flags on the RUN line — no `cqrt_rz` (never lowered as a
; phase) and no `cqrt_cswap` (never lowered by the in-place swap-route method).
; See the note above the CHECK block for why they are RUN-line flags and not
; leading `CHECK-NOT`s; written the latter way they asserted nothing at all.
;
; WHAT CHANGED — the region no longer DECLINES; W7 claims it for PredMux, and the
; flattened select lowers it as what it actually is, an out-of-place value mux.
; The old decline was a genuine OVER-decline. The §3c-style objection that
; motivated it ("q cannot be both kept and disentangled") is a SWAP-ROUTE METHOD
; hazard, not an information-theoretic one: it bites only when the routed
; register is rewritten IN PLACE and the flag must then be stripped by re-reading
; a basis that no longer exists. Read the emitted stream below — `%h` (the qubit)
; is never written. `q+1` lands in a FRESH rail, the mux lands in a FRESH `|0>`
; out rail, and the flag is stripped by `_unc` against the UNTOUCHED `%h`, so it
; is provably `|0>` at its `cqrt_free` (Rule 6). Information is conserved because
; the compiler keeps q AND produces qm — Bennett garbage, which is this project's
; standing posture for a dirty rail (left allocated, never freed dirty).
;
; PER-BASIS-STATE CHECK (the only correctness argument that counts here): for
; basis |q> the emitted stream computes `out = [q!=0] ? q+1 : 0`, matching the
; source on every state.
;
; Flag polarity: the minted flag is `icmp NE`, the complement of the source's
; `icmp eq`, because PredMux's no-NOT invariant materializes a negated edge
; predicate by rewriting the compare leaf into its inverse-predicate twin
; (`buildNegation` emits a FRESH compare, never negating in place). WHICH
; complement, and hence the copy order, is decided by the **phi incoming order**
; (`convertPhis` seeds from `In.back()`) — NOT by successor polarity, which an
; earlier draft of this header wrongly claimed. The Rule-13 round measured that
; directly: control_predmux_accept_int_diamond_constfall{,_phiorder}.ll are the
; same program with the same branch and only the phi order swapped, and they mint
; opposite predicates with opposite copy order.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s \
; RUN:  --implicit-check-not='br i1' --implicit-check-not='phi i32' \
; RUN:  --implicit-check-not='cqrt_rz' --implicit-check-not='cqrt_cswap'
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 0
  br i1 %c, label %merge, label %arm
arm:
  %q1 = add i32 %q, 1                     ; value-changing arm (not a phase)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ 0, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; THE SAFETY PROPERTY (unchanged from the DECLINE era): never a phase arm, never
; the in-place route. It rides `--implicit-check-not` on the RUN line above, NOT a
; pair of leading `CHECK-NOT`s, and that is a Rule-13 finding worth keeping in
; view: a `CHECK-NOT` placed BEFORE the first positive `CHECK` is scanned only
; over the window [start of input .. first CHECK match], i.e. the module header.
; Mutation-verified — with the negatives written that way, injecting BOTH
; `cqrt_rz_i32` and `cqrt_cswap` into the middle of the emitted body still
; PASSED. `--implicit-check-not` scans the whole output, so the same mutant now
; fails. (The pre-W7 decline version of this fixture had the same two lines under
; `not %cq-opt ... | %filecheck`, where `opt` writes zero bytes of module on a
; DS_Error — so they asserted nothing then either. Same trap the suite records at
; control_predmux_reject_i80_cmp_qq.ll:90-96.)

; The out-of-place value mux. `%h` is READ by the add, by the flag mint and by
; the flag strip, and WRITTEN by none of them. EVERY copy SOURCE is pinned to a
; named capture — no `%{{...}}` wildcard on a source operand. That is also a
; Rule-13 finding: with the second copy's source wildcarded, a mutant sourcing
; `%h` (the LIVE QUBIT) instead of `%selop` (the constant rail) PASSED, i.e. the
; fixture admitted `out = [q!=0] ? q+1 : q` while its header advertised
; `out = [q!=0] ? q+1 : 0` as "the only correctness argument that counts here".
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[SUM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 0)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[SUM]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %[[K]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[FLAG]], i32 %[[H]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
