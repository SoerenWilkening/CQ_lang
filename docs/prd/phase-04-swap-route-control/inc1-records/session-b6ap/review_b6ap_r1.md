# Rule-13 REVIEW, ROUND 1 — bd `test_C_libtooling-b6ap`: THE MULTI-PHI MERGE PEEL

Independent adversarial review of branch `merge-phi-peel` (worktree
`/Users/sorenwilkening/Desktop/CQ_b6ap`, off `main` `0c7380c`), 2026-09-11.
SUBJECT `CQ_b6ap/build/ir-pass/{cq-opt,libCQPass.so}`; ORACLE
`CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}` (`main` `0c7380c`, read-only, never
rebuilt or written to). Nothing under `ir-pass/`, `include/`, `tests/`, `tools/`
was edited in either checkout; nothing was committed. Probes + runner:
`review_b6ap_r1_probes/` (`./ab.sh <name>` runs one on BOTH binaries).

## VERDICT: **BLOCK**

One CONFIRMED silent miscompile, reachable from plain C at `-O1`, in **five**
measured consumer classes, at `opt` exit 0, `opt -verify` clean and STRICT
stage-2b `0 violation(s)`. It is not a corner of the predicate — it is the
predicate's *whole accept class* composed with an ordinary downstream consumer,
and it **falsifies the increment's own stated contract** ("produce the module the
hand peel already is"): for every reproducer below the hand-peeled twin of the
very same program either lowers CORRECTLY or declines LOUDLY on the ORACLE.

Everything else I attacked held. The five matrix rows are correct and
`UNROLLED-ONLY` is the right verdict (§6).

---

## F-B6-1 — CONFIRMED SILENT MISCOMPILE: the peel grows the taint set AFTER every stage that adjudicates consumers of tainted values

**Grade: CONFIRMED-MISCOMPILE. Blocks.**

### The mechanism, read off the pipeline

`CQLoweringPass::run` order (`grep -n` on the call sites):

| line | stage | asks |
|---|---|---|
| 321 | `detectSpecializations` | which callees must be CLONED because an argument is tainted (Phase 6) |
| 330 | `declineTaintEscapes` | is any consumer of a tainted value outside the proven set? (store / unknown callee / unsupported inst / non-i32 ret) |
| 337 | `declineStaleRecordOps` | is a tainted pure op scheduled past a non-diagonal wire gate? |
| **416** | **`peelIndependentMergePhis`** | **creates a TAINTED `select` and `propagateFromSeeds` taints its whole transitive user cone** |
| 418/419 | `detectControlRegions` / `lowerControlRegions` | |
| 452 | `repropagateControlMerges` | re-runs `replanReseedSpecialization` **and `declineTaintEscapes`** — *because its own taint growth needs it* (`TaintPropagation.cpp`, and `CQLoweringPass.cpp:522` says so in as many words) |

The implementation's §3 finding was that the peeled `select` **must** be tainted
(a source-written select is a user of the branch condition; a `phi` is not). That
is right, and the fix is right. What was not asked is the other half of the same
sentence: **making the select tainted MANUFACTURES tainted values that no guard
has ever adjudicated**, because the guards that own that question all ran ~90
lines earlier. `repropagateControlMerges` is the in-tree precedent for exactly
this obligation and the peel does not follow it.

The population is precise and is the peel's *entire* accept class: a merge `phi`
whose incomings are pred-available is, by construction, frequently **classical**
(two constants) — so before the peel it is untainted and its consumers are
classical; after the peel the same value is a quantum rail and its consumers are
quantum consumers nobody checked.

### Reproducers — all plain C at `-O1`, all `opt` exit 0 / verify-clean / 2b `0 violation(s)`

Common source shape (`m`'s φ is the peel target; `a`'s φ is the region's own,
arm-defined and correctly left in place):

```c
int q = cq_theta(q, 0.3);  int a = cq_theta(a, 0.4);
int m = 5;
if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
<CONSUMER of m>
```

