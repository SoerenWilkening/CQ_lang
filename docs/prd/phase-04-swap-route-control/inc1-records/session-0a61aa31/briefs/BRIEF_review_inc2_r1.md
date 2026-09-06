# BRIEF_review_inc2_r1 — Rule-13 ROUND 1 on Inc 2 (value arms by controlled-copy merge), two lenses
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_impl_inc2.md`, `$SP/progress/impl_inc2.md` (fully — it
records a Step-0 finding that changed the witness, two new fences, and a load-bearing reviewer flag),
PRD §3 ("Value arm by controlled copy"), §7, §10.3 item 8. Agent name: `review_inc2_V<n>`. Model: opus.
READ-ONLY. SUBJECT = `$SP/wt/inc2` at 8c526d9 (branch `3qlq-inc2`, its `build/` is current; never edit
or rebuild it); ORACLE = `$SP/wt/pre-3qlq` (52d7764; both surfaces are the SAME here — Inc 2 does not
touch cq_phi — so every program runs unchanged on both). Files under `$SP/progress/review_inc2_V<n>/`.

## The claim under review
A tainted-condition VALUE arm (`if (c) p = R(p)`, `R` a pure chain of template ops) no longer takes the
cswap route. `emitValueRegion` HOISTS the arm's proven pure linear chain into the pred (unconditionally,
on the original `p`), builds a `select` with Rule-9 polarity, RAUWs the merge φ, flattens, and hands the
select to the Rule-13-cleared 4.4 `emitSelectRegion` (controlled-XOR copy merge): `alloc out(|0>)`;
`copy_controlled(f, R(p), out)`; `x(f)`; `copy_controlled(f, p, out)`; `x(f)`; chain `_unc`; strip; free.
`p` stays allocated and entangled with `out` (keep-source-live). V2 if/else = both chains hoisted; V3
switch = preload `copy(p,out)` + per-case `d_i = R_i(p) ^ p` (Q+Q xor) + `copy_controlled(f_i, d_i, out)`
+ uncompute. Witness: byte identity with the PRE-HOISTED select twin `int t = R(p); p = c ? t : p;`
(three cmp pairs). Two new fences: speculation totality via `llvm::isSafeToSpeculativelyExecute`
(a `p/n` with run-time classical n declines — a NARROWING of a shipped accept), and an explicit Q+Q
condition decline.

## V1 — the MECHANISM, adversarially (PRD §10.3 item 8 + the reviewer flag)
1. **Speculation totality.** The hoisted chain runs on EVERY branch. For each template opcode the arm
   may contain (read `OpcodeSupport.cpp` for the supported set; the templates are generated from
   `tools/opcode_table.yaml` — read the runtime bodies in `runtime/cq_templates.c` for `sdiv`/`srem`/
   `udiv`/`urem`/shifts/`fdiv`/`frem`-if-any): is the template TOTAL on the inactive branch's input?
   `isSafeToSpeculativelyExecute` is LLVM's predicate about UB of the LLVM instruction; the question
   here is about the TEMPLATE the instruction lowers to — a Q+Q `sdiv` whose divisor is a tainted
   register that is zero on the inactive branch (`if (d != 0) p = p / d;` — the canonical guard!)
   lowers to `cq_template_sdiv_i32(h_p, h_d)`: what does the trace/runtime do at d=0? Does the
   shipped pass ACCEPT this (isSafeToSpeculativelyExecute says sdiv by a non-constant is unsafe → it
   should decline — MEASURE it), and does the decline cover `udiv`, `srem`, `urem`, shifts by a
   tainted amount ≥ W (`if (s < 32) p = p << s;` — is the template total? measure both binaries),
   `fdiv` by tainted zero (inf/NaN are labels — argue whether the merge is still a permutation).
   The oracle's route ran the chain on a |0> work rail on the inactive branch (`0 / d`), so the
   hazard class changed shape: before, the inactive-branch input was ZERO; now it is `p`'s real value.
   Find any opcode whose template is total at 0 but not at arbitrary p (e.g. a Bennett divider that
   asserts the quotient fits?) — read the template bodies, do not assume.
2. **§3c clobber under the hoist.** The hoisted chain must be OUT-OF-PLACE only (fresh rails); an
   in-place dtzb `cqrt_addc/xorc` on `p`'s rail (M-C) before the strip would relabel the condition
   operand if the condition READS p. Probe: `if (p > 5) p = p + 3;` (condition on p itself — must
   decline §3c as before, measure the string), `if (q > 5) p = p + 3;` with q ≠ p (accept; check
   whether M-C fires in place on p — it must NOT, because the second `copy_controlled(f, p, out)`
   reads the ORIGINAL p AFTER the chain ran; if M-C converts `p+3` in place, the second copy reads
   p+3 and the merge is WRONG on the inactive branch: `out = f ? p+3 : p+3`). This is the round's
   most likely miscompile: read `OpcodeLowering`'s M-C in-place decision (G6/G7 "later record
   read") and confirm the hoisted chain's ops are refused in-place conversion BECAUSE the controlled
   copy is a later read — then try to defeat it: a chain whose LAST op is in-place-eligible, a chain
   of one op, a derived base, an arm that reads p twice (`p = p + p`), a chain feeding two arms.
3. **Derived bases / the reviewer flag.** `emitSelectRegion` is now reached with inputs
   `classifySelectRegion` would refuse (derived bases `r = p*5` etc. — `slice_control_value_derived`
   ships without a twin because its select twin declines on both binaries). Enumerate what
   `classifySelectRegion` refuses that the br classifier accepts, and for each construct the
   program, run it on both binaries, and argue the unitary (the select-merge's correctness proof
   assumed its own preconditions — which of them did the value diamond path skip?). Include:
   a base that is a compare-derived rail; a base that feeds the CONDITION's derived chain; a base
   that is an alias of q (`int a = q, b = q`); an fp base (kjd1 copy family — is `copyControlledFpFn`
   reached from the diamond path?); an `i1` base; `i128`.
4. **Uncompute interaction.** The chain's `_unc` after the merge, the flag strip, `out` as the new
   register: probe a dead `out` (whole-DAG spine frees it?), `out` measured, `out` returned, `out`
   feeding a second region, two value diamonds on one p (the hcrg sequential ordering), a value
   diamond followed by a kickback on `out` (needs Inc 1 — skip), in-loop value arm (must keep the
   loop decline — measure the string).
5. **The three twin gates** — re-run all three cmp pairs on the subject and on the oracle (the twin
   is a pre-hoisted select the oracle already lowered — its trace must be IDENTICAL on both binaries,
   else the oracle moved and the witness is void).

## V2 — V3 (switch), the fixture/doc truth, and the goldens
1. **V3 XOR-delta.** Per case `d_i = R_i(p) ^ p` then `copy_controlled(f_i, d_i, out)` onto the preloaded
   `out = p`: correct only if the per-case flags are MUTUALLY EXCLUSIVE and EXHAUSTIVE over the
   non-default range — with an EMPTY default (C5) a scrutinee value hitting no case must leave `out
   = p`: measured? Two cases with the SAME chain (`case 1: case 2: p = p+1;` grouped → must decline
   C4); a case whose chain is the identity (`p = p`); a case value equal to a value the preload
   already encoded; N=1 case; the default arm carrying a chain (C5 decline); a switch inside a loop.
   Byte identity with the 4.5 data-mux precedent where the structures coincide.
2. **Fixture truth.** Every fixture Inc 2 added or rewrote (`git diff --name-only main..HEAD --
   ir-pass/test` in `$SP/wt/inc2`): CHECKs re-derived from the subject's output, handle names exist,
   counts in their own prefix, NOROUTE pure-negative whole-file; injection matrix over every accept
   (a `cqrt_cswap`; a work-rail `cqrt_alloc(0)`+`cswap`+`free` triple; a dropped `copy_controlled`; a
   swapped polarity `cqrt_x` pair; a dropped chain `_unc`) with clean + known-bad controls; decline
   strings character-for-character in the source (incl. the retired-mechanism string `value-arm
   swap-route` still in use — record where).
3. **Goldens.** `slice_control_value_diamond` (28→23) and `slice_control_switch_value` (29→23):
   reproduce the regeneration on the subject, diff against the committed pre-Inc-2 goldens (`git show
   main:tests/e2e/<f>.expected.log`), and audit line by line that the ONLY change is the route →
   copy-merge substitution (state the substitution shape precisely; anything else is a finding).
   The six new slices + three cmp gates: run them.
4. **The cswap census** claim ("zero value-path call sites; survivors = AbortParkEmit + the two
   PHASE routes Inc 1 retires"): grep and confirm; run the two phase-route fixtures on the subject
   to confirm they are unchanged from the oracle.

Both lenses: write `$SP/progress/review_inc2_V<n>.md` with numbered findings F-V<n>-k (grade
CONFIRMED-MISCOMPILE / OVER-DECLINE / DOC-OR-FIXTURE-TRUTH / CLEAR, reproducer, both traces, the
analytic argument, proposed fix file:line, pinning fixture) and a verdict line; return it as the
final message.
