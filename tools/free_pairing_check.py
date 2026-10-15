#!/usr/bin/env python3
"""free_pairing_check.py — structural Rule-6 free-pairing checker over LOWERED IR.

WHY THIS EXISTS (bd test_C_libtooling-8txa, the CHEAP half)
==========================================================
Rule 6 says a `cqrt_free(%r)` is sound only on a **provably-|0> rail**. The
project's Rule-2 gate is the e2e golden byte-diff — the only layer that links
and runs — but that layer **cannot witness this property**, because a generated
adjoint template prints

    cq_template_<op>_<W>_hl_inv(<forward args>) -> h<fresh>

and **never names the rail it is supposed to restore**. When bd `oudq` moved
atanhl's `cqrt_free` count 300 -> 217, the golden alone could not distinguish
"shared predicate, fewer rails" from "dropped uncompute" — closing that took two
throwaway out-of-band tools. This file promotes the structural one to a committed
gate at the IR layer, where the rail identity IS present (`%r` is an SSA name)
even though the trace has lost it.

WHAT bd `8txa` CHANGED, AND WHAT IT DID NOT
-------------------------------------------
The COMPARE FLAG-STRIP no longer has this defect. It used to be the flag-shaped
instance of it — this docstring's own motivating example was four textually
IDENTICAL `cq_template_fcmp_olt_f80_hl_inv(h67, …)` lines in
`slice_libm_real_log1pl.expected.log` that paired with four DIFFERENT
`cqrt_free`s. 8txa switched that strip to the void, out-first `_unc` ABI, so the
same four lines now read

    cq_template_fcmp_olt_f80_hl_unc(h78,  h60, 0xb.504f333f9de6484p-4)
    cq_template_fcmp_olt_f80_hl_unc(h80,  h60, 0xb.504f333f9de6484p-4)
    cq_template_fcmp_olt_f80_hl_unc(h106, h60, 0xb.504f333f9de6484p-4)
    cq_template_fcmp_olt_f80_hl_unc(h110, h60, 0xb.504f333f9de6484p-4)

— each naming the rail it zeroes, and the golden byte-diff DOES now witness that
pairing for compare flags.

This checker is NOT thereby redundant. It still owns every rail the trace label
cannot speak for: the whole-DAG uncompute spine's data `_unc` chains, the loop
reverse-play write history, and the "was this rail actually |0> at the free"
question, which no label can answer at any ABI. Read `classify()` and the
obligation below for exactly what it does and does not witness.

THE OBLIGATION IT WITNESSES
===========================
For every `cqrt_free(%r)`: **at the free, %r holds a KNOWN CLASSICAL BASIS
STATE and is unentangled** — the property that makes the free (a hardware reset
= projective measurement, Rule 6) collapse nothing. It establishes that by one
of two structural proofs, one per rail class.

MINTED rails — `%r = M(a...)` for a `cq_template_*`, a `cqrt_qram_load_<W>`, a
`cqrt_tape_write_<W>`, or a Phase-6 clone `@__cq_q_*`. The mint creates a fresh
|0> rail and writes `f(a...)` into it, so the free is sound iff that write was
undone:

  (T1) a REVERSAL exists and is claimed ONE-TO-ONE: either the void
       `M_unc(%r, a...)` (which names the rail — no inference needed) or an
       `M_inv(a...)` whose ARGUMENT LIST matches the forward's operand for
       operand. Every `_inv` token is consumed by at most one free, so N frees
       of same-shaped rails need N reversals. A deleted uncompute, or a
       reversal whose operands do not match the forward's, fails here.
  (T2) the forward's own handle operands are UNCHANGED between the forward and
       the reversal — either never written, or written only in a self-cancelling
       way (below). An `_inv` recomputes `f` from the live sources; if a source
       moved in between, it recomputes a DIFFERENT value and leaves the rail
       dirty. A self-cancelling pair of SUPERPOSING writes (`Ry(-t) … Ry(t)`)
       counts only if its LIGHT CONE closes (L): nothing between the two may
       keep a copy of the rotated-basis state — no tape record, measurement,
       unreversed template rail or unrestored CNOT target (bd r2j3.3; see
       `StreamAnalysis.light_cone_closed`) — and nothing between them may
       leave a PHASE on it: a diagonal gate with an operand in the cone must
       be cancelled by its adjoint inside the window (bd r2j3.4,
       `StreamAnalysis._phase_closed`). Rule (L) lives in the reduction,
       so it binds (A2) and (T3) exactly as it binds (T2).
  (T3) the rail itself is unchanged between mint and reversal (the `¬flag`
       `cqrt_x` bracket is such a self-cancelling pair) and is NOT written at
       all between the reversal and the free.
  (T4) THE LOOP-EXIT DISCHARGE, and it is the one rule here that reads outside
       its own STREAM. T1-T3 need the mint and the reversal in one straight-line
       run; Group 1's P2 anchor (2026-09-18) mints a rail OUTSIDE a loop, reads
       it per trip, and reverses and frees it at the loop EXIT — a different
       stream, so the free arrived at `U3-extern-rail` on a rail that is
       provably |0>. (T4) proves it instead, from facts that need no execution
       order across the loop: a unique template mint, the `_unc` in the free's
       own stream, EXACTLY ONE write to the rail in the WHOLE function (so every
       in-loop use is a read), exactly one free, no cycle through the mint's or
       the free's stream, and every forward operand written only before the mint
       or after the reversal. See `StreamAnalysis.loop_exit_discharge`.

ALLOCATED rails — `%r = cqrt_alloc_<W>(v)`: the conjunction ancillas
(`cqrt_alloc_i1` + the toffoli/cnot flag network), the swap-route work rails,
and the `cq_theta` source rails. `v` is a CLASSICAL value, so the rail starts in
a known basis state and the free is sound iff it is still in one:

  (A1) every basis-changing write is a classical-immediate in-place update
       (`cqrt_addc_<W>` / `cqrt_xorc_<W>`, whose second operand is by ABI a
       classical literal) AND that operand is one this file can SHOW is not a
       rail. A known classical state plus a classical offset is still a known
       classical state — no superposition, no entanglement. This is the dtzb
       `break` index rail (`alloc(k)`, `addc(-k)`, free).
       The second half is not pedantry (bd az1h): the ABI's declaration that
       the slot is classical is an ASSERTION, and until 2026-07-31 this rule
       converted it straight into a Rule-6 clearance without ever looking. A
       planted `cqrt_xorc_i32(%r, %h)` entangles `%r` with the rail `%h`, and
       the next line's `cqrt_free(%r)` is then the hidden measurement Rules 6/8
       forbid — yet it reported `OK … via A1-classical-immediate`, exit 0. At
       W=i32 BOTH parameters are `int32_t`, so the verifier cannot see it, and
       `cq_runtime.c` prints the immediate slot as a bare decimal, so rail h13
       renders as `13` and the GOLDEN TRACE CANNOT SEE IT EITHER. Both gates
       blind on the same axis is precisely the complementarity bd 8txa claims,
       so the assertion is now CHECKED (`provably_not_a_rail`); an immediate
       that cannot be shown classical falls through to (A2), which still
       discharges a genuine `xorc(%r,%h) … xorc(%r,%h)` bracket, and otherwise
       reports `A1-imm-not-classical`.
  (A2) otherwise the write history REDUCES TO IDENTITY, returning the rail to
       its alloc-time classical `v`. Reduction repeatedly cancels a write
       against an earlier ADJOINT write when every write between them commutes
       with it (see COMMUTATION). `x`/`cnot`/`toffoli`/`cswap`/`xorc`/`copy`
       are self-adjoint; `ry`/`rz` pair with the negated angle; `addc` with the
       negated immediate; a qram store with its `_unc` twin. The plain
       even-length adjoint palindrome the ticket asks for is the common case of
       this reduction; a deleted uncompute toffoli leaves an odd, unpairable
       history and fails here.
       Those stability questions recurse (proving an operand held still means
       reducing ITS write history, whose pairs have operands of their own), and
       the recursion has NO STEP BUDGET: it terminates because every recursive
       edge strictly narrows the position interval. There used to be a
       `depth > 6` cut-off and it was a defect, not a safety net — see
       `unchanged_over` for the argument and for what the budget did to the
       memo (bd xzdx).
       A pair cancels only if everything ITS action depends on held still in
       between: the declared reads, the `classical_imm` slots (bd az1h), and —
       for the one symbol in the model that writes two rails — the CO-WRITTEN
       slot (bd 0gwl). `cqrt_cswap` is modelled `reads=(0,) writes=(1,2)`
       though a Fredkin physically reads all three, so until 2026-08-07 a
       route-pair cancelled with only the FLAG ever checked:
       `cswap(%f,%q,%rail); ry(%q,0.75); cswap(%f,%q,%rail); free(%rail)`
       reported `A2-reduces-to-identity`, exit 0, while the route-back parked
       `Ry(0.75)|0>` on the rail it then freed. See
       `pair_operands_unchanged` / `co_written_stable`.

Plus two whole-stream invariants:

  (W)  every `_inv` is claimed by EXACTLY ONE free. An `_inv` is the only
       construct in the lowered IR that writes a rail its signature does not
       name, so an unclaimed one is an adjoint whose target cannot be
       identified — the "re-paired to the wrong rail" defect in its purest
       form. The "exact bijection: 25174 `_inv` tokens, 25174 claims, 0
       orphans" this paragraph used to quote was measured BEFORE bd 8txa moved
       the compare flag-strip onto the void `_unc` ABI. RE-MEASURED 2026-07-31
       over the 237 registered slices: the ship floor now emits **ZERO** `_inv`
       calls. So (W) and the (T1b) `_inv` matching arm have NO corpus coverage
       left at all — their only live exercise is the POSITIVE fixtures in
       tools/free_pairing_check_test.py, which are therefore HISTORICAL rather
       than current lowerings and must not be "refreshed" from today's output
       without replacing that coverage. Do not quote the old bijection as
       evidence the rule is exercised; it is evidence about a corpus that no
       longer exists.
  (F)  the lifetime hygiene that has no other gate anywhere in the project:
       double free, use after free, freeing a measured handle, and freeing a
       non-rail resource token (a `cqrt_qram_alloc_*` array or a
       `cqrt_tape_alloc` tape).

THE SECOND OBLIGATION: THE CASE-A / CASE-B PARTITION  (bd 6f3o)
===============================================================
Independent of any free site, EVERY emitted gate must satisfy:

    *** NO INPUT OPERAND MAY ALIAS A RAIL THE GATE WRITES. ***

  CASE A — aliased INPUTS, output a FRESH |0> rail. REALIZABLE, ALLOWED, and
    deliberately NOT flagged. The generated ABI's out-of-place shape is
    `out(fresh |0>) ^= f(in0, in1)`, so aliasing the inputs gives `out ^= g(a)`
    with `g(a) := f(a, a)`, and `(a, 0) -> (a, g(a))` is the standard
    reversible embedding of a classical function — unitary and self-inverse for
    ANY `g`. Realizability is UNCONDITIONAL; aliasing changes only COST, and
    the argument needs no per-op identity (which is exactly why it is the one
    to use — do NOT justify Case A by enumerating degeneracies; `fsub(a,a)==0`
    and `fdiv(a,a)==1` are both WRONG under IEEE-754 and both ship in
    `slice_libm_real_acos`). MEASURED over this corpus: 638 Case-A calls across
    27 template symbols, plus 15 `_unc` twins of the same shape. A rule that
    flags those is a WRONG RULE, not a discovery.
  CASE B — an input aliases a rail the gate WRITES. NOT realizable:
    `cswap(c,c,b)` maps both |1,0> and |0,1> to |0,1>, which is not injective,
    so no unitary implements it. Reported `B1-input-aliases-written-rail`.
    `B2-two-written-rails-alias` covers the adjacent spelling — a symbol whose
    TWO write slots are the same rail — and its ground is DIFFERENT, so do not
    quote B1's non-unitarity argument for it: `cswap(f,x,x)` is the IDENTITY,
    hence perfectly unitary. It is flagged as DEGENERATE (no router can have
    meant to swap a register with itself), which is a decline of intent rather
    than of physics, and is what the bd 6f3o write-set table specifies.

The write-sets are `classify()`'s, not a second table: `cnot(c,t)` writes t,
`toffoli(c1,c2,t)` writes t (c1==c2 is Case A), `cswap(f,x,y)` writes BOTH x
and y, `copy_W(s,d)` writes d, `copy_W_controlled(f,s,d)` writes d, a
`cq_template_OP_W(ins)` writes NO operand, `cq_template_OP_W_unc(out, ins...)`
writes out. A `classical_imm` slot counts as an input, so `xorc(%r,%r)` is
Case B like any other; a slot that is both read and written at the SAME index
is an in-place update, not aliasing (`cqrt_measure_<W>(%h)`), and is skipped.

A 14-agent audit (bd big5, 2026-07-31) swept every rail-writing mint in the
pass and found ZERO Case B emitted; this rule is what keeps that true. It is a
STATIC check over SSA-value identity and deliberately does not depend on the
runtime's monotonic never-recycling handle counter — that counter is a property
of the TRACE-ONLY STUB, not of the ABI contract a Phase-9 backend must honour.

TWO MODELLING DECISIONS THAT ARE PHYSICS, NOT CONVENIENCE
=========================================================
* `cqrt_rz_<W>` IS TRANSPARENT. Rz = diag(1, e^{i.theta}) is DIAGONAL in the
  computational basis: it changes no basis label, so it can neither dirty a
  |0> rail nor invalidate a recorded value. This is exactly Rule 6's phase-arm
  clause ("the rail is |0> for free, Rz|0> = |0>") and the same
  diagonal/non-diagonal split the pass's own `declineStaleRecordOps` /
  `WireWalk` guard uses. It is what lets the canonical swap-routed phase arm
  (`cswap; rz; rz; cswap; free`) verify. `cqrt_ry_<W>` is NOT diagonal and
  stays a full write — dropping an `ry` adjoint before a free IS caught.
  THE SPLIT CARRIES OVER TO THE CONTROLLED TWINS UNCHANGED (bd
  test_C_libtooling-drbq): `cqrt_rz_<W>_controlled` is diagonal on BOTH branches
  of its flag (`f=0` is the identity, `f=1` is `diag(1, e^{i.theta})`), so it is
  transparent for the same reason; `cqrt_ry_<W>_controlled` is not, and the
  branch it does nothing on buys it nothing — the state is a superposition over
  both, so the target rail is dirty and entangled with the flag. Only the write
  SLOT moves (arg 1, the control taking arg 0).
  ⚠ TRANSPARENT MEANS "ABSENT FROM THE BASIS LEDGER", NOT "IRRELEVANT" (bd
  test_C_libtooling-r2j3.4). The argument above holds where the rails a phase
  touches are in a computational-basis state on every branch — which is every
  PERMUTATION reduction, because a permutation maps each branch to one branch
  and the phase only rides along. It is FALSE between the two halves of a
  SUPERPOSING pair: `Ry(-t)·Rz(φ)·Ry(t)` is not the identity (t = π/2 gives an
  X up to phase). So diagonal calls stay out of every write history (the phase
  arms need that), and rule (L) asks the phase question separately, over the
  WHOLE restore window: every diagonal call with an operand in the window's
  light cone — write slot OR control slot — must cancel against its adjoint
  inside the window with its operands held still (`_phase_closed`).
* COMMUTATION IS LIMITED TO COMPLEMENTARY FLAG BRANCHES. Two controlled writes
  to the same rail are treated as commuting only when they share a control
  register whose `cqrt_x` parity differs between them AND that register is
  touched by nothing but `cqrt_x` in between — i.e. they provably act on
  disjoint branches of the same flag. That is the `¬flag cqrt_x` bracket the
  two-arm emitter emits (§5b), and it is what makes the if/else `A B A B`
  routing of a shared base reduce to identity. No other reordering is allowed.
  The same admission — and no wider one — governs the co-written slot check
  (bd 0gwl): an intervening write on the complementary branch of a flag the
  pair also carries is dropped before that slot's history is reduced. Two
  operators supported on complementary blocks of one flag commute exactly, so
  on the branch where the pair acts such a write is the identity. Without it
  the `A B A B` two-arm route stops reducing and a correct, reviewed lowering
  is reported UNPROVEN — for a GATE, that is failing a good build.

WHAT IT DOES **NOT** WITNESS  (read this before quoting the tool)
================================================================
  * PHASE OUTSIDE A SUPERPOSING WINDOW. Because Rz is transparent (above), a
    dropped or wrong-angle `rz` adjoint on a rail no superposing pair is asked
    to restore is INVISIBLE here. That is a real miscompile — it is the golden
    trace's job, and the two gates are complementary by construction: the trace
    sees the angles and not the rail identities, this file sees the rail
    identities and not the angles.
    INSIDE a superposing window it is NOT invisible any more (bd
    test_C_libtooling-r2j3.4). Transparency is sound for a rail in a basis
    state and false between two superposing writes: `Ry(-t)·Rz(φ)·Ry(t)`
    changes POPULATIONS, and `ry; rz; ry⁻¹; free` used to VERIFY a dirty free
    here, before and after rule (L). Rule (L) now refuses a window in which a
    diagonal call touching the light cone is not cancelled by its adjoint
    inside the window (`_phase_closed`), and that includes a dropped or
    wrong-angle `rz` adjoint there — so within a window, this file DOES see
    the angle, to the extent of "negated or not".
    Still REFUSED although sound (over-declines), stated: a phase whose
    cancellation is not a pairwise negation of literal angle text
    (`rz(a); rz(b); rz(-(a+b))`, an angle spelled as an SSA value), and the
    other deliberate refusals `light_cone_closed` lists; the angle is compared
    as text through `is_negation`, never evaluated.
    Still VERIFIED although dirty, stated: a phase on a rail that reaches the
    gate through a NON-CALL alias (`%s = select …, %b, …; rz(%s, φ)` inside
    `%b`'s window) — the NON-CALL bullet below, unchanged by this rule and
    held in front of this file by the pass's `declineClassicalMuxes`.
  * The UNITARY. This is a structural check, not a simulator. It proves the
    emitted gate sequence has the SHAPE of a reversal; it does not evaluate it.
    Reduction-to-identity is SUFFICIENT for "unchanged", never necessary:
    `cqrt_x(h); cqrt_cnot(c,h); cqrt_x(h); cqrt_cnot(c,h)` is identity and
    is reported UNPROVEN, not verified. Likewise a Bennett-style uncompute that zeroes an ancilla by
    RECOMPUTING its predicate from updated state — the dtzb `break` fire rail,
    `toffoli(c,eqz,fire) … cnot(eqz',fire)` — is genuinely correct and
    genuinely UNPROVEN here; witnessing it needs the basis-state evaluator that
    is the other, expensive half of bd 8txa.
  * INTERCHANGEABLE reversals. When k frees pair with k character-identical
    `_inv` calls (the log1pl fcmp_olt family), any permutation of the pairing
    satisfies (T1) — correctly so, since identical ops on identically-valued
    rails ARE interchangeable. What it catches is a count or argument mismatch,
    which is what "re-paired to the wrong rail" degenerates into whenever the
    rails are not interchangeable.
  * Rails that are NEVER freed. Rule 6's "a rail not provably |0> is left
    allocated, never freed" is a rule about what the pass must NOT emit; a
    leaked dirty rail is invisible here (and is accepted in the
    qubits-not-scarce regime).
  * The ENTANGLEMENT half of Rule 8. A copy+uncompute that should have been a
    `cqrt_cswap` presents as a well-formed reversal. (Rule (L) witnesses ONE
    slice of it: a superposing pair whose window leaks the rotated state into
    a rail that is not restored before the pair closes. Entanglement created
    OUTSIDE any superposing window is still invisible.)
  * ESCAPE analysis (`ret` / `cq_invert_*` handles) beyond "was it measured in
    this function", and anything cross-function or cross-stream (below).
  * The FORWARD program. It checks reversal, not computation.
  * ALIASING THAT IS NOT SSA-IDENTITY. The Case-B rule compares operand SSA
    names, so it sees `cqrt_cnot(%c, %c)` and not two DISTINCT names that carry
    the same rail at run time. Three ways that can happen, none witnessed here:
    a `phi` that merges a handle with itself; a callee whose two parameters
    receive the same handle at the call site (the check is intra-procedural —
    MEASURED: no `@__cq_q_*` call in the corpus passes a repeated argument, so
    nothing is being hidden today); and a handle laundered through classical
    arithmetic. What makes SSA identity the right layer anyway is that it is
    the one an emitter bug actually produces — a `CreateCall` with the same
    `Value*` twice — and it is exactly the layer a later RAUW can retarget.
    The live example, cited precisely because the two halves are often
    conflated: SwapRouteEmit.cpp:589 only RECORDS
    `taint.SharedCondFlags[Cond] = Flag` and deliberately does NOT RAUW there
    (read its comment); CompareLowering.cpp:415 later runs
    `cmp->replaceAllUsesWith(Shared)`, and THAT is what can rewrite an
    already-emitted gate operand. See bd
    `case-b-cswap-603-near-miss-2026-07-31` for why it cannot reach the routing
    `cqrt_cswap` today, and for the ArmClassify gate that is load-bearing here.
  * SYMBOLS `classify()` DOES NOT MODEL. Write-sets exist only for the symbols
    it knows, so the Case-B rule's coverage is exactly that set. RE-MEASURED
    2026-09-02 (was 145 of 173 on 2026-07-31): of the 182 `cqrt_*` functions
    declared in `runtime/cq_runtime.h` it models 163; the 19 it does not are the
    `_controlled_inv` reserve plus the three un-widthed controlled placeholders
    (`cqrt_x_controlled`, `cqrt_cnot_controlled`, `cqrt_h_controlled`,
    `cqrt_rz_<W>_controlled_inv`, `cqrt_ry_<W>_controlled_inv`), emitted by
    nothing today. The `cqrt_rz_<W>_controlled` family and the NEW
    `cqrt_ry_<W>_controlled` family LEFT this list on 2026-09-02 (bd
    test_C_libtooling-drbq Inc 0): §6a control-in-place is no longer an optional
    peephole but the MECHANISM for a tainted-control Ry arm, since the swap
    route cannot carry an `Ry` at all. Both stems are modelled in `classify()`
    above — the Ry twin as a NON-diagonal write of arg 1, the Rz twin as its
    diagonal counterpart — which is the standing obligation below, discharged
    for those 18 symbols before the emitter that mints them shipped. (bd
    r2j3.33 added the 12 in-place quantum-source symbols
    `cqrt_{xor,add,sub}_{i8,i16,i32,i64}` to the header; they are modelled
    from their first commit, so the "does not model" set is unchanged.)
    This is NOT a silent gap: any of them being CALLED in lowered IR raises
    `Unclassified` and fails the whole run, so the failure mode is a loud stop,
    never an unchecked call. (A bare `declare` does not — only a call is
    parsed — which is correct: an unused declaration acts on no rail.) It IS a
    standing obligation: whoever un-shelves that family must add its read/write
    sets here first, or the run will refuse to render a verdict.
  * NON-CALL instructions. Only calls are modelled; a rail handle reaching a
    gate through `select`/`phi`/integer arithmetic is invisible to the alias
    rule, to `provably_not_a_rail` (which answers "not a rail" for any non-call
    SSA value that is not a formal parameter), AND — the sharper consequence,
    named here after the bd xzdx round found this bullet understated it — to the
    WRITE HISTORY itself. `Rail.writes` is keyed on the literal SSA operand
    string, so `%v = select …, %h, …` followed by `cqrt_x(%v)` records the flip
    against a fresh EXTERN rail called `%v` and leaves `%h`'s history empty;
    (T2), (T3) and (A2) then all report `%h` unchanged and the free VERIFIES,
    where the same flip written directly on `%h` correctly declines. Nothing
    inside this checker stands behind that — what stands in front of it is the
    PASS: `declineClassicalMuxes` (ir-pass/src/TaintPropagation.cpp) loudly
    rejects a live select/phi over tainted data, so stage 2b never sees one, and
    MEASURED over the 237 slices no phi or select result reaches a runtime-call
    argument. It is a standing obligation on whoever widens that (the 8h7d loop
    work, Phase-8 `cq_invert`), and it is filed rather than left implicit.

STREAMS / CFG SCOPE. Execution order is only knowable without a simulator on
straight-line code, so the analysis runs per STREAM: a maximal chain of basic
blocks B0 -> B1 -> ... where each Bi ends in an unconditional `br label %B(i+1)`
and B(i+1) has Bi as its only predecessor. That is the shape the lowering emits
(`RegionFlatten` linearizes accepted control regions; the uncompute spine and
the flag network emit adjacent runs). A rail minted in one stream and freed in
another — the dtzb whole-loop reverse-play is the live example — is reported
UNPROVEN, never silently passed (`U1-cross-stream`, or `U3-extern-rail` when it
is also written here). Writes to a handle that arrives from outside ARE
recorded, so "this operand has no writes in this interval" is a fact about the
stream rather than an absence of information.

  ⚠ SINCE 2026-09-18 THAT PARAGRAPH HAS ONE EXCEPTION, AND IT IS THE ONLY ONE:
  rule (T4), the LOOP-EXIT DISCHARGE (`StreamAnalysis.loop_exit_discharge`,
  reached from the `U3-extern-rail` arm of `check_free`). It verifies a rail
  minted in a dominating stream, read-only inside the loop, and reversed and
  freed at the loop exit — the shape Group 1's P2 anchor emits. It does NOT
  linearize anything across a back edge: every fact it uses is either
  path-insensitive (a write COUNT over the whole function) or a position
  comparison INSIDE one stream, and it REFUSES any cycle through the mint's or
  the free's own stream. The dtzb rails stay exactly as this paragraph says —
  MEASURED, all four `e2e-slice-loop-break*` slices byte-identical in verdict
  and in UNPROVEN class before and after. Read `loop_exit_discharge`'s docstring
  for the seven conjuncts, the arm-kill matrix, and what it does not prove.

EXIT STATUS. 0 iff every free site VERIFIED. Non-zero on any VIOLATION, on any
UNPROVEN site (unless `--allow-unproven`), and on any UNCLASSIFIED runtime
symbol. The last is deliberate and mirrors the Prime Directive: a new `cqrt_*`
symbol whose read/write effects this file does not know makes the model
unsound, so it fails loudly rather than checking the rest and reporting success.

MEASURED STANDING (2026-07-31, the 237 registered e2e slices at their stage-2
`opt` output — 218 single-file + 19 multi-file): 50504 `cqrt_free` sites, 50484
VERIFIED, 0 VIOLATIONS, 20 UNPROVEN, and 0 Case-B findings. All 20 UNPROVEN are
in the five `slice_loop_break*` slices and are the dtzb whole-loop reverse-play
(10 `A-not-reducible` on the `cq.brk.fire` ancilla, which a correct Bennett
RECOMPUTE zeroes rather than a palindrome, and 10 `U1-cross-stream` on
`cq.brk.R`/`cq.brk.idx`, whose write history spans the loop back-edge). Those
five e2e entries therefore pass `--allow-unproven` with that reason written at
the call site; every other slice runs strict. Adding the (A1) immediate check
and the Case-B rule moved ZERO of the 237 verdicts; RE-MEASURED 2026-08-07,
adding the (A2) co-written-slot check (bd 0gwl) moved ZERO of them as well —
same 50504/50484/20/0, no slice changed a single finding. RE-MEASURED AGAIN
2026-08-08 on a freshly regenerated corpus after removing the recursion's depth
budget (bd xzdx): same 50504/50484/20/0, again no slice changed a finding —
expected, because the recursion nests at most 3 frames deep on any of the 237
slices (a `depth` of 2 against a budget that refused at 7), so the ship floor
never touched it. That is a statement about the corpus, NOT about the defect:
see VALIDATED BEFORE USE for where it bites.

VALIDATED BEFORE USE. Proof-targeted mutation — blank or corrupt an instruction
some VERIFIED site's own proof consumes, then re-check — killed 6569 of 6579
mutants (99.8%) when it was run, ON THE 2026-07-26 CORPUS OF 232 SLICES. That
figure is dated, not current: the same experiment over today's 237-slice corpus
generates ~160k mutants and has not been re-run at that scale. All 10 survivors
were the same by-design case: perturbing a classical `cqrt_addc` on an (A1)
rail changes WHICH known classical basis state the rail holds, never whether it
holds one, so the free stays Rule-6 sound.
tools/free_pairing_check_test.py is the committed, ctest-wired subset of that
experiment (positive fixtures + hand-planted named defects + a proof-targeted
sweep), and it IS current.

The Case-B rule was validated the same way before being trusted, because a
rule that has never fired is a rule nobody should believe. Over the SAME 237
lowered slices — the ship floor, not hand-written .ll — write-bearing calls had
one input operand retargeted onto a slot the call writes (and, for the
two-write `cswap`, its two written slots aliased): 392 planted aliases, 392
CAUGHT, 0 SURVIVED, with all 237 slices Case-B-clean before mutation.

THE CAP, STATED RATHER THAN IMPLIED (Rule 12, no silent caps): those 392 are
not every candidate. The corpus offers 109759 (call, alias-plan) candidates
across 165 (symbol, kind) families, and the experiment plants at most 3 per
FAMILY — so coverage is complete across families and a 0.36% sample within
them. That is the right axis to be exhaustive on, because the rule branches on
the symbol's Effect and not on the call site; but it is a sample, and 392/392
must not be read as "every aliasable call in the corpus was tried".

THE (R1) RECORDED-RAIL rule (bd 261j(b)) was validated the same way, 2026-08-11,
and it is the only rule here that does not go THROUGH a proof — so the evidence
matters more, not less.

 (1) VERDICT DIFF over every one of the 240 REGISTERED e2e slices (rebuilt from
     build/tests/e2e/CTestTestfile.cmake so the list cannot drift from ctest),
     comparing the FULL finding list and not just exit codes, against a pinned
     pre-change copy of this file: 0 moved. False positives are the expensive
     direction for a GATE and this is the only measurement that bears on them.
 (2) FIRE TEST on synthetic IR: the pre-261j lowering, its controlled-twin
     ctrl-slot form, a chained theta, and an ANCESTOR-only correlation all
     VIOLATE; the three adjacent shapes it must stay silent on — a diagonal
     `cqrt_rz_` rail, the DERIVED rail whose free bd 261j(a) deliberately KEPT,
     and a rotated rail with no record — all still VERIFY. All six are committed
     in free_pairing_check_test.py, which is what finally gives
     `cqrt_tape_write_<W>` the mutant that file's own docstring admits it lacked.
 (3) FIRE TEST ON REAL LOWERED IR, not hand-written .ll: plant a tape record on a
     rail that the corpus module itself both rotates and frees. 19 planted, 19
     caught, 0 survived. THE CAP, STATED: one plant per module, and only in the
     19 of 240 modules that HAVE such a rail — the other 221 have none, because
     the 261j fix already stopped the compiler emitting that shape. This is not
     "every rotated rail in the corpus".
 (4) ARM-KILL MATRIX, and it found two gaps in the first draft of the mutants
     rather than confirming them. Deleting the ROTATION conjunct, the RECORDED
     conjunct, or the BACKWARD CLOSURE each turns the self-test red (2, 5 and 1
     failures) — but only after adding the ancestor mutant, WITHOUT which
     deleting the closure entirely left the file green. The fourth arm, the
     `cqrt_ry_` name test, could NOT be killed: an `rz` never enters a rail's
     write history at all (`if not e.diagonal`), so the name test is defence in
     depth over an exclusion made one layer earlier. Recorded rather than
     claimed the other way round.

THE LEAK CENSUS ships with it, for the reason bd 261j(b) names: this file counts
free SITES, so a compiler that frees nothing scores "0 cqrt_free site(s): 0
verified" and passes STRICT. The summary now always states how many rail mints
were left allocated. Leaks are legal (Rule 6's fallback) so it never fails on
them — but the number can no longer be silently zero. On the corpus it is what
makes bd 261j(a)'s own effect visible: `slice_io` reads "1 rail mint(s) of which
1 left allocated, 0 cqrt_free site(s)".

    *** THE CENSUS COUNTS `cqrt_alloc_*` MINTS ONLY. A `cq_template_*` RESULT
    *** IS A RAIL AND IS NOT COUNTED. ***

Read that as a stated LIMIT, not a rounding error, because it is how a real
defect got past this file (bd test_C_libtooling-8h7d.5, Rule-13 round 4, finding
F-4). A rolled loop whose body put a basis-relabelling gate BEFORE its tainted
region stopped discharging the region's derived-condition chain: `cq_template_
and_i32_hl(%h, 3)` was minted every trip, never `_unc`-reversed, never freed, and
the trailing `cqrt_ry` then fired over a live ENTANGLED record of its own
register. This checker reported "0 violation(s), 0 unproven" on it — correctly,
by its own obligation (nothing was freed dirty; there was no free at all) and
blindly, by its census (the leaked rail has no `cqrt_alloc`, so `minted` did not
count it and `leaked` could not report it). At 50 trips the program leaked 151
rails and the summary still read "0/0".

Nothing here is unsound as a result — a leak is Rule 6's fallback and this file's
obligation is about FREES. But the leak census exists precisely so that "it never
had to prove anything" cannot masquerade as coverage, and for template-minted
rails it currently cannot say so. Widening `classify()`'s mint census to
`cq_template_*` results (with its own mutant in free_pairing_check_test.py, since
a census nobody has tried to fool is a census nobody should trust) is filed as bd
test_C_libtooling-8h7d.6. UNTIL THEN, the instrument that DOES see this class is
the rolled-equals-unrolled byte-diff — tools/loop_twin_matrix.py, ctest entry
`e2e-loop-twin-matrix` — and the two are complementary in the same way this file
and the golden trace are.

The (A2) CO-WRITTEN-SLOT rule (bd 0gwl) was validated the same way, 2026-08-07,
and here the population is small enough to be EXHAUSTIVE rather than sampled —
so unlike the Case-B figure above, this one has no cap to state. Instrumenting
`pair_operands_unchanged` over the same 237 lowered slices finds 60 co-written
cancellations, all `cqrt_cswap`, across 10 slices (the 11th cswap-bearing
slice, `slice_control_abort`, routes to a grave rail that is never routed back
and never freed, so no pair forms). Planting a dirtying `cqrt_ry` on the
co-written register INSIDE each: 60 planted, 60 CAUGHT, 0 survived.
Then the ARM-KILL MATRIX, because a predicate with N accept-arms and one probe
lets N-1 be deleted with a green suite (the az1h lesson): each arm was deleted
individually and the committed selftest re-run, and each of the FOUR turns it
RED via a DIFFERENT fixture — the co-written loop itself (the three 0gwl
mutants; with it gone the ticket's own reproducer is silently VERIFIED again),
the `v == target` skip (`a2-co-written-target-skip`), the complementary-branch
commutation filter (`IFELSE_DERIVED`), and the nested reduction rather than a
demand for an empty history (`VALUE_DIAMOND`).

REMOVING THE DEPTH BUDGET (bd xzdx, 2026-08-08) is the one change here that
WIDENS what verifies, so it was measured on the axis that matters — is anything
it newly accepts actually dirty? The corpus cannot answer that (it never nests
past 3 frames, so all 237 verdicts are unmoved), and the flat random
streams the Case-B work used cannot either (4-30 gates, 8000 modules, ZERO
sites changed verdict — a probe with no power on this change, which is worth
saying rather than quoting as a pass). The population that does have power is
LADDERS: nested adjoint pairs 5 to 14 levels deep, built from
`cqrt_x`/`cnot`/`toffoli`/`cswap` only — all classical permutations, so the same
exact oracle the Case-B validation used decides the truth by evaluating the
network over every assignment of the unknown rails — with HALF the modules
deliberately perturbed (a gate dropped, duplicated, or inserted) so the
population is not clean by construction. Over 12000 such modules — SEEDS 41 AND
77, 6000 each, named because a count nobody can re-derive is not a measurement —
4201 sites that the old tool declined now verify, and the oracle says every one
of them is genuinely |0> at the free; 0 sites moved the other way; and across
all 23278 OK verdicts the new tool issues there, 0 over-accepts (the old tool:
19077 OK verdicts, also 0). Other seeds give the same picture with different
counts: the invariant being claimed is the two ZEROS, not the 4201.

Read that 23278 as a denominator with care: most of those OK verdicts are on
rails the old tool ALSO cleared, so the figure the widening actually rests on is
the 4201 — every one of which was adjudicated, none of which was dirty.

AND READ THE POPULATION'S SCOPE, which is a real limit and not a formality: it
is permutation-only BECAUSE that is the class the oracle can decide, and that
deliberately excludes the superposition class — `cqrt_ry` / `cqrt_h`. When this
paragraph was written the file did not witness that class at all: a
`cqrt_ry(R,t) … <a CNOT-class READ of R> … cqrt_ry(R,-t)` pair cancelled here
while R was left entangled with the reader, because the reduction reasoned over
WRITES to R and never asked what read it. The bd xzdx Rule-13 round confirmed
both halves of the attribution — the hole was HEAD's (patch HEAD's `depth > 6`
to `> 100` and HEAD accepts the same input at any depth), and removing the
budget widened its REACH from depth <= 6 to any depth. So the two zeros above
are zeros over the permutation class only.
  ⚠ SUPERSEDED IN PART, 2026-10-01 (bd test_C_libtooling-r2j3.3): that READ is
  now refused. The hole shipped: stage 2b certified the compiler's dirty free
  of a QRAM load rail whose index was rotated away, TAPE-RECORDED, and rotated
  back between the load and its `_unc` — the same shape reached through (T2).
  Rule (L), `StreamAnalysis.light_cone_closed`, makes a superposing pair cancel
  only when nothing between its halves kept the rotated state, and it binds
  this reduction wherever it runs. A PHASE between the two halves (bd
  test_C_libtooling-r2j3.4) is refused by the same rule's phase conjunct,
  `_phase_closed`. What is still open in the superposition
  class: any correct closure that is not a LIFO reversal (a Bennett
  recompute), or a phase cancellation that is not a pairwise negation, both of
  which over-decline. Neither yields to a deeper fuzz.

The other three measurements: verdict diff over the 237 slices, 0 moved (above);
proof-targeted mutants planted in the SHIPPED lowered IR, 735 planted (at most 4
per slice, out of 160229 witness lines — a cap, stated), 735 caught by BOTH
tools, 0 catches lost; and the order property itself — 4000 random modules per
seed whose trailing `cqrt_free`s are permuted, where the old tool moved a
verdict on 27 (seed 7) and 19 (seed 99) of them and the new tool on 0 of either.
On real IR that last probe is nearly powerless and says so: only 25 of the 237
slices have two `cqrt_free`s on adjacent lines at all, and swapping them moved
nothing under EITHER tool.

WHAT IT COSTS, since a budget also caps work. With both edges cached the
recursion is polynomial, and the corpus does not notice: the 237-slice sweep is
6-8 s before and after. A deep SYNTHETIC nest does pay, because it now runs to
completion instead of being cut — MEASURED on `order_ladder`, 2026-08-08:
D=2000 / 6005 calls 0.09 s -> 0.31 s, D=8000 / 24005 calls 0.38 s -> 3.73 s
(~10x, growing about quadratically in the nesting depth, mostly in the
`witness |= sub` frozenset unions that `reduces_to_identity` accumulates one per
level). Every one of those PRE timings is the tool declining a stream it should
verify, so the extra time buys the right answer; it is recorded because a gate
with no timeout should have its cost curve written down somewhere.

Its ARM-KILL MATRIX has five rows, and rows (3b) and (4b) exist because the
first pass of it was wrong twice. All five re-measured 2026-08-08 against the
committed selftest as it stands today; the counts move when fixtures are added,
so re-measure rather than quote.
  (1) THE BUDGET REMOVAL ITSELF — run the PRE-change tool against today's
      selftest: 7 FAIL rows over 6 distinct fixtures (both order pairs, the two
      D=7 ladder positives, the deep D=500 positive, the braid, the ticket
      repro).
  (2) `ensure_recursion_headroom` — delete the call and `xzdx-deep-ladder-d500`
      dies on `RecursionError` mid-run, with no summary line at all.
  (3a) THE `co_written_stable` RE-ENTRY ASSERTION — break narrowing by weakening
      `writes_in` to `lo <= p <= hi`. With both assertions in place the tool
      stops loudly and NAMES the re-entered query; delete this one and the same
      input dies on a `RecursionError` that names nothing. The runaway goes
      through this edge on every fixture carrying a `cqrt_cswap` route pair,
      7 of the 19.
  (3b) THE `unchanged_over` RE-ENTRY ASSERTION — which SURVIVES the probe in
      (3a), because that runaway never reaches this edge. Surviving means the
      probe was too weak for this arm, not that the arm is spare. The probe that
      does kill it is the committed mutant
      `case-b-self-aliased-cnot-aka-the-narrowing-probe`: no `cqrt_cswap` at
      all, so `co_written_stable` is never entered, and a self-aliased
      `cqrt_cnot` makes the READS edge re-enter `('%a', 3, 4)`. Guard present:
      named `NarrowingViolation`. Guard deleted: unnamed `RecursionError`.
  (4a) `_stable_memo` IS A PURE CACHE, which is checkable rather than
      assertable: delete its writes and both the selftest and all 237 corpus
      verdicts are byte-identical (slower, and that is the only difference).
  (4b) `_co_written_memo` IS NOT — do not read row (4a) as covering both. Delete
      ITS writes and the selftest turns RED on the `xzdx-cswap-braid-d20` cost
      bound at 1048575 entries against a bound of 5000. That cache is load
      bearing for termination-in-practice, not a speed-up.

THE ARM COUNT IS FOUR BECAUSE THE FIRST ANSWER WAS WRONG, AND THAT IS THE
LESSON WORTH KEEPING. The `v == target` skip survived its first kill test, and
this file then recorded it as "redundant by construction … no input can
distinguish the two". The bd 0gwl Rule-13 round refuted that with a runnable
stream: the caller's `commutes` filter and the one this path would use are
evaluated over DISJOINT intervals ((w, p2) versus (p1, w)), so they disagree
whenever a non-`cqrt_x` write touches the flag on one side of `w`. Surviving a
kill test means the PROBE was too weak, and "redundant by construction" is a
claim about all inputs that a corpus sweep cannot establish — measuring zero
moved verdicts shows only that the corpus lacks the distinguishing shape. Build
the probe; do not promote its absence into a proof.

THE (L) LIGHT-CONE RULE (bd test_C_libtooling-r2j3.3, 2026-10-01) was validated
the same way, and its corpus figure is the one to read most carefully.
 (1) VERDICT DIFF over all 474 registered run_slice*.sh slices (stage 2 rebuilt
     from `ctest -N -V -R '^e2e-'` with the harness's own stage-1/2 commands, at
     main 52e669c4), FULL finding lists against the pinned pre-change file:
     60677 free sites, 60661 verified before and after, 0 findings moved, 0
     exit codes moved; the pre-change file passes all 474 under their
     registered flags. Comparator controls: the r2j3.3 reproducer moves (1 of
     1), the pre-change file against itself moves nothing.
 (2) BUT THAT DIFF HAS ALMOST NO POWER, and that is the measurement worth
     quoting: across the 474 slices only 4 superposing pairs ever reach the
     rule, every one with a TRIVIAL cone (nothing in its window touches the
     rotated rail). The current spine leaves rotated roots allocated instead
     of reverse-playing them, so the window shape is rare. "0 moved" therefore
     says nothing about false positives on non-trivial cones; the accept arms
     are exercised only by the selftest's LIGHT_CONE_POSITIVES (13 shapes, each
     one operand from a mutant) and the D=60 nest.
 (3) ARM-KILL MATRIX, 24 kill-expected mutants of the rule against the
     committed selftest: 24 killed, MISSED 0 (no-op control survives; the two
     memo caches and the re-entry assertion are equivalent by design). Three
     are killed ONLY through the refusal-text assertion and survive a
     verdict-only harness — measure-is-closable, tape-is-a-plain-mint, and the
     (T2) message dropping the reason — because a measured or tape-recorded
     cone rail can never be RESTORED either (neither has an adjoint), so the
     restoration conjunct refuses it one step later. Those two consumer arms
     are defence in depth with a precise diagnostic, not independent gates.
 (4) COST. Linear in the corpus (474-slice sweep 265 s -> 267 s summed). On a
     synthetic D-deep nest of closed windows it is QUADRATIC — every window
     rescans its interior: D=100 0.2 s, D=500 3.0 s, D=1000 10.2 s (2026-10-01,
     `cone_nest` in the selftest). The first draft unioned every cone rail's
     sub-proof lines into each enclosing window and was cubic (D=500 13.5 s);
     the witness is now each cone rail's reversal line alone.

THE (L) PHASE CONJUNCT (bd test_C_libtooling-r2j3.4, 2026-10-13), validated the
same way, and the corpus figure is again the one to read with care.
 (1) VERDICT DIFF over all 440 registered run_slice*.sh slices (392 single +
     48 multi, rebuilt from main fc6ee653's build/tests/e2e/CTestTestfile.cmake
     with the harness's own stage-1/2 commands, cq-opt sha256 f4379f18…), FULL
     finding lists plus the exit code under each slice's registered flags,
     against the pinned pre-change file: 56779 free sites, 56759 verified
     before and after, 0 modules moved, 0 exit codes moved, all 440 exit 0
     both sides. Comparator controls: the pre-change file against a copy of
     itself moves nothing; the ticket's two reproducers (A2 and T2) move.
 (2) THAT DIFF HAS NO POWER AT ALL on this rule, and it was measured before
     the change, not assumed: the pre-change file runs the light-cone rule
     exactly TWICE over the 440 slices (qram-load-index-record-window,
     spec-intermediate-unc), both windows close, and NEITHER contains a single
     diagonal call. The accept arms are exercised only by the selftest's
     PHASE_WINDOW_POSITIVES (11 shapes, each one operand from a mutant or a
     shipped phase mechanism) and UNCOMPUTE_CHAIN's `%h_op3` pair, the one
     historical shipped lowering with a phase inside a window.
 (3) ADDS REFUSALS ONLY, PER PAIR: the scan, the cone and the restoration
     conjunct are unchanged, and the phase test is one more conjunct ANDed
     after them, so every superposing PAIR this file now cancels the
     pre-change file cancelled too. Stated precisely rather than rounded up:
     the reduction is GREEDY, so a pair refused here can leave a different
     (textually identical) stack entry for a later write to take, and "every
     free verified now was verified before" is not proven for every input —
     only measured (item 1) and argued (two candidates an adjoint can match
     are the same text). The review question is whether something sound is
     newly refused.
 (3b) SEVERITY IS NOT NARROWED WITH IT (review round 1, F1, CLAUDE.md L2).
     Two SEVERITY choices read the reduction NEGATED — `T1-no-reversal`'s
     VIOLATION-if-inert and the T3 failure that pre-empts
     `T3-rail-written-after-reversal` — and the first draft let a phase in
     the rail's own window demote both from VIOLATION to a waivable
     UNPROVEN, so `--allow-unproven` exited 0 on a free with no reversal.
     Both now read the LABEL-ONLY reduction (`reduces_to_identity(cone=
     False)`), which asks neither the light cone nor the phase. That also
     RAISES the r2j3.3 open-cone spelling of the same two shapes from
     UNPROVEN back to VIOLATION, the pre-r2j3.3 severity; the corpus has no
     such site (item 2: the light-cone rule never refuses on it). Pinned by
     PHASE_WINDOW_SEVERITY in the selftest. Every other negated use was
     checked: `check_alloc_rail` chooses only among UNPROVEN codes, and
     `_minted_core`'s and the cone's negations refuse in the same direction
     as the predicate they read.
 (4) MUTANTS: one no-op (survives all 29 r2j3.4 rows) and three real ones,
     each run against the single row written to kill it — the conjunct
     deleted (`…a2-rz-on-the-freed-rail…`), the pair's operand-stability test
     dropped (`…phase-pair-straddling-a-label-flip`), the control slot made
     blind (`…controlled-phase-from-the-rotated-index-onto-an-outside-rail`):
     3 killed, MISSED 0. (Measured on the round-1 snapshot; the F1/F3/F4
     fixes were not re-mutated.)

USAGE
    tools/free_pairing_check.py [options] lowered1.ll [lowered2.ll ...]
      -q/--quiet          only print the summary and any findings
      --allow-unproven    downgrade UNPROVEN sites from failure to a report
      --explain           per verified site, the rule and the witness lines
      --stats             print per-category counts
      --json              machine-readable report on stdout
Self-test / mutant validation: tools/free_pairing_check_test.py.
"""

