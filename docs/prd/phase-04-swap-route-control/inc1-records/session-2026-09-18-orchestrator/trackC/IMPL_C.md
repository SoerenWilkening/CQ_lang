# Track C — (T4), the LOOP-EXIT DISCHARGE for `tools/free_pairing_check.py`

**Branch** `freepair-loop-exit-discharge`, forked from the gate tip `10e95a52`.
**Tip** `3fcecc84`. **Files touched: two, and only two** —
`tools/free_pairing_check.py` and `tools/free_pairing_check_test.py`.
The pass source, `tools/loop_twin_matrix*`, every fixture, every golden and
`tests/e2e/CMakeLists.txt` are **untouched** (`git diff --stat` at the commit:
`2 files changed, 798 insertions(+), 8 deletions(-)`).

**Binary of record.** Every measurement below is on the COMBINED gate binary,
built once in this worktree at `-j2` from the same sources:

```
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
96d74fe6008133b843cf5fc5f9ab2f3f96fb4f7986f905676044ce39e676a4bb  build/ir-pass/cq-opt
f9acb293a76af15a09a65b7f8c7ff69ef525849da48e5a897dc330e22ca77a74  build/ir-pass/libCQPass.so
```

both byte-identical to the gate worktree's. The CHECKER ORACLE is
`git show 10e95a52:tools/free_pairing_check.py`.

---

## 0. What was broken, stated as a cost rather than as an inconvenience

`free_pairing_check.py` analyses per **STREAM** — a maximal chain of blocks
joined by unconditional single-predecessor edges. Group 1's P2 anchor discharges
a rail minted OUTSIDE a loop at that loop's **unique exit**, so the mint lands in
one stream and the `_unc` + `cqrt_free` in another. `check_free` then takes the
`extern` arm and reports `U3-extern-rail` on a rail that is provably `|0⟩`.

Two consequences, and the second is the expensive one:

1. `tests/e2e/slice_loop_hoisted_chain_exit_discharge` had to be registered with
   `--allow-unproven` (`tests/e2e/CMakeLists.txt:6223`). That is the **FIFTH**
   such entry, where CLAUDE.md's Build & Test section records **four** and says
   *"every other slice runs strict"* — gate filing **G-4**.
2. `e2e-loop-twin-matrix` runs this checker **STRICT per side**
   (`loop_twin_matrix.py:2064`, `:2166`), so a cell whose rolled side reports
   UNPROVEN returns `HARNESS-ERROR` and **never reaches the trace comparison**.
   **24 cells + the pinned boundary control `q_armoncond` stopped having a
   verdict at all** — and that matrix is the only instrument in the tree that can
   see a leaked TEMPLATE-minted rail. Gate filing **G-7**, which costed this fix
   as option (b) and recommended it.

**All 25 cells are ONE class.** The gate's own measurement:
`grep -o "UNPROVEN [A-Za-z0-9-]*" gate/matrix_report_96d74fe6.txt | sort | uniq -c`
→ `101 UNPROVEN U3-extern-rail`, and nothing else.

---

## 1. Reproduction — measured before any code was written

Sources regenerated read-only via `tools/loop_twin_matrix.py`'s `sources()`
(the matrix itself was **not** run). ⚠ `sources()` takes a `surface` argument
defaulting to `"register"`; the matrix runs the **void** surface, and on the
register surface the `rz`/`der`/`range` cells emit the two-argument
`cq_phi(r, θ)` spelling that is a hard compile error in today's `CQ.h`. Cells
marked `.void` below were regenerated with `surface="void"`; that is a fact about
the regeneration recipe, not about the cells.

| module (lowered on `96d74fe6`) | ORACLE `10e95a52` | SUBJECT (T4) |
|---|---|---|
| `slice_loop_hoisted_chain_exit_discharge` (ROLLED) | `1 verified, 0 violation(s), 3 unproven` | **`4 verified, 0 violation(s), 0 unproven`** |
| `slice_loop_hoisted_chain_exit_discharge_unrolled` (twin) | `5 verified, 0 violation(s), 0 unproven` | `5 verified, 0 violation(s), 0 unproven` |
| `trackT2/probes/a1_apost` | `1 / 0 / 3` | **`4 / 0 / 0`** |
| `trackT2/probes/a1_apost_un` | `5 / 0 / 0` | `5 / 0 / 0` |
| **bd `1m5p` class A, all six:** | | |
| `m_none_oder_none_none_none` (rolled) | `2 / 0 / 6` | **`8 / 0 / 0`** |
| `m_none_oder_none_none_addpost` (rolled) | `1 / 0 / 3` | **`4 / 0 / 0`** |
| `m_none_oder_none_none_rypost` (rolled) | `1 / 0 / 3` | **`4 / 0 / 0`** |
| `m_none_oder_none_none_rypre` (rolled) | `1 / 0 / 3` | **`4 / 0 / 0`** |
| `m_none_oder_none_none_rzpost` `.void` (rolled) | `1 / 0 / 3` | **`4 / 0 / 0`** |
| `m_none_oder_none_rpostmark_none` (rolled) | `1 / 0 / 3` | **`4 / 0 / 0`** |
| *(their five `.unrolled` twins)* | `5 / 0 / 0` | `5 / 0 / 0` — **unmoved** |
| **three more HARNESS-ERROR cells, other families:** | | |
| `m_none_der_none` `.void` (rolled) | `2 / 0 / 6` | **`8 / 0 / 0`** |
| `m_none_range_none` `.void` (rolled) | `2 / 0 / 2` | **`4 / 0 / 0`** |
| `m_none_rder_none_none_rypost` (rolled) | `1 / 0 / 3` | **`4 / 0 / 0`** |

