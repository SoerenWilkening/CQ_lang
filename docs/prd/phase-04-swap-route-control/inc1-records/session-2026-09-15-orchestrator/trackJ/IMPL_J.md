# IMPL_J — Track J, instruments. Session 2026-09-15.

Five beads, each an instance of **an instrument reporting a pass it did not earn**, plus the
`1yeu` scoping (`SCOPE_1yeu.md`) and the F-6 one-liner. Nothing under `ir-pass/`,
`ir-pass/include/` or `runtime/` was touched.

**ORACLE, verified before use and again at the end:**
`cq-opt 0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`,
`libCQPass.so 94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b`.
**This worktree's own build is BIT-IDENTICAL to it** (no pass source was edited), so every
measurement here is a fact about the session ORACLE binary.

Per bead: *what it claimed · what it actually witnessed · what it witnesses now · what it is
STILL blind to*. The last column is the one that matters; naming a residual gap beats
asserting coverage.

---

## bd `rixk` — the census counted static sites across INLINED COPIES

**CLAIMED.** `free_pairing_check: … N rail mint(s) of which M left allocated …` — quoted
throughout CLAUDE.md and the per-increment records as a measurement of rails.

**ACTUALLY WITNESSED.** A count of `cqrt_alloc_*` CALL SITES in *every* function of the
module, including bodies that cannot execute. `-O1` inlines a small `slice()` into `main` and
KEEPS the out-of-line body (external linkage, call dropped), so both copies were counted.

**MEASURED, and the shape is the corpus NORM rather than a corner:**