import argparse
import json
import re
import sys
from collections import Counter, namedtuple

# ---------------------------------------------------------------------------
# Effect model — the read/write/mint behaviour of every symbol the pass emits.
#
# Handle-ness of an operand is decided DYNAMICALLY (an operand is a rail iff
# this analysis already saw it minted), so the `_hl`/`_lh`/`_qq` operand-shape
# grammar never has to be re-parsed here; a classical literal or a classical
# SSA value simply is not in the rail table. Rule 15 (width-only ABI) means the
# width suffix is irrelevant to the effect model, so every entry below is keyed
# by the width-stripped stem.
# ---------------------------------------------------------------------------

_W = r"(?:i1|i8|i16|i32|i64|i80|i128|f16|f32|f64|f80|f128)"

ALL = "ALL"            # every operand is read
ALL_BUT_0 = "ALL_BUT_0"  # `_unc(out, srcs...)` — out is written, srcs read


class Unclassified(Exception):
    def __init__(self, sym):
        super().__init__(f"unclassified runtime symbol: @{sym}")
        self.sym = sym


class Undecidable(Exception):
    """A MEMORY construct whose rail-ness this file cannot decide (bd 21re).

    Same discipline as `Unclassified`, one layer down. A new `cqrt_*` symbol
    changes what "written" means and must be modelled before any verdict is
    worth anything; a rail handle that travels through MEMORY changes what
    "this operand is a rail" means, and the model is keyed on SSA names only.

    WHY IT IS NEW. `provably_not_a_rail` used to answer True for every `load`
    result on a premise that was TRUE WHEN WRITTEN and that bd `xdu2` (L-1a,
    the bounded rail ARRAY) exists precisely to remove: *"a tainted `store` is
    a loud decline at `declineTaintEscapes` long before lowering - so a load
    result is not a rail."* After L-1a a `!cq.railbank` cell holds an i32 rail
    HANDLE and a load of it IS a rail. See `adjudicate_memory`.

    Raised, never reported as UNPROVEN, for the same reason `Unclassified` is:
    an UNPROVEN site can be waived with `--allow-unproven`, and a waivable
    model-unsoundness is the hole, not the report of it.
    """

    def __init__(self, code, fn, line, msg):
        super().__init__(f"{code} @{fn} line {line}: {msg}")
        self.code, self.fn, self.line, self.msg = code, fn, line, msg


class NarrowingViolation(Exception):
    """The stability recursion re-entered a query it was already computing.

    This is an INTERNAL INVARIANT FAILURE, not a property of the input. The
    reduction terminates because every recursive edge strictly narrows the
    position interval (see `unchanged_over`), so a re-entry means an edge that
    does not narrow was added and the recursion is no longer known to
    terminate. It is raised rather than answered `False` on purpose: a silent
    `False` here is exactly the depth-budget artefact bd
    test_C_libtooling-xzdx removed — an over-decline whose value depends on the
    order queries happen to run in. Fix the edge; do not re-add a budget.
    """

    def __init__(self, key):
        super().__init__(
            f"free_pairing_check INTERNAL: stability query {key} re-entered "
            f"itself, so some recursive edge no longer narrows the position "
            f"interval; the termination argument in `unchanged_over` is void")
        self.key = key


class Effect:
    """Per-call effect record.

    reads/writes are operand INDICES (or the ALL / ALL_BUT_0 sentinels).
    `mints` is None (void or classical return), 'rail', 'array', 'tape', or
    'implicit-rail' (an `_inv`: it does write a rail, but the ABI does not say
    which — the whole reason this file exists).
    `diagonal` marks a write that changes no computational-basis label.
    `controls` are the operand indices whose value selects the branch the write
    acts on (used only by the complementary-branch commutation rule).
    `classical_imm` is the tuple of operand INDICES the ABI declares to be
    classical literals rather than rail handles (`addc`/`xorc` slot 1). It is
    an ASSERTION ABOUT THE ABI, never a fact about the call — rule (A1) must
    CHECK the slot before relying on it (bd az1h), and the Case-B scan treats
    these slots as inputs like any other.
    `superposing` marks a write that is NOT a computational-basis permutation
    (`cqrt_ry_<W>`, its `_controlled` twin, `cqrt_h`): between such a write
    and its adjoint the rail is in a rotated basis, so the pair cancels only
    if nothing in between left its light cone open (bd r2j3.3,
    `StreamAnalysis.light_cone_closed`). A permutation pair needs no such
    check: it restores the rail's label in EVERY basis branch whatever read
    it in between.
    """

    __slots__ = ("role", "reads", "writes", "mints", "adjoint_of", "base",
                 "diagonal", "controls", "classical_imm", "superposing")

    def __init__(self, role, reads=(), writes=(), mints=None, adjoint_of=None,
                 base=None, diagonal=False, controls=(), classical_imm=(),
                 superposing=False):
        self.role = role
        self.reads = reads
        self.writes = tuple(writes)
        self.mints = mints
        # 'self' | 'negate-arg<N>' | 'twin:<symbol>' | None
        self.adjoint_of = adjoint_of
        self.base = base            # forward stem for an _inv/_unc twin
        self.diagonal = diagonal    # phase-only: invisible to the basis ledger
        self.controls = tuple(controls)
        # addc/xorc: the slot the ABI says is a classical literal. CHECKED, not
        # trusted — see `provably_not_a_rail` / rule (A1).
        self.classical_imm = tuple(classical_imm)
        self.superposing = superposing  # bd r2j3.3: not a basis permutation


