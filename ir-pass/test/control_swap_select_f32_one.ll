; control_swap_select_f32_one.ll — ACCEPT: the Phase-4.4 fp-DATA `select` (kjd1,
; un-staged 2026-07-02) at f32 under an ORDERED-NOT-EQUAL (`fcmp one`) condition.
; Direct sibling of control_swap_select_f32.ll — same width, same six-step
; controlled-XOR copy merge, same classical false operand; the ONLY delta is the
; compare predicate (`one` here, `ogt` there), and therefore the template pair the
; merge is built out of.
;
; WHY THIS FIXTURE EXISTS (bd `gowy`). Commit dbab515 ("tkju") DE-VENDORED, IN PLACE,
; the 52 e2e slices that had vendored fictional SOFTWARE bodies for Rule-18 HARDWARE
; keeps, and REGENERATED their goldens. It DELETED NO FILES — verify before repeating
; the claim: `git show --name-status --format='' dbab515 | awk 'NF{print $1}' | sort |
; uniq -c` is 1 `A` + 75 `M` and ZERO `D`, and `tests/e2e/*.c` is 249 slices both at
; dbab515^ and at dbab515. Every slice named below is still in the tree today.
;
; What vanished was not files but TRACE LINES. The vendored software ladders were the
; only code path that ever emitted a family of generated runtime symbols, so once the
; ladders were removed the regenerated `.expected.log`s stopped printing them — which
; silently stranded 20 `cq_template_*` symbols in runtime/cq_templates.c with NO
; witness anywhere: not an e2e golden, not a lit fixture. 14 of the 20 are ADJOINT
; twins, i.e. the uncompute/strip half, which is exactly where this project's
; verify-clean silent miscompiles live. (A future archaeologist should read golden
; DIFFS, not look for deleted slices — there are none.)
;
; This file's symbol, concretely. The FORWARD half of the pair kept a witness
; (lowering_fcmp_one_hl_f32.ll:18 pins `cq_template_fcmp_one_f32_hl`). The ADJOINT TWIN
; `cq_template_fcmp_one_f32_hl_inv` was witnessed at dbab515^ by exactly two goldens,
; tests/e2e/slice_libm_real_{lroundf,llroundf}.expected.log, carrying 10 `_inv` lines
; each. dbab515 regenerated both from 625 lines down to 5; both files (and their `.c`)
; still exist and still run as ctest entries #101 / #106, but they now carry 0 such
; lines — the witness left with the ladder, not with the file. That
; twin is what this fixture restores: the `_inv` CHECK below is the load-bearing line of
; this file, and every other CHECK exists to give it the context that makes it mean
; something. Note which adjoint ABI this is: the select merge strips its flag with the
; FRESH-MINTING `_inv` (the compare is live-and-consumed here, not a dead DAG terminal),
; NOT the void whole-DAG `_unc` of the Phase-5 spine — so, unlike
; lowering_uncompute_lh_slot.ll, there is deliberately no CHECK-NOT against `_inv`
; here. `_unc` is simply not this path's ABI.
;
; WHAT IS PINNED, AND WHY EACH LINE IS PHYSICS AND NOT DECORATION
;
; (1) Flag mint. `cq_template_fcmp_one_f32_hl(%h, 1.0)` — the HL shape: the tainted
;     handle stays at slot 0, the classical literal at slot 1, and the literal is
;     passed THROUGH at its real f32 width, never `cqrt_alloc`'d into a qubit
;     (quantum-classical-handling §5.2). `one` is ORDERED-and-not-equal, so its
;     NaN behaviour differs from `une`; the predicate is part of the permutation the
;     template embeds, which is why it must appear verbatim in BOTH the forward call
;     and its adjoint. A predicate that drifted between the two would be a
;     verify-clean wrong unitary that no golden byte-diff could see.
;
; (2) Destination rail. `%out = cqrt_alloc_f32(0.0)` is a FRESH |0> register, not a
;     rewrite of either select operand. Be exact about WHY it is |0>, because the SAME
;     call appears THREE times here in three different states: `cqrt_alloc_<W>(v)` seeds
;     the rail with its ALLOC-TIME CLASSICAL BASIS STATE |v>, so `%out` is |0> only
;     because `v` is literally `0.0`; the theta ROOT `%h = cqrt_alloc_f32(float %u0)`
;     starts at |u0> and is then Ry-rotated off even that, so it is NEVER |0>; and the
;     materialized false operand `cqrt_alloc_f32(float %x)` sits at |x>. Do not read
;     "alloc" as "|0>"; read it as "known classical basis state, whatever `v` was".
;     Ry(-theta) would restore a root to ITS |v>, not to |0>. The merge is additive copy-out
;     with the sources kept live — Rule 8: copy+uncompute cannot disentangle a source,
;     so the sources are never freed by this path.
;
; (3) Two controlled copies, opposite polarity. `cqrt_copy_f32_controlled(flag, src,
;     out)` fires once for the TRUE operand (`%h`, the theta rail) and once for the
;     FALSE operand, the latter inside a self-inverse `cqrt_x` bracket that presents
;     ¬flag. The classical false operand `%x` is materialized at its real f32 width
;     (`cqrt_alloc_f32(float %x)`), again never coerced to an i32 handle.
;
; (4) The copy family is the kjd1 frozen-designate `cqrt_copy_f32_controlled`, minted
;     ONLY by the select-local `copyControlledFpFn`. Crossing the fp and integer copy
;     wires is a live hazard in this codebase (the f64-as-data/f64-as-angle miscompile
;     family), so `CHECK-NOT: cqrt_copy_i` guards the tail — a stray integer copy would
;     surface as a `declare void @cqrt_copy_i32_controlled` in the emitted declare block.
;
; (5) Adjoint slot order. `cq_template_fcmp_one_f32_hl_inv(%h, 1.0)` carries the forward
;     operands in their ORIGINAL order — handle at slot 0, literal at slot 1 — the same
;     DD-3 slot discipline the void `_unc` emitter follows, minus the prepended `out`
;     (this `_inv` returns a fresh trace handle instead of writing an existing rail, so
;     there is no `out` slot to prepend). A swapped slot here is a silent miscompile.
;
; (6) Ordering, and the still-live source. The strip fires AFTER both copies and AFTER
;     the second `cqrt_x` has closed the bracket and restored the flag to true polarity
;     — recomputing against a still-inverted flag would XOR the wrong value and leave
;     the rail dirty. It also fires while `%h` is STILL LIVE, because the strip is a
;     recompute-and-XOR (|a,c> -> |a, c ^ (a one 1.0)>) that needs the exact register the
;     flag was computed from. `%h` and the materialized `%x` rail are both correctly
;     left ALLOCATED at function end — but for DIFFERENT reasons, and only one of them
;     is a hard obligation. `%h` carries the Ry superposition and was CNOT-fanned into
;     `%out` under a flag itself derived from `%h`, so at function end it is genuinely
;     ENTANGLED with a register that is then measured: not disentangled, not in any
;     known classical state, and `cqrt_free` — a hardware reset = projective
;     measurement (Rule 6) — would collapse `q`. That free is fatal. The `%x` rail is
;     the softer case: it is a classical basis state |x> used only as a copy SOURCE, so
;     the controlled copy leaves it factorized at |x> and a free would arguably be
;     provable under the "known classical basis state" clause. The pass leaves it
;     allocated anyway. That is the Prime Directive in its cheap direction — an
;     unnecessary leak in the qubits-not-scarce regime costs nothing, an unproven free
;     costs the whole computation — and the CHECK-NOT below pins the conservative
;     choice rather than inviting a later "optimization" to reason it away.
;
; (7) Proven-|0> free — and unlike the rails in (6) this one genuinely REACHES |0>.
;     That distinction is the whole Rule-6 argument, so state it precisely. The flag is
;     a MINTED DERIVED rail: `cq_template_fcmp_one_f32_hl` allocates it fresh at |0> and
;     XORs the predicate in; the `_inv` recomputes the same predicate from the
;     still-live `%h` and XORs again, so the write history cancels to the identity and
;     the rail is back at |0> — a restoration proof, not the "known classical basis
;     state" proof that covers an alloc'd root. Only then is `cqrt_free` legal, and it
;     must name the FLAG rail — the very SSA value both controlled copies used as their
;     control — not the `_inv`'s fresh return handle. Note the ABI hazard that makes
;     this worth pinning: the `_inv` signature does NOT name the rail it restores (it
;     returns a fresh handle), which is exactly the blind spot tools/free_pairing_check.py
;     was written to cover — and that gate is an e2e stage-2b gate that NEVER runs on a
;     lit fixture. So the capture variables below are the only thing pinning this
;     pairing at this layer. A fixture that merely grepped the symbol names would stay
;     green if the adjoint read the wrong rail or the free landed on the wrong register,
;     which is precisely the bug class tkju left unwitnessed.
;
; WHAT THE DIRECTIVES THEMSELVES BUY (measured by mutation, not assumed)
;
; The unbroken CHECK-NEXT run pins ADJACENCY, not merely order — and adjacency is the
; load-bearing half. Plain ordered CHECKs would admit a gate spliced between the strip
; and the free: `cqrt_x(%h_cmp)` re-dirtying the flag after the `_inv` zeroed it turns
; the `cqrt_free` into a hidden measurement (Rule 6). That mutant is REJECTED here, and
; only because no line is left unaccounted for between the two.
;
; The trailing `CHECK-NOT: call void @cqrt_free(` is the other half of the same claim.
; With the NEXT-chain locking every line from the first alloc through the measure, it
; makes ONE free — the flag rail's — the entire free set of this function, which is
; what (6) asserts and nothing else pinned. Measured: appending `cqrt_free(i32 %h)`
; after the measure (a dirty free of the entangled theta root) PASSED without it and
; FAILS with it. It is spelled `call void @` on purpose — a bare `cqrt_free` pattern
; would be satisfied by the `declare void @cqrt_free(i32)` line, which also falls in
; the guarded [last match -> EOF] tail region.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)