| probe | consumer | ORACLE (`main`) | SUBJECT | what the emitted program does |
|---|---|---|---|---|
| `r20_clone_measured.c` | `int t = helper(m); cq_measure(t)` (`noinline` classical callee) | DECLINE `control flow` | **exit 0** | `call fastcc @helper(i32 %out)` — the **untouched classical body** is called with the quantum rail HANDLE, and `cqrt_measure_i32` then fires on `handle+1`, an **unrelated register**. Trace: `cqrt_measure_i32(h5) -> 0`, where `h5` is `cqrt_alloc_i32(7)` |
| `r07_escape_clone2.c` | `g_probe = helper(m)` | DECLINE `control flow` | **exit 0** | prints `g=5` — `helper(tag=4)` |
| `r04_escape_store.c` | `g_probe = m` (global store) | DECLINE `control flow` | **exit 0** | prints `4` — the **runtime handle tag** of `%out` is stored |
| `r11_escape_ptrstore.c` | `arr[1] = m` | DECLINE `control flow` | **exit 0** | prints `4` |
| `r02_escape_sink.c` | `extern void cq_sink_probe(int); cq_sink_probe(m)` | DECLINE `control flow` | **exit 0** | `call void @cq_sink_probe(i32 %out)` — a quantum rail handed to an unknown callee |

### The twin measurement that makes this the peel's, not `-O1`'s

For each of the above I hand-peeled the SAME stage-1 module (replace the second φ
by `icmp` + `select`, exactly what the stage builds) and ran it on BOTH binaries:

| twin | ORACLE | SUBJECT |
|---|---|---|
| `r23_clone_handpeel.s1.ll` (of `r20`) | **exit 0, CORRECT** — 26 lines: `cq_template_add_i32_hl(h4,1) -> h7`, `cqrt_copy_i32(h7,h8)`, `..._unc`, `cqrt_free(h7)`, `cqrt_measure_i32(h8)`. The Phase-6 candidate WAS specialized and the add WAS lowered | identical |
| `r03_handpeel_escape.s1.ll` (of `r02`) | `cq taint escape: tainted value consumed by an unknown callee` | same |
| `r05_handpeel_store.s1.ll` (of `r04`) | `cq taint escape: tainted value stored to memory` | same |
| `r08_handpeel_clone.s1.ll` (of `r07`) | `cq taint escape: tainted value stored to memory` | same |

`r20` vs `r23` is the decisive pair: **one program, two spellings of the same
module, 21 trace lines measuring an unrelated qubit against 26 trace lines
measuring the right one.** The increment's byte-identity contract was verified on
one shape (`z08`/`z12`) and does not hold in general.

### It is NOT pre-existing / shared with PredMux or with `-O1`'s own selects

`r16_predmux_escape.c` / `r17_predmux_escape1.c`: the same escape written so that
`clang -O1` itself produces the `select` (a trivially speculatable arm)
**declines `cq taint escape: tainted value stored to memory` on BOTH binaries** —
because a source/`-O1` select is tainted at `propagate` time and therefore visible
to the 330 guard. The peel's population is *precisely* the complement: the merges
`-O1` does **not** fold to a select, i.e. the ones where taint arrives too late.

### Round-1 vs round-2 asymmetry (worth stating with the fix)

The **round-2** peel site (`TaintPropagation.cpp:1409`, inside
`detectAndLowerOnwardControl`) is *covered*: `repropagateControlMerges` re-runs
`replanReseedSpecialization` + `declineTaintEscapes` after that loop. The hole is
the two **round-1** call sites (`CQLoweringPass.cpp:416`, `:887`) — and, for a
module with no 6.5/4.5 `%out` rail, `repropagateControlMerges` early-returns on
`UntaintedMergeRails.empty()` and never runs at all (measured: `r04` has a 4.4
`%out`, which is **not** registered there — only `ClassicalCallArmEmit` and
`SwitchDataMuxEmit` register).

### Fix options (reviewer's, not prescriptive)

1. **Follow the in-tree precedent.** After `propagateFromSeeds`, re-run the same
   pair `repropagateControlMerges` runs for its own delta:
   `replanReseedSpecialization`-equivalent + `declineTaintEscapes`. Cheap,
   uniform, and it is the pattern the tree already treats as mandatory after
   taint growth. Needs its own red-green (a widened *decline* is monotone, but
   re-running the Phase-6 re-plan at 416 is a new interaction).
2. **Decline-keeping alternative.** Refuse to peel a φ whose transitive user cone
   contains anything outside the proven consumer set (`cq_measure`, an i32 `ret`,
   a lowerable opcode, an IO sink). Narrower accept class, no new guard ordering.
3. Do **not** ship "the guard would have caught it if it ran" as an argument
   without running it — the five reproducers are what running it looks like.

---

## F-B6-2 — LEAK / unprobed new accept: `classifyGuardedStoreArm` + an all-peelable merge stops the whole 7.5 reversal

**Grade: LEAK (Rule-6-safe direction) + NEW-ACCEPT-UNPROBED.** IMPL §7 Q7(iv)
predicted the decline→accept flip and did not probe it; probed here.

