# IMPL — Track R, increment R-1: F2 excludes the peel's compare CLONES via `taint.PeelClones` (bd `test_C_libtooling-rb9x`)

**Implementation record.** Branch `rb9x-f2-clones`, worktree
`/Users/sorenwilkening/Desktop/CQ_rb9x`, from `main` 81956a2. **Not committed, not pushed.** Nothing
outside this worktree was written. The frozen session ORACLE for every A/B below is
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
`fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661`, read-only; that checkout was
never built or written.

```
SUBJECT  build/ir-pass/cq-opt        221c1caa465db61e3e96ce530fbd51afd25b9cd257b25ceb7966d6d747ee3577
SUBJECT  build/ir-pass/libCQPass.so  818becd47c9a065013f6134518e781cb0fd38b71a910ebd32385b82a49d806b4
```

> **Bottom line.** (a) The change is **ONE conjunct** at F2's equality test plus a `WeakTrackingVH`
> record and its 8-line membership helper: non-comment delta **+11 / −1** across three files.
> (b) **3 probes flip, 33 stay**, and the three that flip are exactly the three C programs whose
> `-O1` output contains a real peel — including **bd `rb9x`'s own program** (`b_A`), which now
> compiles at **22 trace lines**, byte-identical to its already-shipped `int b1` twin except for the
> `i1` widths on the b1 rail. (c) **SCOPE §4's partition table is WRONG in one row and I did not
> make it right**: the hand-IR clone family `b_HP_{a,c,d,e,g}` was predicted ACCEPT and **stays
> DECLINING**, because those modules' `%clone` is hand-written and the record spelling is a RECORD.
> That is the same property SCOPE §5 relies on to keep
> `control_peel_stateprep_datamux_peeled_control.ll` untouched, so the two statements could not both
> be true; the record spelling is the one the brief scopes IN and the one I built. (d) The §3b
> two-diamond over-reach is **UNREACHABLE at HEAD**, measured and bisected, and is now a fixture with
> its retirement trigger. (e) `r_R4` still declines, by design (§3e). (f) `vd` still declines (R-2 is
> a separate increment and was not folded in).

---

## §0 MEASURE-FIRST — SCOPE §0's 36 rows, on the UNMODIFIED worktree build

Build (BOTH targets, always): `cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
-DCMAKE_BUILD_TYPE=Release && cmake --build build -j8`.

```
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so     # UNMODIFIED worktree
fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661  build/ir-pass/cq-opt
40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93  build/ir-pass/libCQPass.so
```

**The unmodified worktree build is BYTE-IDENTICAL to the session ORACLE, on both artefacts.** That
is the strongest possible form of "§0 re-measured", and under PROTOCOL.md's non-redundancy rule (*"a
gate result is a fact about a BINARY, not about a moment … if the binary hash is unchanged and the
gate is recorded, do NOT re-run it — cite the line"*) it makes the scoping agent's 36-row table a
fact about *this* binary. So the 36 probes were **CITED, not re-run**, at that hash:

> `cited: per-probe pipeline (36 probes, ORACLE) — 9 ACCEPT (all STRICT 2b clean, all linked and
> ran), 27 DECLINE @ fbbe0820 (scoping-R, 2026-09-13 12:06)` — `GATES.md`, `probes/README.md`.

Reported as a citation and not as a run, deliberately (Rule 19). The build reproducibility is itself
worth carrying: a Release build of this tree from a clean `build/` in a different directory is
bit-identical, so any future hash difference is a real source difference and never build noise.

---

## §1 THE CHANGE — three sites

Nothing else in `ir-pass/`, `include/`, `runtime/`, `tools/` was touched. **No new runtime symbol, no
YAML row, no `include/CQ.h` change, no new diagnostic string.**

### 1a. The record — `ir-pass/include/TaintPropagation.h`, `struct TaintSet`

Inserted after `LiftedConsumers` (`:245`), i.e. beside the other "a normaliser manufactured
something" witness. Before: no such field. After (`:322`-`:332`, under ~75 lines of header):

```cpp
  llvm::SmallVector<llvm::WeakTrackingVH, 4> PeelClones;

  // The ONE membership question `PeelClones` answers. A NULLED entry (the clone
  // was erased) matches nothing — see the `WeakTrackingVH` paragraph above.
  bool isPeelClone(const llvm::Value *V) const {
    for (const llvm::WeakTrackingVH &C : PeelClones) {
      const llvm::Value *P = C;
      if (P && P == V)
        return true;
    }
    return false;
  }
```