define float @example(float %u0, float %x) {
entry:
  %q   = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %c   = fcmp one float %q, 1.000000e+00     ; ordered-and-not-equal -> flag rail
  %sel = select i1 %c, float %q, float %x    ; fp-DATA select, tainted condition
  %m   = call float @cq_measure_f32(float %sel)
  ret float %m
}

; theta -> qubit rail + Ry.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float %u0)
; CHECK-NEXT: call void @cqrt_ry_f32(i32 %[[H]], double 5.000000e-01)
; Flag mint: HL slots (handle, literal), predicate `one` verbatim.
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_one_f32_hl(i32 %[[H]], float 1.000000e+00)
; Fresh |0> destination, then the true operand under flag.
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f32_controlled(i32 %[[F]], i32 %[[H]], i32 %[[OUT]])
; ¬flag bracket opens; classical false operand materialized at real f32 width.
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f32(float %x)
; CHECK-NEXT: call void @cqrt_copy_f32_controlled(i32 %[[F]], i32 %[[XH]], i32 %[[OUT]])
; Bracket closes — flag back to true polarity BEFORE the strip.
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; THE RESTORED WITNESS: the adjoint twin, same DD-3 slot order as the forward call,
; reading the STILL-LIVE root %[[H]] and the same literal.
; CHECK-NEXT: call void @cq_template_fcmp_one_f32_hl_unc(i32 %[[F]], i32 %[[H]], float 1.000000e+00)
; Flag rail is now provably |0> — free THAT rail, the copies' control.
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call float @cqrt_measure_f32(i32 %[[OUT]])
;
; Rule 6, the leak half: the flag rail's free above is the ONLY free in this function.
; The NEXT-chain accounts for every line up to here, so this guard closes the tail. It
; catches all three ways to get this wrong: a free of the ENTANGLED theta root %[[H]]
; (fatal — a hidden measurement collapsing q), a free of the MEASURED %[[OUT]] (the
; measurement owns that handle), and a free of the %[[XH]] source (sound in principle,
; but pinning the conservative leak per (6)).
; CHECK-NOT: call void @cqrt_free(
; fp and integer copy wires must not cross; the intrinsics must be gone.
; CHECK-NOT: cqrt_copy_i
; CHECK-NOT: cq_theta_
