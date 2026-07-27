; lowering_uncompute_and_qq_i32.ll — witness restoration for the Q+Q (BOTH
; operands tainted handles) bitwise AND reaching the whole-DAG uncompute spine
; (bd `gowy`).
;
; PROVENANCE, stated precisely because a fixture header is institutional memory
; (Rule 0). Commit dbab515 ("tkju") DELETED NOTHING: `git show --name-status
; dbab515` is 1 A + 75 M with ZERO D, and `tests/e2e` holds the same 249 `.c`
; slices before and after it. What it did was DE-VENDOR 52 slices IN PLACE — it
; stripped the fictional SOFTWARE bodies those `.c` files had vendored for
; Rule-18 HARDWARE keeps — and REGENERATED their goldens (21 of the 52
; `.expected.log` files changed bytes; the other 31 came back byte-identical).
; The slices themselves live on; what disappeared are the `cq_template_*` TRACE
; LINES the regenerated goldens no longer contain. 20 generated symbols lost
; their only witness that way. `cq_template_and_i32_unc` is one of them: after
; tkju it existed in runtime/cq_templates.c with no golden and no fixture
; exercising it (grep across the tree still finds it only in
; runtime/cq_templates.{h,c} and here). It is an ADJOINT TWIN, i.e. the
; uncompute spine, which is precisely where this project's verify-clean silent
; miscompiles live (Rule 13).
;
; WHAT THIS DOES AND DOES NOT RESTORE — a PARTIAL replacement, not like-for-like.
; A lit fixture pins the EMITTED IR: the symbol, its slot order, and its place in
; the reversal schedule. It CANNOT witness that `cq_template_and_i32_unc`
; RESOLVES at link time or that its runtime C signature matches the emitted
; `declare` — per Rule 2 the e2e golden diff is the only layer that links.
; (Checked by hand today: runtime/cq_templates.c's `void
; cq_template_and_i32_unc(int32_t, int32_t, int32_t)` does match `declare void
; @cq_template_and_i32_unc(i32, i32, i32)`, so there is no latent mismatch — but
; this fixture is not the thing that would catch a future one. Do not read the
; symbol as link-covered.) No new accept-predicate is introduced here, so per
; Rule 12 a POSITIVE fixture alone is the obligation — there is no decline shape
; to mirror.
;
; `q1 = cq_theta(x); q2 = cq_theta(y); d = q1 & q2` — a DEAD Q+Q terminal. The
; forward `and` is the one place the embedding matters: AND is NOT injective as a
; function (|1,0>, |0,1> and |0,0> all map to 0, so it has no inverse and cannot
; be a unitary on two wires). What CQ emits is the EMBEDDED reversible form on
; three registers, |a,b,c> -> |a,b, c XOR (a AND b)> — a Toffoli-class
; PERMUTATION of the computational basis, and one that is its own inverse
; (XOR-ing the same value twice is the identity). The adjoint therefore re-applies
; the SAME MAP — but through a textually DISTINCT SYMBOL (the void, out-first
; `_unc` pinned below), not by re-calling the forward `cq_template_and_i32`, and
; not via some separate "un-AND" primitive. `and_i32_unc(out, a, b)` recomputes
; `a AND b` and XORs it back into the `out` rail, driving that rail to |0>. Being
; a permutation and not a rotation it writes no phase, so this reversal cannot
; dephase `q1`/`q2`.
;
; Three DD-3 / Phase-5 facts are pinned, and each is a verify-clean WRONG UNITARY
; if it drifts:
;   * SLOT ORDER: the void `_unc` emitter prepends the forward RESULT as
;     argument 0 and then copies the forward operands in their ORIGINAL order
;     (EmitInverse.cpp), so `and_i32(a, b)` must adjoint to
;     `and_i32_unc(out, a, b)`. `and` is commutative, so a swapped `(out, b, a)`
;     would still compute the right value and still pass `opt -verify` — the
;     slot discipline is pinned here on principle, by handle IDENTITY, because
;     the SAME shape-agnostic emitter serves the non-commutative ops where a
;     swap IS a wrong answer.
;   * SOURCE LIVENESS: the adjoint READS `a` and `b`, so it is only correct if
;     both roots are still live at that point. Whole-DAG LIFO reversal is what
;     guarantees that — the leaf (`%d`, the AND) is reversed FIRST, while its
;     roots are untouched, and only afterwards are the roots themselves undone.
;     A non-LIFO order would have the AND adjoint read an already-freed rail.
;   * FREE LICENCE (Rule 6): `cqrt_free` is a hardware reset = projective
;     measurement, legal only on a rail whose state is PROVEN. The two licences
;     in play here are different, and the difference is real:
;       - the DERIVED `out` rail genuinely reaches |0>, and it earns that proof
;         from the XOR-back IMMEDIATELY preceding it;
;       - the two ROOT rails are NOT freed at |0>. `cqrt_alloc_i32(%x)`
;         initialises a root to the alloc-time CLASSICAL BASIS STATE |x>, and
;         `Ry(-theta)` restores THAT state — not |0>. What licenses their free is
;         that each is provably DISENTANGLED and in a known classical state.
;     Both proofs are only good IMMEDIATELY after the instruction that
;     establishes them, which is why every free below is CHECK-NEXT-pinned rather
;     than pinned by a plain CHECK — a single stray in-place gate slipped between
;     an un-compute/un-rotation and its free re-dirties that rail and turns the
;     free into a hidden measurement that collapses `q1`/`q2` (empirically a
;     passing mutant under a plain CHECK directive; nothing else covers it at the
;     lit layer — tools/free_pairing_check.py is an e2e stage-2b gate and never
;     runs on lit fixtures).
; The two roots carry distinct angles (0.25 and 0.5) so the two rails stay
; textually distinguishable, and they are reversed in REVERSE allocation order —
; q2 before q1 — the same LIFO discipline one level out; that order is pinned too.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
;
; The CHECK-LABEL + unbroken CHECK-NEXT chain below seals the WHOLE function body,
; from `entry:` to the last free, against any inserted instruction — including the
; region before the first gate, where a prepended stray gate otherwise slips in
; unnoticed.
;
; Forward: theta -> alloc + ry, twice, then the Q+Q AND (both slots are i32
; HANDLES — no `_hl`/`_lh` literal slot, and no operand promoted to a rail).
; CHECK-LABEL: define void @slice(i32 %x, i32 %y) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[HA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HA]], double 2.500000e-01)
; CHECK-NEXT: %[[HB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HB]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32(i32 %[[HA]], i32 %[[HB]])
; Reversed adjoint (LIFO, leaf-first): the AND rail is XOR-ed back to |0> from
; the STILL-LIVE roots %[[HA]]/%[[HB]] in DD-3 slots (out, then the forward
; operands in original order), then that now-proven-|0> rail is freed; only then
; do the roots un-rotate to their alloc-time basis states and free, in reverse
; allocation order. Every free is CHECK-NEXT-adjacent to the instruction that
; proves its rail.
; CHECK-NEXT: call void @cq_template_and_i32_unc(i32 %[[D]], i32 %[[HA]], i32 %[[HB]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HB]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HB]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HA]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HA]])
;
; The adjoint is the VOID `_unc`, never the fresh-minting `_inv` twin (an `_inv`
; here would allocate a NEW result rail and leave the old one dirty and
; entangled — a leak the subsequent free would then turn into a hidden
; measurement); and the theta intrinsic is fully lowered.
; CHECK-NOT: cq_template_and_i32_inv
; CHECK-NOT: cq_template_and_i32_hl
; CHECK-NOT: cq_theta_
;
; MULTIPLICITY (precedent: lowering_uncompute_qq_both_parents.ll). The chain above
; pins the ORDER of the reversal but not its CARDINALITY: an extra `_unc` appended
; past the end of the chain is a double-uncompute / use-after-free (Rule 8) and an
; extra `cqrt_free` is a double-free of an already-reset rail (Rule 6), and both
; were empirically passing mutants before this prefix existed. Exactly ONE `_unc`
; (the single AND gate, adjointed once) and THREE frees (the AND rail + both
; roots). NOTE the deliberate ordering: BOTH `CNT-NOT`s sit after the LAST
; positive directive so each scopes [last match -> EOF] and catches an APPENDED
; duplicate; the mid-chain region is already sealed by the CHECK-NEXT chain above.
; CNT-COUNT-1: _unc(i32 %
; CNT-COUNT-3: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
; CNT-NOT:     _unc(i32 %
;
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %y) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %d  = and i32 %q1, %q2                       ; Q+Q bitwise AND, dead terminal
  ret void
}
