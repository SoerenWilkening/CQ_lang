# FIX — bd `test_C_libtooling-l4x4` sub-increment **l4x4.b**, round-1 Rule-13 review

Worktree `/Users/sorenwilkening/Desktop/CQ_l4x4`, branch `l4x4b-bool-ry-arm`, from
the PRE-REVIEW checkpoint **267937d**. Review: `review_l4x4b_r1.md`, verdict
**CLEAR-WITH-ITEMS** (F-1..F-5 + the H-9 documentation item; ITEM 1 the spine and
ITEM 2 the negation order both established ABSENT of hazard, so neither is
re-litigated here). Fix brief: `FIX_BRIEF_l4x4b_R1.md`. **Not committed, not
pushed.** Three read-only reference binaries, none rebuilt: **ORACLE** `main`
0c7380c, **F2-BASE** 578dbc4, and — added by this round because neither reference
can witness F-1 — a **FROZEN COPY OF THE CHECKPOINT BINARY 267937d itself**,
rebuilt from a `git stash` of the one modified source file and copied to scratch
before the fix was restored.

> **Bottom line.** ONE of the five items was a wrong unitary and it is fixed with
> **11 non-comment lines** (a 4-line shared helper, a 5-line clause, 2
> substitutions) and **NO new diagnostic string**. The other four are records:
> two bd issues already filed, two corrected claims about what this session's own
> probes and tables measure. **The witness that the fix is a NARROWING and nothing
> else: `chk -> fix` over the whole corpus reads `RCDIFF=4 DIAGDIFF=0 OUTDIFF=0`,
> and the four are this round's own new decline fixtures.**

---

## F-1 — OVER-ACCEPT-ARGUED, FIXED. A non-finite CONSTANT angle on the NEGATED rail arm

**The defect, reproduced before touching anything** (plain C at `-O1`,
`review_l4x4b_r1_probes/x01_neg_inf_angle.c`, on the checkpoint binary):

```
_Bool b = 0; int r = 7;  b = cq_theta(b,0.5);  r = cq_theta(r,0.25);
if (!b) { r = cq_theta(r, __builtin_inf()); }
->  call void @cqrt_ry_i32(i32 %h1, double 0x7FF0000000000000)            ; +inf
    call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 0xFFF0…)    ; -inf
```

`opt` exit 0, verify-clean. On the `b = 1` branch **the source is the identity**
and the register gets `Ry(−∞)·Ry(+∞)` = NaN. The anti-control identity that
licenses the whole negated form (SCOPE §2.3 option A) holds for FINITE angles and
for nothing else.

### The change

| file:line (post-fix) | change |
|---|---|
| `ir-pass/src/ArmClassify.cpp:125` | **NEW** `bool constantAngleIsNonFinite(const Value *Angle)` in the file's first anonymous namespace — `dyn_cast_or_null<ConstantFP>` + `!getValueAPF().isFinite()`. |
| `ir-pass/src/ArmClassify.cpp:3090` | **NEW CLAUSE**, immediately after the `valueCarriesUndef` one and spelled identically: `if (RailCond && Region.ArmNegated && !Region.ArmFalse && constantAngleIsNonFinite(T->getArgOperand(1))) declineArm(T, "rotation angle");` |
| `ir-pass/src/ArmClassify.cpp:5857/5859` | `angleSelectArmsAdmissible`'s clauses **(2a)/(2b)** now CALL that helper instead of spelling `CA && !CA->getValueAPF().isFinite()` inline. Behaviour-identical; the `CA &&` guard the surrounding paragraph explains is inside the helper. |

**ONE SPELLING, and that is the point of the helper (Rule 14).** The sibling
emitter `angleSelectArmsAdmissible` is the only other place in the tree that puts
ONE user angle into TWO gate slots, and it has had this fence since the bd drbq
Inc-2b round-1 Rule-13 review. l4x4.b shipped the `undef` half of the same
argument — its own comment even states *why* a negated arm needs a value fence —
and stopped one conjunct short of the non-finite half. Two spellings of one
question is how the second site gets forgotten again.