`WeakTrackingVH` and not a raw `Value *` — the l4x4.b H-1 defect shape; the clone **is** erased
inside the pass (`SelectMergeEmit.cpp:327-333`, the dead-leaf cascade, once the peeled select is
lowered), and a freed pointer must never answer a membership question. A `SmallVector` and not a set
because `WeakTrackingVH` is documented in `llvm/IR/ValueHandle.h` as unusable as a map key (*"should
not be used as the key of a map, since the map would have to rearrange itself when the pointer
changes"*); the scan is over ≤ a handful of entries, once per F2 test.

### 1b. The insert — `ir-pass/src/MergePhiPeel.cpp:503` (before) → `:516` (after)

Beside the existing `taint.Tainted.insert(Clone)`, with a comment naming the L1 pattern:

```cpp
          taint.Tainted.insert(Clone);
          taint.PeelClones.push_back(Clone);      // <- NEW (+ 11 comment lines)
          Seeds.push_back(Clone);
```

### 1c. The conjunct — `ir-pass/src/ArmClassify.cpp:1616` (before) → `:1682` (after)

```diff
       if (V->getType() == Seed->getType() && !CondWire.count(V) &&
-          f2Exact(V, S) == Seed)
+          !Taint.isPeelClone(V) && f2Exact(V, S) == Seed)
         return true;
```

`Taint` was already a parameter of `f2SeedPinnedByLiveRegister`, so no signature change was needed —
one fewer thing for a reviewer to check than the 2026-09-11 precedent, which had to thread
`CondWire` in. **At the TEST**, in the ONE place `CondWire` is consulted: `V` is still popped and its
users are still modelled, so the exclusion filters an ANSWER and never prunes a SEED. `Truncated` is
untouched (no `isPeelClone` call sits on any path that sets it), which is the second, independent
reason the exclusion belongs here — the conservative half of F2, the one that catches what LLVM's
machinery cannot evaluate, stays un-skippable.

**Measured non-comment delta** (`git diff -U0` over `ir-pass/src` + `ir-pass/include`, comment lines
filtered): **+11 added / −1 removed**, three files. The comment work is much larger: ~75 lines on the
new `TaintSet` field, ~50 at the test, ~11 at the insert, a 14-line cross-reference in
`f2SeedPinnedByLiveRegister`'s own header, and SCOPE §3f's paragraph replacing
`MergePhiPeel.cpp:454-469`.

### 1d. The argument, written at both sites as the PREIMAGE one

Verbatim at the test and in the field's header: *"a value this pass MANUFACTURES has no source
preimage and therefore no rival program for F2 to protect against."* Both sites then carry the
explicit refusal SCOPE §3b asks for — **do not re-ground this on "the same compare on the same
wire"**, because a function with two fused diamonds produces a clone of the OTHER region's condition,
which is on a different wire and is excluded too. Retirement triggers written in-source: the peel's
placement / sole-consumer trigger, the in-loop trigger, the `CmpInst`-RAUW trigger (1e), the
`taint = propagate()`-below-the-peel trigger (§1f), and F2's own pre-existing
`railWireClosure`-vs-`CondRails` divergence trigger, which applies to this conjunct unchanged.

### 1e. The `WeakTrackingVH` RAUW hazard, measured rather than assumed

`WeakTrackingVH` **follows** a RAUW (`ValueHandle.h`: *"tries hard to point to a Value, even across
RAUW operations, but will null itself out if the value is destroyed"*). So a stage that RAUW'd a
`CmpInst` between the peel and the last F2 query would make an entry name a value that is **not** a
clone — an over-ACCEPT. Measured that no such stage exists:

```
$ grep -rn "replaceAllUsesWith" ir-pass/src/{SwapRouteEmit,AngleSelectEmit,ClassicalCallArmEmit,\
    SwitchValueEmit,SwitchDataMuxEmit,RegionFlatten,MergePhiPeel,TaintPropagation}.cpp
```
— every target in that window is a `PHINode`, a `SelectInst`, a `BitCastInst`, a `FreezeInst` or a
`cq_theta` call. The only `CmpInst` RAUW in the pass is `rewriteCompare`
(`CompareLowering.cpp:488,530`), which runs inside `lowerOps`, i.e. **after both control rounds**
(`CQLoweringPass.cpp:646` / `:986`). Written in-source as retirement trigger (c).

### 1f. THE L1 ROUND-2 CLEARING QUESTION — answered, and it is not the obvious answer

The brief asks: *"say which stage could clear a `TaintSet` field between rounds and confirm none
does."*

**No field-level clear exists.** `grep -rn '\.clear()' ir-pass/src/*.cpp | grep 'taint\.'` is empty.

**But a WHOLESALE REASSIGNMENT would, and there are fifteen of them.** `taint = propagate(M, wd);`
constructs a fresh `TaintSet` and drops every field, and it appears at `CQLoweringPass.cpp:146, 218,
236, 260, 282, 284, 311, 313` in `run()` and `:835, 845, 858, 869, 874, 887, 892` in the second entry
point. **Measured: every one of them is in the PRE-PEEL prologue.** The peel is at `:451` / `:938`;
the last reassignment is at `:313` / `:892`. Between the peel and the last F2 query — the round-2
fixpoint inside `repropagateControlMerges` — there is **no reassignment at all**:
`repropagateControlMerges` mutates `taint` (re-seeding `Tainted`, `TaintPropagation.cpp:1434-1440`)
and builds its own local `ControlPlan plan2`, but never replaces the `TaintSet`. The round-2 peel
(`TaintPropagation.cpp:1430`) therefore **appends** to a record that still carries round 1's, exactly
as the brief requires.

**Direction if that ever breaks: SAFE.** An emptied record means F2 collides on the clone again, i.e.
bd `rb9x` re-opens as an over-DECLINE — never as an over-accept. It would re-open with no diagnostic
anywhere, so the fixture that would notice is `control_peel_stateprep_bool_seed_int_cond.ll` and
nothing else; that is retirement trigger (e), in-source.

### 1g. `MergePhiPeel.cpp:454-469` — SCOPE §3f's paragraph, pasted

The false clause (*"merge placement … keeps the peeled compare OUT of the live-on-the-edge set
`f2SeedPinnedByLiveRegister`'s backward half walks"*) and its 2026-09-11 ERRATA (which said the
clause was false and left the door unnamed) are **replaced** by §3f's text: the two halves, the
forward half's four steps with their `ArmClassify.cpp` line numbers, the `HP_g`/`HP_d`/`HP_e`
measurement, the repair's location, the preimage ground, and the refusal to re-ground on the wire.
The `h09c`/`h09d` placement measurement above it is kept verbatim — it is still true and still the
reason for the insertion point.

---

## §2 RED-GREEN LOG (Rule 12) — declines first, then accepts

Every row below is `cq controlled lowering: <string> under quantum control`, `DS_Error`, exit 1.
`F2` = `state prep seed is proven equal to the condition register`.

### (A) DECLINES that must stay red — written and confirmed on BOTH binaries

| fixture | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `control_peel_reject_stateprep_handwritten_clone_i1.ll` (= `b_HP_c_merge`) | the peel's OUTPUT written **by hand**: one merge φ, a hand `%clone` + `select` | F2 | **F2** |
| `control_inplace_ry_reject_stateprep_second_cmp_onwire_merge.ll` (= `r_R1b`) | a USER-written second compare on the wire, in the MERGE block | F2 | **F2** |
| `control_inplace_ry_reject_stateprep_second_cmp_onwire_pred.ll` (= `r_R5`) | the same compare in the ENTRY block, above the branch | F2 | **F2** |
| `control_inplace_ry_reject_stateprep_zext_flag_i32seed.ll` (= `r_R4`) | `zext i1 <a clone-shaped compare> to i32` vs an `i32` seed — §3e | F2 | **F2** |
| `control_peel_reject_stateprep_two_region_foreign_clone.ll` (§3b, new) | two regions, the second peelable; A alone and B alone each ACCEPT | `control flow` | **`control flow`** |
| `control_peel_reject_fp_stateprep.ll` (header only) | the fp mux beside a state-prep arm | F2 | **F2** |
| `control_inplace_ry_reject_stateprep_second_flag_i1.ll` (header only) | a pre-branch off-wire measured `i1` | F2 | **F2** |

The first three are the Rule-12 pair the brief asks for: **the fixtures that fail if R-1 is ever
widened into "any second compare", or re-spelled as a name or structure test.** The
`handwritten_clone_i1` one is the sharpest: it is *the same circuit* as the new ACCEPT and has the
opposite verdict, and that is R-1's whole line — the exclusion is provenance, not shape.

The last two got **header RETIREMENT-TRIGGER lines only**; no RUN or CHECK line was touched, and both
were re-run green. `control_peel_reject_fp_stateprep.ll`'s trigger says in terms that a version of
R-1 which pruned the clone from the users walk would flip that file to an ACCEPT, and that if it ever
goes green the exclusion has moved off the test — *"do not bless it"*.

### (B) ACCEPTS — RED on the ORACLE, GREEN here

| fixture | ORACLE | SUBJECT |
|---|---|---|
| `control_peel_stateprep_bool_seed_int_cond.ll` (= `b_P2`'s stage-1 IR) | F2 | **ACCEPT**, 9 prefixes green |
| `control_peel_stateprep_bool_seed_true.ll` (= `b_P2t`) | F2 | **ACCEPT**, 9 prefixes green |

```
$ <ORACLE>/cq-opt … -S ir-pass/test/control_peel_stateprep_bool_seed_int_cond.ll
cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
$ <ORACLE>/cq-opt … -S ir-pass/test/control_peel_stateprep_bool_seed_true.ll
cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
$ cd build && lit -v ir-pass/test --filter 'control_peel_stateprep_bool_seed'
PASS (2 of 2)
```

Both carry the full ordered `CHECK` stream (18 `CHECK-NEXT` lines), a pure whole-file `NOROUTE`
negative prefix, and eight count prefixes `ACNT/FCNT/XCNT/RYCNT/CCNT/CPCNT/UCNT`. Both seeds are
fixtured **because F2 asks both edges**: the clone folds to `true` on one and `false` on the other, so
one fixture would leave the other edge unpinned and a polarity-reversed successor would go green on
it.

**One fixture-hygiene defect of my own, found and fixed before it shipped** (the same class as
IMPL_f2's): the first `CPCNT`/`UCNT` prefixes used the bare patterns `@cqrt_copy_` and `_unc(`, which
FileCheck also matches on the `declare void @cqrt_copy_i32_controlled(…)` / `declare void
@cq_template_…_unc(…)` lines — so the `-NOT` half could never pass. Both are call-qualified now.
(The shipped `control_peel_stateprep_datamux_peeled_control.ll` carries the un-qualified spelling with
a count that happens to absorb the declare; not mine to change, recorded in §7.)

### (C) The probe table, SUBJECT vs ORACLE — 3 moved, 33 unchanged (9 ACCEPT/27 DECLINE -> 12/24)

`probes/impl/subject_probes.txt` is the full 36-row run; the ORACLE column is `probes/README.md`.

| moved | ORACLE | SUBJECT |
|---|---|---|
| `b_A_intb0_boolb1.c` — **bd `rb9x`'s own program** | F2 | **ACCEPT, 22 trace lines**, STRICT 2b `5 rail mint(s) of which 5 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` |
| `b_P2_intcmp_i1seed_peeled.c` | F2 | **ACCEPT, 20 trace lines** |
| `b_P2t_seed_true_peeled.c` | F2 | **ACCEPT, 20 trace lines** |

**Nothing else moved.** In particular, and each is a deliberate non-move: `r_R1b`, `r_R5`, `r_R3`,
`r_R4`, `r_R4b`, `r_R6a`, `r_R6b` stay F2; `v_vd` stays F2 (R-1 does not touch it — SCOPE §4, and
R-2 was not folded in); `v_vd_two_regions` / `v_vd_guard_neg` / `v_vd_no_b1_arm` stay `control flow`;
`v_vd_intb0` / `v_vd_allint` stay `condition data use`; `w_W1` stays **F1**; `w_W2`–`w_W5` stay
`control flow`; and the nine ORACLE accepts (`b_B` 19, `b_C` 22, `b_HP_f` 9, `b_P1`/`b_P1t` 9,
`r_R1` 16, `r_R3t` 12, `r_R4c` 11, `r_R6c` 20) are unchanged **line-count for line-count**.

### (D) ⚠ SCOPE §4 IS WRONG IN ONE ROW, AND I DID NOT MAKE IT RIGHT

SCOPE §4's partition table predicts `b_HP_{a,c,d,e,g}` (the hand-IR clone family) **ACCEPT** after
R-1, and BRIEF §2.2 asks for `HP_g_sel_only` and `HP_c_merge` as fixtures *"RED on the ORACLE, GREEN
here"*. **Measured: all five stay DECLINING**, and they must.

Those five modules' `%clone` is **hand-written**: each has exactly ONE merge φ, so
`peelIndependentMergePhis`' ≥2-φ entry gate refuses the site, nothing is manufactured and nothing is
recorded. Under the record spelling — spelling (i), the one SCOPE §2 recommends and the brief scopes
IN — they are ordinary user compares. Making them green needs spelling (ii) (a name or structure
test), which SCOPE §2 **refuses** on Rule-14 grounds and which SCOPE §5 **independently refuses**
because `control_peel_stateprep_datamux_peeled_control.ll` hand-writes a value literally named
`%cq.peel.cond` and would silently acquire the exclusion. §4's row and §5's paragraph cannot both be
satisfied; §5 is the one with a measurement behind it.

**What I built instead**, and it is a strictly better red-green pair: the GREEN half is the
**PRE-PEEL** module (`b_P2`'s stage-1 IR — what `-O1` actually hands the pass, where the peel really
runs), and the hand-IR post-peel module is committed as the **RED** half
(`control_peel_reject_stateprep_handwritten_clone_i1.ll`) with the refusal of both alternative
spellings written in its header. The two files are the same circuit with opposite verdicts, which
pins the provenance line far more sharply than two greens would have.

---

## §3 INJECTION MATRIX (Rule 12(c)) — `probes/impl/injection_matrix.txt`

Five mutations applied to the **lowered** stream of each new ACCEPT, then all **nine** declared
FileCheck prefixes re-run per mutant: (a) an uncontrolled `cqrt_ry` on the CONDITION register after
the flag's free; (b) a `cqrt_x` on a user register (the prepped `i1` rail); (c) an extra `cqrt_free`
— of the prepped rail, i.e. the Rule-6 freeze violation; (d) the `_controlled` gate's control and
target swapped; (e) the peeled mux's two controlled copies' source rails swapped.

```
fixtures=2 mutations=10 MISSED=0 n/a=0        (DIRTY=0: no unmutated stream fails any prefix)
```

Per mutant, the prefixes that caught it (identical on both fixtures):

| mutation | caught by |
|---|---|
| a — uncontrolled `cqrt_ry` on the condition register | `CHECK`, `RYCNT` |
| b — `cqrt_x` on a user register | `CHECK`, `XCNT` |
| c — extra `cqrt_free` of the prepped rail | `CHECK`, `NOROUTE` (the freeze negative), `FCNT` |
| d — `_controlled` control/target swapped | `CHECK` (the capture binding) |
| e — the peeled mux's two copies swapped | `CHECK` (the ordered stream) |

(d) and (e) are caught by the ordered `CHECK` stream alone, which is the argument for carrying the
whole stream rather than a count summary: a count prefix is blind to a permutation.

---

## §4 e2e — one STRICT slice

`tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.c` = the `rb9x` program
(`probes/b_A_intb0_boolb1.c`: `int a` / `int b0` / `_Bool b1`), reshaped into the harness's
`int slice(void)` + `int main(void)` form. Registered after the last `slice_control_inplace_ry_*`
group in `tests/e2e/CMakeLists.txt` as
`e2e-slice-control-stateprep-bool-under-int-compare-fused`.

```
$ ctest --test-dir build -R '^e2e-slice-control-stateprep-bool-under-int-compare-fused$'
1/1 Test #349: … Passed 1.79 sec
```

The golden was **NOT composed-and-committed**. SCOPE §5's composition (*"`b_C`'s 22 lines with the b1
rail at `i1` widths"*) was used as a PREDICTION, the program was run through the real four-stage
pipeline on the SUBJECT binary, and the measured trace was committed:

```
$ clang -O1 -g -emit-llvm -S … | cq-opt -passes=cq-lowering -S …      # opt exit=0
$ python3 tools/free_pairing_check.py slice.s2.ll
free_pairing_check: 1 file(s), 10 rail mint(s) of which 10 left allocated,
                    4 cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven   # STRICT
$ ./a | wc -l
22
```

**The prediction was exactly right**, which is worth recording because it is the increment's cleanest
statement of the defect. `diff` of the b1 rail against `b_C`'s (the `int b1` twin that already
compiled on the ORACLE) is three lines and nothing else:

```
  cqrt_alloc_i32(0) -> h2          ->   cqrt_alloc_i1(0) -> h2
  cqrt_ry_i32_controlled(h1,h2,…)  ->   cqrt_ry_i1_controlled(h1,h2,…)
  cqrt_measure_i32(h2)             ->   cqrt_measure_i1(h2)
```

Same 22 lines, same shape, `i1` widths — i.e. **the WIDTH was the over-decline, not the circuit.**
The `int` twin is not committed as a slice (it has no defect to pin) and there is deliberately no
`compare_files` gate: the two goldens differ by a stated reduction, so byte-identity would be a false
assertion (the drbq Inc-4 precedent). The 10/4 in stage 2b is DOUBLE the six mints and two frees the
trace shows, because `slice()` has external linkage and `-O1` also inlines it into `main`; the header
says so, so nobody reads it as six rails.

The slice header carries the 22-line stream annotated line by line, the Rule-6 freeze note (`h2` is
never freed — `Ry(0.5)|0⟩ ≠ |0⟩`), and the Rule-2 caveat that a green byte-diff proves symbols and
angles, not the unitary.

---

## §5 THE §3b TWO-DIAMOND QUESTION — measured, bisected, and UNREACHABLE at HEAD

SCOPE §3b is the place this scope said it was thinnest: R-1 excludes a clone of a SECOND fused
region's condition, which is a different compare on a different wire, and only the preimage argument
licenses it. I built the shape (`probes/impl/td1.ll`): region A is the `i1` state prep; region B is a
peelable diamond whose condition `%g` is an operand ancestor of A's condition, so `%g` is in
`CondWire` (already excluded) while the peel's clone of `%g` is not.

```
td1.ll        ORACLE: control flow   SUBJECT: control flow     anchor: br i1 %g, label %armB, label %mB
td_aonly.ll   ORACLE: ACCEPT         SUBJECT: ACCEPT           (region A alone)
td_bonly.ll   ORACLE: ACCEPT         SUBJECT: ACCEPT           (region B alone)
```

The fence is `SwapRouteEmit.cpp:2494`'s `reorderable()`, which admits only `BranchRegion` and
`PhaseKickback`, so the `hcrg` precedence graph refuses a chain whose first member is a state-prep
region — **the bd `35t0` family, an over-decline filed independently of this increment**. So no module
that compiles can exercise R-1's exclusion of a foreign clone today.

That is a measurement over the spellings I could build and **not a theorem** (L5 — a syntactic
enumeration of what `-O1` can produce lost F2 four rounds running), which is exactly why the source
comment states the preimage argument and refuses the wire one. It is committed as
`control_peel_reject_stateprep_two_region_foreign_clone.ll` with the bisect in its header and an L8
retirement trigger: **the day bd `35t0` is closed this file becomes an ACCEPT**, and at that moment
the preimage-vs-wire distinction becomes load-bearing rather than theoretical.

---

## §6 CORPUS SWEEP — ORACLE vs SUBJECT: 12 movers out of 2949, and NO accepted stream changed

`probes/impl/corpus_221c1caa.txt` (`probes/impl/corpus.sh`). Both binaries on the SAME stage-1 file;
a row is `<rel>|<oracle>|<subject>` with `A:<md5-8 of the lowered IR>` or `D:<diagnostic>`. Corpora
per PROTOCOL.md: `ir-pass/test/*.ll` (1900) + every `session-2026-09-13-orchestrator/track*/probes`
+ `session-2026-09-13-orchestrator/probes` + `session-{9pum,b6ap,f2-i1,l4x4,boi6,r903,2026-09-11-orchestrator}`'s
`probes/` and `review_*_probes/`.

```
rows=2949   oracle_accepts=1476   subject_accepts=1486   movers=12
accept_on_ORACLE_with_a_DIFFERENT_lowered_IR_on_the_SUBJECT = 0
```

**That last line is the strongest statement this sweep can make and it is the one to read first: not
one module that accepted on the ORACLE emits a different circuit here.** R-1 is accept-monotone by
construction (F2 only ever ADDS colliders, so removing one can only turn a decline into an accept),
and the sweep measures that the construction holds over 2949 modules.

### The 12 movers, every one listed

**(i) DECLINE(F2) → ACCEPT — 10, all the same shape: a `_Bool`/`i1` state prep whose only collider
was a peel clone.**

| module | subject |
|---|---|
| `ir-pass/test/control_peel_stateprep_bool_seed_int_cond.ll` | A:`b59deb42` — this increment's fixture |
| `ir-pass/test/control_peel_stateprep_bool_seed_true.ll` | A:`51f4aada` — this increment's fixture |
| `trackR/probes/b_A_intb0_boolb1.c` | A:`8b9b032d` — **bd `rb9x`'s own program**, 22 trace lines |
| `trackR/probes/b_P2_intcmp_i1seed_peeled.c` | A:`07eab767` |
| `trackR/probes/b_P2t_seed_true_peeled.c` | A:`64a9d3ce` |
| `session-2026-09-11-orchestrator/review_integration_probes/A_intb0_boolb1.c` | A:`6ba19f62` — the 2026-09-11 copy of `b_A` |
| `…/review_integration_probes/P2_intcmp_i1seed_peeled.c` | A:`37b31b7d` — the 2026-09-11 copy of `b_P2` |
| `…/review_integration_probes/P2t_seed_true_peeled.c` | A:`216498b6` — the 2026-09-11 copy of `b_P2t` |
| `…/review_integration_probes/O3_mux_quantum_incomings.c` | A:`fdadbb7f` — **examined below** |
| `…/review_integration_probes/R1_p80_bool.c` | A:`da1855cc` — **examined below: the ROUND-2 peel** |

**(ii) DECLINE(F2) → a DIFFERENT, LATER DECLINE — 2. Still loud, still exit 1.**

| module | subject |
|---|---|
| `…/review_integration_probes/R2_p80_window.c` | `D: control flow` |
| `…/review_integration_probes/R4_p80_measured.c` | `D: condition measured before the control route` |

Both are `p80` + a `_Bool` prep. F2 was in front of a second fence; with F2 gone the second fence
fires, which is what those two probes were written to exercise in the first place (R4's is the Track
A.1 rung-(ii) backstop, named in its own comment). Neither becomes an accept.

**Every `control_peel_*` and `*stateprep*` fixture that does NOT move: 164 rows, byte-unchanged** —
including `control_peel_reject_fp_stateprep.ll`, `control_peel_stateprep_datamux_peeled_control.ll`
(the hand-written `%cq.peel.cond`, untouched exactly as SCOPE §5 requires),
`control_peel_stateprep_datamux.ll`, `control_peel_stateprep_rail.ll`, the whole
`range_forward_*` / `sideways_*` / `merge_edge_sideways` / `step_cap_over` family, and
`control_inplace_ry_reject_stateprep_second_flag_i1.ll`.

### The two movers that were not predicted, examined

**`O3_mux_quantum_incomings.c` — an if/else whose peeled `a` mux has TWO QUANTUM incomings,
alongside a `_Bool` prep in the else arm.** Its 2026-09-11 verdict chain was
`control flow` → (b6ap) → `F2`; R-1 removes the last wall. The emitted stream is 23 lines, STRICT 2b
`2 verified, 0 violation(s), 0 unproven`: the prep is `cqrt_alloc_i1(0)` +
`cqrt_ry_i1_controlled(f, h4, 0.5)` on the else-polarity flag, and the mux is the ordinary 4.4
controlled-copy merge — `cqrt_copy_i32_controlled(f, h1, out)`, `cqrt_x(f)`,
`cqrt_copy_i32_controlled(f, h0, out)`, `cqrt_x(f)` — with `p` and `q` **kept live and measured**, so
it is an additive controlled copy and not a clone (Rule 8's keep-sources-live case).

⚠ **ISOLATED, so the claim is not a reading of a trace.** `probes/impl/o3_noprep.c` is O3 with the
`_Bool` prep deleted and nothing else: it lowers to **md5 `9ce7d45e75e212a8721ac831d32bdca3` on BOTH
binaries** — byte-identical. So the quantum-incoming mux is pre-existing, already-cleared 4.4
behaviour that R-1 did not touch; the only thing R-1 changed in O3 is that F2 stopped declining the
*separate* state-prep arm, which is `control_peel_stateprep_bool_seed_int_cond.ll`'s shape in its
if/else spelling.

**`R1_p80_bool.c` — and this one is the L1 obligation DEMONSTRATED rather than argued.** `p80` is the
canonical ROUND-2 shape: a 6.5 classical-call region whose `%out` rail makes a downstream condition
(`r == 13`) classical at round 1 and TAINTED at round 2, so the fused 2-φ diamond behind it is peeled
by the **round-2** `peelIndependentMergePhis` call (`TaintPropagation.cpp:1430`) and judged by the
**round-2** `classifyArms`. It now accepts at 33 trace lines, STRICT 2b
`8 rail mint(s) of which 8 left allocated, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0
unproven`, with the prep correctly fired on `¬(r == 13)` (`cqrt_x`-bracketed) because `r == 13` sets
`a = 2` and the guard is `a >= 3`. **A round-2 clone is therefore recorded and excluded — §1f's
reasoning about the reassignment window is confirmed by a measurement and not only by line numbers.**

---

## §7 OPEN QUESTIONS / FOUND IN PASSING

1. **`SCOPE_R.md` §4's `b_HP_{a,c,d,e,g}` row is wrong** (§2(D) above) and contradicts §5 of the same
   document. Recorded here rather than edited into `SCOPE_R.md`, which is another agent's sealed
   record. A reader who quotes §4's table without §5 will conclude R-1 under-delivered; it did not —
   §4's row describes spelling (ii), which §2 of that same document refuses.
2. **bd `rb9x`'s NOTES ask for more than R-1 delivers.** The correction reads *"exclude the peel's
   clones **(and any `i1` the condition-tree grammar derives from the condition)**"*. R-1 is the
   clones only. The parenthesis is a second, unargued narrowing — a derived `i1` the user wrote has a
   source preimage, so the preimage argument does not reach it and it would need its own rival audit.
   Not filed as a bd (I do not close or file issues from an implementation worktree); it belongs in
   the R-2 discussion.
3. **`r_R4`'s `zext` reach has no genuine peel-clone instance**, and the reason is structural rather
   than lucky: the peel's clone has exactly ONE consumer by construction (its own select), so no
   module can contain a `zext` of a *real* peel clone. §3e's worry is therefore only ever about
   hand-written clone-shaped compares, which `…_handwritten_clone_i1.ll` already covers. The
   committed `…_zext_flag_i32seed.ll` pins the width-reach finding itself (*any pinned flag that is
   zero-extended is an `i32` collider*), which is worth a fixture on its own.
4. **`control_peel_stateprep_datamux_peeled_control.ll` carries an unqualified `CPCNT-NOT:
   @cqrt_copy_` / `UCNT-NOT: _unc(`** whose count silently absorbs the `declare` lines. It is green
   and correct today by arithmetic accident; the same spelling in a new fixture is a `-NOT` that can
   never fail. Not touched (out of scope, and its counts are load-bearing for bd `b6ap`).
5. **The two exclusions at F2's test are now independent and neither subsumes the other**
   (`CondWire` vs `PeelClones`). A future tidy-up that merged them into one set would have to carry
   BOTH arguments — the R4-cancellation one and the preimage one — and they are different kinds of
   argument. Said in-source at the test; flagged here because "two conjuncts on one line" is exactly
   the shape someone refactors.
6. **R-2 was not folded in and `vd` still declines**, as scoped. SCOPE §6's prediction is unchanged by
   this increment: when Track M's binary exists, `vd.c` should still report F2 on it.
7. **R-1's customer set is LARGER than the scope measured, and the two extra customers are both
   worth a reviewer's attention rather than a footnote** (§6): `O3_mux_quantum_incomings.c` (a peeled
   mux with two QUANTUM incomings beside a `_Bool` prep — isolated to pre-existing 4.4 behaviour by
   `o3_noprep.c`'s byte-identical lowering on both binaries) and `R1_p80_bool.c` (the **round-2**
   peel). Neither was in SCOPE's 36. The scope sampled the shape; the corpus found the population.
   A round-2 customer existing at all is the thing to check hardest in a Rule-13 round, because §1f's
   argument for it is a line-number argument and this is its only end-to-end witness.
8. **Three modules are DUPLICATED between `trackR/probes` and
   `session-2026-09-11-orchestrator/review_integration_probes`** (`b_A`/`A_intb0_boolb1`,
   `b_P2`/`P2_intcmp_i1seed_peeled`, `b_P2t`/`P2t_seed_true_peeled`), so 3 of the 12 corpus movers
   are the same programs counted twice. Not a defect — the scoping agent copied them deliberately and
   says so — but a reader counting movers should know that the 12 are **9 distinct programs**.
9. **`b_HP_b_orig.ll` declines `condition data use neither escaped nor measured` BEFORE F2**, on both
   binaries, so the "region's own compare given a data use" cell is still untested against R-1. It is
   not a gap R-1 created; recorded so a future widening of `condDataUseDisposition` knows it will
   expose a cell this increment could not measure.