| | before | after | truth |
|---|---|---|---|
| `probes/j_rixk_inlined_dead_body.c` (11 lines, loop-free) | 6 mints | **3** | 3 (`./a \| grep -c cqrt_alloc`) |
| `slice_control_cascade_three_bools` (CLAUDE.md §4c's headline) | 9 / 7 left / 3 verified | **9 / 7 / 3, unchanged** | golden carries exactly 9 `cqrt_alloc`, 3 `cqrt_free` |
| the lowered e2e corpus | — | — | **162 of 368 slices carried a doubled census** |

**WITNESSES NOW.** The census counts only functions that can execute. `main`'s static call
graph when the module has a `main`; **every** function when it has none (a translation unit's
external functions may be entered from outside — and the rixk shape REQUIRES a `main`, since
it is `-O1` inlining into one); address-taken functions are roots; an indirect call anywhere
makes the graph unresolvable, so the census counts everything **and says so in the line**
(`[call graph unresolved: every function counted]`) rather than silently guessing.

⚠ **STILL BLIND TO.** It is still a **STATIC SITE census**. A site inside a loop executes K
times and counts once — the UNDER-count CLAUDE.md already records, untouched. Reachability
only removes bodies that cannot run. **Do not quote the number as "rails the program
allocates"; quote it as "rail mint SITES that can execute."** Also unmodelled: a function
reachable only through a function pointer stored in a global (address-taken covers the
common case, but a pointer laundered through memory the parser does not follow falls into
the indirect-call fallback only if an indirect *call* is visible in the same module).

---

## bd `19vy` + bd `1739` hole 1 — the census could not see a TEMPLATE-minted rail at all

**CLAIMED.** `0 violation(s)` on the F × P value-arm accepts.

**ACTUALLY WITNESSED.** Everything except the one rail those accepts are about. The census
counted `eff.role == "alloc"` only, so a rail minted by a `cq_template_*` or a
`cqrt_qram_load_<W>` was invisible: **not counted as minted, not counted as leaked, not
reported anywhere.** That is the C-1 leak family CLAUDE.md says must never be cleared by this
file — and it is live on the owner's own headline slice.

**WITNESSES NOW.** A second census clause: `K template rail mint(s) of which L left dirty`,
where *left dirty* is `census_03_orphan_rails.py`'s **UNDISCHARGED** definition reused
verbatim (Rule 14 — one spelling of one population): no `_unc` naming it in the OUT slot, no
`cqrt_free`, no `cqrt_measure_*`, no `ret`, no escape into an unmodelled callee. The output
tape (`cqrt_tape_write_<W>`) is excluded because 7.6 keeps it BY DESIGN, and the exclusion is
named in the code rather than implied.

**What it shows on the two subjects:**

* `slice_control_cascade_three_bools` — `9 rail mint(s) of which 7 left allocated, **2
  template rail mint(s) of which 1 left dirty**, 3 cqrt_free site(s): 3 verified`. The dirty
  one is **`h6 = cq_template_add_i32_hl(h2, -3)`** in the committed golden: minted, never
  `_unc`'d, never freed, never measured. **On the file CLAUDE.md §4c quotes as the landing's
  proof, and invisible to every gate in the tree until now.**
* `probes/j_gzgs_m28_VACUOUS_merge.c` and its live twin — `1 template rail mint(s) of which 1
  left dirty`, which is bd `19vy`'s `h6` exactly.

**INDEPENDENT CROSS-CHECK — two instruments, two layers, two parsers:**

| instrument | layer | corpus | undischarged template/qram rails |
|---|---|---|---|
| `free_pairing_check.py` (this fix) | static, lowered IR | 368 lowered slices | **5048** in 154 modules |
| `tools/record_census/census_03_orphan_rails.py` | executed trace | 383 goldens | **5046** in 155 goldens |

0.04 % apart, and the residual has the expected sign: a trace is ONE EXECUTION and under-counts
an untaken branch; static IR sees both arms. ⚠ **The agreement is itself evidence for the
`rixk` fix** — the same measurement *before* reachability gave 5361/159, and applying
reachability moved the static count onto the dynamic one.

⚠ **STILL BLIND TO / DELIBERATELY NOT A FAILURE.** A left-dirty template rail is **reported,
never failed on**. Rule 6's fallback makes leaving a not-provably-`|0⟩` rail allocated LEGAL,
159 of 368 shipped slices do it, and deciding **which** of those leaks is a Rule-8 dephasing
hazard (entangled *and* later interfered with) is a compiler question — bd `s82e`, bd `tu9q`,
and CLAUDE.md §5's Q-R1-1 correction — not one this file can answer from structure. What
changed is that the number can no longer be **zero by construction**.

---

## bd `1739` hole 2 — a textual operand match is not a value match when the text is `undef`

**CLAIMED.** T1's docstring: *"an `M_inv(a...)` whose ARGUMENT LIST matches the forward's
operand for operand"*, and `0 violation(s)` on a module whose adjoint inverts a different
predicate.

**ACTUALLY WITNESSED.** Operand **TEXT** identity. `undef`/`poison` is the one token in
LLVM's grammar that does not denote a value — LangRef lets each use materialise
independently, and at the `-O0` stage-3 link they do. **REPRODUCED on the shipped checker**
(`probes/j1739_undef_pairing.ll`): forward `cq_template_icmp_sgt_i32_hl(%h, i32 undef)`,
reversal `..._hl_unc(%c, %h, i32 undef)`, `cqrt_free(%c)` → `1 verified, 0 violation(s)`,
exit 0. The runtime prints the slot as a bare literal, so the golden cannot see it either —
both gates blind on the same axis, which is exactly the complementarity bd `8txa` claims.

**WITNESSES NOW.** One predicate, `carries_undef`, applied at the three places where operand
identity IS the proof: (T1a) the `_unc` arg-tuple match, (T1b) the `_inv` pool key, and
`adjoint_matches`' three arms. Two distinct codes, `T1-undef-literal-pairing` and
`A-undef-literal-pairing`, each naming the operand and the two lines.

**BLAST RADIUS — MEASURED, NOT ARGUED: ZERO.**

```
# 368 lowered e2e modules, old checker vs new, exit code compared per module
EXIT-CODE MOVERS (verdict-surface change): 0
alloc-census movers (rixk reachability): 162
```

⚠ **This sweep is load-insensitive by construction** and is reported as such per the
orchestrator's 2026-09-15 note: it is a pure-Python comparison of two checker versions over
368 **pre-lowered** `.ll` files — no compiler, no timing, deterministic — and it completed
with a full count of all 368. It was taken at the load stated in `GATES.md`. The four
`--allow-unproven` slices are inside that 368 and did not move; `e2e-slice-loop-break{,-qq,
-qq-derived,-qq-i64}` were additionally run and pass.

**Why zero:** exactly **1 of 368** lowered slices carries `undef`/`poison` in ANY
modelled-call operand — `%selop = call i32 @cqrt_alloc_f64(double undef)` in
`slice_libm_ld80_nexttoward`, which is bd `u7z9`'s blessed precedent — and it is an **ALLOC
SEED**, a slot this fix deliberately does not touch.

⚠ **STILL BLIND TO / SCOPE, stated so nobody widens it by accident.** The guard refuses a
**pairing** proof, never a value. It is NOT applied to a `cqrt_alloc_<W>(undef)` seed, nor to
rule (A1)'s classical-immediate slot, because those rules rest on the rail holding *a*
classical basis state and not on knowing *which* — an unentangled rail in an
unknown-but-definite basis state is still a sound reset. A control pins that
(`undef-control-alloc-seed-slot`), so "refuse every undef everywhere" cannot be shipped by
accident: it would turn a committed golden's slice red for a property this file does not
claim.

---

## bd `jdec` — the vacuity script reported `checked 0` instead of failing

**CLAIMED.** `checked 0 named negatives across N accept fixtures: 0 VACUOUS` — a line
indistinguishable at a glance from `checked 29, 0 VACUOUS`. PROTOCOL §S3 points **every track
in this session** at it.

**ACTUALLY WITNESSED — five defects, four of them worse than the filed one:**

1. It matched only the HANDLE form `; NOX-NOT: … (i32 %h)`, so a batch of 29 real (symbol)
   negatives scored **zero checks**, exit 0 (the filed defect).
2. **IT NAMES A WORKTREE THAT DOES NOT EXIST.** `REPO='/Users/sorenwilkening/Desktop/CQ_mphi'`
   — verified absent today. The copies name `CQ_3d8q`, `CQ_undef`, `CQ_wx8g`, all gone. **The
   shared script the protocol points at raises `FileNotFoundError` on this box.** A gate
   result is a fact about a BINARY; these were facts about nothing.
3. `if o.returncode != 0: continue` — every declining fixture dropped silently, uncounted.
4. It never printed which binary it used.
5. Five divergent copies with the same name and different coverage.

**WITNESSES NOW.** `tools/negative_vacuity_check.py`, one committed tool, six questions:
**V0** module non-empty (the 0-byte passthrough-accept trap, bd memory
`empty-module-accepts-vacuity-trap`); **V1** header collision (bd `qta2`), **scoped the way
FileCheck scopes a `-NOT`**; **V2** does the name exist in the lowered output, the fixture's
own input, or the universe; **V3** universe reachability; **V4** is the prefix passed to any
FileCheck on any RUN line at all; **V5** a decline writes 0 bytes of IR to stdout (Rule-12
hygiene defect (b)). It resolves the compiler from `--cq-opt`/`$CQ_OPT`/its own location,
**refuses to run without one**, and **prints its sha256 with every verdict**.

**Exit codes: 0 clean · 1 a VACUOUS finding · 2 A HOLE** — nothing evaluated, no arguments,
an empty module, a missing compiler, a universe that lowered to nothing. `checked 0` can no
longer be a pass.

**MEASURED over the whole corpus, ORACLE binary:**

```
$ python3 tools/negative_vacuity_check.py ir-pass/test/*.ll
negative_vacuity_check: 2039 fixture(s), 6734 directive(s) evaluated, 0 VACUOUS,
  18 decline-stdout note(s), 33 latent header collision(s), 1033 declining module(s),
  0 unparsed, 1 not-modelled (compiler input is not %s), 466 front-end-intrinsic
  exemption(s), 749 unreachable-symbol note(s), 155 on an unmodelled stream,
  2393 resolved by the universe, 0 undecidable (universe too small),
  universe 1005 module(s)  [cq-opt 0e280fc62a91cec2]           exit 0
```

**⚠ THE FOUR TIMES THIS TOOL CRIED WOLF ON ITS WAY TO THAT LINE, because they are the
finding, not the anecdote.** Every one was caught by running it over the tree before
shipping it, and every one would have shipped as a fabricated defect:

| draft rule | what it reported | why it was FALSE | fix |
|---|---|---|---|
| V4 with a permissive prefix regex | **719** fixtures with an "orphan prefix" | it matched comment prose (`; bd 3qlq: …`) | prefixes must be UPPERCASE and directive-shaped; population is then **0 of 2039** |
| V1 unscoped | 24 header collisions over `control_*` | a `PFX-NOT` only searches between positive `PFX` directives; a positive above it puts the header out of range | scoped; **1** live → then 0, with **33** latent collisions COUNTED as notes rather than silenced |
| V2 "defined in the lowered module" | 5 VACUOUS | **3 were ELIMINATION negatives** (`; CHECK-NOT: %s = add i32` asserts the input's `%s` was lowered AWAY — of course the output lacks it; that IS the assertion) and **1 was an LLVM TYPE name** (`%union.IEEEl2bits`) | a name in the output, the fixture's own input (comments excluded) or the universe is accounted for |
| V3 as a VERDICT | **1116** VACUOUS against a 1005-module universe | **every one examined was a WORKING negative**: `; NOUNDEF-NOT: i1 undef` (bd `z9t1` normalises undef away — its absence IS the property), `; NOROUTE-NOT: double 0xFFF`, `; NOROUTE-NOT: cq_phi_` (the front-end postcondition, missed because the exclusion list was `@`-anchored) | **V3 DEMOTED TO A NOTE** (`--strict-unreachable` to promote); front-end exclusion matched on the STEM |

⚠ **The V3 lesson is the durable one and it belongs in the tool's docstring, where it is:**
**a `-NOT` naming something the compiler must NEVER emit is the most valuable negative in the
tree, and "absent from every lowered module" is what it means for that negative to be
PASSING.** Universe membership cannot separate *impossible by construction of the ABI* (a
misspelt `@cqrt_teleport_i32` — genuinely vacuous) from *forbidden by the lowering* (`i1
undef` — genuinely working). That needs the ABI GRAMMAR, not a corpus. **Track W's checker
has the same rule and reported 0 VACUOUS only because its universe was six modules.**

**Two more self-inflicted blind spots, found and closed the same way:**

* **A fixture whose compiler input is not `%s`.** `lowering_predmux_purecallee_deep_chain.ll`
  (bd `ziuw`) GENERATES its modules with `%python %S/Inputs/gen_deep_pure_chain.py`. Lowering
  `%s` there answers a question about a different module, and V0 was about to report
  `V0-EMPTY-MODULE` on a healthy fixture. Now NOT-MODELLED: counted, reported, never scored.
  ⚠ **The guard's own first spelling was the bug it exists to prevent** — it asked *"does the
  pipeline contain `cq-opt` and `%s`"*, and the real RUN line contains both (`%s` is
  FileCheck's argument). It has to ask per pipeline SEGMENT.
* **The stream a prefix actually reads.** `railbank_promote_reject_classical_store.ll`'s
  `OUT`/`NOTS` prefixes read `--input-file=%t.dbg` from `env CQ_RAILBANK_DBG=1 %cq-opt …`.
  `%cq.bank` is a name `RailBankPromote.cpp` really mints (`SSA.Initialize(Plan.CellTy,
  "cq.bank")`) and it is visible **only** on that stream — two more fabricated VACUOUS
  verdicts about a stream never inspected. Prefixes are now mapped to their FileCheck's
  input; an unmodelled one is skipped and counted (**155** directives). Modelling the `2>&1`
  merged stream (which all 1033 decline fixtures use) moved that number from **774 to 155**
  — the first spelling had blinded the tool to half the corpus, which is the same failure it
  exists to stop.

⚠ **STILL BLIND TO.** Whether a POSITIVE `CHECK` is meaningful (that is the injection
matrix's job). Whether a negative is *semantically* the right negative. The 749 V3 notes and
33 latent V1 collisions are POPULATIONS this file can see and cannot adjudicate — they are
printed, not hidden, and not counted as passes. **And the five inherited copies are left
where they are**: deleting a session record is not this track's call, but the protocol should
point at `tools/negative_vacuity_check.py` from now on.

---

## bd `gzgs` — the committed F × P VALUE witness is vacuous on its own reachable support

**CLAIMED** (`MERGE_FILINGS.md` §2, `MERGE_REPORT.md` §5b): `m28.c` is one of the two
witnesses that the F × P composition is sound — *"29 trace lines, STRICT 2b 8 mints / 6 left
allocated / 2 frees verified, streams well-formed."*

**ACTUALLY WITNESSED — the bead's analysis REPRODUCED end to end on the ORACLE**
(`probes/j_gzgs_m28.trace`, 29 lines, and the stage-2b line above verbatim):

* lines 4–5 `cqrt_ry_i1(h1, 0x1p-1); cqrt_ry_i1_controlled(h0, h1, -0x1p-1)` — the
  NEGATED-control prep. By additivity the arm is `Ry(0.5)` on the `h0=0` branch and
  `Ry(0.5)Ry(-0.5) = I` on `h0=1`, so **b1 is `|0⟩` wherever b0 = 1**.
* line 19 `cqrt_toffoli(h0, h1, h7)` — the flag is `b0 ∧ b1`.
* **the amplitude on `|b0=1, b1=1⟩` is EXACTLY ZERO**, so `h7` is 0 on every populated
  branch; line 21's `copy_i32_controlled(h7, h6, h8)` never fires, line 23's (after the
  `cqrt_x`) always fires, and **`h8 = h3` identically**.

So the controlled-copy merge the composition NEWLY ENABLES **is the identity on the whole
reachable support** and cannot be distinguished from several incorrect merges by anything
this program can produce. That is the project's own headline lesson arriving again: a
self-consistent trace of the identity.

**WHAT m28 DOES WITNESS, stated precisely so it can still be cited:** that the composed
accept PREDICATE fires (opt exit 0, no decline, a source-located stream) and that the emitted
stream is well-formed and stage-2b clean. **Never the unitary.**

**WITNESSES NOW.** `probes/j_gzgs_x5b_LIVE_merge.c` is committed beside it with a header
naming the difference. It is m28 with the third region's polarity flipped (`if (a < 3)`), so
b1 is prepared on the `b0==1` branch and `|1,1⟩` carries amplitude `sin(0.25)² = 0.0612`
(probability 0.0037). **MEASURED: opt exit 0, 28 trace lines, STRICT 2b `8 rail mint(s) of
which 6 left allocated, 1 template rail mint(s) of which 1 left dirty, 2 cqrt_free site(s): 2
verified, 0 violation(s), 0 unproven`, and the ONLY trace difference is the prep spelling —
the downstream is BYTE-IDENTICAL** (`diff` of m28 lines 6–29 against x5b lines 5–28 is
empty). On that module the merged arm actually fires.

⚠ **DELIBERATELY NOT PROMOTED TO AN e2e SLICE.** A golden would pin this stream as correct,
and **the F × P composition still has no Rule-13 opinion** (`MERGE_FILINGS.md` F-1/F-2: Track
F cleared a binary on which Track P's leaf does not exist, and Track P cleared one on which
Track F's exclusion does not — *a composition is not cleared by clearing its parts*). Rule 2:
a byte-identical golden proves every symbol resolves and signature-matches, never that the
unitary is right. This probe makes the composition REVIEWABLE. **It does not clear it, and
the review is still owed.**

⚠ **AND THE SECOND HALF OF bd `gzgs` IS NOW VISIBLE RATHER THAN ARGUED.** The bead's closing
note — *"`cq_template_add_i32_hl(h3,-3) -> h6` is never `_unc`'d and never freed, and
`free_pairing_check.py` counts …"* — is bd `19vy`, and the census fix above reports it:
`1 template rail mint(s) of which 1 left dirty`, on both twins.

---

## F-6 — the two record `.c` files did not compile

`tests/e2e/slice_control_select_{bool,cmp}_round2_window.c` nested `/* … */` inside their
conversion header's block comment, so the prose leaked into the code
(`expected identifier or '('`). Fixed by de-nesting the two inner comments in each; **both now
pass `clang -fsyntax-only` cleanly**, both remain UNREGISTERED, and both still produce the
exact decline their headers claim, character for character, on the linked two-TU module:

```
cq opcode lowering: rotation/measure operand predates a non-diagonal gate
```

---

## Files changed

| file | why |
|---|---|
| `tools/free_pairing_check.py` | `census_of` / `live_functions` / `address_taken` (bd `rixk`, bd `19vy`, bd `1739` h1); `carries_undef` + the guard at 3 comparison sites (bd `1739` h2) |
| `tools/free_pairing_check_test.py` | 5 undef mutants + 3 controls; 19 census cases across two new layers (2e the census OBJECT, 2f the census LINE) |
| `tools/negative_vacuity_check.py` | NEW — bd `jdec` |
| `tools/negative_vacuity_check_test.py` | NEW — its mutant validation |
| `tests/e2e/CMakeLists.txt` | one `add_test`: `e2e-negative-vacuity-selftest` (appended at the tail anchor, above the mandatory-last sweep) |
| `tests/e2e/slice_control_select_{bool,cmp}_round2_window.c` | F-6 |
| `…/trackJ/**` | these records + probes |

**Post-union checks on `tests/e2e/CMakeLists.txt`:** 0 duplicate `add_test` names,
`grep -c '^add_test(NAME'` = **433**, the `get_property`/`set_tests_properties` sweep is
still LAST.

---

## Open, and owed to somebody else

* **The F × P composition's Rule-13 opinion is still owed** (`MERGE_FILINGS.md` F-1). This
  track supplied a non-vacuous witness; it did not review anything.
* **The 5048 left-dirty template rails are now VISIBLE and still UNADJUDICATED.** Which of
  them are Rule-8 dephasing hazards is bd `s82e` / bd `tu9q` / CLAUDE.md §5's Q-R1-1
  correction — a compiler question.
* **`h6` in `slice_control_cascade_three_bools`** is a left-dirty template rail on the
  owner's headline slice. Filed here as an observation, not a defect: Rule 6 permits the
  leak. Whether it dephases the later `cqrt_ry_i1_controlled(h9, h10, …)` is exactly the
  Q-R1-1 question and belongs with the compiler tracks.
* **CLAUDE.md's census quotes.** Every record that cites `N rail mint(s)` for a slice in the
  162-module doubled population is quoting a number that is now different. The cited §4c
  figures are NOT among them (checked: 9/7/3, unchanged). A docs pass is a separate act.
* **PROTOCOL §S3 still points at the dead script.** Repointing it at
  `tools/negative_vacuity_check.py` is the orchestrator's edit, not mine.