**NO NEW DIAGNOSTIC STRING.** `rotation angle` is what the `undef` clause beside
it already emits and what the angle-select family's own non-finite arm produces
(`control_angle_select_reject_inf_arm.ll`). So `cq-opt-equivalence-full` is not
owed by this change — the brief's condition ("if a string was added") is not met,
and the routine sampled entry runs in the full suite regardless.

### Decision (b) — a RUN-TIME angle keeps ACCEPTING, with the argument written down

At the clause, in `IMPL_l4x4b.md` §8 Q8, and in the fixture headers:

* **`fneg` cannot manufacture a non-finite value from a finite one.** It flips one
  sign bit. Inc-2b's `fsub` *can* — measured there, two ORDINARY FINITE arms
  `±8.98846567431158e307` emit a controlled gate at `inf` — which is exactly why
  its clearance ranked run-time arms a BLOCKER (F-11) and narrowed to constants.
  **That structure does not transfer**: here there is no class of well-formed
  input the compiler cannot see.
* So the ONLY failing input is an angle that was **already** non-finite, i.e. an
  ill-formed CQ program in every spelling — `Ry(NaN)` lands on the taken branch of
  the compare twin too, and an uncontrolled `cq_theta(q, inf)` lowers to
  `cqrt_ry_<W>(h, inf)` on every binary in this tree. What the negated form ADDS
  is corruption of the **untaken** branch of that already-broken program. For a
  constant the compiler can see it and declines; refusing every run-time angle to
  protect a program that is broken anyway would be a total over-decline of the
  shipped accept class (Rule 17).

**RESIDUAL, recorded not fenced:** a run-time angle that is non-finite AT RUN
TIME.