def classify(sym):
    """Map a callee name to an Effect, or None if the symbol is not ours.

    Raises Unclassified for a `cqrt_*` symbol this model does not know: a new
    runtime primitive changes what "written" means, so it must be added here
    before any verdict from this file means anything.
    """
    # ---- allocation / lifetime -------------------------------------------
    if re.fullmatch(rf"cqrt_alloc_{_W}", sym):
        return Effect("alloc", mints="rail")
    if re.fullmatch(rf"cqrt_qram_alloc_{_W}", sym):
        return Effect("alloc-array", mints="array")
    if sym == "cqrt_tape_alloc":
        return Effect("alloc-tape", mints="tape")
    if sym == "cqrt_alloc_handle":
        return Effect("alloc", mints="rail")
    if sym == "cqrt_free":
        return Effect("free")
    if re.fullmatch(rf"cqrt_measure_{_W}", sym):
        # Recorded as a WRITE with no adjoint: a measurement is irreversible, so
        # a rail it touched can never afterwards be shown "unchanged" for some
        # later reversal, and can never be freed (F8).
        return Effect("measure", reads=(0,), writes=(0,))

    # ---- in-place gates ---------------------------------------------------
    if re.fullmatch(rf"cqrt_rz_{_W}", sym):
        # DIAGONAL: Rz = diag(1, e^{i.theta}) relabels nothing (Rule 6 phase arm).
        return Effect("gate", writes=(0,), adjoint_of="negate-arg1",
                      diagonal=True)
    if re.fullmatch(rf"cqrt_ry_{_W}", sym):
        return Effect("gate", writes=(0,), adjoint_of="negate-arg1",
                      superposing=True)
    # Control-in-place rotations (control-in-place-PRD §5, bd
    # test_C_libtooling-drbq): `cqrt_{ry,rz}_<W>_controlled(ctrl, handle, angle)`.
    # The control flag is arg 0 (READ), the register is arg 1 (WRITTEN), the
    # angle is arg 2 — so the adjoint tag has to name slot 2, not slot 1.
    # The Rz twin is DIAGONAL for the same reason the uncontrolled one is
    # (`diag(1, e^{i.theta})` on either branch of the flag relabels nothing); the
    # Ry twin is NOT, and that asymmetry is the whole point of modelling them —
    # a controlled Ry dirties its target rail exactly as an unconditional one
    # does, so freeing that rail without an adjoint must decline, and the R1
    # recorded-rail rule (which keys on `cqrt_ry_` as a prefix) reaches it too.
    if re.fullmatch(rf"cqrt_rz_{_W}_controlled", sym):
        return Effect("gate", reads=(0,), writes=(1,), adjoint_of="negate-arg2",
                      controls=(0,), diagonal=True)
    if re.fullmatch(rf"cqrt_ry_{_W}_controlled", sym):
        return Effect("gate", reads=(0,), writes=(1,), adjoint_of="negate-arg2",
                      controls=(0,), superposing=True)
    if sym == "cqrt_x":
        return Effect("gate", writes=(0,), adjoint_of="self")
    if sym == "cqrt_h":
        # Self-adjoint; the pass does not emit it. Classified for safety.
        return Effect("gate", writes=(0,), adjoint_of="self", superposing=True)
    if sym == "cqrt_cnot":
        return Effect("gate", reads=(0,), writes=(1,), adjoint_of="self",
                      controls=(0,))
    if sym == "cqrt_toffoli":
        return Effect("gate", reads=(0, 1), writes=(2,), adjoint_of="self",
                      controls=(0, 1))
    if sym == "cqrt_cswap":
        return Effect("gate", reads=(0,), writes=(1, 2), adjoint_of="self",
                      controls=(0,))
    if re.fullmatch(rf"cqrt_copy_{_W}", sym):
        # dst ^= src — an involution (cq_runtime.h: "no cqrt_copy_<W>_inv twin")
        return Effect("gate", reads=(0,), writes=(1,), adjoint_of="self")
    if re.fullmatch(rf"cqrt_copy_{_W}_controlled", sym):
        return Effect("gate", reads=(0, 1), writes=(2,), adjoint_of="self",
                      controls=(0,))
    if re.fullmatch(rf"cqrt_addc_{_W}", sym):
        return Effect("gate", writes=(0,), adjoint_of="negate-arg1",
                      classical_imm=(1,))
    if re.fullmatch(rf"cqrt_xorc_{_W}", sym):
        return Effect("gate", writes=(0,), adjoint_of="self",
                      classical_imm=(1,))
    # bd r2j3.33 / dm7f.51 step 1 — the in-place QUANTUM-source gates
    # `cqrt_{xor,add,sub}_<W>(src, dst)`: src (slot 0) READ, dst (slot 1)
    # WRITTEN, a basis permutation of the pair. xor is self-adjoint; add and sub
    # are each other's adjoint (same operands). Width 1 is `cqrt_cnot` above.
    if re.fullmatch(rf"cqrt_xor_{_W}", sym):
        return Effect("gate", reads=(0,), writes=(1,), adjoint_of="self")
    m = re.fullmatch(rf"cqrt_(add|sub)_({_W})", sym)
    if m:
        other = "sub" if m.group(1) == "add" else "add"
        return Effect("gate", reads=(0,), writes=(1,),
                      adjoint_of=f"twin:cqrt_{other}_{m.group(2)}")

    # ---- output tape (7.6) ------------------------------------------------
    if re.fullmatch(rf"cqrt_tape_write_{_W}", sym):
        return Effect("mint", reads=(1,), writes=(0,), mints="rail")
    if re.fullmatch(rf"cqrt_tape_write_{_W}_controlled", sym):
        return Effect("mint", reads=(0, 2), writes=(1,), mints="rail",
                      controls=(0,))

    # ---- QRAM (7.5) -------------------------------------------------------
    if re.fullmatch(rf"cqrt_qram_load_{_W}", sym):
        return Effect("mint", reads=(0, 1), mints="rail")
    m = re.fullmatch(rf"cqrt_qram_load_({_W})_unc", sym)
    if m:
        return Effect("unc", reads=(1, 2), writes=(0,),
                      base=f"cqrt_qram_load_{m.group(1)}")
    if re.fullmatch(rf"cqrt_qram_store_{_W}", sym):
        return Effect("gate", reads=(1, 2), writes=(0,),
                      adjoint_of="twin:" + sym + "_unc")
    m = re.fullmatch(rf"cqrt_qram_store_({_W})_unc", sym)
    if m:
        return Effect("gate", reads=(1, 2), writes=(0,),
                      adjoint_of="twin:cqrt_qram_store_" + m.group(1))
    if re.fullmatch(rf"cqrt_qram_store_{_W}_controlled", sym):
        return Effect("gate", reads=(0, 2, 3), writes=(1,), controls=(0,),
                      adjoint_of="twin:" + sym + "_unc")
    m = re.fullmatch(rf"cqrt_qram_store_({_W})_controlled_unc", sym)
    if m:
        return Effect("gate", reads=(0, 2, 3), writes=(1,), controls=(0,),
                      adjoint_of="twin:cqrt_qram_store_" + m.group(1) +
                                 "_controlled")
    # bd test_C_libtooling-01po.9 — the CLASSICAL-index forms: slot 1 (`idx`) is a
    # classical literal (`classical_imm`), never a rail; `arr` and `val`/`out` are
    # handles exactly as in the handle-index forms above.
    if re.fullmatch(rf"cqrt_qram_load_{_W}_hl", sym):
        return Effect("mint", reads=(0,), mints="rail", classical_imm=(1,))
    m = re.fullmatch(rf"cqrt_qram_load_({_W})_hl_unc", sym)
    if m:
        return Effect("unc", reads=(1,), writes=(0,), classical_imm=(2,),
                      base=f"cqrt_qram_load_{m.group(1)}_hl")
    if re.fullmatch(rf"cqrt_qram_store_{_W}_hl", sym):
        return Effect("gate", reads=(2,), writes=(0,), classical_imm=(1,),
                      adjoint_of="twin:" + sym + "_unc")
    m = re.fullmatch(rf"cqrt_qram_store_({_W})_hl_unc", sym)
    if m:
        return Effect("gate", reads=(2,), writes=(0,), classical_imm=(1,),
                      adjoint_of="twin:cqrt_qram_store_" + m.group(1) + "_hl")

    # ---- generated templates + specialization clones ----------------------
    # Grammar (TemplateName.h):
    #   cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv]
    #   cq_template_..._unc(out, forward operands...)      (DD-3 slot order)
    #   @__cq_q_<callee>_<mask>[_unc]                      (Phase 6.3)
    if sym.startswith("cq_template_") or sym.startswith("__cq_q_"):
        ctl = (0,) if "_controlled" in sym else ()
        if sym.endswith("_unc"):
            # `_unc` puts `out` in slot 0 (DD-3), so a control — if a
            # `..._controlled_unc` twin is ever generated; none exists today,
            # EmitInverse declines controlled callees — shifts to slot 1.
            return Effect("unc", reads=ALL_BUT_0, writes=(0,),
                          base=sym[: -len("_unc")],
                          controls=(1,) if ctl else ())
        if sym.endswith("_inv"):
            # The 8txa gap: writes a rail the signature does not name.
            return Effect("inv", reads=ALL, mints="implicit-rail",
                          base=sym[: -len("_inv")], controls=ctl)
        return Effect("mint", reads=ALL, mints="rail", controls=ctl)

    if sym.startswith("cqrt_"):
        raise Unclassified(sym)
    return None  # @llvm.*, @printf, user classical calls — not our surface.


# ---------------------------------------------------------------------------
# Parsing. LLVM prints one instruction per line, so a line-oriented parser is
# exact; nothing below depends on formatting the verifier does not guarantee
# (Rule 9 — no assumptions about naming or ordering, only about the textual
# grammar `llvm-as` accepts).
# ---------------------------------------------------------------------------

DEFINE_RE = re.compile(r"^define\s.*?@([\w.$\"]+)\s*\(")

# libcqops b6a — a QRAM INDEX BRACKET. The pass hands every QRAM call whose
# index rail is not 32 bits wide its OWN cast, emitted as four consecutive calls
# (`bracketQramIndexCasts`, ir-pass/src/QramIndexWidth.cpp):
#     %t = call i32 @cq_template_<trunc|sext|zext>_<W>_to_i32(i32 %x)
#     <the cqrt_qram_* call, reading %t in exactly one slot>
#     call void @cq_template_<...>_to_i32_unc(i32 %t, i32 %x)
#     call void @cqrt_free(i32 %t)
# so a forward load/store and its `_unc` read two DIFFERENT bracket rails. Each
# bracket rail is checked as an ordinary minted rail (T1a). For the PAIRING of
# the QRAM call itself, its index operand compares as `<cast sym>(%x)`: the same
# OPERAND-TEXT standard every pairing here applies to a raw index `%x` (the
# forward and the `_unc` read the same register text), lifted through one cast
# that is uncomputed against that same text before anything else runs. Only
# the exact four-call shape is recognised; anything else compares raw and
# fails to pair, never the other way round.
_QRAM_IDX_CAST_RE = re.compile(r"cq_template_(?:trunc|sext|zext)_i\d+_to_i32")
# canonical bracketed index -> the source register it reads. T2 ("forward
# operands unchanged across [mint, reversal]") checks THAT register for a
# bracketed slot: the canonical operand denotes cast(%x), so %x is what must not
# change between the forward and the reversal's own bracket.
_QRAM_IDX_SOURCE = {}


# bd 01po.19 S4 review A-F1: the CURRENT function's handle-array spellings ->
# their canonical cell rail (`window_families`), set per function before its
# streams are analysed. A pairing compares a forward with its `_unc` on the
# ORIGINAL spelling (`cargs`), while every question about WRITES to an operand
# goes through this map to the one rail the array's cells share.
_WINDOW_ALIAS = {}


def pairing_register(v):
    v = _QRAM_IDX_SOURCE.get(v, v)
    return _WINDOW_ALIAS.get(v, v)


def mark_qram_index_brackets(calls):
    for i in range(len(calls) - 3):
        d, q, u, f = calls[i:i + 4]
        if not (d.res and _QRAM_IDX_CAST_RE.fullmatch(d.sym) and
                len(d.vals) == 1):
            continue
        if not q.sym.startswith("cqrt_qram_") or \
                q.sym.startswith("cqrt_qram_alloc_"):
            continue
        slots = [k for k, v in enumerate(q.vals) if v == d.res]
        if len(slots) != 1:
            continue
        if u.res or u.sym != d.sym + "_unc" or u.vals != [d.res, d.vals[0]]:
            continue
        if f.sym != "cqrt_free" or f.vals != [d.res]:
            continue
        k, canon = slots[0], f"{d.sym}({d.vals[0]})"
        _QRAM_IDX_SOURCE[canon] = d.vals[0]
        q.cargs = q.args[:k] + [q.args[k].split()[0] + " " + canon] + \
            q.args[k + 1:]
        q.cvals = q.vals[:k] + [canon] + q.vals[k + 1:]
LABEL_RE = re.compile(r"^([-\w.$]+):")
CALL_RE = re.compile(
    r"^\s*(?:(%[-\w.$]+|%\"[^\"]+\")\s*=\s*)?"
    r"(?:tail\s+|musttail\s+|notail\s+)?call\s+"
    r"(?:[^@()]|\([^()]*\))*?@([\w.$]+|\"[^\"]+\")\s*\(")
TERM_BR_UNCOND_RE = re.compile(r"^\s*br\s+label\s+%([-\w.$]+)\s*$")
TERM_TARGETS_RE = re.compile(r"label\s+%([-\w.$]+)")
TERM_START_RE = re.compile(r"^\s*(br|switch|ret|unreachable|indirectbr|resume)\b")
# An `invoke` is a CALL and a TERMINATOR at once, and this file models neither
# half of it — see the loud refusal in `parse_module`.
INVOKE_RE = re.compile(r"^\s*(?:%[-\w.$]+\s*=\s*)?invoke\b")
# ANY `call` instruction, named callee or not. `CALL_RE` above reads only a
# call to a named `@symbol`, so a call through a FUNCTION POINTER
# (`call void %fp(i32 %b)`) or to INLINE ASM (`call void asm "…", "r"(i32 %b)`)
# used to be dropped by the parser: the rail it took was invisible, and a
# superposing window whose state escaped through it VERIFIED (bd r2j3.3 review
# F3, probe `@indir`). Such a line is now recorded as a call to the sentinel
# `UNNAMED_CALLEE`, which `classify()` does not model (it is not `cqrt_*`), so
# every rule treats it exactly like a named classical call: its operands
# escape, and a light cone that reaches it is refused.
ANY_CALL_RE = re.compile(r"^\s*(?:(%[-\w.$]+|%\"[^\"]+\")\s*=\s*)?"
                         r"(?:tail\s+|musttail\s+|notail\s+)?call\b")
UNNAMED_CALLEE = "<indirect or inline-asm callee>"


def read_terminator(lines, i):
    """(the WHOLE terminator's text, index of the first line after it).

    WHY THIS IS NOT `lines[i].strip()` (bd `t4sw`, P1, 2026-09-18)
    =============================================================
    LLVM prints a `switch` across several lines:

        switch i32 %x, label %out [
          i32 0, label %body
        ]

    so the first line names only the DEFAULT successor. `parse_module` used to
    record exactly that line, and `TERM_TARGETS_RE` then found one target, so
    `fn.succ[%block]` lost every case edge and `fn.preds` lost the matching
    incoming edges. The independent Rule-13 composition round turned that into a
    VERIFY of the one shape rule (T4f) exists to refuse — a rail minted ONCE
    outside a loop and reversed-and-freed PER TRIP inside it, with the loop's
    back edge spelled as a `switch` case (`t4-switch-backedge-k1`). The
    `br i1`-spelled twin of the same module was refused correctly, which is what
    makes it a parser defect rather than a rule defect.

    THE RULE HERE IS BRACKET BALANCE, which is exactly the set of terminators
    LLVM wraps: `switch` and `indirectbr` are the two that open a `[ ... ]`
    operand list, and every other terminator is complete on its first line and
    leaves `depth == 0` so this returns it unchanged. A bracketed TYPE on the
    line (`ret [4 x i32] %v`) balances on that same line and is likewise a no-op.

    It stops at `}` or at a label rather than running to the end of the module,
    so a malformed or truncated block cannot swallow the rest of the function —
    the safe direction, since a terminator that loses targets can only make
    `cyclic_blocks()` under-report, which is the direction that over-accepts.
    ⚠ That is a real residual and it is stated rather than assumed: this reads
    the textual grammar `llvm-as` accepts, and an input that is not that is
    refused-by-truncation, not diagnosed.
    """
    first = lines[i]
    parts = [first.strip()]
    depth = first.count("[") - first.count("]")
    j = i + 1
    while depth > 0 and j < len(lines):
        nxt = lines[j]
        if nxt.startswith("}") or LABEL_RE.match(nxt):
            break
        parts.append(nxt.strip())
        depth += nxt.count("[") - nxt.count("]")
        j += 1
    return " ".join(parts), j