Every SUBJECT row above exits **0 under STRICT** (no `--allow-unproven`). The
ORACLE column for `m_none_der_none` and `m_none_range_none` matches the gate's
`MATRIX_ADJUDICATION.md` per-cell census table character for character, which is
what says the reproduction is of the gate's finding and not of a lookalike.

**Two IR shapes, both covered.** The 3-deep LICM chain
(`sitofp_i32_to_f64` → `fadd_f64_hl` → `sqrt_f64`, rails `%h_cast`/`%h_op`/`%h_intr`)
and the single `add_i32_hl` rail (`%h_op`). The cells where `main` also carries an
inlined copy of `slice` report **both** streams; those are the `6 unproven` /
`2 unproven` rows, and both halves are proved.

---

## 2. The slices question, answered

**The rolled slice did NOT pass strict 2b.** It is registered **with
`--allow-unproven`** at `tests/e2e/CMakeLists.txt:6223`; its twin is registered
STRICT with no flag. Reproduced exactly: `1 verified, 0 violation(s), 3 unproven`
against the twin's `5 verified, 0 unproven`.

**Is that a landing defect? No — and the distinction is worth stating precisely.**
A silent `--allow-unproven` would be one. This one carries (a) a written
structural reason of exactly the kind CLAUDE.md demands for the four dtzb
entries, (b) a positional compensation — `ir-pass/test/loop_pairing_accept_hoisted_chain_exit_discharge.ll`
pins the rail identities by `CHECK-NEXT` — and (c) an **L8 RETIREMENT TRIGGER**
naming this track's work: *"if `free_pairing_check.py` ever grows a cross-stream
model, drop this flag and re-derive the count — do NOT leave it as insurance."*
What IS now stale is CLAUDE.md's own count and naming pattern (four → five, and
the fifth is not a `loop-break` slice) — that is gate filing **G-4**, already
routed to the closing docs pass.

**Does the rule prove exactly the gate's three?** Yes — by rail name and by mint
symbol, and nothing else changed:

```
$ python3 tools/free_pairing_check.py --explain <rolled.s2.ll>
  OK @slice line 21 [%h_intr]  via T4-loop-exit-discharge (witness lines 16,20)
  OK @slice line 23 [%h_op]    via T4-loop-exit-discharge (witness lines 15,22)
  OK @slice line 25 [%h_cast]  via T4-loop-exit-discharge (witness lines 14,24)
  OK @slice line 41 [%h_cmp]   via T1-unc-reversal        (witness lines 36,37,39,40)
free_pairing_check: … 4 cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven
```

line 14 = `%h_cast = … @cq_template_sitofp_i32_to_f64(i32 %h)`, line 15 =
`%h_op = … @cq_template_fadd_f64_hl(…)`, line 16 = `%h_intr = … @cq_template_sqrt_f64(…)`.
The per-trip flag `%h_cmp` is still discharged by the ordinary in-stream (T1)
rule — (T4) did not take a site that was already proved.

**The retirement trigger is therefore MET**, and dropping the flag is a
one-line edit at `tests/e2e/CMakeLists.txt:6223` that this track **did not make**
(out of its file scope). Recommended to whoever owns that file, with the
re-derived count: `4 verified, 0 violation(s), 0 unproven`.

---

## 3. The rule as written

Entry point: `StreamAnalysis.loop_exit_discharge`, reached **only** from the
`r.kind == "extern"` arm of `check_free`. Supporting machinery:
`CrossStreamIndex` (one per function, built from the SAME `build_streams` result
the scan runs under, so stream ids cannot drift).

Let `%h` be freed at `F`, position `pos` in stream `S_f`, with an `extern` record.