`g01_guarded_store_2phi.c` — `tests/e2e/slice_qram_guarded_store.c` with two
constant-armed muxes added to the merge:

* ORACLE: `cq controlled lowering: guarded store with a merge value` (loud).
* SUBJECT: **exit 0**, 35 trace lines, 2b `10 rail mint(s), 10 left allocated,
  2 free(s), 0 violation(s)`.

The answer is right, but **none of the 7.5 reversal spine runs**: there is no
`cqrt_qram_load_i32_unc`, no `cqrt_qram_store_i32_controlled_unc`, no strip and
no free of the guarded store's path-predicate flag `h3`, and no `cqrt_ry` inverse.
`h3` is left allocated and entangled with the condition register.

Control `g02_guarded_ctrl.c` (same program, the two extra registers NOT in the
merge, so no φ and no peel) runs the **complete** shipped reversal on the ORACLE:
`qram_load_unc`, `qram_store_controlled_unc`, `icmp_slt_unc`, `cqrt_free(h5)`,
both `cqrt_ry(-0.5)`. So the difference belongs to the new accept, not to the
extra registers.

Not a wrong unitary and not a dirty free (Rule 6's safe direction), but it is a
brand-new accept in the 7.5 QRAM neighbourhood that behaves materially unlike its
shipped one-φ sibling and has no fixture. It should either be fenced out for this
increment or get its own row and its own round.

---

## What I attacked and could NOT break (each argued from the emitted stream)

### The fp / ANGLE boundary (brief §1) — HELD

The peel does manufacture fp selects, and the `SelectClassify` gate-3 partition
holds for a peeled select exactly as for a source-written one. Measured:

| probe | shape | SUBJECT | emitted |
|---|---|---|---|
| `f01_angle_only.c` | peeled `double` φ → `cq_phi(ang)` | ACCEPT | Rz-stem kickback pair `x(f); rz_i1(f,0.1); x(f); rz_i1(f,0.7)` = `diag(e^{i0.1},e^{i0.7})` on the flag. **Correct**; no `cqrt_alloc_f64` |
| `f04_angle_theta.c` | peeled `double` φ → `cq_theta(b, ang)` | ACCEPT | Ry stem BY DIFFERENCE: `cqrt_ry_i32(h2, 0.1)` + `cqrt_ry_i32_controlled(f, h2, 0.6)`. **Correct**, constant arms |
| `f02_angle_and_data.c` | the SAME fp value used as an angle AND as data (`g_d = ang*2.0`) | DECLINE `rotation angle` | the wire is not crossed |
| `f03_angle_two_consumers.c` | one peeled angle select, TWO `cq_phi` consumers | DECLINE `rotation angle` | the ONE-consumer fence fires |
| `f05_ry_runtime_arm.c` | Ry stem, RUN-TIME arm (volatile load) | DECLINE `rotation angle` | the Inc-2b clearance narrowing holds through the peel |
| `f06_rz_runtime_arm.c` | Rz stem, RUN-TIME arm | ACCEPT | kickback pair, no subtraction — the shipped Rz-stem semantics |
| `f07_quantum_angle.c` | a QUANTUM-derived `double` as the peeled arm | DECLINE `control flow` | Rule 3 held |

I could not construct the P7/F-L3-1 recurrence (an orphaned angle select
re-classified as fp DATA): `deleteGlobalPhases` runs at 533, long after detection
at 418, so every peeled angle select is adjudicated by gate 3 while its consumer
still exists.

### D1, the `>=2`-φ entry gate (brief §2) — the gate is right; its stated reason is stronger than the measurement

Measured pair `d01_tail_onephi.c` (one φ — the shipped `phaseAngleTail` path,
ORACLE == SUBJECT byte-identical, 12 lines) vs `d02_tail_twophi.c` (the SAME
angle-tail φ **plus** a data mux — ORACLE declines, SUBJECT peels both, 26 lines):

```
d01 :  rz_i1(f,1.5) ; rz_i1(f,0.7) ; x(f) rz_i1(f,0.1) x(f)
d02 :  rz_i1(f1,1.5) | mux triple on f2 | x(f3) rz_i1(f3,0.1) x(f3) rz_i1(f3,0.7)
relative phase, BOTH:  c=1 -> 1.5+0.7 = 2.2   c=0 -> 0.1
```

**Same unitary.** So peeling an angle-tail φ is not itself a semantic hazard; what
D1 actually buys is that on a ONE-φ merge the stage cannot tell the angle tail
from *the region's own value φ*, and peeling the latter would break a shipped
accept. That is the sound reason; the "it stops the f64/angle wire-crossing"
framing in IMPL §2/§7 Q1 is not what the measurement shows. **DOC item.**

### The taint fix across incoming kinds (brief §3) — the taint edge itself is correct

Every peeled incoming kind I could reach lowers its downstream correctly once
tainted: constant (`r04`), `Argument` (`z22`, implementer), pre-region tainted
(`p90`/`h90` Q+Q), classical `i64` used as a QROM index (`u03_index.c` →
`cqrt_copy_i64_controlled` then `cqrt_qram_load_i32`), a shift amount
(`u05_shift.c` → `cq_template_shl_i32_lh(1, h4)`), a `switch` scrutinee in the
same merge (`x01_switch_in_merge.c`, 10 mints / 4 frees / 2b clean), a new tainted
branch condition (`u04_newbranch.c` — declines identically on both binaries).
The `afmv` handle-tag class is gone *for op consumers*; §F-B6-1 is the same class
arriving through consumers that are not ops.

### Rule 8 / aliasing, stale records, polarity, placement

* `n01_alias_rail_mux.c` — both peeled incomings are the SAME physical rail at two
  points of its history (a chained `cq_theta`, distinct SSA). The peel FIRES
  (decline anchored **on the peeled select**, `CQ_CTRL_DBG=1`) and
  `SelectClassify` refuses it `control flow`. Held.
* `s01_stale_record_mux.c` — the peeled mux reads the PRE-rotation record of a
  register the arm rotates in place: SUBJECT declines
  `stale rail record read past a controlled Ry`. Held.
* **Polarity (Rule 9)** is right in both orientations, measured, not argued:
  orientation A (`if (q==5)`, arm = successor 0) gives `select c, 7, 5`
  (`r04`'s stream: `copy_controlled(f, alloc(7), out)` then `x(f)` then
  `copy_controlled(f, alloc(5), out)`); orientation B is the flagship fixture's
  `select i1 %c, i32 2, i32 5` with the merge as successor 0.
* **P9 / in-loop (brief §7).** `regionEntryInLoop` is `blockOnCycle(Pred)`, so
  irreducible cycles are covered. `MergeBB` cannot be on a cycle while `Pred` is
  not: `hasNPredecessors(2)` forces `preds(MergeBB) = {Pred, Arm}` and `Arm`'s only
  pred is `Pred`, so any back edge into the merge passes through `Pred`. Sound.
* **Block lifetime / hcrg (brief §4).** `SelectRegion`/`AngleSelectRegion` are
  inert to the pre-flight; the peel only ever puts a select in `MergeBB`, which
  `flattenRegion` SPLICES into `Pred` (never frees), and every emitter inserts
  POSITIONALLY, so source order survives any Kahn order. `control_peel_seq_chain`
  accepts (41 lines) where the ORACLE says `nested control flow`.
* **P3b.** `poison` is refused (`x02_poison_incoming.s1.ll`, unchanged on both).
  `freeze i32 poison` is an `Instruction`, so it is *peeled* (`x03`) — sound, because
  `freeze` is single-valued and that is exactly what `LiteralIntegrity` guard 1 is
  counting. Worth one line in the P3b comment. **DOC.**

### Q8 — the `sed`/`diff` RUN line is real, not vacuous

I re-ran the fixture's own RUN pipeline by hand with a MUTATED peeled control
(the select's two arms swapped): `diff -u` exits **1** and the emitted
`cqrt_alloc_i32(2)` / `cqrt_alloc_i32(5)` pair swaps. Unmutated: exit 0. lit fails
a RUN line on non-zero exit, so the byte-identity claim is enforced.

---

## Gates I ran

| gate | result |
|---|---|
| `ctest -R ir-pass-lit` (SUBJECT) | **Passed, 52.71 s, 1/1** |
| all 25 `control_peel_*.ll` on BOTH binaries | matches IMPL §3 exactly: 9 accepts RED on `main`, 3 controls green both, 9 declines keep `control flow`, 4 declines move to a deeper string |
| `ctest -R 'fused.regions'` | 2/2 Passed |
| corpus diff, ORACLE vs SUBJECT, stride-5 sample of the 1776 pre-existing fixtures | **355 sampled, 0 movers** (exit code, stderr and lowered text) |
| `e2e-loop-twin-matrix` | NOT re-run (1027 s); the five moved cells were re-derived by hand from their own sources — §6 |

---

## §6 — MY RULING ON THE FIVE `loop_twin_matrix` ROWS

**KEEP `UNROLLED-ONLY`. Do not apply the Q10 conservative clause.**

Re-derived from scratch on `m_rz_eq_rz` (`m01_rz_eq_rz_unrolled.c` — generated
from `tools/loop_twin_matrix.py`'s own `sources('rz','eq','rz',surface='void')`,
not copied from IMPL). `clang -O1` leaves TWO `double` angle φ in the merge; the
peel makes both selects and each is claimed by `classifyAngleSelect`'s **Rz
stem**. Emitted, 22 lines, 2b `0 violation(s), 0 unproven`, no `cqrt_alloc_f64`
anywhere:

```
f1 = (a==5): rz_i1(f1, PI) ; rz_i1(f1, -0.125)          <- the ARM's two cq_phi
f2 = (a==5): x rz_i1(f2,-0.125) x ; rz_i1(f2, 0.125)    <- select(c, 0.125, -0.125)
f3 = (a==5): x rz_i1(f3, 0.125) x ; rz_i1(f3, PI)       <- select(c, PI, 0.125)
relative phase:  c=1 -> (PI-0.125) + 0.125 + PI = 2*PI     c=0 -> 0 - 0.125 + 0.125 = 0
```

The source's two unconditional `cq_phi(±0.125)` are global phases and are deleted
by D2; the true unitary is a `2*PI` relative phase on `a==5`, i.e. the identity.
**The emitted stream is correct**, each flag is minted from an unchanged `h0`
(every intervening gate is a diagonal Rz on a *flag*), and each is stripped and
freed at `|0>`. The rolled side's `condition predates a non-diagonal gate` is
unchanged on both binaries, so the divergence is a rolled-side OVER-decline and
`UNROLLED-ONLY` is the established class for it (63 other cells, three of them
the same `m_rz_*_none` family one axis over). The hand edit is 5 rows + a dated
header block, `--regenerate` was not used, and the quarantine is untouched.

Q10's alternative (refuse to peel a φ whose sole user is an angle slot) would
*also* be sound, but it buys nothing measurable here and it would put a second
spelling of a `phaseAngleTail`-shaped question in the peel (Rule 14). Keep the
rows.

**Caveat, and it is the reason this is a ruling and not a rubber stamp:** the
peel IS now a customer-generator for the angle-select path, and that path's
accept class is narrower than the data path's (constant arms for Ry, one
consumer, the `2^-40` rounding fence). Every boundary I probed declines loudly
(`f02`–`f05`, `f07`), so the generator is currently fenced — but a future
widening of `classifyAngleSelect` now has a second, non-obvious source of
customers.

---

## §7 — ITEMS FOR THE NEXT ROUND (not blockers)

1. **F-B6-2**'s guarded-store accept — fence or fixture it.
2. **The classify-vs-emit taint window on a select ARM.** `detectControlRegions`
   (418) classifies a select whose arm is another region's merge φ while that φ is
   still UNTAINTED; `lowerControlRegions` (419) may RAUW it to a 6.5/4.5 `%out`
   before `emitSelectRegion` runs. I could not reach it from `-O1` (`w03` —
   IPSCCP const-folds the 6.5 callee, so the arm arrives as an already-tainted 4.4
   `%out` and lowers correctly, `cqrt_copy_i32_controlled(h7, h2, h8)`), and the
   window is **not the peel's** (a source-written select has it too) — but the peel
   adds customers to it. Worth one probe with a genuinely opaque 6.5 callee.
3. **The peel never runs inside a Phase-6 clone body** (`specialize` is at 595,
   the peel at 416), so a 2-φ merge in a specialized callee keeps declining. An
   over-decline; record it rather than leave IMPL Q7(ii) open.
4. **D1's stated justification** (§ above) — correct gate, wrong reason in the
   source comment and in IMPL §2/§7 Q1.
5. **P3b + `freeze`** — one clarifying line.
6. **Assume a fifth thing.** This round found F-B6-1 by asking one question the
   implementer's own §3 finding implies but does not ask: *the peel's taint fix
   is correct; what did the new taint reach that nobody has asked about?* The
   symmetric question for the NEXT round is the other half of IMPL Q9: the peel
   also copies the **debug location** and the **incoming values**, and it copies
   the compare's **flags** (`Instruction::clone` carries `nsw`/`nuw`/`exact`/fast-math
   and the `!dbg`) — none of which was checked against what a source-written
   compare at that position would carry.