def split_args(s):
    """Split a call's argument text on top-level commas."""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{<":
            depth += 1
        elif ch in ")]}>":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def norm_arg(a):
    """Canonical `(type, value)` for one argument, parameter attributes dropped.

    `i32 noundef %0` -> `i32 %0`; `x86_fp80 0xK3FFE…` -> unchanged. Every symbol
    in the runtime ABI takes scalars only (i32 handles plus classical literals),
    so first-token/last-token is an exact normalisation here — and it is the
    reason a `noundef` on a Phase-6 clone argument does not desynchronise a
    forward from its `_unc` twin.
    """
    toks = a.split()
    if not toks:
        return a
    # A CONSTANT-EXPRESSION argument (`i32 ptrtoint (ptr @u to i32)`,
    # `i32 sub (i32 0, ...)`) is NOT a scalar: first/last-token collapses it to
    # `i32 i32)`, which broke the addc adjoint pairing for symbolic immediates
    # (Inc 2a Rule-13 round, SHOULD-FIX 2). Pass-emitted runtime calls carry no
    # parameter attributes, so for these the exact normalisation is the full
    # text after the type.
    CONSTEXPR_OPS = {"sub", "add", "mul", "xor", "and", "or", "ptrtoint",
                     "inttoptr", "bitcast", "trunc", "zext", "sext",
                     "getelementptr"}
    if len(toks) > 2 and toks[1] in CONSTEXPR_OPS and "(" in a:
        return toks[0] + " " + " ".join(toks[1:])
    return toks[0] + " " + toks[-1]


def arg_value(a):
    toks = a.split()
    return toks[-1] if toks else a


class Call:
    __slots__ = ("line", "res", "sym", "args", "vals", "eff", "text",
                 "ctl_parity", "cargs", "cvals", "window_distinct")

    def __init__(self, line, res, sym, args, text):
        self.line = line
        self.res = res
        self.sym = sym
        self.args = [norm_arg(a) for a in args]
        self.vals = [arg_value(a) for a in args]
        # The operands a forward/reversal PAIRING compares. Equal to args/vals
        # except for a bracketed QRAM index (`mark_qram_index_brackets`).
        self.cargs, self.cvals = self.args, self.vals
        self.eff = None
        self.text = text
        self.ctl_parity = ()   # per-control `cqrt_x` parity at this position
        # bd 01po.19 S5: operand index pairs proven to be DISTINCT cells of one
        # handle array (`window_cells_distinct`); Case B skips exactly these.
        self.window_distinct = frozenset()

    def key(self):
        return (self.sym, tuple(self.args))

    def read_idx(self):
        r = self.eff.reads
        if r == ALL:
            return range(len(self.vals))
        if r == ALL_BUT_0:
            return range(1, len(self.vals))
        return r


class Function:
    def __init__(self, name, params=()):
        self.name = name
        # The formal parameters. A parameter's value ARRIVES FROM OUTSIDE this
        # function, so nothing here can show it is (or is not) a rail handle —
        # a Phase-6 clone's quantum arguments are rails, a loop trip count is
        # classical, and both spell `%0`. `provably_not_a_rail` therefore
        # refuses to vouch for one, the same way `U3-extern-rail` refuses to
        # vouch for a handle minted outside the stream.
        self.params = frozenset(params)
        self.blocks = []          # [(label, [Call], terminator_text)]
        self.succ = {}
        self.preds = {}
        # -- the MEMORY surface (bd 21re) ---------------------------------
        # Only calls are modelled by the rest of this file; these three
        # records exist so `adjudicate_memory` can REFUSE rather than guess
        # when a rail handle travels through memory. `def_op` is every
        # `%x = <opcode> ...` in the function, which is what makes "I cannot
        # resolve this pointer" a decidable question instead of a silence.
        self.def_op = {}          # %name -> (opcode, line_text, line_no)
        self.bank_allocas = set()  # allocas carrying !cq.railbank
        self.window_allocas = set()  # allocas carrying !cq.railwindow (01po.19)
        self.loads = []           # [(line_no, %res, ptr_token, text)]
        self.stores = []          # [(line_no, value_token, ptr_token, text)]
        self.insts = []           # [(line_no, text)] every body line (bd xdu2.4)


def balanced(s, open_at):
    """Index of the `)` matching the `(` at `open_at` (or len(s) if unbalanced)."""
    depth = 0
    for j in range(open_at, len(s)):
        if s[j] == "(":
            depth += 1
        elif s[j] == ")":
            depth -= 1
            if depth == 0:
                return j
    return len(s)


SSA_NAME_RE = re.compile(r"%(?:\"[^\"]+\"|[-\w.$]+)")

# -- the MEMORY surface (bd 21re) -------------------------------------------
# LLVM prints one instruction per line, so these are exact for the grammar
# `llvm-as` accepts; nothing here assumes an ordering or a naming convention
# (Rule 9). A shape NOT matched falls through to "unresolvable", which is the
# safe direction: `adjudicate_memory` refuses on unresolvable, it does not
# assume classical.
RAILBANK_MD = "!cq.railbank"
# bd 01po.19 S4: a HANDLE array of a rolled quantum array. Its cells are rails
# that live in memory between windows; see `window_families`.
RAILWINDOW_MD = "!cq.railwindow"
DEF_OP_RE = re.compile(r"^\s*(%(?:\"[^\"]+\"|[-\w.$]+))\s*=\s*"
                       r"(?:tail\s+|musttail\s+|notail\s+)?(\w+)\b")
GLOBAL_DEF_RE = re.compile(r"^\s*(@[-\w.$]+)\s*=\s*[^=]*?\b(?:global|constant)\b")
STORE_RE = re.compile(r"^\s*store\s+(?:volatile\s+|atomic\s+)*"
                      r"[^,]*?\s([%@][-\w.$]+|[-\w.$]+)\s*,\s*ptr\b")
# The FIRST `ptr <name>` of a line: the pointer operand of a load/store, the
# base of a getelementptr, the source of a bitcast. A CONSTANT-EXPRESSION gep
# (`ptr getelementptr inbounds ([3 x i32], ptr @bank, i64 0, i64 1)`) puts the
# keyword between, and the keyword is not `%`/`@`, so the first match is still
# the underlying object.
PTR_OPERAND_RE = re.compile(r"\bptr\s+(?:nonnull\s+|noundef\s+|dereferenceable\([^)]*\)\s+|"
                            r"align\s+\d+\s+|inbounds\s+)*([%@][-\w.$]+)")
# Opcodes whose result is the SAME underlying object as their pointer operand.
# `select`/`phi`/`inttoptr`/a call result are deliberately NOT here: they are
# unresolvable, and unresolvable is a REFUSAL, not a classical answer.
PTR_FORWARDING_OPS = {"getelementptr", "bitcast", "addrspacecast"}


def first_ptr_operand(line):
    m = PTR_OPERAND_RE.search(line)
    return m.group(1) if m else None


class ModuleFns(list):
    """The function list, plus the module-scope facts `adjudicate_memory` needs.

    A `list` subclass rather than a changed return type on purpose: this
    function's other in-tree caller (tools/record_census/census_common.py:393)
    treats the result as a list of functions and must keep working unchanged.
    """

    def __init__(self, *a):
        super().__init__(*a)
        self.bank_globals = set()   # @globals carrying !cq.railbank


def parse_module(text):
    """Split a .ll into functions -> basic blocks -> calls, with a CFG."""
    funcs = ModuleFns()
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        gm = GLOBAL_DEF_RE.match(lines[i])
        if gm and RAILBANK_MD in lines[i]:
            funcs.bank_globals.add(gm.group(1))
        m = DEFINE_RE.match(lines[i])
        if not m:
            i += 1
            continue
        # Formal parameters: the balanced `(...)` the define's `@name` opens.
        popen = lines[i].index("(", m.end() - 1)
        params = SSA_NAME_RE.findall(lines[i][popen + 1:balanced(lines[i],
                                                                 popen)])
        fn = Function(m.group(1), params)
        i += 1
        cur_label, cur_calls, term = "%__entry", [], ""
        while i < len(lines) and lines[i] != "}":
            ln = lines[i]
            lm = LABEL_RE.match(ln)
            if lm:
                fn.blocks.append((cur_label, cur_calls, term))
                cur_label, cur_calls, term = "%" + lm.group(1), [], ""
                i += 1
                continue
            # -- the MEMORY surface (bd 21re), recorded for EVERY instruction --
            fn.insts.append((i + 1, ln))
            dm = DEF_OP_RE.match(ln)
            if dm:
                fn.def_op[dm.group(1)] = (dm.group(2), ln, i + 1)
                if dm.group(2) == "alloca" and RAILBANK_MD in ln:
                    fn.bank_allocas.add(dm.group(1))
                if dm.group(2) == "alloca" and RAILWINDOW_MD in ln:
                    fn.window_allocas.add(dm.group(1))
                if dm.group(2) == "load":
                    fn.loads.append((i + 1, dm.group(1),
                                     first_ptr_operand(ln), ln.strip()))
            sm = STORE_RE.match(ln)
            if sm:
                # The POINTER operand is after the first comma. Taking the
                # line's first `ptr <name>` would pick up the stored VALUE for
                # `store ptr %h, ptr %p`.
                fn.stores.append((i + 1, sm.group(1),
                                  first_ptr_operand(ln.split(",", 1)[1]),
                                  ln.strip()))
            cm = CALL_RE.match(ln)
            if cm:
                open_at = ln.index("(", cm.end() - 1)
                j = balanced(ln, open_at)
                cur_calls.append(Call(i + 1, cm.group(1),
                                      cm.group(2).strip('"'),
                                      split_args(ln[open_at + 1:j]), ln.strip()))
            elif ANY_CALL_RE.match(ln):
                # An indirect or inline-asm call (see `ANY_CALL_RE`). Its
                # operands are every SSA name after the `call` keyword — the
                # callee pointer included, which is harmless: it is never a
                # rail name. Over-collecting is the safe direction here.
                am = ANY_CALL_RE.match(ln)
                cur_calls.append(Call(i + 1, am.group(1), UNNAMED_CALLEE,
                                      SSA_NAME_RE.findall(ln[am.end():]),
                                      ln.strip()))
            elif INVOKE_RE.match(ln):
                # bd `t4sw` F-1's neighbour, and it is refused rather than
                # half-parsed. An `invoke` is BOTH a call and a terminator, and
                # this file models NEITHER half of it: `CALL_RE` requires
                # `call`, so an `invoke`d `cqrt_*` never enters the effect model
                # at all, and `TERM_START_RE` does not list it, so its `to` /
                # `unwind` edges never enter `fn.succ` — which would make
                # `cyclic_blocks()` answer "acyclic" for a block that plainly
                # branches, the exact (T4f) defeat F-1 found through `switch`.
                # Two unsound halves, so the model cannot render a verdict about
                # the module (the `Unclassified` discipline, one layer out).
                # MEASURED: the only two `invoke`s in the tree are in
                # `lowering_reject_intrinsic_invoke_phi.ll` and
                # `spec_reject_eh.ll`, BOTH of which the pass declines, so no
                # lowered module reaches here with one and this costs nothing
                # today.
                raise Undecidable(
                    "P1-invoke-is-a-call-and-a-terminator", fn.name, i + 1,
                    f"`{ln.strip()}` is an `invoke`. This file models calls via "
                    f"`CALL_RE` (which requires `call`) and successors via the "
                    f"terminator text, and an `invoke` is BOTH — so its callee's "
                    f"read/write effects and its `to`/`unwind` edges are both "
                    f"invisible here. A block whose successors are unknown would "
                    f"be read as ACYCLIC by `cyclic_blocks()`, which is what "
                    f"rule (T4f) rests on. Model the invoke before trusting any "
                    f"verdict from this file")
            elif TERM_START_RE.match(ln):
                # ⚠ MULTI-LINE. Do NOT go back to `term = ln.strip()`: LLVM
                # prints a `switch`'s case targets on the lines AFTER its first,
                # so the first line alone names only the DEFAULT successor. That
                # was a P1 (bd `t4sw`, the 2026-09-18 composition Rule-13 round):
                # `fn.succ` lost every case edge, `cyclic_blocks()` could not see
                # a `switch` BACK EDGE, and (T4f) — the conjunct whose whole job
                # is to refuse the K:1 "minted once, reversed-and-freed per trip"
                # shape — VERIFIED it. `fn.preds` was incomplete the same way,
                # and `build_streams` merges blocks on a single-predecessor test.
                term, i = read_terminator(lines, i)
                continue
            i += 1
        fn.blocks.append((cur_label, cur_calls, term))
        for _, blk_calls, _ in fn.blocks:
            mark_qram_index_brackets(blk_calls)
        for label, _, t in fn.blocks:
            tgt = ["%" + x for x in TERM_TARGETS_RE.findall(t)]
            fn.succ[label] = tgt
            fn.preds.setdefault(label, [])
            for x in tgt:
                fn.preds.setdefault(x, []).append(label)
        funcs.append(fn)
        i += 1
    return funcs


def build_streams(fn):
    """Maximal single-pred / unconditional-successor block chains.

    A stream is a run of blocks whose concatenation is a valid linear execution
    trace: Bi ends in `br label %B(i+1)` and B(i+1)'s only predecessor is Bi.
    """
    by_label = {lbl: (lbl, calls, t) for lbl, calls, t in fn.blocks}
    consumed, streams = set(), []
    for lbl, calls, t in fn.blocks:
        if lbl in consumed:
            continue
        chain, cur_t = [lbl], t
        consumed.add(lbl)
        while True:
            m = TERM_BR_UNCOND_RE.match("  " + cur_t)
            if not m:
                break
            nxt = "%" + m.group(1)
            if nxt in consumed or nxt not in by_label:
                break
            if fn.preds.get(nxt, []) != [chain[-1]]:
                break
            chain.append(nxt)
            consumed.add(nxt)
            cur_t = by_label[nxt][2]
        merged = []
        for c in chain:
            merged.extend(by_label[c][1])
        streams.append((chain, merged))
    return streams


# ---------------------------------------------------------------------------
# THE CROSS-STREAM INDEX — the whole-FUNCTION rail facts rule (T4) needs
# (bd test_C_libtooling-j31l / the 2026-09-18 Group-1 P2 loop-EXIT anchor).
#
# Everything else in this file reasons inside ONE stream, because a stream is
# the only place execution order is knowable without a simulator. (T4) does not
# relax that: it reasons about a rail whose write history is a SINGLETON over
# the whole function, which is a PATH-INSENSITIVE fact and therefore true on
# every path, however the blocks between the mint and the free are ordered.
#
# So this index answers exactly four questions, all of them quantified over the
# WHOLE function and none of them over an execution order:
#   * where was `%h` minted, and by what?      (`mint`)
#   * what writes `%h` — ANYWHERE?             (`writes`)
#   * how many `cqrt_free(%h)` sites are there? (`frees`)
#   * can this block execute more than once?   (`cyclic_blocks`)
# The first three are keyed by SSA name and carry `(stream id, position)` so
# (T4g) can place a write relative to the mint and the reversal WITHOUT ever
# ordering two different streams against each other — it only ever compares two
# positions INSIDE one stream, which is the one comparison this file's model
# licenses.
#
# THE WRITE MODEL IS `StreamAnalysis.run`'s, COPIED IN ITS EXACT SPELLING and
# not re-derived (Rule 14 — one spelling of one population): a write is a
# non-`diagonal` Effect write slot, a `cqrt_measure_<W>` counts as one, and a
# `cqrt_free` counts as none. If that rule moves in `run()` it must move here in
# the same change, or (T4c) starts proving a rail is untouched while the stream
# model says it was written. There is a committed mutant for exactly that
# divergence (`t4-write-model-drift`, tools/free_pairing_check_test.py).
# ---------------------------------------------------------------------------


class CrossStreamIndex:
    """Whole-function rail facts, computed once per function.

    `classify()` may raise `Unclassified` from here rather than from the stream
    scan; that is the same loud stop one step earlier, exactly as
    `check_module`'s mint scan already does.
    """

    __slots__ = ("fn", "streams", "mint", "writes", "frees", "_cyclic")

    def __init__(self, fn, streams):
        self.fn = fn
        self.streams = streams
        self.mint = {}        # %name -> (sid, pos, Call, Effect)
        self.writes = {}      # %name -> [(sid, pos, Call)]
        self.frees = {}       # %name -> [(sid, pos, Call)]
        self._cyclic = None
        for sid, (_chain, calls) in enumerate(streams):
            for pos, c in enumerate(calls):
                eff = classify(c.sym)
                if eff is None:
                    continue
                if eff.role == "free":
                    if c.vals:
                        self.frees.setdefault(c.vals[0], []).append((sid, pos, c))
                    continue
                if c.res and eff.mints == "rail":
                    # SSA gives uniqueness for free: a value is defined once.
                    self.mint[c.res] = (sid, pos, c, eff)
                if eff.diagonal:
                    continue      # `run()`'s own test: a diagonal gate relabels
                for wi in eff.writes:                        # nothing, so it is
                    if wi < len(c.vals):                     # not a write here
                        self.writes.setdefault(c.vals[wi],
                                               []).append((sid, pos, c))

    def cyclic_blocks(self):
        """Block labels reachable from THEMSELVES, i.e. able to execute twice.

        Computed LAZILY and memoised: nothing asks for it unless a (T4)
        candidate exists, which on the 2026-09-18 corpus is a handful of
        modules. A self-loop latch (`br i1 %c, label %3, label %1` in block %3)
        is caught because `%3 in succ[%3]`, so the seeding is over SUCCESSORS
        rather than over `{start}`.
        """
        if self._cyclic is not None:
            return self._cyclic
        succ, out = self.fn.succ, set()
        for start in succ:
            seen, work = set(), list(succ.get(start, ()))
            while work:
                b = work.pop()
                if b in seen:
                    continue
                seen.add(b)
                work.extend(succ.get(b, ()))
            if start in seen:
                out.add(start)
        self._cyclic = out
        return out

    def stream_runs_at_most_once(self, sid):
        """No block of stream `sid` can execute twice.

        Checked over EVERY block of the chain, not just its head. A stream's
        non-head blocks have a single predecessor by construction, so a cycle
        through one of them has to come back through the head — but that is an
        argument about `build_streams`, and this is a Rule-6 gate, so the
        property is CHECKED rather than inherited.
        """
        cyc = self.cyclic_blocks()
        return not any(b in cyc for b in self.streams[sid][0])


# ---------------------------------------------------------------------------
# Numeric helpers for adjoint matching (negated angle / negated immediate).
# ---------------------------------------------------------------------------

def _hex_neg(a, b):
    """LLVM hex float payloads: negation flips the SIGN (top) bit.

    Covers `0x…` (double, 16 nibbles), `0xK…` (x86_fp80, 20), `0xL…` (fp128,
    32) and `0xH…` (half, 4) — for each the sign bit is bit 4*len-1. `0xM…`
    (ppc_fp128) is deliberately NOT handled: its negation touches both member
    doubles, so falling through to "not a negation" over-declines, which is the
    safe direction. The pass emits `cqrt_rz`/`cqrt_ry` angles as `double`, so
    this path only fires on hand-written or future wider-angle IR.
    """
    for pre in ("0xK", "0xL", "0xH", "0x"):
        if a.startswith(pre) and b.startswith(pre):
            ha, hb = a[len(pre):], b[len(pre):]
            if len(ha) != len(hb) or not ha or not hb:
                return False
            try:
                va, vb = int(ha, 16), int(hb, 16)
            except ValueError:
                return False
            return va ^ vb == 1 << (4 * len(ha) - 1)
    return False


# ---------------------------------------------------------------------------
# bd 1739 HOLE 2 — A TEXTUAL OPERAND MATCH IS NOT A VALUE MATCH WHEN THE TEXT
# IS `undef`/`poison`.
#
# Every pairing proof in this file establishes "the reversal undoes the
# forward" by comparing OPERAND TEXT: (T1a) `tuple(w.args[1:]) == fwd_args`,
# (T1b) the `_inv` pool keyed on `(base, fwd_args)`, and `adjoint_matches`'
# three arms. `undef` is the one token in LLVM's grammar that DOES NOT DENOTE A
# VALUE: LangRef lets each USE of it materialise independently, and at the -O0
# stage-3 link they do. So
#
#     cq_template_icmp_sgt_i32_hl(h0, undef)      -> h4
#     cq_template_icmp_sgt_i32_hl_unc(h4, h0, undef)
#
# is a structurally perfect pair whose adjoint inverts a DIFFERENT predicate,
# leaving h4 dirty at its `cqrt_free` — and the checker reported
# `1 verified, 0 violation(s)`, exit 0 (probes/j1739_undef_pairing.ll). The
# runtime prints both slots as bare decimals, so the GOLDEN TRACE cannot see it
# either; this is bd bu96 / bd xy9n, the pairing break the pass's own
# `LiteralIntegrity::declineUnpairedUndefLiterals` exists to refuse. A module
# reaching this file with one is a module where that guard did not fire.
#
# ⚠ SCOPE, AND IT IS NARROW ON PURPOSE. This refuses a PAIRING proof, never a
# value. It is deliberately NOT applied to:
#   * a `cqrt_alloc_<W>(undef)` SEED — rule (A1)/(A2) rest on the rail holding
#     *a* classical basis state, not on knowing WHICH, and an unentangled rail
#     in an unknown-but-definite basis state is still a sound reset. That slot
#     is also the one shipped occurrence in the whole corpus (MEASURED: 1 of
#     368 lowered e2e slices carries `undef` in any modelled-call operand, and
#     it is `%selop = call i32 @cqrt_alloc_f64(double undef)` in
#     slice_libm_ld80_nexttoward — bd u7z9's blessed precedent), which is why
#     this fix moves ZERO shipped verdicts.
#   * rule (A1)'s classical-immediate slot, for the same reason.
# What it does refuse is any place where "these two operands are the same
# value" is the LOAD-BEARING STEP of a proof.
UNDEF_TOKEN_RE = re.compile(r"\b(?:undef|poison)\b")


def carries_undef(arg):
    """Does this operand's text contain `undef`/`poison` (constexprs included)?"""
    return bool(UNDEF_TOKEN_RE.search(arg))


def is_negation(a, b):
    """True iff argument strings `a` and `b` are `x` and `-x`.

    Three spellings beyond the plain decimal, each added when a REAL emitted
    form failed to pair (Inc 2a Rule-13 round, SHOULD-FIX 2 — the checker is
    the only gate that can witness "freed at |0>", so a pairing it cannot read
    is lost coverage, not a cosmetic):
      * `i1 true`/`i1 true` — the addc immediate at width 1: -1 == 1 (mod 2),
        so the adjoint re-emits the SAME boolean (`false` likewise, -0 == 0).
        float("true") used to raise and silently return False.
      * `<ty> sub (<ty> 0, X)` vs `<ty> X` — the adjoint of a symbolic
        (constant-expression) immediate is spelled as an explicit constexpr
        negation; token-count comparison used to fail it.
      * hex (`0x...`) — pre-existing, via `_hex_neg`.
    """
    if a == b and a.split()[0] == "i1" and a.split()[-1] in ("true", "false"):
        return True
    ta, tb = a.split(), b.split()
    if len(ta) >= 2 and len(tb) >= 2 and ta[0] == tb[0]:
        ty = ta[0]
        ea = a[len(ty):].strip()
        eb = b[len(ty):].strip()
        # The inner operand of the constexpr repeats its own type, so the
        # adjoint of forward-arg `a` ("<ty> X") is spelled "<ty> sub (<ty> 0, <ty> X)".
        if eb == "sub (%s 0, %s)" % (ty, a) or ea == "sub (%s 0, %s)" % (ty, b):
            return True
    if len(ta) < 2 or len(tb) < 2 or ta[:-1] != tb[:-1]:
        return False
    va, vb = ta[-1], tb[-1]
    if va.lower().startswith("0x") or vb.lower().startswith("0x"):
        return _hex_neg(va, vb)
    try:
        na = float(va) if ("." in va or "e" in va.lower()) else int(va)
        nb = float(vb) if ("." in vb or "e" in vb.lower()) else int(vb)
    except ValueError:
        return False
    return na == -nb


# ---------------------------------------------------------------------------
# The analysis.
# ---------------------------------------------------------------------------

def _outward(seq, i):
    """The members of the strictly increasing `seq` other than `seq[i]`,
    nearest to `seq[i]` first, a tie going to the EARLIER one — the order
    `sorted(..., key=lambda x: (abs(x - seq[i]), x))` gives, produced by a
    two-pointer merge so a caller that stops early pays only for what it read
    (`_phase_closed`, bd r2j3.4 review F4)."""
    q, lo, hi = seq[i], i - 1, i + 1
    while lo >= 0 or hi < len(seq):
        if hi >= len(seq) or (lo >= 0 and q - seq[lo] <= seq[hi] - q):
            yield seq[lo]
            lo -= 1
        else:
            yield seq[hi]
            hi += 1


VIOLATION = "VIOLATION"    # demonstrably unsound
UNPROVEN = "UNPROVEN"      # outside the structural proofs this file can give
# The common tail of every light-cone refusal (bd r2j3.3); the selftest keys on it.
LC_OPEN = "light cone is left open"
# Memo-key tag of the LABEL-ONLY reduction (`reduces_to_identity(cone=False)`,
# bd r2j3.4 review F1): the severity callers' predicate, never a proof.
LABELS_ONLY = "labels-only"


class Finding:
    def __init__(self, kind, code, fn, line, handle, msg):
        self.kind, self.code, self.fn = kind, code, fn
        self.line, self.handle, self.msg = line, handle, msg
        self.path = None

    def __str__(self):
        return (f"{self.kind} {self.code} @{self.fn} line {self.line} "
                f"[{self.handle}]: {self.msg}")


class Rail:
    __slots__ = ("name", "kind", "origin", "pos", "writes", "measured_at")

    def __init__(self, name, kind, origin, pos):
        self.name, self.kind = name, kind
        self.origin, self.pos = origin, pos
        self.writes = []          # [(pos, Call)] basis-changing, stream order
        self.measured_at = None


class StreamAnalysis:
    def __init__(self, fnname, calls, module_defs, params=frozenset(),
                 rail_defs=frozenset(), recorded=frozenset(),
                 xstream=None, stream_id=-1):
        self.fnname, self.calls = fnname, calls
        self.module_defs = module_defs
        # (T4): the whole-function rail index, and WHICH stream this is inside
        # it. Both default to "absent", and with them absent this class behaves
        # exactly as it did before the rule existed — which is what lets the
        # selftest construct a StreamAnalysis directly without one.
        self.xstream = xstream
        self.stream_id = stream_id
        self.params = params
        self.rail_defs = rail_defs
        # bd 261j(b): names correlated with a kept output carrier. Computed per
        # FUNCTION, not per stream — a tape write in another block still records.
        self.recorded = recorded
        self.rails = {}
        self.findings = []
        self.verified = self.sites = 0
        self.inv_pool = {}          # (base, args) -> [positions]
        self.inv_claimed = set()
        self.freed_names = {}
        self.x_parity = {}          # register -> `cqrt_x` count so far
        self._stable_memo = {}      # (name, lo, hi) -> (ok, witness lines)
        self._stable_active = set()  # queries currently being computed
        self._co_written_memo = {}   # (v, p1, p2, id(c1)) -> (ok, lines)
        self._co_written_active = set()   # ditto, the co-written edge
        self._cone_memo = {}         # (target, p1, p2) -> (ok, lines, why)
        self._cone_active = set()    # ditto, the light-cone edge (r2j3.3)
        self._minted_core_memo = {}  # (rail, mint pos, rev pos) -> why|None
        self.proofs = []            # [(fn, free_line, handle, rule, lines)]
        # bd 1739 hole 2: adjoint pairs refused because their operand match was
        # `undef`/`poison` TEXT rather than a value. Kept so the free site can
        # name the reason (`A-undef-literal-pairing`) instead of reporting an
        # ordinary unpairable history.
        self.undef_refused = []

    # -- main scan ---------------------------------------------------------
    def run(self):
        for pos, c in enumerate(self.calls):
            c.eff = classify(c.sym)
            if c.eff is None:
                continue
            e = c.eff
            self.check_case_b(c)
            for v in c.vals:
                if v in self.freed_names and e.role != "free":
                    self.add(VIOLATION, "F2-use-after-free", c, v,
                             f"@{c.sym} uses {v} after its cqrt_free at line "
                             f"{self.freed_names[v]}")
            # Parity MOD 2 — `cqrt_x` is an involution, so only the polarity of
            # the flag at this point matters, not how many brackets deep it is.
            c.ctl_parity = tuple(self.x_parity.get(c.vals[i], 0) & 1
                                 for i in e.controls if i < len(c.vals))
            if e.role == "free":
                self.sites += 1
                self.check_free(pos, c)
                continue
            if e.role == "measure":
                r = self.rail_for_write(c.vals[0])
                r.measured_at = c.line
                r.writes.append((pos, c))
                continue
            if e.role == "inv":
                self.inv_pool.setdefault((e.base, tuple(c.cargs)),
                                         []).append(pos)
            if not e.diagonal:
                for wi in e.writes:
                    if wi < len(c.vals):
                        self.rail_for_write(c.vals[wi]).writes.append((pos, c))
            if c.sym == "cqrt_x":
                self.x_parity[c.vals[0]] = self.x_parity.get(c.vals[0], 0) + 1
            if e.mints in ("rail", "array", "tape") and c.res:
                kind = {"rail": "alloc" if e.role == "alloc" else "mint",
                        "array": "array", "tape": "tape"}[e.mints]
                self.rails[c.res] = Rail(c.res, kind, c, pos)
        self.check_orphan_reversals()
        return self.findings

    def check_orphan_reversals(self):
        """Every `_inv` must be claimed by exactly one free.

        An `_inv` is the ONLY construct in the lowered IR that writes a rail the
        signature does not name (bd 8txa). If no free claims it, this file
        cannot say which rail it acted on — and one extra adjoint on a live rail
        is precisely the "re-paired to the wrong rail" defect the golden trace
        is blind to. The old "exact bijection (25174 tokens, 25174 claims)"
        justification is STALE — since bd 8txa moved the compare flag-strip to
        the void `_unc` ABI the ship floor emits ZERO `_inv` (re-measured over
        all 237 slices, 2026-07-31), so this rule's only live exercise is the
        selftest's historical fixtures. It stays because an `_inv` is still the
        one construct whose target the ABI does not name, so if one ever comes
        back an orphan is still a real signal — but do not cite corpus counts
        for it.
        """
        for positions in self.inv_pool.values():
            for p in positions:
                if p in self.inv_claimed:
                    continue
                c = self.calls[p]
                self.add(UNPROVEN, "W-orphan-reversal", c, c.res or "<void>",
                         f"`{c.text}` is an adjoint no cqrt_free claims; the "
                         f"ABI does not name the rail it acts on, so the rail "
                         f"it left (or dirtied) cannot be identified here")

    def rail_for_write(self, name):
        """The record for `name`, materialising an EXTERN one if it was not
        minted in this stream.

        Without this, a write to a handle that arrives from outside (a Phase-6
        clone parameter, a rail defined in another block) would be INVISIBLE:
        `unchanged_over` would report the operand stable because it had no
        recorded writes, and `commutes` would take a flag's `cqrt_x` parity at
        face value while a `cnot` retargeted it. Recording externs makes the
        in-stream write history complete for every handle, so "no writes here"
        is a fact rather than an absence of information. An extern rail can
        never be VERIFIED at a free (its incoming state is unknown) — see
        `U3-extern-rail`.
        """
        r = self.rails.get(name)
        if r is None:
            r = Rail(name, "extern", None, -1)
            self.rails[name] = r
        return r

    # -- CASE B: an input aliasing a rail the gate WRITES (bd 6f3o) ---------
    def check_case_b(self, c):
        """No emitted gate may take an INPUT that aliases a rail it WRITES.

        THE PARTITION (bd big5, 2026-07-31). For every gate, ask: can an input
        operand alias a rail the gate writes?

          CASE A — aliased INPUTS, output a FRESH |0> rail. REALIZABLE, ALLOWED,
            and NOT flagged here. The generated ABI's out-of-place shape is
            `out(fresh |0>) ^= f(in0, in1)`; aliasing the inputs gives
            `out ^= g(a)` with `g(a) := f(a, a)`, and `(a, 0) -> (a, g(a))` is
            the standard reversible embedding of a classical function — unitary
            for ANY `g`. Realizability is UNCONDITIONAL; aliasing only changes
            COST. 638 calls across 27 template symbols in the committed corpus
            are Case A (`cq_template_fmul_f64(%h, %h)` — `x*x`), plus 15 `_unc`
            twins of the same shape (`..._unc(%out, %h, %h)`). All must stay
            silent, so this rule compares inputs against WRITE slots only and
            never against each other.

          CASE B — an input aliases a rail the gate WRITES. NOT realizable:
            `cswap(c, c, b)` sends both |1,0> and |0,1> to |0,1>, which is not
            injective, so no unitary implements it. A backend handed one cannot
            honour the ABI contract.

        The write-sets come straight from `classify()`, so this rule needs no
        per-symbol table of its own: `cnot(c,t)` writes t, `toffoli(c1,c2,t)`
        writes t (c1==c2 is Case A), `cswap(f,x,y)` writes BOTH x and y,
        `copy_W(s,d)` writes d, `copy_W_controlled(f,s,d)` writes d, a
        `cq_template_OP_W(ins)` writes NO operand (it returns a fresh rail), and
        `cq_template_OP_W_unc(out, ins...)` writes out.

        A `classical_imm` slot counts as an input here: `xorc(%r, %r)` is Case B
        exactly as `cnot(%r, %r)` is. A slot that is BOTH read and written by
        the same index is an in-place update, not aliasing (`measure(%h)`), and
        is skipped.
        """
        e = c.eff
        ws = [i for i in e.writes if i < len(c.vals)]
        if not ws:
            return
        ins = sorted(set(c.read_idx()) | set(e.classical_imm))
        for wi in ws:
            for ri in ins:
                if ri == wi or ri >= len(c.vals) or c.vals[ri] != c.vals[wi]:
                    continue
                if (ri, wi) in c.window_distinct:
                    continue  # two proven-distinct cells (bd 01po.19 S5).
                self.add(VIOLATION, "B1-input-aliases-written-rail", c,
                         c.vals[wi],
                         f"`{c.text}`: operand {ri} aliases operand {wi}, a "
                         f"rail @{c.sym} WRITES. An input that aliases a "
                         f"written rail is CASE B — not a unitary, so no "
                         f"backend can realize it (aliased inputs with a fresh "
                         f"output, CASE A, are allowed and not flagged)")
                return
        for a in range(len(ws)):
            for b in range(a + 1, len(ws)):
                if c.vals[ws[a]] != c.vals[ws[b]]:
                    continue
                self.add(VIOLATION, "B2-two-written-rails-alias", c,
                         c.vals[ws[a]],
                         f"`{c.text}`: operands {ws[a]} and {ws[b]} are the "
                         f"same rail and @{c.sym} WRITES BOTH through two "
                         f"distinct write ports, which is outside the ABI "
                         f"contract. Note this one is DEGENERATE rather than "
                         f"non-unitary — `cqrt_cswap(f,x,x)` is the identity, "
                         f"so it is flagged because no router can have meant "
                         f"it, not because no backend could run it")
                return

    # -- is an operand PROVABLY not a rail handle? (bd az1h) ---------------
    def provably_not_a_rail(self, v):
        """Can this file SHOW that operand value `v` is not a rail handle?

        `classify()` records which slots the ABI DECLARES classical, but a
        declaration is not an observation: at W=i32 both `cqrt_xorc_i32`
        parameters are `int32_t`, so a rail handle in the immediate slot is
        verify-clean, and the runtime prints that slot as a bare decimal, so
        the golden trace renders rail h13 as `13`. Both gates are blind on the
        SAME axis — which is why the assertion has to be CHECKED here.

        Answers True only on positive evidence:
          * a literal constant (no `%`), or
          * an SSA value that is neither a known rail nor a formal parameter
            nor the result of a rail-minting call anywhere in THIS FUNCTION —
            i.e. a plain classical instruction result (`sub i32 0, %k`, a
            counter `phi`) or a classical call result such as `cqrt_measure_W`.

        RE-MEASURED 2026-08-28 over the 250-slice corpus, after M-C batches
        2a+2b (bd test_C_libtooling-6uqc) put `cqrt_addc_<W>` on straight-line
        rails: there are now 213 `addc`/`xorc` CALL sites (177 with a literal
        immediate, 36 with an SSA one), up from 41 (11 + 30) when this rule was
        written against the 237-slice corpus. EVERY ONE of the 36 is a plain
        classical instruction result — 22 `sub i32 0, %v` (the negation
        `EmitInverse` emits for an `addc` adjoint, and since 2b the one M-C
        emits FORWARD for `q - c`), 10 `add` (the `break` index rail's counter),
        and 4 `load volatile i32, ptr @off` (2a, the seq-grover reassignment
        immediate). So this still answers True for all 213 and rule (A1) still
        discharges every site it used to.

        The `load` class arrived with 2a and is worth naming because it is NOT
        "integer arithmetic" as the original wording had it: it qualifies on the
        rule's actual ground, which is that the value is neither a known rail,
        nor a formal parameter, nor a rail-minting call result IN THIS FUNCTION.

        ⚠ THE JUSTIFICATION THIS PARAGRAPH USED TO CARRY IS FALSE AND HAS BEEN
        REMOVED FROM THE SOURCE, NOT JUST FROM THE RECORD (bd 21re, and
        CLAUDE.md L7-with-a-twist: a record correction that is not applied to
        the source is not a correction). It read:

            "A handle cannot reach a global and come back — a tainted `store`
             is a loud decline at `declineTaintEscapes` long before lowering —
             so a load result is not a rail."

        bd `xdu2` (L-1a, the bounded rail ARRAY) exists precisely to remove that
        decline: `bool b[N]` is carved into an `[N x i32]` bank of HANDLES, and
        a load from a bank cell IS a rail. The premise is now a CHECK rather
        than an assumption, and it lives in `adjudicate_memory`, which runs
        before this predicate is ever asked: a rail stored to memory that
        carries no `!cq.railbank` marker is a LOUD STOP, and a load that
        resolves INTO a marked bank is folded into `rail_defs`, so this
        function answers False for it at the third arm below. What survives of
        the old sentence is only its narrow, measured consequence — the 4
        `load volatile i32, ptr @off` corpus sites still answer True, because
        `@off` is not a bank and no rail is stored into it.

        (213, not 224: a `grep -c` over the corpus also counts the `declare`
        prototype lines. And no immediate is a `phi` DIRECTLY — the loop counter
        reaches the slot through an `add` — so do not cite one.)
        """
        if not v.startswith("%"):
            return True                              # a literal constant
        if v in self.rails:
            return False       # minted in, or written in, this stream
        if v in self.params:
            return False       # arrives from outside; nothing here can vouch
        if v in self.rail_defs:
            return False       # rail minted elsewhere in this function
        return True

    def add(self, kind, code, c, handle, msg):
        self.findings.append(Finding(kind, code, self.fnname, c.line, handle,
                                     msg))

    def ok(self, c, r, rule, witness):
        """Record a discharged free site plus the lines its proof consumed.

        `r.origin` is None for an EXTERN rail — the mint is in another stream,
        so this record cannot reach for it. Rule (T4) puts the mint's line into
        its own witness set instead, which is what keeps the proof-targeted
        sweep able to blank it.
        """
        self.verified += 1
        origin = {r.origin.line} if r.origin is not None else set()
        self.proofs.append((self.fnname, c.line, r.name, rule,
                            tuple(sorted(set(witness) | origin))))

    # -- reduction to identity --------------------------------------------
    def writes_in(self, name, lo, hi):
        r = self.rails.get(name)
        return [] if r is None else [(p, c) for p, c in r.writes if lo < p < hi]

    def unchanged_over(self, name, lo, hi, cone=True):
        """(ok, witness lines) — `name`'s writes inside (lo, hi) net to identity.

        WHY THERE IS NO STEP BUDGET HERE (bd test_C_libtooling-xzdx, 2026-08-08)
        ----------------------------------------------------------------------
        There used to be a `depth > 6` cut-off, and it was UNSOUND IN THE MEMO:
        the cache is keyed `(name, lo, hi)` with no depth, so a `False` produced
        by exhausting the budget deep in one recursion was served to a later,
        SHALLOWER query for the same interval that had budget to succeed. The
        cache outlives the free site (it is per STREAM), so the artefact leaked
        ACROSS free sites and the verdict came to depend on the ORDER of the
        `cqrt_free` calls. The committed demonstration is the two PAIRS in
        `ORDER_PAIRS`, tools/free_pairing_check_test.py — `xzdx-ladder-d7-*`
        (16 gates, hand-explainable) and `xzdx-ticket-repro-*` (the ticket's own
        18-gate find). Each pair is one stream written twice with the frees in a
        different order, and the OLD tool split both: 0 of 2 sites verified
        versus 2 of 2 for the ladder, 1 of 3 versus 3 of 3 for the repro.
        The direction was always safe (an artefact `False` over-declines, never
        over-accepts), but a GATE whose answer moves when you move a free is a
        gate people route around with `--allow-unproven`.

        The budget is gone rather than depth-keyed because IT WAS NEVER WHAT
        MADE THIS TERMINATE. Every recursive edge STRICTLY NARROWS the position
        interval, and the interval is a pair of integer stream positions:

          * `unchanged_over(name, lo, hi)` reduces exactly `writes_in(name, lo,
            hi)`, whose members satisfy `lo < p < hi` STRICTLY (the comparison
            is `lo < p < hi`, not `<=`), and it does not widen `(lo, hi)`.
          * `reduces_to_identity` only ever pairs two of those members, an
            earlier `pk` against a later `p`, so any interval it hands down
            satisfies `lo < pk < p < hi`.
          * `pair_operands_unchanged(c1, p1, p2, …)` passes exactly that pair
            down, to `unchanged_over(v, p1, p2)` and to `co_written_stable(v,
            p1, p2, …)`, and the latter reduces a SUBSET of `writes_in(v, p1,
            p2)` — the complementary-branch filter only removes members.
          * the three entry points (`check_alloc_rail`, the two in
            `check_minted_rail`) start from a write list drawn the same strict
            way, from `(r.pos, pos)` or `(r.pos, rev_pos)`.

        So `hi - lo` strictly decreases by at least 2 down every edge and is
        bounded below by 0: the recursion is at most `(hi - lo) / 2` deep and
        cannot cycle, for ANY input, including adversarial ones. MEASURED on the
        237-slice corpus (2026-08-08): the recursion nests at most 3 frames deep
        — a `depth` of 2 in the units the deleted budget used, which refused at 7
        — so the budget was hit ZERO times and removing it moves no corpus
        verdict; it only removes the artefact.

        The re-entry check below is therefore an ASSERTION on that argument, not
        a policy: it can only fire if a future edit adds an edge that does not
        narrow, and it fires LOUDLY (see `NarrowingViolation`) instead of
        answering `False`, because a silent `False` is the very bug this
        replaced. It has never fired. `co_written_stable` carries the SAME
        assertion, and it has to: they are the two edges that re-enter the
        reduction, and a tripwire on only one of them is not a tripwire. That
        is not a hypothetical — it is what the arm-kill probe found. Weakening
        `writes_in` to `lo <= p <= hi` (the one-character way to break
        narrowing) sends every committed fixture carrying a `cqrt_cswap` route
        pair — 7 of the 19 as of 2026-08-08, a count that moves whenever
        fixtures are added — into an unbounded `co_written_stable` recursion
        that this check never sees, so with the guard here alone they died on
        `RecursionError` instead of naming the broken invariant. The converse
        also holds and is why BOTH assertions ship: that same probe leaves the
        guard here untouched, and killing it needs the committed mutant
        `case-b-self-aliased-cnot-aka-the-narrowing-probe` (no `cqrt_cswap`, so
        the co-written edge is never entered).

        THE MEMO IS SOUND WITH NO DEPTH IN THE KEY, which is the other half of
        the fix, and the cache is shared by every free site in the stream — so
        "pure function of `(name, lo, hi)`" has to hold ACROSS sites, while
        `run()` is still mutating the analysis between them. Three reads matter:

          * `Rail.writes`, via `writes_in`. Every query a free site at position
            `pos` issues has `hi <= pos`, and `run()` appends a write when it
            scans it, so every write inside `(lo, hi)` was already appended
            before that site was checked. The list can grow later; the WINDOW
            cannot gain a member.
          * `self.rails` MEMBERSHIP, which the scan grows — `rail_for_write`
            materialises an extern record the first time a handle is written.
            `pair_operands_unchanged` skips an operand that is `not in
            self.rails`, but an operand with a write inside `(p1, p2)` was
            written before `p2 < hi <= pos`, so it is already present whenever
            skipping it could change anything; a later-materialised record can
            only carry writes at positions past the window.
          * the same membership test inside `commutes`, which is the one that
            looks dangerous — it declines the complementary-branch claim for a
            register this stream has never seen, and a later site might have
            seen it. It CANNOT differ, because the test is only reached after
            `pu != pw`, and a `ctl_parity` that differs means `run()` scanned a
            `cqrt_x` on that register between the two calls; `cqrt_x` is
            non-diagonal with `writes=(0,)` and is the only thing that bumps
            `x_parity`, so that same scan step already put the register in
            `self.rails`. MEASURED over the 237 slices: 30 `commutes` calls, 6
            of them with differing parity, the membership guard fired 0 times.

        Nothing else the scan mutates (`inv_claimed`, `freed_names`, `x_parity`
        itself) is read on this path — `ctl_parity` is frozen onto each Call at
        scan time. And the whole argument has a cheap standing check: the memo
        is a PURE CACHE, so deleting its writes must not move a verdict, which
        is measured (all 237 slices byte-identical) rather than asserted.
        """
        # `cone=False` is the LABEL-ONLY reading (see `reduces_to_identity`);
        # it is a different predicate, so it gets its own memo key.
        memo = (name, lo, hi) if cone else (name, lo, hi, LABELS_ONLY)
        hit = self._stable_memo.get(memo)
        if hit is not None:
            return hit
        if memo in self._stable_active:
            raise NarrowingViolation(memo)
        self._stable_active.add(memo)
        try:
            ok, _why, lines = self.reduces_to_identity(
                self.writes_in(name, lo, hi), name, cone)
        finally:
            self._stable_active.discard(memo)
        self._stable_memo[memo] = (ok, lines)
        return ok, lines

    def adjoint_matches(self, a, b, record_undef=True):
        """Is call `b` the adjoint of call `a` on their shared target rail?

        `record_undef=False` refuses an `undef`/`poison` pair exactly as the
        default does but leaves `undef_refused` alone. That ledger names the
        reason at a free whose WRITE-HISTORY reduction failed, so only that
        reduction may write it; the phase conjunct (`_phase_closed`) asks
        about diagonal calls, which are in no write history, and recording
        them misnamed an unrelated failure as `A-undef-literal-pairing` (bd
        r2j3.4 review F3).
        """
        ea = a.eff
        if ea is None or ea.adjoint_of is None:
            return False
        # bd 1739 hole 2: every arm below decides by comparing operand TEXT
        # (`key()` equality, per-slot equality, `vals` equality). `undef` text
        # is not a value, so a pair that matches only because both sides spell
        # it is not a cancellation. Recorded, not silently dropped, so the
        # rail's finding can name the reason instead of reading as an ordinary
        # unpairable history.
        if a.sym == b.sym and len(a.args) == len(b.args) and \
                any(carries_undef(x) for x in a.args + b.args):
            if record_undef:
                self.undef_refused.append((a, b))
            return False
        if a.ctl_parity != b.ctl_parity:
            # Same gate on the complementary branch of its flag is NOT the
            # adjoint — composing the two is a full, unconditional operation.
            return False
        if ea.adjoint_of == "self":
            return a.key() == b.key()
        if ea.adjoint_of.startswith("negate-arg"):
            n = int(ea.adjoint_of[len("negate-arg"):])
            if a.sym != b.sym or len(a.args) != len(b.args):
                return False
            for i, (x, y) in enumerate(zip(a.args, b.args)):
                if i == n:
                    if not is_negation(x, y):
                        return False
                elif x != y:
                    return False
            return True
        if ea.adjoint_of.startswith("twin:"):
            want = ea.adjoint_of[len("twin:"):]
            return b.sym == want and a.cvals == b.cvals
        return False

    def commutes(self, u_pos, u, w_pos, w):
        """Do writes `u` and `w` to the same rail provably commute?

        The ONLY admitted reason is complementary flag branches: they share a
        control register whose `cqrt_x` parity differs, and that register is
        touched by nothing but `cqrt_x` between them — so the two writes act on
        disjoint branches of the same flag. This is exactly the `¬flag`
        `cqrt_x` bracket the two-arm phase emitter emits (§5b).
        """
        ucs = [(u.vals[i], p) for i, p in zip(u.eff.controls, u.ctl_parity)
               if i < len(u.vals)]
        wcs = [(w.vals[i], p) for i, p in zip(w.eff.controls, w.ctl_parity)
               if i < len(w.vals)]
        for reg, pu in ucs:
            for reg2, pw in wcs:
                if reg != reg2 or pu == pw:
                    continue
                if reg not in self.rails:
                    # Never minted and never written here: its write history is
                    # not this stream's to know, so the parity claim is not
                    # backed by anything. Decline rather than assume.
                    continue
                lo, hi = min(u_pos, w_pos), max(u_pos, w_pos)
                if all(c.sym == "cqrt_x"
                       for _, c in self.writes_in(reg, lo, hi)):
                    return True
        return False

    def reduces_to_identity(self, ws, target, cone=True, residue_ok=None):
        """Cancel adjoint pairs in `target`'s write history (commutation-aware).

        `ws` is the write history of the rail `target` over some interval, and
        the question is whether those writes net to identity ON THAT RAIL.
        Threading `target` through is not cosmetic (bd 0gwl):
        `pair_operands_unchanged` needs it to tell a gate's CO-WRITTEN slots —
        which must hold still for the pair to cancel — from the slot carrying
        `target` itself, whose stability is the very thing this reduction is
        establishing and so cannot be an input to it.

        `cone=False` is the LABEL-ONLY reading, all the way down the recursion:
        a superposing pair cancels on the label ledger alone, with rule (L) —
        its light cone and its phase conjunct — not asked. It is NOT a proof
        that anything is |0>, and nothing may verify a free on it. It exists
        for exactly one kind of caller (bd r2j3.4 review F1, CLAUDE.md L2): a
        SEVERITY decision that reads this predicate NEGATED. `T1-no-reversal`
        and `T3-rail-written-after-reversal` are VIOLATIONs only when the
        rail's own writes net to identity on its labels (no recognised zeroing
        history; a phase sandwich can still permute labels, a contrived case
        kept at main's severity); if those
        callers read the full predicate, every narrowing of rule (L) would
        silently demote a hard VIOLATION to a waivable UNPROVEN. Reading the
        label-only one makes their severity independent of rule (L).

        Returns (ok, reason, witness) where `witness` is the set of SOURCE LINES
        the proof consumed — every cancelled pair, plus the pairs any nested
        operand-stability check consumed. Deleting or corrupting any witness
        line must break this proof; that is what the mutant self-test targets.
        """
        stack, witness, rejects = [], set(), []
        for p, c in ws:
            placed = False
            for k in range(len(stack) - 1, -1, -1):
                pk, ck = stack[k]
                if not self.adjoint_matches(ck, c):
                    continue
                if not all(self.commutes(stack[m][0], stack[m][1], p, c)
                           for m in range(k + 1, len(stack))):
                    continue
                ok, sub, blocker = self.pair_operands_unchanged(
                    ck, pk, p, target, cone)
                if not ok:
                    rejects.append((ck, c, f"operand {blocker} is not "
                                           f"provably unchanged between them"))
                    continue
                if cone and ck.eff.superposing:
                    # bd r2j3.3: a rotation pair is the identity on `target`
                    # only if nothing between them kept a copy of the
                    # rotated-basis state. Permutation pairs skip this — they
                    # restore the label in every basis branch regardless.
                    ok, csub, why = self.light_cone_closed(target, pk, p)
                    if not ok:
                        rejects.append((ck, c, why))
                        continue
                    sub = sub | csub
                witness |= sub
                witness.add(ck.line)
                witness.add(c.line)
                del stack[k]
                placed = True
                break
            if not placed:
                stack.append((p, c))
        if not stack:
            return True, None, frozenset(witness)
        if residue_ok is not None and all(residue_ok(c) for _, c in stack):
            # (A3, bd r2j3.32) every write left standing is a classical
            # update the caller vouched for: the rail holds its alloc-time
            # classical value moved by classical offsets — a known basis
            # state, unentangled. The residue lines are NOT witnesses: the
            # verdict does not rest on them (blanking one leaves a known
            # classical state too, as (A2) already rules for a seeded alloc),
            # so the |0>-exactness of a residue is pinned by the lit fixtures
            # (`cqrt_xorc_<W>(out, seed)`), not by this checker.
            return True, None, frozenset(witness)
        p, c = stack[0]
        why = (f"write `{c.text}` (line {c.line}) is never cancelled "
               f"by an adjoint ({len(stack)} of {len(ws)} write(s) "
               f"left after reduction)")
        if rejects:
            # A matched adjoint that was REJECTED is a much sharper signal than
            # "nothing cancelled it" — it says the shape was right and an
            # operand moved. Name it, or the ticket's own repro reports only
            # that two identical `cqrt_cswap`s failed to pair, which reads as a
            # checker bug rather than as the dirty rail it is.
            ck, cc, reason = rejects[-1]
            why += (f"; the nearest adjoint candidate (lines {ck.line} and "
                    f"{cc.line}) matched but was REJECTED because {reason}")
        return False, why, frozenset(witness)

    def pair_operands_unchanged(self, c1, p1, p2, target, cone=True):
        """(ok, witness, blocker) — everything `c1`'s action depends on holds.

        THREE operand classes, each here for a reason that was once a hole:

        * the DECLARED READS. A gate acts on its live sources; if one moved in
          between, the second call is not the adjoint of the first.
        * the `classical_imm` slots (bd az1h). They are not in `reads` because
          the ABI calls them literals, and for a genuine literal the check
          costs nothing (a constant is not in `self.rails`, so it is skipped).
          It matters when the slot holds a RAIL: `xorc(%r,%h); ry(%h,0.75);
          xorc(%r,%h)` cancels on `key()` equality alone otherwise, because
          xorc declares reads=() and this loop would inspect ZERO operands — so
          (A2) would VERIFY the very entangle-then-free that (A1) had just
          declined, and the az1h hole would simply move one rule down. Found by
          the bd az1h/6f3o Rule-13 round, 2026-07-31, in the fall-through that
          change itself introduced.
        * the CO-WRITTEN slots (bd 0gwl, 2026-08-07) — every write slot except
          the one carrying `target`. `cqrt_cswap` is the ONLY symbol in the
          model that writes two rails (`reads=(0,) writes=(1,2)`; a Fredkin
          physically reads all three), so this loop used to iterate `read_idx()`
          alone and never look at the other routed register:

              %rail = cqrt_alloc_i32(0)
              cqrt_cswap(%f, %q, %rail)   ; f=1 routes psi onto %rail, |0> onto %q
              cqrt_ry_i32(%q, 0.75)       ; dirties %q
              cqrt_cswap(%f, %q, %rail)   ; route-back parks Ry(0.75)|0> on %rail
              cqrt_free(%rail)            ; hidden measurement — NOT |0>

          reported `OK … via A2-reduces-to-identity`, exit 0, because the pair
          matched on `key()` equality and only `%f`'s stability was ever
          checked. The slot carrying `target` is skipped because proving it is
          this reduction's job, not its premise.

        `blocker` is the operand that failed, for the diagnostic; None on ok.
        """
        acc = set()
        for ri in list(c1.read_idx()) + list(c1.eff.classical_imm):
            if ri >= len(c1.vals):
                continue
            v = c1.vals[ri]
            if v not in self.rails:
                continue
            ok, lines = self.unchanged_over(v, p1, p2, cone)
            if not ok:
                return False, frozenset(), v
            acc |= lines
        for wi in c1.eff.writes:
            if wi >= len(c1.vals):
                continue
            v = c1.vals[wi]
            # `v == target` is the rail under reduction, and skipping it is
            # what keeps this loop from taking its own conclusion as a premise.
            # It is also why single-write gates add NO work here: their one
            # write slot IS the target, so among the REDUCTION's callers only
            # `cqrt_cswap` ever reaches `co_written_stable` at all. The one
            # other caller is the phase conjunct (`_phase_closed`, bd r2j3.4),
            # which asks about a DIAGONAL pair with `target=None`: no slot is
            # under reduction there, and the write slot is exactly the rail
            # whose label must hold still for the two phases to cancel.
            #
            # THIS CLAUSE IS AN ACCEPT-ARM. It is kill-tested by the POSITIVE
            # fixture `a2-co-written-target-skip`, which the checker VERIFIES
            # today and reports `A-not-reducible` on with only this clause
            # removed — a false decline of a stream whose net unitary is the
            # identity on the freed rail in BOTH branches of its flag.
            #
            # An earlier draft of this comment claimed the clause was
            # "redundant by construction … no input can distinguish the two",
            # on the argument that a target write inside (p1, p2) either already
            # cancelled or survived onto the stack, where `reduces_to_identity`
            # made it COMMUTE with the pair using "the same `commutes` call"
            # this path would use. THAT ARGUMENT IS FALSE, on both horns, and
            # the bd 0gwl Rule-13 round refuted it with a runnable input:
            #   * IT IS NOT THE SAME CALL. The caller filters with
            #     `commutes(stack[m], …, p, c)` — interval (w, p2), against the
            #     LATER pair member. This path would filter with
            #     `commutes(p, w, p1, c1)` — interval (p1, w), against the
            #     EARLIER one. `adjoint_matches` does force the two calls to
            #     agree on control register and `cqrt_x` parity, but NOT on the
            #     interval, and `commutes` demands the flag see nothing but
            #     `cqrt_x` inside its own interval. One non-`cqrt_x` write on
            #     the flag placed on a single side of `w` makes the two answers
            #     differ.
            #   * THE OTHER HORN LEAKS TOO. A target write inside (p1, p2) whose
            #     adjoint partner lies OUTSIDE that window cannot cancel in a
            #     reduction restricted to `writes_in(target, p1, p2)`, however
            #     the caller disposed of it.
            # The lesson is the file's own (bd az1h): a model's assertion about
            # itself is not an observation. Both statements were checkable and
            # neither had been checked — the corpus being unmoved (still true:
            # dropping the clause moves 0 of 237 slices) says only that the
            # corpus does not contain the distinguishing shape.
            #
            # DIRECTION, so the risk is not overstated: re-deriving the target's
            # stability here can only ADD declines, never accept more. So the
            # clause guards against a FALSE POSITIVE — which for a gate wired
            # into every e2e slice means failing a CORRECT build.
            if v == target or v not in self.rails:
                continue
            ok, lines = self.co_written_stable(v, p1, p2, c1, cone)
            if not ok:
                return False, frozenset(), v
            acc |= lines
        return True, frozenset(acc), None

    def co_written_stable(self, v, p1, p2, c1, cone=True):
        """(ok, witness) — co-written register `v` holds still across the pair.

        The same question `unchanged_over` answers, with ONE extra admission:
        an intervening write that provably acts on the COMPLEMENTARY BRANCH of
        a flag `c1` also acts on is dropped BEFORE the reduction runs. Two
        operators supported on complementary blocks of the same flag commute
        exactly, so on the branch where the pair acts such a write is the
        identity. That is not a new physics claim — it is the argument
        `commutes` already makes for the target rail's own intervening writes,
        applied to a co-written one.

        WITHOUT this admission the rule fails a CORRECT, REVIEWED build, which
        for a gate is the expensive direction. In
        `slice_control_phase_ifelse_derived` the shared base `%h` is routed
        `A B A B`: the `%rail` route-pair has the `%rail1` route sitting inside
        it, on the far side of the `¬flag cqrt_x` bracket. `%h` is genuinely
        written in between, and only complementary-branch commutation explains
        why the `%rail` pair still cancels. Pinned BOTH ways, by fixtures that
        EXIST — name them, never invent one (a docstring that cites a fixture
        nobody can grep sends the next maintainer to duplicate coverage that is
        already there): deleting this admission turns the POSITIVE
        `ifelse-derived-two-rail` red, and widening it into "any intervening
        write is fine" is caught by the MUTANTS
        `a2-cswap-route-pair-whose-co-written-rail-was-dirtied` and
        `t2-cswap-route-pair-whose-work-rail-was-dirtied`. All three live in
        tools/free_pairing_check_test.py.

        WHY `c1` ALONE IS CONSULTED, AND NOT THE PAIR. `adjoint_matches` forces
        both calls to carry the same control REGISTERS at the same `cqrt_x`
        PARITY (`self` compares whole keys; `negate-arg<N>` never has `n` in
        `controls`, and every NON-`n` slot — control slots included — must
        compare EQUAL, so a differing control is rejected either way; `twin:`
        compares whole value lists). It does NOT make `commutes(…, c1)` and
        `commutes(…, c2)` agree, and an earlier draft of this docstring wrongly
        said it did: `commutes` also demands the flag see nothing but `cqrt_x`
        inside ITS OWN interval, and those intervals are (p1, w) and (w, p2) —
        disjoint. The bd 0gwl Rule-13 round built a stream where the two answers
        differ, so do not repeat that claim.

        The argument that actually holds splits the window in two, and the two
        halves are established by two DIFFERENT checks:
          * (p1, w) — this `commutes` call. Only `cqrt_x` touched the flag, so
            the flag at `w` really is `ctl_parity`'s complement of the flag at
            `p1`, and `w` therefore acts on the other branch from `c1`.
          * (w, p2) — NOT re-checked here, because `pair_operands_unchanged`
            has ALREADY run its READS loop before reaching this one, and that
            loop required `unchanged_over(flag, p1, p2)` over the whole window.
            So the flag at `p2` carries the same basis label as at `p1`, and
            `c2` acts on the same branch as `c1`.
        Together: the pair acts on one branch throughout and `w` on the other.
        That rests on the shared control register being one of `c1`'s READS,
        which holds for every symbol `classify()` models — controls ⊆ reads for
        cnot, toffoli, cswap, copy_controlled, qram_store_controlled, the
        rotation twins `cqrt_{ry,rz}_<W>_controlled` (`reads=(0,)`,
        `controls=(0,)`) and the `_controlled` template/`_unc` arms alike. A
        future symbol with a control
        outside its read-set would break this argument, so put it in `reads`.

        NO STEP BUDGET, for the reason `unchanged_over` gives at length: this
        edge narrows too (`writes_in(v, p1, p2)` is strict and the
        complementary-branch filter only DROPS members), so the recursion is
        bounded by the interval.

        IT IS MEMOISED, AND THAT IS NOT OPTIONAL — the bd xzdx Rule-13 round
        found this out the expensive way. The first draft of the budget removal
        left this edge uncached, on the argument that its population is tiny:
        `cqrt_cswap` is the only multi-write symbol in `classify()`, so nothing
        else reaches here at all (true then; since bd r2j3.4 a diagonal pair
        asked by `_phase_closed` reaches it too), and the whole 237-slice corpus makes just 66
        calls here against 90671 to `unchanged_over`. That argument is the
        corpus-has-no-power error in its purest form. The deleted budget was the
        only thing bounding the WORK on this edge, and without a cache the cost
        is EXPONENTIAL: on a braid of cswap route pairs over one register pair
        with a distinct flag per level (`cswap(f0,A,B) … cswap(f19,A,B)
        cswap(f19,A,B) … cswap(f0,A,B)`), reducing A recurses into
        `co_written_stable(B, …)`, which recurses back into A over every
        strictly-inner window, and the same window is recomputed along
        4^(D/2) paths. MEASURED 2026-08-08 on a 63-CALL module: 0.017 s
        pre-change (which declined it on the budget), 44.6 s uncached, 0.008 s
        with this cache — and D=30 never finished. A build gate that a 66-line
        input can hang is a denial of service on every e2e slice.

        The key is `(v, p1, p2, id(c1))` and both the cache and the re-entry
        assertion use it. `c1` is in it by IDENTITY rather than by position
        because this file never needs `c1` to be the call AT `p1` and does not
        check that it is — keying on `(v, p1, p2)` alone would bake in an
        unstated assumption, and `commutes` reads `c1`. `id()` is safe here
        precisely because it is scoped to one `StreamAnalysis`: every `c1` that
        reaches this method is an element of `self.calls`, which outlives the
        analysis, so no id can be recycled underneath the table. The
        label-only reading (`cone=False`, see `reduces_to_identity`) is a
        different predicate and carries a fifth key element.
        """
        key = (v, p1, p2, id(c1)) if cone else (v, p1, p2, id(c1),
                                                LABELS_ONLY)
        hit = self._co_written_memo.get(key)
        if hit is not None:
            return hit
        if key in self._co_written_active:
            raise NarrowingViolation(key[:3])
        self._co_written_active.add(key)
        try:
            ws = [(p, w) for p, w in self.writes_in(v, p1, p2)
                  if not self.commutes(p, w, p1, c1)]
            ok, _why, lines = self.reduces_to_identity(ws, v, cone)
        finally:
            self._co_written_active.discard(key)
        self._co_written_memo[key] = (ok, lines)
        return ok, lines

    # -- (L) the LIGHT CONE of a superposing pair (bd r2j3.3) ---------------
    def light_cone_closed(self, target, p1, p2):
        """(ok, witness, why) — is `pair · U · pair⁻¹` the identity on `target`?

        `p1`/`p2` are an adjoint pair of SUPERPOSING writes to `target`
        (`cqrt_ry_<W>` and its `_controlled` twin, `cqrt_h`) that the reduction
        has matched, and U is everything the stream runs between them.

        THE HOLE (bd test_C_libtooling-r2j3.3, P1, 2026-10-01). The write model
        cancels `Ry(-t) … Ry(t)` on `key()` equality plus a negated angle, and
        never asks what READ `target` in between. Between the two rotations the
        register is in a ROTATED basis, so a read there copies a rotated-basis
        label: a tape record, a measurement, a copy onto a kept carrier, or a
        template rail that is not reversed before the second rotation leaves
        `target` entangled with it, and `Ry(t)` does not restore the label. The
        compiler's own lowering of `_Bool b=cq_theta(0,.5); int v=tbl[b];
        cq_theta(&b,-.5); printf(b, v)` in a non-`main` function frees the
        QRAM load rail after exactly that, and stage 2b certified it through
        (T2): "the load's index operand is unchanged" because its writes were
        `Ry(-.5) Ry(.5)`. The frozen module is
        `R2J3_3_FROZEN` in tools/free_pairing_check_test.py.

        THE RULE IS A CLOSURE, NOT "NO READ", because the whole-DAG LIFO spine
        puts every rail derived from a rotated root INSIDE that root's restore
        window, reversed before the second rotation (UNCOMPUTE_CHAIN, a shipped
        lowering). "Any read in the window declines" would fail that build. So:

          * THE CONE. Scan U in stream order from `{target}`. A call with ANY
            operand in the cone — read, control, classical-immediate or WRITE
            slot (a `cqrt_cswap` moves `target`'s state into its co-written
            rail through a write slot) — adds every rail it writes and the rail
            it mints. `cqrt_free` adds nothing. A DIAGONAL call is scanned
            like any gate, so a controlled diagonal whose CONTROL is in the
            cone adds its write-slot rail (an earlier version of this bullet
            said "its only write slot is already in the cone", which is false
            for `cqrt_rz_<W>_controlled(cone, y, …)`). That addition is
            conservative — a diagonal relabels nothing, so it never carries
            the rotated label into `y` — and it is kept so that bd r2j3.4's
            change only ADDS refusals; the phase the call carries is the PHASE
            conjunct's business (below).
          * THE CONSUMERS THAT CAN NEVER CLOSE IT. A cone rail reaching a
            measurement, the output tape (`cqrt_tape_write_<W>[_controlled]`,
            slot-blind like R1's seed), an `_inv` (it names no rail), an alloc
            seed, a void `__cq_q_*` clone, or any call `classify()` does not
            model, refuses at once. "Any call" includes a call through a
            function pointer or to inline asm: `parse_module` records those
            as calls to `UNNAMED_CALLEE` (review F3 — before that they were
            not parsed at all, and a window leaking through one VERIFIED). The
            one exemption is `@llvm.dbg.*`: a debug intrinsic names a value
            and acts on no rail (review F4).
          * RESTORATION. Every cone rail other than `target` must be back where
            it was by `p2`: a rail MINTED in U needs its (T1a) `_unc` inside U,
            an unchanged history from mint to reversal, nothing written after
            it, and its own forward operands held still — (T1a)/(T2)/(T3) in a
            window; a rail that EXISTED before it joined needs its writes from
            the joining write onward to reduce to identity (`unchanged_over`).
          * PHASE (bd test_C_libtooling-r2j3.4, 2026-10-13). Every DIAGONAL
            call in U with an operand in the cone at its position — write slot
            or control slot, so a `cqrt_rz_i1` kickback on a flag derived from
            `target` and a `cqrt_rz_<W>_controlled` whose control is a cone
            rail both count — must be cancelled by a distinct adjoint diagonal
            inside U with its operands held still between the two
            (`_phase_closed`). Without this conjunct the rule above is blind to
            phases, because diagonal calls stay out of every write history (the
            phase arms need that), and `Ry(-t) · Rz(φ) · Ry(t)` is NOT the
            identity: a phase between two rotations changes POPULATIONS. Before
            it, `ry; rz; ry⁻¹; free` VERIFIED a dirty free, and so did a
            kickback on a flag derived from the rotated rail (the U2 review's
            `@kick` probe) and a controlled phase from it onto an outside rail
            (`@rzc`).

        Why that suffices, relative to the reduction's own soundness: by
        construction no call writes a rail OUTSIDE the cone while reading one
        inside it, so the rest of the circuit evolves independently of
        `target`'s rotated state; every cone rail is returned, so U acts on
        `target ⊗ cone` as a PERMUTATION that is the identity on every basis
        branch; and every phase U puts on a cone rail is cancelled by its
        adjoint across a stretch that holds that rail's label still, so no
        branch-dependent phase is left either. Only then is U the identity on
        `target ⊗ cone` — the label argument alone allows a diagonal. Nested
        superposing pairs inside U reach this same rule through the recursive
        reductions.

        WHAT IT DOES **NOT** CLOSE, stated so it is not read as covering it:
          * A phase cancellation that is not a PAIRWISE NEGATION of literal
            angle text: `rz(a); rz(b); rz(-(a+b))`, a cancellation by an
            angle held in an SSA value, or one that only a non-greedy matching
            finds. All three are REFUSED — an over-decline, the safe side.
          * A phase that is harmless for a reason other than cancellation:
            a controlled diagonal on the COMPLEMENTARY flag branch of a
            controlled superposing pair (the pair is the identity on that
            branch, so nothing there is in a rotated basis), or a phase on a
            cone rail that has already been restored to its pre-window label.
            Both are REFUSED as well, and no shipped lowering emits either
            today (the pre-change file runs this rule twice on the corpus,
            with no diagonal in either window).
          * Two kickbacks of opposite angle on two SEPARATELY minted flags of
            the same predicate over an unchanged register (`f1 = icmp_eq(b,1);
            rz_i1(f1, a); …; f2 = icmp_eq(b,1); rz_i1(f2, -a)`). They cancel
            physically — both phases are the same function of `b`'s label —
            but `adjoint_matches` pairs by operand TEXT and `%f1` is not
            `%f2`, so the window is REFUSED (round-1 review F2). Kept on
            purpose: deciding that two rails carry the same function of the
            same label is value reasoning this file does not do, an
            instrument's failure mode is reporting a pass, and no lowering is
            known to emit the shape.
          * A phase that reaches the cone only through a NON-CALL alias
            (`%s = select …, %b, …` then `rz(%s, φ)`) still VERIFIES — the
            NON-CALL bullet below, which this conjunct inherits unchanged.
          * A rail reaching a NON-CALL instruction (`store`, `phi`, `select`,
            `ret`) inside U. Only calls are modelled, as everywhere else here,
            so the cone stops at the instruction: `%s = select i1 %c, i32 %b,
            i32 %k` followed by a tape record of `%s` records the rotated rail
            under a name the cone never reaches, and the window VERIFIES (review
            F2). What stands in front of that is the PASS —
            `declineClassicalMuxes` (ir-pass/src/TaintPropagation.cpp) refuses
            a live select/phi over tainted data, the same guard the header's
            NON-CALL bullet relies on — not this rule.
          * Any closure that is not a LIFO reversal: a Bennett recompute, an
            `_inv`. Those refuse (over-decline, the safe direction).

        NARROWING, for `unchanged_over`'s termination argument: every query
        issued here is over `(q, rev)` or `(qj - 1, p2)` with `p1 <= qj - 1`,
        `p1 < q < rev < p2`, or (the phase conjunct) over a diagonal pair's
        `(lo, hi)` with `p1 < lo < hi < p2`, and `(p1, p2)` is itself strictly inside the
        interval whose reduction matched the pair — so each edge narrows by at
        least 2, and the re-entry assertion below can only fire on a future
        edge that does not. Memoised on `(target, p1, p2)`; it reads only calls
        and write lists at positions `< p2`, all scanned before any free site
        that can reach it, so the memo is pure for the same reasons
        `unchanged_over` gives.
        """
        key = (target, p1, p2)
        hit = self._cone_memo.get(key)
        if hit is not None:
            return hit
        if key in self._cone_active:
            raise NarrowingViolation(key)
        self._cone_active.add(key)
        try:
            res = self._light_cone(target, p1, p2)
        finally:
            self._cone_active.discard(key)
        self._cone_memo[key] = res
        return res

    def _light_cone(self, target, p1, p2):
        a, b = self.calls[p1], self.calls[p2]
        where = (f"{target}'s state between the superposing pair at lines "
                 f"{a.line} and {b.line}")
        cone, minted = {target: p1}, set()
        # bd r2j3.4: every DIAGONAL call in the window (partner candidates),
        # and the ones with an operand in the cone at their position (each of
        # which must be cancelled — see `_phase_closed`).
        diags, phased = [], []
        calls = self.calls
        for q in range(p1 + 1, p2):
            c = calls[q]
            e = c.eff
            if e is not None and e.diagonal:
                diags.append(q)
            hit = None
            for v in c.vals:
                if v in cone:
                    hit = v
                    break
            if hit is None:
                continue
            if e is not None and e.diagonal:
                phased.append((q, hit))
            role = e.role if e is not None else None
            if role == "free" or (e is None and c.sym.startswith("llvm.dbg.")):
                # A debug intrinsic is not a gate: it names a value for the
                # debugger and acts on no rail (review F4).
                continue
            # The closable consumers: an in-place gate, a `_unc`, and a rail
            # MINT that names its result (so its reversal can be looked for).
            # Everything else that touches the cone refuses below.
            if not (role in ("gate", "unc") or
                    (role == "mint" and c.res and not _tape_sink(c.sym))):
                if e is None:
                    callee = (c.sym if c.sym == UNNAMED_CALLEE
                              else "@" + c.sym)
                    what = (f"is passed to {callee}, a call this file does "
                            f"not model,")
                elif role == "measure":
                    what = "is measured"
                elif role == "inv":
                    what = ("is read by an `_inv`, which writes a rail the "
                            "ABI does not name,")
                elif _tape_sink(c.sym):
                    what = ("is recorded onto the output tape, a carrier no "
                            "reversal restores,")
                else:
                    what = (f"reaches @{c.sym}, which leaves no rail this "
                            f"file can see reversed,")
                return False, frozenset(), (
                    f"{hit} — carrying {where} — {what} at line {c.line} "
                    f"(`{c.text}`), so that {LC_OPEN}")
            vals = c.vals
            for wi in e.writes:
                if wi < len(vals) and vals[wi] not in cone:
                    cone[vals[wi]] = q
            if c.res and e.mints == "rail":
                cone[c.res] = q
                minted.add(c.res)
        wit = set()
        for v, qj in cone.items():
            if v == target:
                continue
            if v in minted:
                ok, lines, detail = self._minted_closed(v, qj, p2)
            else:
                ok, lines = self.unchanged_over(v, qj - 1, p2)
                detail = (f"its writes from line {self.calls[qj].line} on do "
                          f"not reduce to identity before line {b.line}")
            if not ok:
                return False, frozenset(), (
                    f"{v} picks up {where} at line {self.calls[qj].line} and "
                    f"is not provably restored before line {b.line} "
                    f"({detail}), so that {LC_OPEN}")
            wit |= lines
        if phased:
            ok, lines, why = self._phase_closed(phased, diags, where)
            if not ok:
                return False, frozenset(), why
            wit |= lines
        return True, frozenset(wit), None

    def _phase_closed(self, phased, diags, where):
        """(ok, witness, why) — the PHASE conjunct of rule (L) (bd r2j3.4).

        `phased` lists the diagonal calls inside the window that have an
        operand in the light cone at their position, `diags` every diagonal
        call inside the window. Each `phased` call must be cancelled by a
        DISTINCT adjoint diagonal inside the same window (`adjoint_matches`:
        same symbol and operands, negated angle, same flag parity) such that
        everything the pair's action depends on holds still between them
        (`pair_operands_unchanged` — the predicate every other pairing here
        asks, called rather than re-derived). Then the two phases multiply to
        the identity on every basis branch of their operands, and what lies
        between them commutes with the pair; so the window's net action on the
        cone carries no phase, and the restoration conjunct above is the whole
        story again.

        WHY THE CONE AND NOT THE TARGET ALONE. A phase on a rail DERIVED from
        the rotated target (a kickback flag `icmp(b)`, a template `add(b)`, a
        CNOT copy of b) is a function of b's computational label, so after the
        derived rail is uncomputed it is a diagonal on b itself — and
        `Ry(t)·D·Ry(-t)` is not the identity for a non-constant diagonal D.
        WHY BOTH SLOTS. A controlled diagonal is diagonal in BOTH of its rails
        — its phase depends on the label of each — so a cone rail in EITHER the
        control or the write slot carries the phase.

        Diagonal calls that touch nothing in the cone stay transparent, and so
        does every diagonal outside every superposing window: on a rail in a
        computational-basis state Rz relabels nothing, which is what the
        shipped phase arms and the R6 kickback flag rest on.

        Greedy, nearest partner first, scanning outward from the candidate
        through `diags` (which is in stream order) — the first draft re-sorted
        all of `diags` per candidate, super-linear in one window's diagonal
        count (review F4). A diagonal that only a non-greedy matching could
        cancel is refused — an over-decline, the safe side. Partners are
        searched among ALL diagonals in the window, cone or not: a phase taken
        on `y` before `y` joined the cone and cancelled after `y` was restored
        is still a cancelled pair. Matching is by `adjoint_matches`, i.e. by
        OPERAND TEXT: two kickbacks of opposite angle on two SEPARATELY minted
        flags of the same predicate on an unchanged register cancel
        physically, and are refused here (review F2; see `light_cone_closed`'s
        list of deliberate refusals).

        NARROWING: each pair `(lo, hi)` satisfies `p1 < lo < hi < p2`, so
        `pair_operands_unchanged` hands `unchanged_over` and
        `co_written_stable` a strictly narrower interval than the window — the
        termination argument in `unchanged_over` carries over unchanged.
        """
        used, wit = set(), set()
        calls = self.calls
        index = {q: i for i, q in enumerate(diags)}
        for q, hit in phased:
            if q in used:
                continue
            partner = sub = None
            for q2 in _outward(diags, index[q]):
                if q2 in used:
                    continue
                lo, hi = (q, q2) if q < q2 else (q2, q)
                if not self.adjoint_matches(calls[lo], calls[hi],
                                            record_undef=False):
                    continue
                ok, s, _blocker = self.pair_operands_unchanged(
                    calls[lo], lo, hi, None)
                if ok:
                    partner, sub = q2, s
                    break
            c = calls[q]
            if partner is None:
                return False, frozenset(), (
                    f"{hit} — carrying {where} — takes a phase at line "
                    f"{c.line} (`{c.text}`) that no adjoint inside the window "
                    f"cancels with its operands held still. A diagonal gate is "
                    f"transparent only on a rail in a computational-basis "
                    f"state; between two superposing writes it changes "
                    f"populations (Ry(-t)·Rz(φ)·Ry(t) is not the identity), so "
                    f"that {LC_OPEN}")
            used.add(q)
            used.add(partner)
            wit |= sub
            wit.add(c.line)
            wit.add(calls[partner].line)
        return True, frozenset(wit), None

    def _minted_closed(self, x, q, hi):
        """(ok, witness, detail) — (T1a)/(T3)/(T2) for rail `x`, minted at
        stream position `q`, restored inside the window `(q, hi)`.

        The reversal is the FIRST matching `_unc` after the mint; any later
        write before `hi` (a second `_unc` included) refuses. The part that
        does not depend on `hi` is memoised on `(x, q, rev)`, which is pure:
        every position it reads is below `rev < hi <= ` the free being checked.
        """
        fwd, r = self.calls[q], self.rails.get(x)
        rev = None
        if r is not None:
            fwd_args = tuple(fwd.cargs)
            for p, w in r.writes:
                if q < p < hi and w.eff.role == "unc" and \
                        w.eff.base == fwd.sym and \
                        tuple(w.cargs[1:]) == fwd_args:
                    rev = p
                    break
        if rev is None:
            return False, frozenset(), (
                f"no matching @{fwd.sym}_unc reverses it inside the window")
        rl = self.calls[rev].line
        late = [w for p, w in r.writes if rev < p < hi]
        if late:
            return False, frozenset(), (
                f"`{late[0].text}` (line {late[0].line}) writes it after its "
                f"reversal at line {rl}")
        key = (x, q, rev)
        detail = self._minted_core_memo.get(key, 0)
        if detail == 0:
            detail = self._minted_core(x, q, rev, fwd, rl)
            self._minted_core_memo[key] = detail
        if detail is not None:
            return False, frozenset(), detail
        # The WITNESS is the reversal line alone, deliberately. The sub-proofs
        # are each some rail's OWN proof too, and unioning their line sets
        # into every enclosing cone made a D-deep nest of closed windows cubic
        # (MEASURED: D=500, 13.5 s, almost all in frozenset unions).
        return True, frozenset((rl,)), None

    def _minted_core(self, x, q, rev, fwd, rl):
        """None if `x` holds still from its mint to its reversal and so do the
        forward's operands (and none is `undef`); else the reason."""
        if any(carries_undef(a) for a in fwd.cargs):
            return (f"its forward operands carry `undef`/`poison`, so its "
                    f"reversal at line {rl} matches by text only (bd 1739 "
                    f"hole 2)")
        if not self.unchanged_over(x, q, rev)[0]:
            return (f"it is written between its mint and its reversal at line "
                    f"{rl}")
        for v in map(pairing_register, fwd.cvals):
            if v in self.rails and not self.unchanged_over(v, q, rev)[0]:
                return (f"its forward operand {v} is not provably unchanged "
                        f"before its reversal at line {rl}")
        return None

    # -- the free site -----------------------------------------------------
    def check_free(self, pos, c):
        name = c.vals[0]
        if name in self.freed_names:
            self.add(VIOLATION, "F1-double-free", c, name,
                     f"already freed at line {self.freed_names[name]}")
            return
        self.freed_names[name] = c.line
        r = self.rails.get(name)
        if r is None:
            where = self.module_defs.get(name)
            if where is None:
                self.add(UNPROVEN, "U2-unknown-def", c, name,
                         "no definition for the freed handle in this function")
            else:
                self.add(UNPROVEN, "U1-cross-stream", c, name,
                         f"handle is defined by @{where[1]} outside this "
                         f"straight-line stream, so its write history is not "
                         f"linearly ordered here")
            return
        if r.kind == "extern":
            # (T4) the rail may still be provably |0> here: a LOOP-EXIT (or any
            # cross-stream) discharge of a rail minted in a dominating stream.
            ok, rule, wit, why = self.loop_exit_discharge(pos, c, r)
            if ok:
                self.ok(c, r, rule, wit)
                return
            where = self.module_defs.get(name)
            self.add(UNPROVEN, "U3-extern-rail", c, name,
                     f"handle is written in this stream but minted outside it"
                     + (f" (by @{where[1]})" if where else "")
                     + "; its state on entry to this stream is unknown"
                     # Only a NEAR MISS says why. A rail with no cross-stream
                     # mint at all (the dtzb `cq.brk.*` family) keeps this
                     # finding's text byte-for-byte as it has always read.
                     + (f". (T4) loop-exit discharge refused: {why}"
                        if why else ""))
            return
        if r.kind in ("array", "tape"):
            self.add(VIOLATION, "F9-free-of-nonrail", c, name,
                     f"{r.kind} resource token minted by @{r.origin.sym} is "
                     f"not a rail and must never be freed")
            return
        if r.measured_at is not None:
            self.add(VIOLATION, "F8-free-after-measure", c, name,
                     f"handle was measured at line {r.measured_at}; the "
                     f"measurement owns it (Rule 6)")
            return
        # (R1) bd 261j(b) — RECORDED onto a kept carrier AND carrying a
        # non-diagonal rotation. Checked BEFORE the proof rules and independently
        # of them: all four rules that certified this defect ask only whether the
        # write history returns the rail to its alloc value, and `Ry(-t) Ry(t)`
        # does. What they cannot see is that the copy's DESTINATION is never
        # restored, so the rail is entangled with it and the reduction is no
        # longer a statement about the rail alone (Rules 5/6/8).
        rot = [w for p, w in r.writes
               if p < pos and w.sym.startswith("cqrt_ry_")]
        if rot and r.name in self.recorded:
            self.add(VIOLATION, "R1-recorded-rotated-rail", c, r.name,
                     f"rail carries `{rot[0].text if rot else '<rotation>'}` "
                     f"(line {rot[0].line if rot else 0}) and is "
                     f"transitively RECORDED onto a kept carrier (an output tape, or "
                     f"since bd 5pio a `cqrt_copy_<W>` destination), which the "
                     f"reversal never restores; it is therefore ENTANGLED with "
                     f"that carrier at the free, so `cqrt_free` is a hardware "
                     f"reset of an entangled rail = a hidden measurement (Rules "
                     f"5/6/8). `cqrt_ry` has no live condition to be a "
                     f"permutation OF, so no reverse-play returns it to |0>. "
                     f"Leave it allocated instead (the Rule-6 fallback). NOTE "
                     f"this fires REGARDLESS of the proof rules: each of them "
                     f"certifies this exact shape.")
            return
        if r.kind == "alloc":
            self.check_alloc_rail(pos, c, r)
        else:
            self.check_minted_rail(pos, c, r)

    # -- (T4) the LOOP-EXIT / cross-stream discharge -------------------------
    def loop_exit_discharge(self, pos, c, r):
        """(ok, rule, witness, why) — is this cross-stream free provably |0>?

        THE SHAPE, AND WHY THE REST OF THIS FILE CANNOT SEE IT
        =====================================================
        Group 1's P2 anchor (bd `test_C_libtooling-tu9q`, 2026-09-18) discharges
        a rail minted OUTSIDE a loop at that loop's unique EXIT:

            entry:   %h_cast = cq_template_sitofp_i32_to_f64(%h)     ; MINT
                     %h_op   = cq_template_fadd_f64_hl(%h_cast, 3.0) ; MINT
                     %h_intr = cq_template_sqrt_f64(%h_op)           ; MINT
                     br label %body
            body:    %h_cmp = cq_template_fcmp_ugt_f64_hl(%h_intr, %6)  ; a READ
                     ... ; %h_cmp minted, stripped and freed per trip
                     br i1 %8, label %body, label %exit
            exit:    cq_template_sqrt_f64_unc(%h_intr, %h_op)        ; REVERSAL
                     cqrt_free(%h_intr)
                     ...

        The mint is in one stream and the reversal and free are in another, so
        `check_minted_rail` never runs: the free arrives at `check_free` with an
        `extern` rail record and reports `U3-extern-rail`. MEASURED at the
        landing, and the asymmetry is the instrument's and not the rail's: the
        rolled slice reported `1 verified, 0 violation(s), 3 unproven` where its
        hand-unrolled twin — the SAME circuit with the discharge in the mint's
        own stream — reported `5 verified, 0 unproven`. The cost is not one
        slice's flag: `e2e-loop-twin-matrix` runs this checker STRICT per side,
        so 24 twin cells plus the pinned boundary control `q_armoncond` became
        `HARNESS-ERROR` and STOPPED HAVING A VERDICT AT ALL — and that matrix is
        the only instrument in the tree that can see a leaked TEMPLATE-minted
        rail. All 25, and all 101 of their UNPROVEN lines, are this one class.

        THE PROOF, AND WHY IT NEEDS NO EXECUTION ORDER
        =============================================
        The mint writes `f(args)` into a fresh |0> rail; the reversal writes
        `f(args')` into it, where `args'` are the argument rails' labels AT THE
        REVERSAL. So the rail is |0> at the free iff (1) nothing else ever
        writes it, and (2) `args' == args`.

        This file cannot linearize a loop — that is the whole reason the stream
        model exists, and reducing a write history that spans a back edge is
        exactly the dtzb hazard `U1-cross-stream` refuses. (T4) never tries: it
        establishes (1) and (2) from facts that are PATH-INSENSITIVE, hence true
        on every path, whatever the blocks between mint and free do:

          (T4a) `%h` has a UNIQUE rail MINT in this function (SSA gives
                uniqueness), it is a `role == "mint"` template/qram forward, and
                it is not a `cqrt_tape_write_<W>`. An `alloc` rail is REFUSED —
                its soundness rests on (A1)/(A2), a REDUCTION of its whole write
                history, and a reduction across a loop is the thing this rule
                exists not to do. An `_inv` mint is refused too: it is
                `implicit-rail`, i.e. the ABI does not name the rail it acts on.
          (T4b) the REVERSAL is in the FREE's OWN stream, before the free: an
                `@<base>_unc(%h, <the forward's operands>)`, the (T1a) test
                verbatim. The (T1b) `_inv` arm is deliberately NOT admitted
                here — an `_inv` names no rail, so its pool and its one-to-one
                claim are per-stream bookkeeping and a cross-stream claim would
                need a global pool with its own (W) argument. `undef`/`poison`
                in the forward operands is refused exactly as (T1u) refuses it:
                a textual operand match is not a value match (bd 1739 hole 2).
          (T4c) `%h` IS WRITTEN NOWHERE IN THE FUNCTION BUT THAT REVERSAL. This
                is the load-bearing conjunct and it is the one that makes the
                loop body safe without looking at the loop: every use of `%h`
                inside the cycle is a READ operand, and a read relabels nothing
                in this file's effect model. It is also what makes the rule
                SUBSUME two checks the `extern` branch returns in front of:
                a `cqrt_measure_<W>(%h)` is a write here, so `F8-free-after-
                measure` cannot be bypassed, and `R1-recorded-rotated-rail`
                needs a `cqrt_ry_` ON the rail, which is a write too. Both are
                refused function-wide rather than stream-locally, which is
                STRICTLY stronger than the checks being skipped.
          (T4d) there is EXACTLY ONE `cqrt_free(%h)` in the function.
                `F1-double-free` is per-stream and cannot see a rail freed once
                in each of two exit blocks — that is a double free of a rail
                minted once, and this conjunct is the only thing refusing it.
          (T4f) NO BLOCK of the mint's stream, and no block of the free's
                stream, can execute twice. This is what forbids the K:1 shape
                (mint once outside, reverse-and-free K times inside) that P2's
                own anchor walk exists to avoid: put the reversal and the free
                in the loop body and this conjunct refuses, where every other
                conjunct still passes. With it, `M`, `R` and `F` each execute at
                most once, and each stream is a linear trace, so a position
                comparison INSIDE one stream is a real execution order.
          (T4g) every forward operand of the mint holds still from the mint to
                the reversal: each write to it in the function is either in the
                MINT's stream strictly before the mint, or in the FREE's stream
                strictly after the reversal. Nothing in the loop body, nothing
                in a third stream, nothing in the window.

        Then, on every path: `M` runs, nothing writes `%h` or moves `args`, `R`
        runs and computes the same `f(args)`, so `%h` is |0>; nothing writes it
        before `F`. SSA supplies the missing dominance for free — every use of
        `%h` is dominated by its definition, so `B_mint` dominates `B_free` and
        no path reaches the reversal without the mint.

        WHAT (T4) DOES **NOT** PROVE — read this before widening it
        ==========================================================
          * ANY write to `%h` inside the loop. Not "a write that cancels", not
            an `X` bracket, not an `A B A B` route: (T4c) is a COUNT, and that
            is deliberate. A cancelling bracket inside a cycle would have to be
            reduced across a back edge, which is the `U1-cross-stream` refusal.
          * An `alloc` rail in this shape (T4a). The dtzb `%cq.brk.idx` /
            `%cq.brk.R` rails are exactly that and stay `U1-cross-stream` /
            `A-not-reducible`; MEASURED — the four `e2e-slice-loop-break*`
            entries' `--allow-unproven` verdicts are unmoved by this rule.
          * An IRREDUCIBLE cycle, or any cycle at all through the mint's or the
            free's stream (T4f). It does not classify the cycle, it refuses it.
          * A NESTED loop is not reasoned about AT ALL, and it does not need to
            be: the question "is `%h` written between the mint and the
            reversal?" is answered over the whole function, so an inner loop's
            trip count cannot matter. A read that runs K times is K reads, and
            reads commute with reads and relabel nothing — whereas a WRITE that
            runs K times is refused by (T4c) no matter which loop carries it.
            The rule is per-activation-safe because it never counts activations.
          * A rail READ after its free from another block. `F2-use-after-free`
            is per-stream and stays so; that gap is pre-existing and untouched.
          * The ENTANGLEMENT half of Rule 8, as everywhere else here: the rail
            this rule clears is |0> and unentangled AT THE FREE, which says
            nothing about a which-path record the loop body may have copied
            onto some OTHER carrier (bd s82e's question, not this file's).

        THE ARM-KILL MATRIX, AND THE ONE ARM IT COULD NOT KILL
        ======================================================
        A predicate with N accept-arms and one probe lets N-1 be deleted with a
        green suite (the bd az1h lesson), so each conjunct was deleted
        INDIVIDUALLY and the committed selftest re-run. NINE arms, EIGHT killed,
        each by a DIFFERENT fixture and each naming its own arm:

          (T4a) the template-mint test    -> t4-alloc-rail-cross-stream-bracket
          (T4b) the undef test            -> t4-undef-forward-operand
          (T4b) the operand-list match    -> t4-adjoint-with-a-different-literal
          (T4c) the single-write test     -> FOUR fixtures (write-in-loop,
                measured-then-freed, rotated-inside-the-loop, two-exit-blocks)
          (T4d) the one-free test         -> t4-one-reversal-two-frees
          (T4f) the mint-stream test      -> t4-mint-inside-the-loop
          (T4f) the free-stream test      -> t4-k1-reversal-and-free-inside-the-loop
          (T4g) the forward-operand test  -> t4-forward-operand-moved-inside-the-loop

        THE SURVIVOR IS `w.vals[0] == name` IN (T4b), AND IT SURVIVED BECAUSE IT
        RESTATES THE KEY IT IS SEARCHING. `r.writes` is appended by
        `rail_for_write(c.vals[wi])` for each `wi in eff.writes`, and a `_unc`
        Effect has `writes=(0,)` — so every `w` in THIS rail's write list already
        has `name` at `w.vals[0]`, and deleting the test changes no input's
        answer. It is kept as an explicit statement of what the rule reads
        rather than as a live filter, and the honest record is that its probe is
        not merely too weak: no input can distinguish the two versions while the
        `_unc` write slot is 0. ⚠ RETIREMENT TRIGGER, which is exactly when that
        stops being true: the day `classify()` gives any `role == "unc"` Effect a
        write slot other than 0 — a `..._controlled_unc` twin that shifted `out`,
        say — this conjunct becomes LOAD-BEARING and needs a real mutant. Do not
        delete it "because the matrix says it is redundant"; that is the bd 0gwl
        mistake, where "redundant by construction" was refuted by a runnable
        stream one round later.
        """
        x = self.xstream
        name = r.name
        if x is None:                       # no index (a direct-construction
            return False, None, None, None  # caller); behave exactly as before
        m = x.mint.get(name)
        if m is None:
            # Not a near miss — no rail mint anywhere in the function. Keep the
            # historic `U3-extern-rail` text unchanged for this case.
            return False, None, None, None
        msid, mpos, fwd, meff = m

        # (T4a) a reversible template/qram forward mint, never an alloc.
        if meff.role != "mint" or _TAPE_MINT.fullmatch(fwd.sym):
            return False, None, None, (
                f"the mint `{fwd.text}` (line {fwd.line}) is an @{fwd.sym}, not "
                f"a reversible out-of-place template mint; an alloc rail's "
                f"soundness is a REDUCTION of its whole write history (A1/A2) "
                f"and reducing one across a loop is what the stream model "
                f"refuses to do")
        if any(carries_undef(a) for a in fwd.args):
            return False, None, None, (
                f"forward operand of `{fwd.text}` (line {fwd.line}) is "
                f"`undef`/`poison`, so a matching reversal would match by TEXT "
                f"and not by VALUE (bd 1739 hole 2)")

        # (T4b) the `_unc` reversal, in THIS stream, before the free.
        fwd_args = tuple(fwd.cargs)
        rev_pos = None
        for p, w in r.writes:
            if p < pos and w.eff.role == "unc" and w.eff.base == fwd.sym and \
                    w.vals and w.vals[0] == name and \
                    tuple(w.cargs[1:]) == fwd_args:
                rev_pos = p
        if rev_pos is None:
            return False, None, None, (
                f"no `@{fwd.sym}_unc({name}, <the operands of `{fwd.text}` at "
                f"line {fwd.line}>)` appears in this stream before the free")
        rev = self.calls[rev_pos]

        # (T4c) nothing else in the FUNCTION writes it.
        for _wsid, _wpos, w in x.writes.get(name, ()):
            if w is rev:
                continue
            return False, None, None, (
                f"`{w.text}` (line {w.line}) also writes {name}; (T4) admits "
                f"EXACTLY ONE write to the rail in the whole function — its "
                f"reversal — because any other one would have to be cancelled "
                f"across a back edge")

        # (T4d) one free site, function-wide.
        fr = x.frees.get(name, ())
        if len(fr) != 1:
            return False, None, None, (
                f"{len(fr)} `cqrt_free({name})` site(s) in this function; a "
                f"rail minted once outside a region and freed at two of its "
                f"exits is a double free that the per-stream `F1-double-free` "
                f"cannot see")

        # (T4f) neither the mint's nor the free's stream can repeat.
        if not x.stream_runs_at_most_once(msid):
            return False, None, None, (
                f"the block minting {name} (`{fwd.text}`, line {fwd.line}) can "
                f"execute more than once, so the mint is not a single event")
        if not x.stream_runs_at_most_once(self.stream_id):
            return False, None, None, (
                f"the block carrying the reversal (line {rev.line}) and the "
                f"free can execute more than once — a rail minted ONCE and "
                f"reversed-and-freed PER TRIP is the K:1 shape, and it is a "
                f"use-after-free from the second trip on")

        # (T4g) the forward's operands hold still across [mint, reversal].
        for v in fwd.vals:
            for wsid, wpos, w in x.writes.get(v, ()):
                if wsid == msid and wpos < mpos:
                    continue           # strictly before the mint reads it
                if wsid == self.stream_id and wpos > rev_pos:
                    continue           # strictly after the reversal reads it
                return False, None, None, (
                    f"forward operand {v} of `{fwd.text}` (line {fwd.line}) is "
                    f"written by `{w.text}` (line {w.line}), which is neither "
                    f"before the mint in the mint's own stream nor after the "
                    f"reversal in this one, so the reversal may recompute a "
                    f"different value")

        return True, "T4-loop-exit-discharge", {fwd.line, rev.line}, None

    def check_alloc_rail(self, pos, c, r):
        ws = [(p, w) for p, w in r.writes if r.pos < p < pos]
        # (A1) classical-immediate updates keep a known classical basis state —
        # but ONLY if the immediate really is classical. The ABI's word for it
        # is not evidence (bd az1h): a rail in that slot ENTANGLES the two, and
        # the free then collapses both. Check every declared immediate slot, and
        # fall through to (A2) when one cannot be shown classical — a genuine
        # `xorc(%r,%h); xorc(%r,%h)` bracket still reduces to identity there, so
        # this tightening declines nothing that (A2) can prove.
        dirty = [(w, i) for _, w in ws for i in w.eff.classical_imm
                 if i < len(w.vals) and not self.provably_not_a_rail(w.vals[i])]
        if ws and not dirty and all(w.eff.classical_imm for _, w in ws):
            self.ok(c, r, "A1-classical-immediate", {w.line for _, w in ws})
            return
        # (A2) otherwise the history must return the rail to its alloc value.
        ok, why, wit = self.reduces_to_identity(ws, r.name)
        if ok:
            self.ok(c, r, "A2-reduces-to-identity", wit)
            return
        # (A3, bd r2j3.32) the history reduces to a RESIDUE of classical-
        # immediate updates whose immediates are provably classical: the
        # 4.5 data-mux preload `alloc(v)`, its copies cancelled by their
        # replay, then `xorc(v)` back to |0>. (A1) alone cannot take a mixed
        # history and (A2) alone leaves the `xorc` standing; together the
        # rail is still in a known classical basis state.
        # An `undef`/`poison` immediate is not a known value (each use may
        # materialise independently, bd 1739 hole 2), so it never qualifies.
        def classical_update(w):
            return bool(w.eff.classical_imm) and all(
                self.provably_not_a_rail(w.vals[i])
                and 'undef' not in w.vals[i] and 'poison' not in w.vals[i]
                for i in w.eff.classical_imm if i < len(w.vals))
        ok3, _, wit3 = self.reduces_to_identity(ws, r.name,
                                                residue_ok=classical_update)
        if ok3 and not dirty:
            self.ok(c, r, "A3-reduces-to-classical-residue", wit3)
        elif dirty:
            w, i = dirty[0]
            self.add(UNPROVEN, "A1-imm-not-classical", c, r.name,
                     f"`{w.text}` (line {w.line}) puts {w.vals[i]} in the "
                     f"classical-immediate slot {i} of @{w.sym}, and this file "
                     f"cannot show {w.vals[i]} is not a rail handle; if it is "
                     f"one, the update ENTANGLES the two and the free at line "
                     f"{c.line} collapses both (Rules 6/8). The ABI declares "
                     f"that slot classical, but at i32 both parameters are "
                     f"int32_t and the trace prints the slot as a bare decimal, "
                     f"so neither the verifier nor the golden can see it. "
                     f"(A2) did not rescue it either: {why}")
        else:
            # bd 1739 hole 2: name the reason when the reduction failed because
            # a pair matched only by `undef`/`poison` TEXT on THIS rail.
            names = {w.vals[i] for a, b in self.undef_refused for w in (a, b)
                     for i in w.eff.writes if i < len(w.vals)}
            if r.name in names:
                ua, ub = next((a, b) for a, b in self.undef_refused
                              if any(w.vals[i] == r.name for w in (a, b)
                                     for i in w.eff.writes if i < len(w.vals)))
                self.add(UNPROVEN, "A-undef-literal-pairing", c, r.name,
                         f"`{ua.text}` (line {ua.line}) and `{ub.text}` (line "
                         f"{ub.line}) cancel only by OPERAND TEXT, and that "
                         f"text is `undef`/`poison`: LangRef lets each use "
                         f"materialise independently, so the bracket need not "
                         f"close and the rail need not be back at its alloc "
                         f"value at the free (bd 1739 hole 2). {why}")
                return
            self.add(UNPROVEN, "A-not-reducible", c, r.name,
                     f"rail allocated at line {r.origin.line} by "
                     f"@{r.origin.sym}: {why}; cannot prove it holds a known "
                     f"classical basis state at the free")

    def check_minted_rail(self, pos, c, r):
        fwd, base = r.origin, r.origin.sym
        fwd_args = tuple(fwd.cargs)

        # (T1a) an explicit `_unc(%r, forward args...)` naming the rail.
        rev_pos = rev_kind = None
        for p, w in r.writes:
            if r.pos < p < pos and w.eff.role == "unc" and \
                    w.eff.base == base and tuple(w.cargs[1:]) == fwd_args:
                rev_pos, rev_kind = p, "_unc"
        # (T1b) otherwise an unclaimed `_inv(forward args...)` token.
        if rev_pos is None:
            # EARLIEST unclaimed token in the window, not the latest. Free
            # sites are visited in stream order (increasing right endpoint), so
            # "smallest feasible available token" is the optimal matching here;
            # taking the latest can strand a later free whose window is
            # narrower and report a reversal that exists as missing.
            cands = [p for p in self.inv_pool.get((base, fwd_args), [])
                     if r.pos < p < pos and p not in self.inv_claimed]
            if cands:
                rev_pos, rev_kind = min(cands), "_inv"
                self.inv_claimed.add(rev_pos)
        if rev_pos is None:
            # bd 01po.19 S4 review A-F1: an `_unc` that matches the forward
            # ONLY once the handle-array spellings are canonicalized read a
            # DIFFERENT cell spelling than its forward. The compiler emits an
            # adjoint on the forward's own operand values, never on another
            # load of the array, so this is never a legitimate pairing: the
            # reversal recomputes from another cell and the free is dirty.
            # Only the WINDOW map is consulted (never the QRAM bracket's,
            # which has its own T1 discipline), and only a position where the
            # two spellings differ AND both are cell spellings decides it.
            fv = [a.split()[-1] for a in fwd_args]
            for p, w in r.writes:
                if not (r.pos < p < pos and w.eff.role == "unc" and
                        w.eff.base == base and len(w.cargs) - 1 == len(fv)):
                    continue
                wv = [a.split()[-1] for a in w.cargs[1:]]
                diff = [(x, y) for x, y in zip(fv, wv) if x != y]
                if diff and all(x in _WINDOW_ALIAS and y in _WINDOW_ALIAS and
                                _WINDOW_ALIAS[x] == _WINDOW_ALIAS[y]
                                for x, y in diff):
                    self.add(VIOLATION, "W1-unc-reads-another-cell-spelling",
                             c, r.name,
                             f"rail minted at line {fwd.line} by `{fwd.text}` "
                             f"is reversed by `{w.text}` (line {w.line}), "
                             f"which reads a DIFFERENT spelling of the same "
                             f"handle array: the adjoint recomputes from "
                             f"another cell, so the free is not of |0>")
                    return
            pre = [(p, w) for p, w in r.writes if r.pos < p < pos]
            # If the rail's own writes net to identity ON THEIR LABELS, no write
            # history this file recognises as zeroing exists, so the rail is
            # dirty for generic inputs; only an unrecognised write history
            # leaves room for some other zeroing mechanism. A phase or open-cone
            # sandwich can still permute labels (Ry(-pi/2)Rz(pi)Ry(pi/2) = iX),
            # and that contrived case is knowingly reported at main's
            # pre-r2j3.4 severity (batch-053 round-2 review). A SEVERITY choice
            # on the NEGATED predicate, so it reads the LABEL-ONLY reduction
            # (bd r2j3.4 review F1, CLAUDE.md L2): with the full one, a phase
            # or an open light cone in the rail's own window demoted this
            # VIOLATION to a waivable UNPROVEN, and `--allow-unproven` then
            # exited 0 on a free with no reversal at all.
            inert, _why, _wit = self.reduces_to_identity(pre, r.name,
                                                         cone=False)
            self.add(VIOLATION if inert else UNPROVEN, "T1-no-reversal", c,
                     r.name,
                     f"rail minted at line {fwd.line} by `{fwd.text}` is freed "
                     f"with no matching @{base}_inv / @{base}_unc reversal in "
                     f"between" + ("" if not pre else
                     f" ({len(pre)} intervening write(s), first "
                     f"`{pre[0][1].text}` at line {pre[0][1].line})"))
            return

        rev = self.calls[rev_pos]
        witness = {fwd.line, rev.line}
        # (T1u) bd 1739 hole 2 — the match that just succeeded was TEXTUAL, and
        # `undef`/`poison` text does not denote a value. The token is claimed
        # above rather than left in the pool on purpose: it IS the textual
        # match, and leaving it unclaimed would let a second free of the same
        # shape be discharged by it.
        und = [a for a in fwd_args if carries_undef(a)]
        if und:
            self.add(UNPROVEN, "T1-undef-literal-pairing", c, r.name,
                     f"rail minted at line {fwd.line} by `{fwd.text}` is "
                     f"paired with the {rev_kind} at line {rev.line} ONLY BY "
                     f"OPERAND TEXT, and operand `{und[0]}` is "
                     f"`undef`/`poison`: LangRef lets each use of it "
                     f"materialise independently, so the reversal may recompute "
                     f"a DIFFERENT value and leave the rail dirty at the free "
                     f"(bd 1739 hole 2 / bd bu96 / bd xy9n). The runtime prints "
                     f"the slot as a bare literal, so the golden trace cannot "
                     f"see this either. The pass's own "
                     f"`declineUnpairedUndefLiterals` refuses such a module — "
                     f"reaching this file means it did not fire.")
            return
        # (T3) rail unchanged mint->reversal, untouched reversal->free.
        pre_rev = [(p, w) for p, w in r.writes if r.pos < p < rev_pos]
        post = [(p, w) for p, w in r.writes if rev_pos < p < pos]
        ok, why, wit = self.reduces_to_identity(pre_rev, r.name)
        # The VIOLATION below is a SEVERITY choice gated on the T3 reduction,
        # so a T3 failure must not pre-empt it when the failure is rule (L)'s
        # alone (bd r2j3.4 review F1, L2 — the same hazard as T1-no-reversal's
        # `inert`): the post-reversal write is demonstrable whenever the
        # LABEL-ONLY reduction of the pre-reversal history succeeds.
        if not ok and not (post and self.reduces_to_identity(
                pre_rev, r.name, cone=False)[0]):
            self.add(UNPROVEN, "T3-rail-written-before-reversal", c, r.name,
                     f"rail minted at line {fwd.line}: {why}, so the "
                     f"{rev_kind} at line {rev.line} does not provably zero it")
            return
        if post:
            self.add(VIOLATION, "T3-rail-written-after-reversal", c, r.name,
                     f"rail is written by `{post[0][1].text}` (line "
                     f"{post[0][1].line}) after its {rev_kind} reversal at "
                     f"line {rev.line} and before the free")
            return
        witness |= wit
        # (T2) forward operands must be unchanged across [mint, reversal]. A
        # bracketed QRAM index is checked through to its source register.
        for v in map(pairing_register, fwd.cvals):
            if v not in self.rails:
                continue
            ok, wit = self.unchanged_over(v, r.pos, rev_pos)
            if not ok:
                bad = self.writes_in(v, r.pos, rev_pos)
                # The reduction's own reason, so a pair refused for an open
                # light cone (bd r2j3.3) says so instead of reading as an
                # unpaired write. Recomputed only on this failure path.
                _ok, why, _w = self.reduces_to_identity(bad, v)
                self.add(UNPROVEN, "T2-operand-mutated", c, r.name,
                         f"forward operand {v} of `{fwd.text}` (line "
                         f"{fwd.line}) is written by `{bad[0][1].text}` (line "
                         f"{bad[0][1].line}) with no proof it is restored "
                         f"before the {rev_kind} reversal at line {rev.line}, "
                         f"so the reversal may recompute a different value: "
                         f"{why}")
                return
            witness |= wit
        self.ok(c, r, "T1-" + rev_kind.strip("_") + "-reversal", witness)


# Python frames the stability recursion burns per nesting level: the chain is
# `unchanged_over -> reduces_to_identity -> pair_operands_unchanged ->
# {unchanged_over | co_written_stable -> reduces_to_identity -> ...}`, so three
# to four — and since bd r2j3.3 the light-cone edge `reduces_to_identity ->
# light_cone_closed -> _light_cone -> _minted_closed -> _minted_core ->
# unchanged_over` is six. The bd r2j3.4 phase edge `reduces_to_identity ->
# light_cone_closed -> _light_cone -> _phase_closed -> pair_operands_unchanged
# -> {unchanged_over | co_written_stable}` is six as well, and every pair it
# asks about lies strictly inside the window, so it narrows like the others.
# 6 is the count; `ensure_recursion_headroom` multiplies
# it by the whole stream length although a level consumes at least two
# positions, which is the margin.
_FRAMES_PER_LEVEL = 6


def ensure_recursion_headroom(stream_len):
    """Raise the interpreter's recursion limit to cover this stream's WORST CASE.

    The stability recursion is bounded by INTERVAL NARROWING, not by a step
    budget (bd test_C_libtooling-xzdx — see `unchanged_over` for why the budget
    had to go). Narrowing bounds the DEPTH at `stream_len / 2`, since every
    level consumes at least two stream positions, so the interpreter stack is
    the only thing left that can stop the proof — and it stops it by CRASHING,
    which for a gate wired into every e2e slice is a correct build failing on a
    traceback. MEASURED 2026-08-08 against the SHIPPED code path, with this call
    removed and the default limit of 1000: `order_ladder(D)` from
    tools/free_pairing_check_test.py — a perfectly nested chain of self-inverse
    `cqrt_cnot`s, an exact palindrome, so the free IS sound — verifies at D=300
    and raises `RecursionError` from D=350. Measure that BARE: a tracer that
    adds one frame per level moves the wall a long way and will flatter you.

    So size the limit from the input rather than capping the proof. The figures
    this rests on are measured, not assumed:
      * the deepest nesting any of the 237 registered slices actually reaches is
        3 frames — the headroom is for adversarial input, not the ship floor;
      * the longest single stream in that corpus is 14135 calls
        (`slice_libm_real_lgammaf`), which made this function set the limit to
        57540 at 4 frames per level (85810 since bd r2j3.3 raised the count to
        6 for the light-cone edge). That is the CEILING it grants, not a frame
        count anything reaches: narrowing caps that stream at 7067 levels and
        the measured cost was 3 frames per level, so its true worst case was
        ~21k frames (~42k if every level went through the light-cone edge);
      * either number is far inside what the interpreter takes — a plain
        300000-deep pure-Python recursion completes on CPython 3.11 here without
        a segfault (3.11 does not consume C stack for Python-to-Python calls,
        and nothing on this recursion path goes through C).
    The limit is only ever RAISED, never lowered, so importing this module
    cannot shrink a caller's headroom.
    """
    need = _FRAMES_PER_LEVEL * stream_len + 1000
    if sys.getrecursionlimit() < need:
        sys.setrecursionlimit(need)


# ---- bd 261j(b): rails CORRELATED with a kept output carrier ---------------
#
# THE HOLE THIS CLOSES. bd 261j(a) ruled that freeing a rail RECORDED onto a carrier
# the reversal never touches is a hidden measurement unless the rail's own forward
# chain is a basis permutation of live conditions (bd memory
# [record-freeze-invariant-2026-08-10]). This checker CERTIFIED that defect — four
# separate proof paths did (`A2-reduces-to-identity`, `T1-unc-reversal`, and two more
# found on `p_i8`/`p_qram_qidx` shapes in the Rule-13 round) — because every one of
# them asks only "does the write history return the rail to its alloc value", and
# `Ry(-t) Ry(t)` does. What none of them can see is that a CNOT-class copy onto a
# carrier that is never restored has already correlated the rail with it, so the
# reduction is no longer a statement about the rail alone.
#
# So this is NOT a tightening of a proof rule: no rule change can close it, because
# the correlation is absent from the EFFECT MODEL — `classify` records that
# `cqrt_tape_write_<W>` reads its src and writes the tape token, which is true and
# says nothing about the carrier being kept. The rule is layered ON TOP, and it
# rejects regardless of which proof would otherwise have discharged the site.
#
# BOTH CONJUNCTS ARE REQUIRED and dropping either is a false-positive machine:
#   (i)  the rail's own write history contains a NON-DIAGONAL rotation. `cqrt_rz_` is
#        excluded — diagonal, trivial on |0>, and its label-phase cancels against a
#        basis-label record (the ruling's own whitelist). SAY WHERE THAT EXCLUSION
#        ACTUALLY HAPPENS, because the obvious answer is wrong: it is NOT the
#        `cqrt_ry_` name test below. The stream scan appends to a rail's write
#        history only `if not e.diagonal`, so an `rz` never enters it at all, and
#        MEASURED by arm-kill, widening the name test to `cqrt_r` does not make the
#        rz positive control fire. The name test is defence in depth over an
#        exclusion the effect model already makes one layer earlier.
#   (ii) the rail is transitively CORRELATED with a kept carrier.
# (i) alone fires on all 36 legitimate Bennett straddles; (ii) alone fires on every
# sound `cq_template_*` rail a tape ever reads — including the DERIVED rail whose
# free bd 261j(a) deliberately KEPT (lowering_io_tape_derived_uncompute.ll).
#
# CORRELATION PROPAGATES BACKWARD ONLY, over ancestor edges, mirroring the pass: the
# record reads a descendant's label, which is a function of its ancestors'. A
# descendant of a recorded rail reverses cleanly (the record is diagonal on the
# ancestor and commutes with the descendant's chain).
#
# SLOT-BLIND at the seed, deliberately, for the same reason the pass is: the
# controlled twin `cqrt_tape_write_<W>_controlled(ctrl, tape, src)` records BOTH ctrl
# and src, and a slot-indexed test would miss the controlled form's src. The tape
# TOKEN swept in with them is a `tape`-kind resource that `F9-free-of-nonrail`
# already refuses to free, so blindness costs nothing here.
#
# WHAT THE ARM-KILL MATRIX ACTUALLY MEASURED about that, because the tidy claim is
# not the true one: replacing the blind seed with a slot-indexed one does NOT turn
# the controlled-twin mutant red. The backward closure reaches the ctrl anyway — the
# tape token is a WRITTEN slot of the same call, so closing over that call's operands
# picks the ctrl up one hop later. The two mechanisms OVERLAP here. Slot-blindness is
# kept because it is the direct statement of the physics and does not depend on the
# token happening to be modelled as written; it is not, on this shape, independently
# load-bearing, and saying otherwise would be exactly the unverified claim this
# ticket's history is made of.
#
# The closure walks only names this function MINTS as rails — the same restriction
# the pass's `taint.Tainted` test applies. Widening it to every operand would drag
# classical immediates in and turn a GATE into a false-positive generator, which is
# the expensive direction (bd memory [gate-validation-not-corpus-silence-2026-07-31]).
_TAPE_SINK = re.compile(rf"cqrt_tape_write_{_W}(?:_controlled)?$")
_TAPE_SINK_MEMO = {}


def _tape_sink(sym):
    """`_TAPE_SINK.fullmatch(sym)`, cached — the light-cone scan asks it once
    per cone-touching call (bd r2j3.3)."""
    hit = _TAPE_SINK_MEMO.get(sym)
    if hit is None:
        hit = _TAPE_SINK_MEMO[sym] = bool(_TAPE_SINK.fullmatch(sym))
    return hit

# THE COPY-OUT SURFACE (bd 5pio, owner ruling 2026-08-11). A method-B
# `cqrt_copy_<W>(src, dst)` records `src`'s basis label onto `dst`, and `dst` is a
# kept carrier this reversal never restores — the SAME relation the tape has, so it
# seeds R1 the same way. The pass made exactly this change to
# `ChainWalk::recordsIntoKeptCarrier`; keeping the two gates' seeds in step is the
# whole point, because they are INDEPENDENT and complementary (the trace sees the
# angles and not the rail identities; this checker sees the identities and not the
# angles). Before this, the pass froze the copy surface while stage 2b would still
# have CERTIFIED the very shape it froze — a gate disagreement of exactly the class
# bd uow0/1fim are about, found by the bd 5pio Rule-13 round.
#
# SLOT-AWARE, unlike the tape seed above, and it mirrors `isCopyOutSink` argument for
# argument: only arg 0 (the SOURCE) is a recorded rail; arg 1 is the carrier itself.
# The uncontrolled 2-arg form only — the `_controlled` data-mux copy and the
# `_inv`/`_unc` twins are excluded — and the two slots must be DISTINCT (an aliased
# `cqrt_copy_<W>(%x, %x)` is not a source-preserving read at all; the checker already
# rejects it as `B1-input-aliases-written-rail`).
_COPY_SINK = re.compile(rf"cqrt_copy_{_W}$")


def recorded_rails(fn, mints):
    """Names in `fn` transitively correlated with a kept output carrier."""
    writers = {}
    for _lbl, calls, _term in fn.blocks:
        for c in calls:
            eff = classify(c.sym)
            if eff is None:
                continue
            targets = set()
            if c.res:
                targets.add(c.res)
            for wi in eff.writes:
                if wi < len(c.vals):
                    targets.add(c.vals[wi])
            for tgt in targets:
                writers.setdefault(tgt, []).append(c)

    seed, work = set(), []
    for _lbl, calls, _term in fn.blocks:
        for c in calls:
            if _TAPE_SINK.fullmatch(c.sym):
                for v in c.vals:        # SLOT-BLIND — see the note above
                    if v not in seed:
                        seed.add(v)
                        work.append(v)
                continue
            # bd 5pio: the copy-out SOURCE only (arg 0), distinct from its carrier.
            if _COPY_SINK.fullmatch(c.sym) and len(c.vals) == 2 \
                    and c.vals[0] != c.vals[1]:
                v = c.vals[0]
                if v not in seed:
                    seed.add(v)
                    work.append(v)
    while work:
        x = work.pop()
        for w in writers.get(x, ()):
            for v in w.vals:
                if v in mints and v not in seed:
                    seed.add(v)
                    work.append(v)
    return seed


def resolve_object(fn, ptr, bank_globals, _seen=None):
    """The underlying object `ptr` names, or None if this file cannot tell.

    Pointer arithmetic and pointer casts FORWARD the object; everything else
    (`select`, `phi`, `inttoptr`, a call result, a formal parameter) does not,
    and answers None. None is a REFUSAL — `adjudicate_memory` raises on it
    while a bank is in scope — never "it is classical".
    """
    if ptr is None:
        return None
    if _seen is None:
        _seen = set()
    if ptr in _seen:
        return None                 # a pointer cycle: refuse
    _seen.add(ptr)
    if ptr.startswith("@"):
        return ptr                  # a module-scope object names itself
    d = fn.def_op.get(ptr)
    if d is None:
        return None                 # a formal parameter, or an unparsed def
    op, line, _ln = d
    if op == "alloca":
        return ptr                  # a function-local object names itself
    if op in PTR_FORWARDING_OPS:
        return resolve_object(fn, first_ptr_operand(line), bank_globals, _seen)
    return None


LIFETIME_CALL_RE = re.compile(r"\bcall\s+void\s+@llvm\.lifetime\.(?:start|end)\.p0\(")


def bank_address_confined(fn, bank):
    """bd xdu2.4 — does the bank's ADDRESS stay inside a provable derivation?

    True iff every value derived from `bank` by a pointer-forwarding op
    (`PTR_FORWARDING_OPS`) is used ONLY as: the pointer operand of another
    forwarding op, the pointer operand of a `load`, the pointer operand (never
    the value) of a `store`, or the object of a `llvm.lifetime.{start,end}`.
    Any other mention - a phi/select merge, a call argument, a stored pointer,
    `ptrtoint`, a compare, a `ret` - answers False.

    Why that settles L2 for EVERY other pointer: under LLVM's provenance rules
    a pointer into the bank must be DERIVED from the bank's address, and a
    confined address flows nowhere but this derived set. So a load through a
    pointer outside the set (a formal parameter such as `argv`, a call result,
    anything) cannot read a bank cell, whatever its root. The only escapes
    would be out-of-bounds arithmetic from another object or a guessed
    `inttoptr`, both UB in the source, and an `inttoptr` of the bank's address
    needs a `ptrtoint` of it, which is refused above.

    Debug records (`#dbg_*`) are ignored: they carry no semantics.
    """
    derived = {bank}
    changed = True
    while changed:
        changed = False
        for _n, ln in fn.insts:
            dm = DEF_OP_RE.match(ln)
            if dm and dm.group(2) in PTR_FORWARDING_OPS and \
                    dm.group(1) not in derived and \
                    first_ptr_operand(ln[dm.end():]) in derived:
                derived.add(dm.group(1))
                changed = True
    for _n, ln in fn.insts:
        if ln.lstrip().startswith("#dbg_"):
            continue
        dm = DEF_OP_RE.match(ln)
        body = ln[dm.end():] if dm else ln
        toks = [t for t in SSA_NAME_RE.findall(body) if t in derived]
        if not toks:
            continue
        # Defensive, and an EQUIVALENT mutant under LLVM's grammar (measured by
        # deleting it): every two-derived-token line is already refused by the
        # clause below that owns its opcode. Kept so a future clause cannot
        # admit a line on its FIRST derived operand alone.
        if len(toks) != 1:
            return False
        t = toks[0]
        if dm and dm.group(2) in PTR_FORWARDING_OPS | {"load"} and \
                first_ptr_operand(body) == t:
            continue
        sm = STORE_RE.match(ln)
        if sm and sm.group(1) != t and \
                first_ptr_operand(ln.split(",", 1)[1]) == t:
            continue
        if LIFETIME_CALL_RE.search(ln) and first_ptr_operand(
                ln[ln.index("(") + 1:].split(",", 1)[1]) == t:
            continue
        return False
    return True


def adjudicate_memory(fn, mints, bank_globals):
    """bd 21re — the LOAD/STORE half of the model, and what it REFUSES.

    THE FALSIFIED PREMISE
    ---------------------
    `provably_not_a_rail` answers True for any non-call SSA value, and its
    docstring converted the ABSENCE of evidence into positive evidence for the
    `load` class:

        "A handle cannot reach a global and come back - a tainted `store` is a
         loud decline at `declineTaintEscapes` long before lowering - so a load
         result is not a rail."

    bd `xdu2` (L-1a, the bounded rail ARRAY) exists precisely to remove that
    decline: `bool b[N]` is carved into an `[N x i32]` bank of HANDLES, so a
    load from a bank cell IS a rail. Two distinct wrong-discharges follow, and
    both are `exit 0` on the pre-fix tool (the committed subjects are
    $SES/trackI/probes/p1 and p2):

      * the bd `az1h` defect through a new door - a bank load in the slot the
        ABI merely ASSERTS is classical, discharged `A1-classical-immediate`;
      * a bank load used as a CONTROL, where the model's write history is keyed
        on the literal SSA operand string, so the rail's real history (under its
        MINT name) is invisible and a non-cancelling pair reduces to identity.

    WHAT THIS FUNCTION DOES
    -----------------------
      (L1) a `store` whose VALUE is a known rail of this function and whose
           object is not a `!cq.railbank` bank (or cannot be resolved) is a
           LOUD STOP. This is the premise above turned into a CHECK: either no
           rail reaches memory, or the memory it reaches is marked.
      (L2) with a bank in scope, a `load` whose object cannot be resolved is a
           LOUD STOP - it is the difference between a classical immediate and a
           rail, and this file must not guess it. EXCEPT (bd xdu2.4) when every
           bank in scope is a local alloca whose address is CONFINED
           (`bank_address_confined`): then no pointer outside the bank's own
           derivation has bank provenance, so the load is DECIDED classical
           rather than guessed. The exact-Grover `argv[1]` load is the customer;
           a module-scope bank is never exempted.
      (L3) a BANK-LOAD result used in a slot `classify()` models as a RAIL slot
           (a read or a write index - NOT a `classical_imm` slot) at any symbol
           other than `cqrt_measure_<W>` is a LOUD STOP: `Rail.writes` is keyed
           on the SSA name, so that name and the mint's name are two rails to
           the model and no verdict about either is sound. `cqrt_measure_<W>`
           is the ONE exemption, because it is the only use SCOPE_L1a's D5
           allow-list sanctions and it is the L-1a emitted shape (p3).

    and RETURNS the bank-load results, which `check_module` folds into
    `rail_defs` so `provably_not_a_rail` answers False for them - the positive
    half, whose live arm is the `classical_imm` slot (L3 owns every other).

    WHAT IT DOES NOT DO, STATED SO THE NEXT INCREMENT DOES NOT REDISCOVER IT
    -----------------------------------------------------------------------
      * A bank load is NOT entered into the stream write history (`self.rails`).
        Doing so would MANUFACTURE a second rail identity for one physical rail,
        which is the defect, not the fix. (L3) is what makes that absence safe:
        no modelled rail slot may hold one.
      * The (L1) store rule keys on values this file can SHOW are rails - a
        rail-minting call result in this function. A FORMAL PARAMETER is
        "cannot vouch either way" (`provably_not_a_rail` refuses it too), and
        refusing every parameter store would fire on classical spills. A
        promoter that banks a parameter rail is therefore out of this rule's
        reach; it is also not a shape L-1a emits (a bank is a local alloca).
      * Nothing here sees a rail that reaches memory through a callee. The file
        is intra-procedural by construction (bd `1yeu`: every corpus in the tree
        is one function per module, so a cross-function defect is invisible to
        all of them).
      * (L3) matches the bank load's OWN SSA name. A bank load LAUNDERED through
        classical arithmetic (`%z = zext i1 %v`, `%w = add i32 %v, 0`) and only
        then handed to a gate is NOT matched - it is the same
        "ALIASING THAT IS NOT SSA-IDENTITY" / "NON-CALL instructions" blind spot
        the header already names, reached through the bank instead of through a
        `select`. What stands in front of it is the PASS, exactly as it does for
        the select/phi case: SCOPE_L1a's D5 allow-list makes "a bank load
        feeding arithmetic" a loud DECLINE, so a laundered one should never
        reach stage 2b. It is filed rather than left implicit, and it is the
        first thing to build if D5 ever widens.

    L8 RETIREMENT TRIGGER: when L-1a's taint rule + type rewrite + D5
    allow-list land (bd `xdu2`, the second half), REAL lowered modules carry
    `!cq.railbank`, the hand-built subjects stop being the only exercise of
    these three rules, and (L3)'s measure-only exemption must be re-derived
    against the allow-list the pass actually ships. Re-derive it then; do NOT
    delete the subjects.
    """
    banks = set(fn.bank_allocas) | set(fn.window_allocas) | set(bank_globals)

    # (L1) - unconditional: it is what makes the premise CHECKED, not assumed.
    for line, val, ptr, text in fn.stores:
        if val not in mints:
            continue
        obj = resolve_object(fn, ptr, bank_globals)
        if obj is None or obj not in banks:
            raise Undecidable(
                "L1-rail-stored-to-unmarked-memory", fn.name, line,
                f"`{text}` stores the rail {val} into "
                + (f"{obj}, which carries no `{RAILBANK_MD}` marker"
                   if obj else "an object this file cannot resolve")
                + ". `provably_not_a_rail` reasons that no `load` result can be "
                  "a rail BECAUSE a tainted store is a loud decline before "
                  "lowering (bd 21re); this module falsifies that premise, so "
                  "every load classification below it would be a guess. Mark "
                  f"the bank with `{RAILBANK_MD}`, or add this escape "
                  "mechanism to `adjudicate_memory` before trusting any "
                  "verdict from this file")

    if not banks:
        return frozenset()          # premise holds: nothing changes

    # bd xdu2.4: an UNRESOLVED load is provably not a bank load when every
    # bank in scope is a local alloca whose address is CONFINED (see
    # `bank_address_confined`). A module-scope bank is never exempted: its
    # address is reachable from every function, which this per-function file
    # cannot survey.
    confined = not bank_globals.intersection(banks) and all(
        bank_address_confined(fn, b)
        for b in fn.bank_allocas | fn.window_allocas)

    bank_loads = set()
    for line, res, ptr, text in fn.loads:
        obj = resolve_object(fn, ptr, bank_globals)
        if obj is None and confined:
            continue
        if obj is None:
            raise Undecidable(
                "L2-undecidable-load-provenance", fn.name, line,
                f"`{text}` loads through a pointer whose underlying object "
                f"this file cannot resolve, and a `{RAILBANK_MD}` bank is in "
                f"scope in @{fn.name}. With a bank present the answer decides "
                f"whether {res} is a classical immediate or a rail handle "
                f"(bd 21re), so it is refused rather than assumed")
        if obj in banks and obj not in fn.window_allocas:
            bank_loads.add(res)

    # (L3) - every use of a bank load outside the sanctioned measure slot.
    if bank_loads:
        for _lbl, calls, _t in fn.blocks:
            for c in calls:
                eff = classify(c.sym)
                if eff is None:
                    continue
                if re.fullmatch(rf"cqrt_measure_{_W}", c.sym):
                    continue
                for i, v in enumerate(c.vals):
                    if v not in bank_loads or i in eff.classical_imm:
                        continue
                    raise Undecidable(
                        "L3-bank-rail-in-a-modelled-rail-slot", fn.name,
                        c.line,
                        f"`{c.text}` puts the rail-bank load {v} in operand "
                        f"slot {i} of @{c.sym}, which this file models as a "
                        f"RAIL slot. The write history is keyed on the literal "
                        f"SSA operand string, so {v} and the rail's mint name "
                        f"are two different rails to the model and a gate on "
                        f"one is invisible to the other (bd 21re). The only "
                        f"sanctioned use of a bank load is the user's "
                        f"`cqrt_measure_<W>` (SCOPE_L1a D5); anything else is "
                        f"refused rather than guessed at")
    return frozenset(bank_loads)


def window_families(fn, bank_globals):
    """bd 01po.19 S4 — a `!cq.railwindow` HANDLE ARRAY, ARRAY-GRANULAR.

    A rolled quantum array keeps its cells' rail HANDLES in memory between
    windows, so one physical rail is spelled by a different SSA load in every
    window, and by the value a rebind stored into the cell. The stream model
    keys a rail's write history on the literal SSA name, so left alone a gate
    on one spelling is invisible to a reversal reading another — the bd 21re
    hazard (L3) in its window form. The array cannot be told apart cell by
    cell (the index is a runtime value), so EVERY cell read of the array and
    every rail stored into it is renamed to ONE canonical rail per array
    (`<alloca>.cells`), in every call operand but never in a call RESULT (a
    mint keeps its own name and its own census line). A gate on any cell is
    then a write on the canonical rail, and a reversal of a temporary that read
    any cell must find that rail unwritten since its forward gate: strictly
    more writes than the program performs, so the model can only refuse more,
    never vouch for a reversal the program does not support. A free of a
    cell rail is a free of a rail this function never minted and is never
    discharged. Returns {spelling: canonical}.
    """
    ren = {}
    if not fn.window_allocas:
        return ren
    for _line, res, ptr, _text in fn.loads:
        obj = resolve_object(fn, ptr, bank_globals)
        if obj in fn.window_allocas:
            ren[res] = obj + ".cells"
    for _line, val, ptr, _text in fn.stores:
        obj = resolve_object(fn, ptr, bank_globals)
        if obj in fn.window_allocas and val.startswith("%"):
            ren[val] = obj + ".cells"
    return ren


def apply_window_families(fn, ren):
    """Rewrite every call OPERAND named in `ren` (see `window_families`) in
    `vals`/`args` — the WRITE history — and keep `cvals`/`cargs` on the
    ORIGINAL spelling, so a forward on one cell read is never paired with an
    `_unc` on another (bd 01po.19 S4 review A-F1: canonicalizing the pairing
    operands too VERIFIED a dirty free whose `_unc`s read the swapped cells).
    `pairing_register` maps a spelling back to the canonical rail for the
    (T2) unchanged-operand question."""
    def rename(vals, args):
        for k, v in enumerate(vals):
            c = ren.get(v)
            if c is not None:
                vals[k] = c
                args[k] = args[k].split()[0] + " " + c
    ptrs = window_cell_pointers(fn, ren)
    for _lbl, calls, _t in fn.blocks:
        for c in calls:
            if c.cvals is c.vals:
                c.cvals, c.cargs = list(c.vals), list(c.args)
            # bd 01po.19 S5: which operand pairs are two PROVABLY DISTINCT
            # cells of one array (`window_cells_distinct`), asked on the
            # original spellings before the array-granular rename below.
            c.window_distinct = {
                (i, j) for i, a in enumerate(c.vals)
                for j, b in enumerate(c.vals)
                if i != j and window_cells_distinct(fn, ptrs.get(a), ptrs.get(b))}
            rename(c.vals, c.args)
    fn.window_alias = dict(ren)


def window_cell_pointers(fn, ren):
    """{spelling: cell pointer} for every renamed window spelling with ONE
    address (a cell read's pointer, or the single store parking a value)."""
    ptrs, seen = {}, set()
    for _line, res, ptr, _text in fn.loads:
        if res in ren:
            ptrs[res] = ptr
    for _line, val, ptr, _text in fn.stores:
        if val in ren and val not in ptrs:
            if val in seen:
                ptrs.pop(val, None)
                continue
            seen.add(val)
            ptrs[val] = ptr
    return ptrs


GEP_CELL_RE = re.compile(
    r"getelementptr\s+(?:inbounds\s+)?i32,\s*ptr\s+(%[-\w.]+),\s*i64\s+(\S+)\s*$")
ADD_CONST_RE = re.compile(
    r"^(add|sub)\s+(?:nuw\s+)?(?:nsw\s+)?i64\s+(%[-\w.]+),\s*(-?\d+)\s*$")


def _affine_index(fn, v, depth=0):
    """`v` as (base, offset): an i64 literal is (None, k); `add/sub X, k`
    chains fold into the offset; anything else is its own base."""
    if re.fullmatch(r"-?\d+", v):
        return None, int(v)
    d = fn.def_op.get(v)
    if d is None or depth > 16:
        return v, 0
    m = ADD_CONST_RE.match(d[1].split("=", 1)[-1].strip())
    if not m:
        return v, 0
    base, k = _affine_index(fn, m.group(2), depth + 1)
    return base, k + (int(m.group(3)) if m.group(1) == "add" else -int(m.group(3)))


def _window_cell(fn, ptr):
    """(object, base, offset) of a handle-array cell pointer, or None."""
    d = fn.def_op.get(ptr)
    if d is None:
        return None
    if d[0] == "alloca":
        return ptr, None, 0
    m = GEP_CELL_RE.search(d[1].split("=", 1)[-1].strip().split(", !")[0])
    if not m or m.group(1) not in fn.window_allocas:
        return None
    return (m.group(1),) + _affine_index(fn, m.group(2))


def window_cells_distinct(fn, pa, pb):
    """bd 01po.19 S5 — are two handle-array cell pointers PROVABLY different
    cells of ONE array? Asked by this instrument INDEPENDENTLY of the compiler
    (whose own answer is SCEV's, `railWindowDistinct`): an instrument must not
    share the transformation it witnesses, so this is a deliberate second
    proof, not a second spelling. The proof is narrow on purpose: both cell
    indices are the SAME SSA base (or both literals) plus different constant
    offsets through `add`/`sub` chains. Anything else is unproven, and the
    Case-B rule then fires (fail closed)."""
    if pa is None or pb is None:
        return False
    a, b = _window_cell(fn, pa), _window_cell(fn, pb)
    return a is not None and b is not None and a[0] == b[0] and \
        a[1] == b[1] and a[2] != b[2]


# ---------------------------------------------------------------------------
# THE CENSUS (bd rixk, bd 19vy, bd 1739 hole 1)
#
# The census line is not a proof — it is the thing that stops the PROOF COUNT
# from being read as a coverage measure. bd 261j(b) added it because "0
# cqrt_free site(s): 0 verified" passes STRICT, so a compiler that stops
# freeing everything reports a clean gate. Two halves of that line were wrong
# in opposite directions and both were quoted as measurements for months.
#
# (1) bd rixk — IT COUNTED STATIC SITES IN EVERY FUNCTION OF THE MODULE,
#     INCLUDING BODIES THAT CANNOT EXECUTE. `-O1` inlines a small `slice()`
#     into `main` and KEEPS the out-of-line body (external linkage, no call
#     site left), so eleven lines of loop-free C reported "6 rail mint(s)" for
#     a trace that allocates 3. MEASURED at the fix: 162 OF THE 368 lowered
#     e2e slices carried a doubled census for exactly this reason — the shape
#     is the corpus norm, not a corner. CLAUDE.md records only the OTHER
#     direction ("a rolled per-trip alloc reads as ONE rail"), which is an
#     UNDER-count and needs a loop; this one is an OVER-count and needs no
#     loop at all. Both are the same root cause: A STATIC SITE CENSUS
#     PRESENTED AS A RAIL COUNT.
#
#     The fix is reachability, not a heuristic: count only functions that can
#     execute — `main`'s static call graph when the module has a `main`, every
#     function nothing in the module calls otherwise, plus every
#     address-taken function, and EVERYTHING when an indirect call makes the
#     call graph unresolvable (the conservative direction is the old
#     behaviour, and it is stated in the census line rather than assumed).
#
#     ⚠ WHAT IT IS STILL NOT. This remains a STATIC SITE census: a site inside
#     a loop executes K times and counts once. Reachability only removes
#     bodies that cannot run at all. Do not quote the number as "rails the
#     program allocates"; quote it as "rail mint SITES that can execute".
#
# (2) bd 19vy / bd 1739 hole 1 — IT COUNTED ONLY `cqrt_alloc_*`. A rail minted
#     by a `cq_template_*` (or a `cqrt_qram_load_<W>`) was invisible: not
#     counted as minted, not counted as leaked, and therefore not visible at
#     all when it is never uncomputed, never freed and never measured. That is
#     the C-1 leak family CLAUDE.md warns must not be cleared by this file,
#     and it is the ONE residual of the F x P value-arm accepts (`h6 =
#     cq_template_add_i32_hl(h2, -3)` in slice_control_cascade_three_bools,
#     the owner's own headline slice: minted, never reversed, never freed,
#     never measured, and invisible to every gate in the tree).
#
#     `left_dirty` uses census_03_orphan_rails.py's UNDISCHARGED definition
#     verbatim (Rule 14 — one spelling of one population): a template/qram
#     rail with no `_unc` naming it in the OUT slot, no `cqrt_free` of it, no
#     `cqrt_measure_*` of it, and no escape. CROSS-CHECKED against that file's
#     independent trace-layer sweep at the fix: 5361 here over 368 lowered
#     modules against its 5046 over 383 goldens, and the direction is the
#     expected one (a trace is ONE EXECUTION and under-counts; static IR sees
#     both arms of a classical branch).
#
#     ⚠ IT IS REPORTED, NEVER FAILED ON, and that is deliberate rather than
#     timid: Rule 6's fallback LEAVES a not-provably-|0> rail allocated, 159
#     of 368 shipped slices do it, and deciding WHICH of those leaks is a
#     Rule-8 dephasing hazard is a compiler question (bd s82e), not one this
#     file can answer from structure. What this file can do is stop the number
#     being ZERO BY CONSTRUCTION.
# ---------------------------------------------------------------------------

Census = namedtuple("Census",
                    ["minted", "leaked", "tmpl_minted", "tmpl_dirty",
                     "unresolved_callgraph"])

# A call through a value rather than a symbol: `call i32 %fp(i32 %x)`. One of
# these anywhere in the module means the static call graph is not the whole
# call graph, and the census says so instead of pretending.
INDIRECT_CALL_RE = re.compile(
    r"^\s*(?:%[-\w.$]+\s*=\s*)?(?:tail\s+|musttail\s+|notail\s+)?call\s"
    r"(?:[^@\n]|\([^()]*\))*?%[-\w.$]+\s*\(", re.M)
RET_VALUE_RE = re.compile(r"^\s*ret\s+\S+\s+(%[-\w.$]+)", re.M)
# The output tape is KEPT BY DESIGN (Phase 7.6: never freed, never uncomputed),
# so a tape rail that is never discharged is CORRECT. Excluded here for the
# same reason census_03_orphan_rails.py excludes it, and named so the exclusion
# is visible rather than silent.
_TAPE_MINT = re.compile(rf"cqrt_tape_write_{_W}(?:_controlled)?")


def address_taken(text, defined):
    """Defined functions whose `@name` appears somewhere other than a call."""
    out = set()
    for name in defined:
        pat = re.compile(r"@" + re.escape(name) + r"(?![\w.$])")
        for line in text.split("\n"):
            if not pat.search(line):
                continue
            s = line.lstrip()
            if s.startswith("define") or s.startswith("declare"):
                continue
            m = CALL_RE.match(line)
            if m and m.group(2).strip('"') == name:
                # A direct call to it is not taking its address — but the same
                # line may ALSO pass it as an argument, so check the operands.
                popen = line.index("(", m.end() - 1)
                if not pat.search(line[popen:balanced(line, popen)]):
                    continue
            out.add(name)
            break
    return out


def live_functions(funcs, text):
    """(set of function names that can execute, call-graph-unresolved flag)."""
    defined = {fn.name for fn in funcs}
    if not defined:
        return set(), False
    edges = {}
    for fn in funcs:
        e = set()
        for _lbl, calls, _term in fn.blocks:
            for c in calls:
                if c.sym in defined:
                    e.add(c.sym)
        edges[fn.name] = e
    if INDIRECT_CALL_RE.search(text):
        # Unresolvable: fall back to the pre-rixk behaviour (count everything)
        # and SAY SO. The safe direction for a census is to over-report.
        return set(defined), True
    if "main" not in defined:
        # A TRANSLATION UNIT, NOT A PROGRAM. Every external-linkage function in
        # it may be entered from outside the module, so nothing here can be
        # shown dead and the census counts all of it — the pre-rixk behaviour,
        # kept deliberately. This is also why the narrowing costs nothing on
        # `ir-pass/test/*.ll`, which are single-function modules with no `main`.
        # The rixk shape REQUIRES a `main`: it is `-O1` inlining a callee into
        # it and keeping the now-uncalled out-of-line body.
        return set(defined), False
    roots = {"main"} | address_taken(text, defined)
    seen, work = set(), list(roots)
    while work:
        x = work.pop()
        if x in seen:
            continue
        seen.add(x)
        work.extend(edges.get(x, ()))
    return seen, False


# 2026-10-08 review (bd r2j3.19 round 2 F2): a Phase-6 clone whose result is not
# an i32 handle returns CLASSICAL data (a clone returns a rail only as an i32
# handle, R13), so it mints no rail. Census only; verification never reads this.
_CALL_RET_TY = re.compile(
    r"=\s*(?:tail |musttail |notail )?call\s+(?:[a-z_]+(?:\([^)]*\))?\s+)*([^\s@]+)\s+@")


def _clone_returns_data(c):
    if not c.sym.startswith("__cq_q_"):
        return False
    m = _CALL_RET_TY.search(c.text)
    return bool(m) and m.group(1) != "i32"


def _returned_by(fn):
    """The values `fn` ITSELF returns. Per function, like `rail_defs`: LLVM
    reuses local names (`%r`, `%0`) across functions, so a module-wide set let
    another function's `ret i32 %r` discharge a dirty rail here and the census
    report 0 (review round 3, 2026-10-08)."""
    return {m.group(1) for _lbl, _calls, term in fn.blocks
            for m in [RET_VALUE_RE.match(term)] if m}


def census_of(funcs, text):
    """The reported census over the functions that can actually execute."""
    live, unresolved = live_functions(funcs, text)
    minted = leaked = tmpl_minted = tmpl_dirty = 0
    for fn in funcs:
        if fn.name not in live:
            continue
        returned = _returned_by(fn)
        freed, uncd, measured, escaped = set(), set(), set(), set()
        mints = []
        for _lbl, calls, _term in fn.blocks:
            for c in calls:
                eff = classify(c.sym)
                if eff is None:
                    # An unmodelled callee (a user classical call, a Phase-6
                    # clone this file does not model): a handle passed to it
                    # ESCAPES, and an escaped rail is the callee's to discharge.
                    escaped.update(c.vals)
                    continue
                if c.sym == "cqrt_free" and c.vals:
                    freed.add(c.vals[0])
                elif eff.role == "unc" and c.vals:
                    uncd.add(c.vals[0])        # DD-3: the rail is slot 0
                elif eff.role == "inv":
                    uncd.update(c.vals)        # generous: the ABI names no rail
                elif eff.role == "measure" and c.vals:
                    measured.add(c.vals[0])
                if c.res and eff.mints == "rail" and not _clone_returns_data(c):
                    mints.append((c.res, eff.role, c.sym))
        for res, role, sym in mints:
            if role == "alloc":
                minted += 1
                if res not in freed:
                    leaked += 1
            else:                              # template / qram_load / tape
                if _TAPE_MINT.fullmatch(sym):
                    continue                   # kept BY DESIGN (7.6)
                tmpl_minted += 1
                if not (res in freed or res in uncd or res in measured
                        or res in returned or res in escaped):
                    tmpl_dirty += 1
    return Census(minted, leaked, tmpl_minted, tmpl_dirty, unresolved)


def check_module(text):
    """Returns (findings, verified_count, free_site_count, proofs).

    `proofs` is one record per VERIFIED free site: the rule that discharged it
    and the set of source lines the proof consumed. It is what
    tools/free_pairing_check_test.py mutates, so the self-test can plant a
    defect in exactly the instructions a proof rests on rather than shotgunning
    the module and drowning in semantically-null mutants.
    """
    funcs = parse_module(text)
    module_defs = {}
    # Rails minted anywhere in a FUNCTION, keyed per function. `self.rails`
    # knows only the current stream, so without this a rail minted in another
    # block of the same function is invisible to `provably_not_a_rail`. It is
    # deliberately NOT module-wide: LLVM reuses `%0` / `%h` / `%h_op` across
    # functions, so a module-wide table both over- and UNDER-reports — a `%h`
    # that names a rail here and a `cqrt_measure` result elsewhere would
    # resolve to whichever definition was parsed last. Per function it is
    # exact. (`classify` may raise Unclassified here rather than in the stream
    # scan; that is the same loud failure, one step earlier.)
    rail_defs = {}
    for fn in funcs:
        mints = set()
        for _, calls, _ in fn.blocks:
            for c in calls:
                if not c.res:
                    continue
                module_defs[c.res] = (fn.name, c.sym)
                eff = classify(c.sym)
                if eff is not None and eff.mints is not None:
                    mints.add(c.res)
        rail_defs[fn.name] = mints
    # bd 21re — the MEMORY half. Runs AFTER the mint scan (it needs to know
    # which values are rails) and BEFORE anything consults `rail_defs`, so a
    # rail that arrives through a `!cq.railbank` cell is a rail everywhere
    # `provably_not_a_rail` is asked. It RAISES rather than reports for the
    # constructs the model cannot decide — see `adjudicate_memory`.
    for fn in funcs:
        rail_defs[fn.name] |= adjudicate_memory(
            fn, rail_defs[fn.name], getattr(funcs, "bank_globals", ()))
        # bd 01po.19 S4: one canonical rail per handle array (see
        # `window_families`), applied before any stream is built.
        ren = window_families(fn, getattr(funcs, "bank_globals", ()))
        if ren:
            apply_window_families(fn, ren)
            rail_defs[fn.name] |= frozenset(ren.values())
    recorded = {fn.name: recorded_rails(fn, rail_defs.get(fn.name, frozenset()))
                for fn in funcs}
    # bd 261j(b) — THE LEAK CENSUS. This file counts free SITES, so a compiler that
    # stops freeing everything reports "0 cqrt_free site(s): 0 verified" and passes
    # STRICT. That is not a hypothetical failure mode: bd 261j(a) is a change whose
    # whole content is "emit fewer frees", and its blunt alternative would have
    # emitted none at all. A count of verified proofs is not a coverage measure
    # unless you also know what it did NOT have to prove. Rails left allocated are
    # LEGAL (Rule 6's fallback) so this is reported, never failed on — but it is
    # reported, so the number can never be silently zero.
    # Its two measured defects (bd rixk: static sites across INLINED COPIES; bd
    # 19vy / bd 1739 hole 1: `cqrt_alloc_*` only) are fixed in `census_of`.
    census = census_of(funcs, text)
    findings, verified, sites, proofs = [], 0, 0, []
    for fn in funcs:
        # ONE `build_streams` per function, shared with the (T4) index, so the
        # stream ids the index hands out and the ones the scan runs under are
        # the same numbers by construction rather than by agreement.
        _WINDOW_ALIAS.clear()
        _WINDOW_ALIAS.update(getattr(fn, "window_alias", {}))
        streams = build_streams(fn)
        xstream = CrossStreamIndex(fn, streams)
        for sid, (_chain, calls) in enumerate(streams):
            if not calls:
                continue
            ensure_recursion_headroom(len(calls))
            sa = StreamAnalysis(fn.name, calls, module_defs, fn.params,
                                rail_defs.get(fn.name, frozenset()),
                                recorded.get(fn.name, frozenset()),
                                xstream, sid)
            findings.extend(sa.run())
            verified += sa.verified
            sites += sa.sites
            proofs.extend(sa.proofs)
    return findings, verified, sites, proofs, census


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Rule-6 free-pairing checker over lowered CQ IR.")
    ap.add_argument("files", nargs="+")
    ap.add_argument("-q", "--quiet", action="store_true")
    ap.add_argument("--allow-unproven", action="store_true",
                    help="report UNPROVEN free sites without failing")
    ap.add_argument("--stats", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--explain", action="store_true",
                    help="print, per verified free site, the rule that "
                         "discharged it and the source lines its proof rests on")
    args = ap.parse_args(argv)

    all_findings, verified, sites, unclassified = [], 0, 0, []
    undecidable = []
    minted_total = leaked_total = 0
    tmpl_total = tmpl_dirty_total = 0
    unresolved_cg = False
    for path in args.files:
        try:
            with open(path) as fh:
                text = fh.read()
        except OSError as e:
            print(f"free_pairing_check: cannot read {path}: {e}",
                  file=sys.stderr)
            return 2
        try:
            f, v, s, proofs, cen = check_module(text)
        except Unclassified as e:
            unclassified.append((path, e.sym))
            continue
        except Undecidable as e:
            # bd 21re: the model cannot decide this construct, so no verdict
            # about this module is worth anything. Same discipline as an
            # unmodelled symbol, one layer down.
            undecidable.append((path, e))
            continue
        for x in f:
            x.path = path
        all_findings.extend(f)
        verified += v
        sites += s
        minted_total += cen.minted
        leaked_total += cen.leaked
        tmpl_total += cen.tmpl_minted
        tmpl_dirty_total += cen.tmpl_dirty
        unresolved_cg = unresolved_cg or cen.unresolved_callgraph
        if args.explain:
            for fn, line, handle, rule, lines in proofs:
                print(f"{path}: OK @{fn} line {line} [{handle}] via {rule} "
                      f"(witness lines {','.join(str(x) for x in lines)})")

    viol = [f for f in all_findings if f.kind == VIOLATION]
    unpr = [f for f in all_findings if f.kind == UNPROVEN]

    if args.json:
        def dump(fs):
            return [{"code": f.code, "file": f.path, "fn": f.fn,
                     "line": f.line, "handle": f.handle, "msg": f.msg}
                    for f in fs]
        print(json.dumps({"files": len(args.files), "free_sites": sites,
                          "rail_mint_sites": minted_total,
                          "rail_mints_left_allocated": leaked_total,
                          "template_rail_mint_sites": tmpl_total,
                          "template_rails_left_dirty": tmpl_dirty_total,
                          "call_graph_unresolved": unresolved_cg,
                          "verified": verified, "violations": dump(viol),
                          "unproven": dump(unpr),
                          "unclassified": [{"file": p, "symbol": s}
                                           for p, s in unclassified],
                          "undecidable": [{"file": p, "code": e.code,
                                           "fn": e.fn, "line": e.line,
                                           "msg": e.msg}
                                          for p, e in undecidable]},
                         indent=2))
    else:
        for path, sym in unclassified:
            print(f"free_pairing_check: {path}: UNCLASSIFIED SYMBOL @{sym} — "
                  f"add its read/write effects to classify() before trusting "
                  f"any verdict from this file", file=sys.stderr)
        for path, e in undecidable:
            print(f"free_pairing_check: {path}: UNDECIDABLE MEMORY CONSTRUCT "
                  f"[{e.code}] @{e.fn} line {e.line}: {e.msg}", file=sys.stderr)
        for f in viol:
            print(f"{f.path}: {f}", file=sys.stderr)
        for f in unpr:
            print(f"{f.path}: {f}",
                  file=sys.stdout if args.allow_unproven else sys.stderr)
        if not args.quiet or viol or unpr or unclassified:
            print(f"free_pairing_check: {len(args.files)} file(s), "
                  f"{minted_total} rail mint(s) of which {leaked_total} left "
                  f"allocated, "
                  f"{tmpl_total} template rail mint(s) of which "
                  f"{tmpl_dirty_total} left dirty, {sites} "
                  f"cqrt_free site(s): {verified} verified, {len(viol)} "
                  f"violation(s), {len(unpr)} unproven"
                  + (" [call graph unresolved: every function counted]"
                     if unresolved_cg else "")
                  + (f", {len(unclassified)} unclassified symbol(s)"
                     if unclassified else "")
                  + (f", {len(undecidable)} undecidable memory construct(s)"
                     if undecidable else ""))
    if args.stats:
        for k, n in Counter(f.code for f in all_findings).most_common():
            print(f"   {n:6d}  {k}")

    if unclassified or undecidable or viol:
        return 1
    if unpr and not args.allow_unproven:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