- **(T4a) UNIQUE TEMPLATE MINT.** Exactly one call in the function defines `%h`
  (SSA), its Effect has `mints == "rail"` and `role == "mint"`, and it is not a
  `cqrt_tape_write_<W>`. ⚠ An **`alloc` rail is REFUSED** — its soundness rests
  on (A1)/(A2), a *reduction of its whole write history*, and reducing one across
  a back edge is precisely what the stream model exists not to do. An `_inv` mint
  is refused too (`implicit-rail` names no rail).
- **(T4b) THE REVERSAL IS IN THE FREE'S OWN STREAM.** A call at `rev < pos` in
  `S_f` with `role == "unc"`, `base == M.sym`, `vals[0] == %h` and
  `tuple(args[1:]) == tuple(M.args)` — the **(T1a) test verbatim**. The (T1b)
  `_inv` arm is deliberately NOT admitted cross-stream: an `_inv` names no rail,
  so its pool and its one-to-one claim are per-stream bookkeeping. `undef` /
  `poison` in the forward operands is refused exactly as (T1u) refuses it — a
  textual operand match is not a value match (bd `1739` hole 2).
- **(T4c) `%h` IS WRITTEN NOWHERE IN THE FUNCTION BUT THAT REVERSAL.** The
  load-bearing conjunct. It is what makes the loop body safe **without looking at
  the loop**: every in-loop use of `%h` is a READ operand, and a read relabels
  nothing in this file's effect model. It also SUBSUMES the two checks the
  `extern` arm returns in front of — a `cqrt_measure_<W>(%h)` is a write here, so
  `F8-free-after-measure` cannot be bypassed, and `R1-recorded-rotated-rail`
  needs a `cqrt_ry_` ON the rail, which is a write too. Both are refused
  **function-wide** rather than stream-locally: strictly stronger than the checks
  being skipped. Each has its own mutant.
- **(T4d) EXACTLY ONE `cqrt_free(%h)` IN THE FUNCTION.** `F1-double-free` is
  per-stream and cannot see a rail minted once and freed at two exits.
- **(T4f) NEITHER THE MINT'S NOR THE FREE'S STREAM CAN REPEAT.** Checked over
  **every block** of each chain, not just its head — a non-head block's single
  predecessor makes the head argument true, but this is a Rule-6 gate so the
  property is CHECKED rather than inherited. This is what forbids the **K:1**
  shape (mint once outside, reverse-and-free K times inside) that P2's own anchor
  walk exists to avoid. With it, `M`, `R` and `F` each execute at most once and
  each stream is a linear trace, so a position comparison inside one stream is a
  real execution order.
- **(T4g) THE FORWARD OPERANDS HOLD STILL FROM MINT TO REVERSAL.** Every write to
  each rail operand of `M` is either in `S_m` at a position `< M`, or in `S_f` at
  a position `> rev`. Nothing in the loop body, nothing in a third stream,
  nothing in the window. ⚠ STRICTER than (T2)'s `unchanged_over` on purpose: no
  cancellation, no reduction, no commutation — a bracket that would reduce to
  identity across the loop is REFUSED.

**The proof.** The mint writes `f(args)` into a fresh `|0⟩` rail; the reversal
writes `f(args′)` where `args′` are the operands' labels at the reversal. (T4c)
gives "nothing else writes `%h`", (T4g) gives `args′ == args`, so
`%h = |0⟩ ⊕ f(args) ⊕ f(args) = |0⟩`, and (T4c) again gives nothing writes it
between the reversal and the free. **SSA supplies the missing dominance for
free**: every use of `%h` is dominated by its definition, so the mint's block
dominates the free's and no path reaches the reversal without the mint. Nothing
in the argument counts activations, which is why a NESTED loop needs no reasoning
at all — a read that runs K times is K reads, and a WRITE that runs K times is
refused by (T4c) whichever loop carries it.

### What it does NOT prove — the stated limits

* **Any write to `%h` inside the loop.** Not a cancelling `X` bracket, not an
  `A B A B` route. (T4c) is a COUNT, deliberately.
* **An `alloc` rail in this shape** (T4a) — a deliberate over-decline, with its
  own fixture `t4-alloc-rail-cross-stream-bracket` whose `xorc/xorc` bracket
  genuinely reduces to identity.
* **Any cycle through the mint's or the free's stream** (T4f) — refused, not
  classified. Irreducible cycles included.
* **A forward-operand write in a THIRD stream**, even one provably after the
  free. Measured while building the (T4d) control: a `cqrt_measure_i32(%h)`
  placed in a sibling successor block refuses at (T4g). Closing that needs a
  dominance/post-dominance relation the file does not have (bd `j31l` names the
  same missing machinery).
* **A rail read after its free from another block.** `F2-use-after-free` stays
  per-stream; that gap is pre-existing and untouched.