**OWNER OPTION that removes it entirely, NOT BUILT** (SCOPE §2.3 option B; the
brief says do not build it): the bd `r9e5` 1b-B.1 `CopyRailRoot` ancilla with the
`cqrt_x` bracket **on the ANCILLA** —
`bf = cqrt_alloc_i1(0); cqrt_cnot(h_b,bf); cqrt_x(bf); cry(bf,h_r,θ); cqrt_x(bf);
cqrt_cnot(h_b,bf); cqrt_free(bf)`. **4 extra gates + 1 ancilla, ONE rotation
fired, exact for every angle** including run-time and non-finite — and it would
also retire the one-content-arm fence, because anti-control would stop needing
additivity. Its cost is plumbing (`CondTreeEmit`'s `CopyRailRoot` is written for
`emitCondNetwork`, which `classifyArms`' path does not use), and `fg9k` / `54ur`
are the other customers for the same mechanism.

### Fixtures — 4 declines + 3 accept controls

**DECLINES** (all four `rc 0` on the checkpoint 267937d — the STRONG red; `main`
and F2-BASE are red too but with `bare i1 register condition`, a different string
from a different layer, so neither can witness the fence):

| fixture | angle | measured on 267937d |
|---|---|---|
| `control_inplace_ry_reject_rail_negated_inf_angle.ll` | `+inf` | rc 0, `ry(+inf); cry(-inf)` |
| `control_inplace_ry_reject_rail_negated_nan_angle.ll` | NaN | rc 0 |
| `control_inplace_ry_reject_rail_negated_neginf_angle.ll` | `-inf` | rc 0 |
| `control_inplace_ry_reject_rail_stateprep_negated_inf_angle.ll` | `+inf`, **STATE PREP** | rc 0, `ry(%h1,+inf); cry(%h,%h1,-inf)` |

⚠ **TWO THINGS IN THAT TABLE THE REVIEW DID NOT SAY, and both were measured
rather than assumed:**

1. **`-inf` is a DECLINE here, and the brief's wording grouped it with the accept
   controls** (*"decline fixture … for `inf` and `NaN`, plus the `-inf` and
   `−0.0`/`0.0` ACCEPT controls"*). It declines because the defect is the SUM of
   the two emitted slots: `Ry(+inf)·Ry(−inf)` is NaN whichever sign the source
   wrote, so accepting `-inf` while declining `+inf` would be an over-accept on
   the identical unitary (Prime Directive). The finite accept controls the brief
   asks for are `0.0` / `-0.0`. The reading is recorded in that fixture's header,
   not just here.
2. **The CONTROLLED STATE PREP is a fourth member of the class** and F-1's three
   reproducers are all in-place arms. The prep duplicates the angle the same way
   (`alloc(SEED); ry(h_r,θ); cry(h_b,h_r,−θ)`), and it is plain-C reachable —
   measured on the checkpoint at rc 0. It is covered because the clause sits among
   the SHARED rail clauses, ABOVE the three `StatePrep`-guarded ones; that
   placement is what the fixture pins.

**ACCEPT CONTROLS** (green on the checkpoint AND after the fix — the measurement
that the narrowing narrowed nothing it should not; each is `-O1`-reachable):

| fixture | pins | goes RED if |
|---|---|---|
| `control_inplace_ry_rail_negated_zero_angle.ll` | `0.0` is FINITE, `Ry(0)·Ry(−0) = I` exactly | the `isFinite()` question is re-spelled as any "is this angle usable" test |
| `control_inplace_ry_rail_negated_runtime_angle.ll` | **decision (b)**; asserts the `fneg` and `NOROUTE-NOT: fsub` | Inc-2b's constant-arms-only narrowing is imported to this shape |
| `control_inplace_ry_rail_unnegated_inf_angle.ll` | the `Region.ArmNegated` conjunct — ONE slot for one angle is FAITHFUL | the fence is widened into a blanket refusal of non-finite angles |

The existing `control_inplace_ry_stateprep_rail_negated.ll` is the finite control
for the prep member and is byte-unmoved.

---

## F-2 — l4x4.c: the cost said in full (bd `test_C_libtooling-wx8g`, already filed)

No code. The reviewer's sentence is now at the fence itself
(`ArmClassify.cpp:2981`, the `RailCond && Region.InLoop` carve-out) and in
`IMPL_l4x4b.md` §1's row:

> Because the COMPARE spelling cannot express this shape AT ALL — measured, `t5c`
> declines `condition predates a non-diagonal gate` on ORACLE, F2 and this tree
> alike — the carve-out closes the ONLY door: **"Grover as a ROLLED loop with a
> `_Bool`-controlled rotation or state prep" compiles in NO spelling on ANY
> binary.**

Stated as an owner-visible over-decline, not as "the capability has no witness".
The C-1 history (eight silent miscompiles over six adversarial rounds in
`markIfRailLocal`'s neighbourhood, on exactly this invariant-condition +
carried-register mixture) remains the reason it is its own increment, and the
fence keeps the loop STRING.

---

## F-3 — the hcrg precedence over-decline, filed (bd `test_C_libtooling-35t0`)

No code; pre-existing on `main` 0c7380c and arm-class-independent. A 6.5
classical-call-arm region immediately followed by a flat control region declines
`control flow`, because `lowerControlRegions`' hcrg precedence graph resolves
`A.Pred == B.MergeBB` only when both regions are `BranchRegion`/`PhaseKickback`
(`SwapRouteEmit.cpp:2459`'s `sequentialChainAlias` → `reorderable()`). Measured
with the COMPARE twin `probes/impl/multi/w1c_caller.c` on all three binaries.
A README line is added under `probes/`, and `IMPL_l4x4b.md` §7 Q2's *"Not filed —
out of brief"* is superseded in place (left visible, because the reason it was not
filed is the reason a reviewer had to find it twice).

---

## F-4 — two of this session's probes do not measure what their headers claimed

No code; re-measured on the fix binary, then both headers rewritten and
`probes/README.md` corrected.

* **`probes/impl/p5_classical_call_arm_rail.c`** — header said *"the 6.5
  CLASSICAL-CALL arm … must keep declining"*. **It ACCEPTS**, here and on `main`.
  Measured: **0 `br i1`, 2 `select i1`** after `-O1` — the `noinline const`
  callee's arm folds to a `select i32`, so there is no control region,
  `classifyClassicalCallArm` is never reached, and bd `r9e5`'s 1b-B.1 rail
  DATA-SELECT compiles it (`cqrt_alloc_i1; cqrt_cnot; 2 × cqrt_copy_i32_controlled;
  cqrt_x; cqrt_cnot; cqrt_free`). Kept, with the measurement, because the fact it
  DOES establish matters to bd `54ur`: the plain-C spelling of its target shape is
  **already compiled**, so `54ur` needs a spelling `-O1` does not fold.
* **`probes/impl/p6_eqfold_rail.c`** — header said *"EQ-FOLD"*. There is no
  equality in it; it emits `cqrt_rz_i1`, the Inc-1b branch-phase kickback. Kept as
  a real regression probe for the SEPARATION l4x4.b relies on (a `cq_phi` arm on a
  rail must keep reaching the kickback, not the new rotation-arm path).

**Neither §2.6 row has a dedicated fixture**, and `IMPL_l4x4b.md` §8 Q9 now says
that outright instead of citing probes for it: what fences those classes is
`classifyClassicalCallArm`'s own `isa<CmpInst>` early return and
`declineRailClass()` at the eq-fold accept site — **read, not measured**. This is
the DER lesson one level down, and the second instance in this session's records
(§7 Q3, `t10`): a probe that measures a different lowering is worse than no probe,
because it reads like coverage.

---

## F-5 — the VALUE class on a rail has TWO exits

`SCOPE_l4x4.md` §2.6 now carries an **ERRATA block**, and `IMPL_l4x4b.md` §8 Q10
the same fact: the table's `kBareRailCondReason` cells are the DISPOSITION, never
the STRING. Measured, plain C at `-O1` (probe `t16_i1_stateprep`, `_Bool r;
if (b) r = cq_theta(0, 0.9);` — the `int` overload leaves an `icmp ne` in the arm
as the merge incoming):

```
cq controlled lowering: value-arm swap-route under quantum control
```

from the `isValueChangingOp(Base)` clause above the §2.6 re-decline, not from
`declineRailClass()`. The hand-IR `add`-chain spelling DOES answer `bare i1
register condition` (`control_swap_reject_value_rail_cond.ll`, measured), so
neither fixture subsumes the other and **both exits are now pinned** — the second
by the new `control_swap_reject_value_rail_cond_early_clause.ll`, whose header
records the discriminating mutation (delete the `isValueChangingOp` decline and
the string flips to `bare i1 register condition`).

⚠ That fixture is **green on the checkpoint too**, and the header says so: F-5 is
a COVERAGE finding, not a behaviour one. The ERRATA also warns that the same
caution has **not** been individually measured for the other DECLINE rows —
`declineRailClass()` is a rail region's LAST word, not its first.

---

## H-9 — the SECOND, stronger reason the spine never claims the control register

No behaviour change; written at both sites the review named
(`ir-pass/src/ChainWalk.cpp`, `+39` comment-only lines, `cq-opt` `cmp`-identical
after the edit):

* in **`preservesBasisUnderRecord`'s header**, beside its own DECISIVE COROLLARY
  (`cond(W) = ∅ ⇒ R is freeable only if W is trivial on |0⟩`, and
  `cqrt_ry_<W>(H, θ)` is not);
* at **`isInPlaceGateOn`'s `if (N.contains("_controlled")) return false;` bail**,
  as a cross-reference.

The argument: `IMPL_l4x4b.md` §3 rests on the `_controlled` disqualify list, which
is a property of THAT LIST. But a rail leaf is by definition a `cq_theta_i1`
result, so its register **always** carries an uncontrolled `cqrt_ry_i1` — the very
gate the corollary names — and `isInteriorConsumer` arm (a) therefore refuses it
**independently of every row in the list**. That is the argument that survives a
future widening: the day a new `_controlled` stem is admitted there, the six
emitters named at that site need re-reading and a bare-`_Bool` control does not.

---

## Files touched

| file | delta |
|---|---|
| `ir-pass/src/ArmClassify.cpp` | **+11 / −2 non-comment** (helper, clause, two substitutions) + comments: the F-1 argument at the clause, the F-2 sentence at the in-loop carve-out, the single-spelling note at (2a)/(2b) |
| `ir-pass/src/ChainWalk.cpp` | **+0 non-comment**, +39 comment (H-9) |
| `ir-pass/test/` | **+8 fixtures** (5 decline, 3 accept); corpus **1810 → 1818** |
| `docs/…/session-l4x4/IMPL_l4x4b.md` | §1 round-1 row + post-fix anchors, §1 in-loop row (F-2), §4a-R1/§4b-R1, §7 Q2 superseded, **new §8 Q8–Q11** |
| `docs/…/session-l4x4/SCOPE_l4x4.md` | §2.6 **ERRATA** block (F-5 + F-4) |
| `docs/…/session-l4x4/probes/README.md` | F-3 / F-4 corrections |
| `docs/…/session-l4x4/probes/impl/p5_*.c`, `p6_*.c` | headers rewritten with the measurement |
| `docs/…/session-l4x4/fix_l4x4b_r1_probes/` | **NEW** — this round's 10 probes (4 copied from the reviewer's set so the directory stands alone), the two probe re-runners and the two corpus sweepers, with a README recording how the **267937d checkpoint binary was reconstructed** (`git stash` → rebuild → freeze → `stash pop` → rebuild, both ends `cmp`/`diff`-verified) and why the reviewer's **26**-mover and the implementer's **2**-mover readings are both correct |

**No `runtime/`, no `tools/opcode_table.yaml`, no `include/`** — owner D3 holds.

---

## Gates, in the fix brief's order

Every corpus/probe measurement ran against a **FROZEN COPY** of the binary pair,
never the live build tree (IMPL_f2 §5b: a relink makes `build/ir-pass/cq-opt`
vanish for a second and kills anything holding a path to it). **Nothing was
rebuilt while a measurement was running, and no process was killed by pattern.**
Both frozen copies were `cmp`-verified against the rebuilt tree afterwards: the
build is deterministic here, so the two later COMMENT-ONLY edits left `cq-opt`
and `libCQPass.so` **byte-identical** — which is what lets the sweeps and the
suite results stand for the tree as it is.

**1. `lit --filter` per fixture** — each of the 8 new fixtures verified
individually as it was written (`lit -v ir-pass/test --filter 'rail_negated|rail_unnegated'`
→ `13 of 1816 tests … Passed: 13`, and the two later ones by name).

**2. `ctest -R ir-pass-lit`** — run twice. At 1816 fixtures (before the last two
were added): `1/1 Test #8: ir-pass-lit ...... Passed 41.26 sec`. Re-run at the
final **1818**: `1/1 Test #8: ir-pass-lit ...... Passed 82.30 sec`, with
`lit -s ir-pass/test` reporting
`Total Discovered Tests: 1818 · Passed: 1817 (99.94%) · Expectedly Failed: 1 (0.06%)`
(the 1 XFAIL is the pre-existing `lowering_invert_add_i32.ll`, a Phase-7 tracker).

**3. `ctest -j6 -R '^e2e-'`** —
`100% tests passed, 0 tests failed out of 386`,
`Total Test time (real) = 726.68 sec`, including
`e2e-loop-twin-matrix ... Passed 726.65 sec` — **no cell moved, no quarantine
churn**. `git status --porcelain tests/` afterwards: **EMPTY**. This round adds no
slice, no golden and no CMake entry, so 386 is the checkpoint's own count and the
empty `tests/` status is the assertion.

**4. CORPUS DIFF — three ways, against frozen binaries.**

*(a) The round-1 fix itself, `chk -> fix` over the WHOLE corpus:*

```
[chk -> fix] files=1818 RCDIFF=4 DIAGDIFF=0 OUTDIFF=0
  RCDIFF control_inplace_ry_reject_rail_negated_inf_angle.ll        rc=0 [] -> rc=1 [rotation angle]
  RCDIFF control_inplace_ry_reject_rail_negated_nan_angle.ll        rc=0 [] -> rc=1 [rotation angle]
  RCDIFF control_inplace_ry_reject_rail_negated_neginf_angle.ll     rc=0 [] -> rc=1 [rotation angle]
  RCDIFF control_inplace_ry_reject_rail_stateprep_negated_inf_angle.ll rc=0 [] -> rc=1 [rotation angle]
```

**The four movers are this round's own new decline fixtures and nothing else.**
`DIAGDIFF=0` means no diagnostic string moved anywhere; **`OUTDIFF=0` means every
one of the other 1814 fixtures emits BYTE-IDENTICAL lowered IR** — which is the
witness that the `constantAngleIsNonFinite` extraction in
`angleSelectArmsAdmissible` is a true no-op (every `control_angle_select_*`
fixture is in that 1814) and that the new clause reaches nothing but its own
shape.

*(b) The brief's three-way, `f2 -> fix`, over the fixtures COMMON to both trees:*

```
[f2 -> fix] listed@578dbc4=1784 common=1782 absent(renamed/deleted)=2
            RCDIFF=0 DIAGDIFF=0 OUTDIFF=0
```

*(c) and the 2 absent ones are exactly IMPL §6's **2 movers**, measured by CONTENT
(the F2 binary on the 578dbc4 blob vs the fix binary on the renamed file), since a
`git mv` makes a name-keyed sweep blind to them:*

| 578dbc4 name | current name | f2 | fix | IR |
|---|---|---|---|---|
| `control_inplace_ry_reject_raw_i1_cond.ll` | `control_inplace_ry_rail_diamond.ll` | rc 1 `bare i1 register condition` | **rc 0** | byte-identical modulo comments/blank lines |
| `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll` | `control_inplace_ry_stateprep_rail_i1_seed.ll` | rc 1 `bare i1 register condition` | **rc 0** | same |

**So: the same 2 movers, both DECLINE → ACCEPT on `bare i1 register condition`,
and no others.** (The round-1 reviewer's whole-tree `f2 -> subj` sweep reads 26
movers over 1810 because a renamed fixture appears under its NEW name and so looks
new; both readings are correct at their own denominators, and (b)+(c) separate
them explicitly rather than leaving the discrepancy to be rediscovered.)

**5. BOTH PROBE CORPORA RE-RUN** (`chk` vs `fix`, frozen binaries; an accepting
row is compared by the **md5 of its lowered IR**, not merely by exit code, so an
unchanged verdict with a changed circuit would show):

| corpus | probes | MOVED |
|---|---|---|
| `session-l4x4/probes` (the SCOPING corpus) | 35 | **0** |
| `session-l4x4/probes/impl` (the IMPLEMENTATION corpus) | 8 | **0** |
| `session-l4x4/probes/impl/multi` (two-TU) | 4 | **0** |
| `session-l4x4/review_l4x4b_r1_probes` (the REVIEWER's corpus) | 42 | **2** — `x01_neg_inf_angle`, `x02_neg_nan_angle` |
| `review_l4x4b_r1_probes/multi` (two-TU) | 3 | **0** |
| this round's own probes | 10 | **4** — `x01`, `x02`, `x03` (`-inf`), `x06` (the state prep) |

**The only moving rows in 92 single-TU + 7 two-TU probes are F-1's own
reproducers**, every one `rc 0 -> rotation angle`. In particular
`n11_neg_runtime_angle` (decision (b)), `n12_neg_zero_angle` (θ = 0.0),
`x01c_neg_inf_cmp` (the compare twin) and all 9 of the review's §1 spine probes
are **unmoved, with byte-identical lowered IR**.

**6. FULL `ctest -j6`** (Rule-19 gate moments 1 and 5 — a Rule-13 lowering-core
change AND a moved accept/decline predicate), run ONCE, at the end:

```
100% tests passed, 0 tests failed out of 396
Total Test time (real) = 1269.75 sec          (e2e-loop-twin-matrix: 1267.26 s)
```

396 is the checkpoint's own entry count — this round adds no ctest entry.

⚠ **BOTH suite wall times above are LOADED figures, not quiet-box ones, and must
not be compared with each other or with CLAUDE.md's ~130-230 s band.** Two other
worktrees (`CQ_b6ap`, `CQ_trackA`) were running their own full `ctest -j6` on the
same machine throughout — verified by `pgrep` afterwards, 18 processes, **none of
them mine and none killed**. That is the whole of the difference between
`e2e-loop-twin-matrix` at 726.65 s in gate 3 and 1267.26 s in gate 6: same cells,
same verdicts, different contention. Contention causes false FAILURES, never false
passes, so a 100%-green loaded run is a sound result — it is only the *timing*
that is uninformative.

**7. `cq-opt-equivalence-full`:**

```
cq_opt_equivalence: compared 1818 fixtures, 0 mismatch(es)
```

⚠ **Strictly it was not owed**: the brief's condition is "if a string was added",
and **no string was added** — the only literal in the non-comment diff is
`"rotation angle"`, which already occurs at 14 sites in `ir-pass/src` and is
pinned by 62 fixtures. It was run anyway because the change *is* to the analysis
surface (a new decline predicate), which is CLAUDE.md's own trigger for the full
sweep rather than the sampled entry. The target's own rebuild step was a no-op:
`cq-opt` and `libCQPass.so` are `cmp`-IDENTICAL to the frozen copies afterwards.

**Tree state after all gates:** `git status --porcelain tests/ runtime/ tools/
include/` → **0 lines**. The only tracked changes are the two `ir-pass/src` files,
the 8 new `ir-pass/test` fixtures and the session records.

---

## What this round did NOT do, said explicitly

* **Did not build the owner option** (SCOPE §2.3 option B, the `CopyRailRoot`
  ancilla). It is written down at the clause, in `IMPL_l4x4b.md` §8 Q8 and above —
  as an OWNER OPTION with its cost and its other customers (`fg9k`, `54ur`).
* **Did not widen or narrow anything beyond F-1's one conjunct.** `chk -> fix`
  `OUTDIFF=0` over 1814 fixtures and `MOVED=0` over 92 probes outside F-1's own
  class are the measurements, not the intent.
* **Did not touch `classifyAngleSelect`'s behaviour** — the only edit inside
  `angleSelectArmsAdmissible` is the substitution of an identical expression by
  the shared helper, and every `control_angle_select_*` fixture is inside the
  `OUTDIFF=0` set.
* **Did not commit or push** (per the fix brief).
* **Did not re-run the review's §1/§2 analyses.** Both were established ABSENT of
  hazard by the reviewer, structurally and by measurement; H-9 records the second,
  stronger half of §1's argument in the source, which is all the brief asked.

## Open questions carried forward

1. **The F-1 residual** — a run-time angle non-finite at run time (§8 Q8). Owner
   option: SCOPE §2.3 option B. *Not a defect in a well-formed program; a decision
   about how far to fence an ill-formed one.*
2. **`-inf`'s disposition** — DECLINED here, against the fix brief's wording,
   on the Prime Directive. If the owner intended `-inf` to accept, the fixture
   `control_inplace_ry_reject_rail_negated_neginf_angle.ll` is the one to flip,
   and its header carries the argument against.
3. **bd `test_C_libtooling-wx8g` (l4x4.c)** — the in-loop carve-out, now filed
   with the measured sentence that the compare spelling cannot express the shape
   either.
4. **bd `test_C_libtooling-35t0`** — the pre-existing hcrg precedence over-decline
   (`ClassicalCallArm` followed by a flat region), arm-class-independent.
5. **The §2.6 CLASSICAL-CALL and EQ-FOLD rows have no dedicated fixture** and are
   fenced by reading, not by measurement (§8 Q9). Whoever builds `fg9k` / `54ur`
   inherits that, and should note `p5`'s measurement: `-O1` already compiles the
   plain-C spelling of `54ur`'s target shape through bd `r9e5`.
6. **SCOPE §2.6's errata warns that the "two exits" caution is not individually
   measured for the DECLINE rows other than VALUE.** Cheap to measure; not done
   here, because the brief scoped F-5 to the row the review named.