* **The ENTANGLEMENT half of Rule 8**, as everywhere else here. The rail is `|0⟩`
  and unentangled AT THE FREE; that says nothing about a which-path record the
  loop body may have copied onto some OTHER carrier (bd `s82e`'s question).
* **PHASE**, as everywhere else: `cqrt_rz` is transparent to this file. The
  positive control `t4-diagonal-rz-on-the-rail-inside-the-loop` VERIFIES with an
  `rz` applied per trip — that fixture pins the two write models **agreeing**,
  not the physics, and says so at the fixture.

---

## 3a. bd `t4sw` — THE P1 THE COMPOSITION ROUND FOUND, AND IT WAS IN THE PARSER

An independent Rule-13 composition round (`$SES/review_r13_composition/REVIEW.md`
F-1) filed a **P1 against (T4)**: it **VERIFIED the exact K:1 stream (T4f) exists
to refuse**, when the loop's back edge is a `switch` case.

**Reproduced on this branch before any fix** (`probes/t4_switch_backedge_k1.ll`):
`2 verified, 0 violation(s), 0 unproven`, **rc=0** — while the byte-identical
`br i1` control (`t4_br_backedge_k1_control.ll`) was refused correctly with
(T4f)'s own message, rc=1.

**THE DEFECT WAS IN THE PARSER, NOT IN THE RULE**, and the pair is what proves
it — two modules one TERMINATOR SPELLING apart. `parse_module` recorded
`term = ln.strip()`, the **FIRST line** of a terminator, and `TERM_TARGETS_RE`
then matched `label %x` in that one line. LLVM prints a `switch`'s case targets
on the FOLLOWING lines, so `fn.succ` held only the DEFAULT target,
`cyclic_blocks()` could not see the back edge, and `stream_runs_at_most_once()`
answered `True` for a block that plainly repeats. `fn.preds` was incomplete the
same way, and `build_streams` merges blocks on a single-predecessor test.

Confirmed on a SHIPPED fixture, `lowering_classical_mux_phi_onereg_switch_nway.ll`:
before, `succ['%entry'] = ['%merge']` and `preds['%arm1'] = preds['%arm2'] = []`;
after, `succ['%entry'] = ['%merge','%arm1','%arm2']` and `preds['%arm1'] = ['%entry']`.

**THE FIX is the one the reviewer preferred**, not the conservative one.
`read_terminator` accumulates terminator lines by **bracket balance** — exactly
the set LLVM wraps (`switch`, `indirectbr`); every other terminator is complete
on its first line, leaves `depth == 0`, and is returned unchanged. The rejected
alternative — *"any function containing a `switch` answers cyclic everywhere"* —
passes both K:1 mutants and silently refuses every future module that mixes a
switch with a loop-exit discharge, which is why `t4-acyclic-switch-still-verifies`
exists and why it is in the arm-kill matrix in the ANTI direction.

**`invoke` is a LOUD REFUSAL rather than a half-parse.** It is a call AND a
terminator and this file models **neither** half — `CALL_RE` requires `call`, so
an `invoke`d `cqrt_*` never enters the effect model, and `TERM_START_RE` does not
list it, so a block whose successors are unknown would read as ACYCLIC, the same
(T4f) defeat through a second door. New refusal code
`P1-invoke-is-a-call-and-a-terminator`. MEASURED: the only two `invoke`s in the
tree are in `lowering_reject_intrinsic_invoke_phi.ll` and `spec_reject_eh.ll`,
**both of which the PASS declines**, so no lowered module reaches the checker with
one and this costs nothing today.

**MEASURED AFTER THE FIX:**

| module | before | after |
|---|---|---|
| `t4_switch_backedge_k1.ll` (RED) | `2 verified, 0 unproven`, **rc=0** | **`1 verified, 1 unproven`, rc=1**, naming (T4f) |
| `t4_br_backedge_k1_control.ll` (GREEN control) | `1 verified, 1 unproven`, rc=1 | **unchanged** |

**Corpus, targeted and the targeting is the argument.** The fix can only change a
module whose LOWERED IR contains a multi-line terminator or an `invoke`; every
other module parses byte-identically, so a full sweep would be measuring
unchanged inputs. Both populations were enumerated and A/B'd in full against the
pre-fix checker (`43039a28`):

* **`ir-pass/test`: 2095 fixtures, 1044 accepted by `cq-opt`, exactly 1 with the
  construct in lowered IR** (`lowering_classical_mux_phi_onereg_switch_nway` —
  the fixture the reviewer named), **0 MOVED.** Its CFG is now correct; its
  verdict cannot move because it has 0 free sites.
* **e2e: 25 `.c` sources mention `switch`, exactly 1 reaches the construct in
  lowered IR** (`slice_classical_switch_gate`), **0 MOVED.**

So the P1 is closed with **zero** shipped verdict movement — it was latent, as
the filing says, and it is closed on the instrument rather than on the corpus.

⚠ **THE LESSON, and it is worth more than the fix.** (T4)'s arm-kill matrix
killed eight of nine arms — **including (T4f) twice** — and every one of those
mutants spelled its CFG with `br`. *An arm-kill that never varies the SPELLING of
the construct it tests measures the rule and not the parser underneath it.*
(T4f) now has **three** killers, two of them `switch`-spelled.

---

## 3b. RESIDUALS — stated, not fixed

### F-2 (P3, filed by the composition Rule-13 round) — (T4g) is STREAM-LOCAL

`(T4g)` accepts a write to a forward operand only when
`wsid == self.stream_id and wpos > rev_pos` — the **free's own** stream. A
trailing gate that `-O1` places in a **SUCCESSOR** block is therefore
*"neither before the mint in the mint's own stream nor after the reversal in
this one"*, and a discharge that is genuinely proven reports UNPROVEN.

**Probes:** `$SES/review_r13_composition/probes/x1_multiexit_hoisted_cond_then_ry.c`
and `x2_twoexit_goto.c`. Both report `2 template rail mint(s) of which 0 left
dirty` **and** `1 verified, 0 violation(s), 1 unproven`, rc=1, naming
`cqrt_ry_i32(%h, 0.9)` — a gate in a block that is a successor of the free's and
therefore strictly after the reversal on every path. `dD1`, the same circuit with
that gate in the reversal's own block, reports `0 unproven`, rc=0.

**Direction: SAFE** — UNPROVEN, never VERIFIED. **Deliberately NOT widened
here**, on the coordinator's instruction and because widening it to *dominated
successors* is a real increment with its own Rule-13 obligation: it needs a
dominance/post-dominance relation this file does not have, which is the same
machinery bd `j31l` names. I reproduced it independently while building (T4d)'s
control — the first draft of `t4-one-reversal-one-free` put the `cqrt_measure` of
`%h` in a sibling successor block and was refused at (T4g); moving it into the
free's own block is what made the control verify.

**Cost, stated because it is the half that matters:** an e2e slice of the
`x1`/`x2` shape could not be registered without `--allow-unproven` — the flag
this track has just finished driving from 5 back to 4. So the exception is gone
for the shipped SLICE and not for the SHAPE.

### The parser residual that came with the bd `t4sw` fix

`read_terminator` stops accumulating at `}` or at a label rather than running to
the end of the module. On the textual grammar `llvm-as` accepts that boundary is
never reached; on a malformed or truncated block it truncates the terminator,
which loses targets, which makes `cyclic_blocks()` **under**-report — the
over-accept direction. It is refused-by-truncation rather than diagnosed, and it
is written at the function rather than assumed.

---

## 4. L10 — the mutant table, with its MISSED count

17 named mutants + 5 positives = **21 T4 cases**, plus 1 refusal; proof-targeted sweep
**315 → 329** (blanking (T4)'s own witness lines — its mint and its reversal —
is required to break the proof).

⚠ **The harness asserts the ARM, not just the code.** Every mutant here would
report `U3-extern-rail` if (T4) simply stopped working, so matching the finding
code alone would let **eleven of twelve** pass against a rule with one conjunct
left. Each row also names a fragment of the refusal text; the two rows refused
BEFORE (T4) is consulted carry `None` and assert the **ABSENCE** of a (T4)
clause, so they cannot drift into fake arm coverage.

| mutant | verdict | arm that spoke |
|---|---|---|
| `t4-write-to-rail-inside-the-loop` | `U3-extern-rail` | (T4c) `also writes %h_op` |
| `t4-rail-measured-then-freed` | `U3-extern-rail` | (T4c) — the `F8` non-bypass probe |
| `t4-rail-rotated-inside-the-loop` | `U3-extern-rail` | (T4c) — the `R1` non-bypass probe |
| `t4-adjoint-with-a-different-literal` | `U3-extern-rail` | (T4b) `no @…_unc` |
| `t4-undef-forward-operand` | `U3-extern-rail` | (T4b) `` `undef`/`poison` `` |
| `t4-k1-reversal-and-free-inside-the-loop` | `U3-extern-rail` | (T4f) free side, `can execute more than once` |
| `t4-mint-inside-the-loop` | `U3-extern-rail` | (T4f) mint side |
| `t4-one-reversal-two-frees` | `U3-extern-rail` | (T4d) `cqrt_free(%h_op) site(s)` |
| `t4-two-exit-blocks-two-reversals` | `U3-extern-rail` | **(T4c)** — *not* the arm it was written for; see below |
| `t4-forward-operand-moved-inside-the-loop` | `U3-extern-rail` | (T4g) |
| `t4-alloc-rail-cross-stream-bracket` | `U3-extern-rail` | (T4a) |
| `t4-non-lifo-discharge-order` | `U3-extern-rail` | (T4g) — **a real miscompile**, see below |
| `t4-adjoint-in-loop-free-outside` | `U1-cross-stream` | **pre-(T4)** — no write in the exit stream, so no extern record |
| `t4-free-above-the-adjoint` | `F2-use-after-free` | **pre-(T4)**, and loudly |
| POSITIVE `t4-range-cell-rolled` | 0 findings | 1 T4 proof |
| POSITIVE `t4-hoisted-chain-rolled` | 0 findings | 3 T4 proofs |
| POSITIVE `t4-one-reversal-one-free` | 0 findings | 1 T4 proof — (T4d)'s control |
| POSITIVE `t4-diagonal-rz-…-inside-the-loop` | 0 findings | 1 T4 proof — the write-model-agreement control |

**(T4g) CATCHES A REAL MISCOMPILE, not just a structural near-miss.**
`t4-non-lifo-discharge-order` discharges the 3-rail chain FIFO instead of LIFO —
`%h_cast`'s reversal is hoisted above the others, so `%h_op`'s reversal reads a
`%h_cast` that is already back at |0> and recomputes a DIFFERENT value. No
`cqrt_free` moves, so `F2-use-after-free` does not fire and (T4g) is the only
thing that speaks. This is bd `1m5p`'s own *"LIFO-INVERTED … `h3` is freed while
`h4`, derived from it, is still live"* hazard in its adjoint form. ⚠ The other
two rails still VERIFY, correctly — `%h_cast`'s reversal reads `%h` (untouched)
and `%h_intr`'s reads `%h_op` (written only later). A rule that refused the whole
module would be hiding its own precision.

**A mutant caught one arm earlier proves nothing about the arm it was written
for.** `t4-two-exit-blocks-two-reversals` was written for (T4d) and is caught by
(T4c), because a second exit block carries a second `_unc`. Isolating (T4d)
needed `t4-one-reversal-two-frees`, where ONE reversal dominates two free sites.
Both are kept, and the first is recorded with the arm it actually hits.

### The arm-kill matrix — **MISSED 1 of 9**

Each conjunct deleted individually from the source, the committed selftest re-run:

| arm deleted | selftest | killed by |
|---|---|---|
| (T4a) template-mint test | **RED** 1 | `t4-alloc-rail-cross-stream-bracket` |
| (T4b) undef test | **RED** 1 | `t4-undef-forward-operand` |
| (T4b) operand-list match | **RED** 1 | `t4-adjoint-with-a-different-literal` |
| (T4b) `w.vals[0] == name` | **GREEN — SURVIVED** | — |
| (T4c) single-write test | **RED** 4 | write-in-loop, measured, rotated, two-exit-blocks |
| (T4d) one-free test | **RED** 1 | `t4-one-reversal-two-frees` |
| (T4f) mint-stream acyclic | **RED** 1 | `t4-mint-inside-the-loop` |
| (T4f) free-stream acyclic | **RED** 1 | `t4-k1-reversal-and-free-inside-the-loop` |
| (T4g) forward-operand test | **RED** 2 | `t4-forward-operand-moved-inside-the-loop`, `t4-non-lifo-discharge-order` |

**The survivor, and why it is not deleted.** `w.vals[0] == name` in (T4b)
survives because it **restates the key it is searching**: `r.writes` is appended
by `rail_for_write(c.vals[wi])` for each `wi in eff.writes`, and a `_unc` Effect
has `writes=(0,)` — so every `w` in THIS rail's write list already carries `name`
at `w.vals[0]`. No input distinguishes the two versions while the `_unc` write
slot is 0. It is kept as an explicit statement of what the rule reads, with a
**RETIREMENT TRIGGER in the source** naming the day it becomes load-bearing (any
`role == "unc"` Effect given a write slot other than 0). Deleting it "because the
matrix says it is redundant" is the bd `0gwl` mistake, where *"redundant by
construction"* was refuted by a runnable stream one round later.

⚠ **An instrument lesson earned in this track, recorded rather than tidied
away.** The first run of the arm-kill matrix mutated `tools/free_pairing_check.py`
nine times **while a corpus verdict sweep was reading the same file**. Those
sweep results were discarded and the sweep restarted after the source was final.
A measurement taken against a file another process is rewriting measures nothing;
it is the same class as CLAUDE.md's *"never relink a binary under a running
measurement"*, one layer down.

---

## 5. The negative that matters — the dtzb rails are unmoved

(T4) must not accidentally PROVE the dtzb whole-loop reverse-play. Measured on
the four `--allow-unproven` entries, ORACLE vs SUBJECT, comparing the verdict
**and** the UNPROVEN-class breakdown:

| slice | ORACLE | SUBJECT |
|---|---|---|
| `slice_loop_break` | `12 verified, 0 violation(s), 4 unproven` — 2 `A-not-reducible`, 2 `U1-cross-stream` | **identical** |
| `slice_loop_break_qq` | `10 / 0 / 4` — 2 + 2 | **identical** |
| `slice_loop_break_qq_derived` | `10 / 0 / 4` — 2 + 2 | **identical** |
| `slice_loop_break_qq_i64` | `10 / 0 / 4` — 2 + 2 | **identical** |

Two conjuncts are why, and both have mutants: `%cq.brk.fire` is an **alloc** rail
((T4a)), and `%cq.brk.R` / `%cq.brk.idx` have their write history spanning the
back edge, so they carry writes outside the two admitted windows ((T4c)/(T4g))
and never had a reversal in the free's stream ((T4b)) — they report
`U1-cross-stream`, which (T4) is not even consulted for. Their
`--allow-unproven` still means exactly what it meant.

---

## 6. Non-churn evidence

* The **committed selftest's 30 pre-existing positive fixtures** — verbatim
  stage-2 output from shipped e2e slices — all still verify with **0 findings**,
  and all 77 named mutants, 10 memory refusals, 5 Case-A negatives and 19 census
  cases are unchanged. The only counts that moved are the ones this track added.
* `U3-extern-rail`'s finding **code and base message are byte-unchanged**. A
  `(T4) loop-exit discharge refused: …` clause is appended **only** for a NEAR
  MISS — a rail that has a cross-stream rail mint. A rail with no mint at all
  (the dtzb family) keeps its historic text exactly.
* A **corpus verdict diff** over every `tests/e2e/*.c` lowered on `96d74fe6`,
  ORACLE checker vs SUBJECT, comparing the FULL finding list rather than exit
  codes. **COMPLETE: 381 lowered modules compared, exactly 1 MOVED** (42 sources
  do not lower on this binary and are not in the denominator). False positives
  are the expensive direction for a GATE, and this is the only measurement that
  bears on them.

  **The one mover is the one that had to move**, and it is also the sweep's own
  POSITIVE CONTROL — without it, "380 unmoved" would be indistinguishable from a
  broken instrument:

  ```
  === slice_loop_hoisted_chain_exit_discharge
  ORACLE   4 cqrt_free site(s): 1 verified, 0 violation(s), 3 unproven
           (3 × UNPROVEN U3-extern-rail on %h_intr / %h_op / %h_cast)
  SUBJECT  4 cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven
  ```

  So on the whole shipped e2e corpus this change moves **one** verdict, in the
  intended direction, on the one slice that exists to carry the shape.

---

## 7. Gate

Announced in the shared `GATES_INFLIGHT.md` before running, per the
non-redundancy protocol. **One gate, and this track ran nothing else:**

```
ctest --test-dir build -R '^e2e-free-pairing-selftest$' --output-on-failure
1/1 Test #294: e2e-free-pairing-selftest ........   Passed    1.55 sec
100% tests passed, 0 tests failed out of 1
```

on `cq-opt 96d74fe6008133b8`. No `ir-pass-lit`, no `^e2e-slice-`, no full suite —
**the pass source is untouched**, so no other layer can witness this change; the
four `slice_loop_break*` verdicts above were measured directly on their lowered
IR rather than by running their ctest entries.

---

## 8. §bd — the exact `bd create` text

An instrument gap was found and closed in-session, with its mutants. File it as
CLOSED-on-landing, and file the two follow-ons it leaves.

```
bd create \
  --type bug --priority 2 \
  --title "free_pairing_check.py reports UNPROVEN U3-extern-rail on a SOUND loop-exit discharge, which costs e2e-loop-twin-matrix 24 cells + 1 pinned control their verdict" \
  --description "STAGE 2b VISIBILITY GAP, closed in-session by Track C on branch \
freepair-loop-exit-discharge, tip 43039a28 (tools/free_pairing_check.py + \
tools/free_pairing_check_test.py ONLY).

THE GAP. The checker analyses per STREAM (a maximal chain of blocks joined by \
unconditional single-predecessor edges). Group 1's P2 anchor (bd \
test_C_libtooling-tu9q) discharges a rail minted OUTSIDE a loop at that loop's \
unique EXIT, so the mint and the reversal land in two different streams and \
check_free takes the 'extern' arm: 'UNPROVEN U3-extern-rail ... handle is \
written in this stream but minted outside it ... its state on entry to this \
stream is unknown' — on a rail that is provably |0>.

THE COST, and the second half is the expensive one. (1) \
tests/e2e/slice_loop_hoisted_chain_exit_discharge had to be registered with \
--allow-unproven (tests/e2e/CMakeLists.txt:6223), the FIFTH such entry where \
CLAUDE.md records four and says 'every other slice runs strict' (gate filing \
G-4). (2) e2e-loop-twin-matrix runs this checker STRICT per side \
(loop_twin_matrix.py:2064,2166), so 24 twin cells PLUS the pinned boundary \
control q_armoncond returned HARNESS-ERROR and stopped having a verdict at all \
— and that matrix is the only instrument in the tree that can see a leaked \
TEMPLATE-minted rail (gate filing G-7, which costed this fix as option (b)). \
All 25 cells and all 101 of their UNPROVEN lines are ONE class, U3-extern-rail.

THE FIX is rule (T4), StreamAnalysis.loop_exit_discharge, reached only from the \
U3-extern-rail arm. It linearizes NOTHING across a back edge: every fact is \
either path-insensitive (a write COUNT over the whole function) or a position \
comparison inside one stream. Seven conjuncts — (T4a) unique template mint, \
alloc REFUSED; (T4b) the _unc in the free's own stream, operands matching, no \
undef, _inv not admitted; (T4c) exactly ONE write to the rail in the whole \
function, which is what makes the loop body safe without looking at the loop \
and which SUBSUMES F8-free-after-measure and R1-recorded-rotated-rail \
function-wide; (T4d) exactly one cqrt_free; (T4f) no cycle through the mint's \
or the free's stream, forbidding the K:1 shape; (T4g) forward operands written \
only before the mint or after the reversal. SSA supplies the dominance.

MEASURED, ORACLE 10e95a52 vs SUBJECT, all on cq-opt 96d74fe6008133b8: the \
rolled e2e slice 1 verified/0 violations/3 unproven -> 4/0/0 STRICT exit 0, and \
the three proofs are EXACTLY the gate's three by rail and mint symbol \
(%h_intr/sqrt_f64, %h_op/fadd_f64_hl, %h_cast/sitofp_i32_to_f64); \
trackT2/probes/a1_apost 1/3 -> 4/0; all SIX bd test_C_libtooling-1m5p class-A \
cells -> 0 unproven; three more HARNESS-ERROR cells from the der/range/rder \
families -> 0 unproven; every hand-unrolled twin UNMOVED.

THE NEGATIVE THAT MATTERS: all four e2e-slice-loop-break* slices are \
byte-identical in verdict AND in UNPROVEN-class breakdown before and after (2 \
A-not-reducible + 2 U1-cross-stream each). (T4) does not prove the dtzb \
whole-loop reverse-play.

L10 VALIDATION. 13 named mutants + 4 positives; the harness asserts the ARM \
(the refusal text), not just the finding code, because every mutant would \
report U3-extern-rail if the rule simply stopped working. Proof-targeted sweep \
315 -> 329. ARM-KILL MATRIX: nine conjuncts deleted individually, EIGHT turn \
the committed selftest RED each via a different fixture. MISSED 1 of 9 — \
'w.vals[0] == name' in (T4b) survives because it restates the key it searches \
(r.writes is keyed on the _unc write slot, which is 0), so no input \
distinguishes the two versions; kept with a retirement trigger in the source \
rather than deleted on a 'redundant by construction' claim (the bd \
test_C_libtooling-0gwl mistake).

GATE: ctest -R '^e2e-free-pairing-selftest$' Passed 1.55 s, 1/1, on cq-opt \
96d74fe6008133b8. Pass source untouched, so no other layer can witness it.

RECORD: docs/prd/phase-04-swap-route-control/inc1-records/\
session-2026-09-18-orchestrator/trackC/IMPL_C.md"
```

**Two follow-ons this leaves, to be filed separately:**

1. **Drop `--allow-unproven` from `tests/e2e/CMakeLists.txt:6223`** and re-derive
   the count to `4 verified, 0 violation(s), 0 unproven`. The rolled slice's own
   L8 retirement trigger says *"do NOT leave it as insurance."* Out of this
   track's file scope; it also retires gate filing **G-4** and updates CLAUDE.md's
   Build & Test paragraph back to **four** `--allow-unproven` entries.
2. **Re-run `e2e-loop-twin-matrix`** and re-adjudicate the 24 + 1 cells that were
   `HARNESS-ERROR`. They will now reach the trace comparison for the first time.
   ⚠ The six class-A `oder` cells are additionally expected to print
   `QUARANTINE STALE` — the gate already hand-measured them as **multiset-identical
   and order-divergent**, i.e. bd `1m5p` fixed in substance with a positional
   residue, and its disposition is **RE-PIN, do not remove**. `tools/loop_twin_matrix*`
   is Track V's exclusively (R14), so this track neither ran nor edited it.
3. ~~Finish the corpus verdict diff~~ — **DONE** (§6): 381 modules, 1 mover, and
   the mover is the slice item 1 is about.
