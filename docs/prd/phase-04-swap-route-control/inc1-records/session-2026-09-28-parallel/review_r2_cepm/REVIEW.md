# Rule-13 review r2 — bd `test_C_libtooling-cepm` + `3zr4`, round 2

- **Subject:** `1f5dbf98` (round 2) on `7f0be42f` (round 1b). Diff reviewed: `git diff 7f0be42f..1f5dbf98`
  (code: `TaintPropagation.{h,cpp}`, `Specialization.cpp`, `ArmClassify.cpp`; 3 new fixtures + the bank fixture).
- **Subject `cq-opt`:** sha-256 `89186a3011a22882d44bc201` (`build/ir-pass/cq-opt`; every run used the
  byte-identical frozen copy `scratchpad/cepm/cq-opt.subj3`, hash re-measured).
- **Round 1b:** `scratchpad/cepm/cq-opt.subj2` `02522b6a4fdb8911eafe965e`.
- **Oracle:** `scratchpad/frozen/cq-opt.main_9a230646` `3f6db37f5cf937b4d70f5736`.
- **Composed** (private worktree `scratchpad/rev_r2_cepm`: `1f5dbf98` + merge of `main` `ba4fdad4` = rhk5 + z0re;
  one conflict, `CODE_MAP.md`, resolved to main's side; no code conflict; runtime/`opcode_table.yaml`/`CQ.h`
  unchanged on main): `cq-opt` `45c895c2f50757a63f583889` → `scratchpad/r2_cepm/cq-opt.composed`.
- **One mutant** (same worktree, composed code): C1 = no climb past the φ block's direct predecessors in
  `LaterTaintOracle::walk` (`WL.append(pred_begin(X), pred_end(X))` → no-op): `1af67a9ac21b6ba7fe43178c`.
  Source restored afterwards.
- **Time:** ~65 min. Load ≤ `-j4` (one `cmake --build -j4 --target cq-opt`, then one incremental rebuild).

**Ran, literally:** the four new/changed fixtures' RUN lines by hand on subject, round 1b, oracle and the composed
binary; a 23-program twin battery (`probes/tw.sh`: stage 1 per TU `clang -O1` + `llvm-link`, stage 2 on
subject/1b/oracle, stage 2b `free_pairing_check.py` STRICT, link, run at argv `5 7`, `2 9`, `9 1`, trace `cmp` C vs
hand-inlined twin T); the same battery on the composed binary (`probes/twc.sh`, plus stream identity vs the subject);
the C1 mutant on 7 probes.
**Did NOT run:** `lit ir-pass/test` (any binary), corpus A/B, the implementer's mutation matrix, any ctest/e2e entry,
`cq-opt-equivalence`, `+Asserts`, lit on mutant C1 (I rely on r1A F-r1A-2's measurement that no fixture pins the
climb). No statevector simulation.

## Verdict: `CLEAR-WITH-ITEMS` — 0 P1, 1 P2, 4 P3

Round 2 is correct and adds no wrong circuit that I could find. Both changes narrow when a site is tainted at round 1.
Each failure direction ends loud or matches the oracle:
- If `LaterTaintOracle` over-approximates, the site is tainted at round 1, which is what every drain did before cepm.
- If it under-approximates, the site is STICKY. `replanReseedSpecialization` grows its `Pending` mask, since the grown
  argument is always in the `Tainted − beforeTaint` / peel delta. The clone is then built with that mask, and if it
  returns a register, `specialize()` declines with `kMsgPredictedClassicalQuantum`.

  One ordering fact supports this. `detectSpecializations` at `CQLoweringPass.cpp:565` runs before the round-1 peel at
  `:707`. The peel's delta goes through `adjudicateTaintDelta`, which replans. So "reached by a REPLANNED MASK" holds
  at both growth sites.

The items are one false "unreachable" claim with an exhibit that pins the conjunct it covers, two fixture headers
that misstate their twin, two comment grounds, and one removal with no pin.

## The argument restated, and where it is asserted rather than measured

1. **Callee seed removed.** A call RESULT gains taint beyond its operands only through the 3jru return crossing.
   `CB->getCalledOperand() == F` means an indirect call is never crossed. A crossing onto a used direct call is
   refused by `declineQuantumReturnCalls`, and so is any non-call use (address taken, alias, constant user). That
   refusal runs after the round-2 fixpoint and before `specialize()`, in both entry points (`:800`, `:1569`). Memory
   is not a taint channel: `drainWorklist` follows SSA users only, and a store of a tainted value dies at
   specialization or escape (`mem1`). **Measured, holds** (battery below).
2. **`selectsIncoming`.** Each growth replaces a φ (6.5/4.5/IO-sink `%out`, peel `select`) whose incoming edge is
   chosen by the tainted branch. Every successor E-set of that branch is then a different single predecessor, so it
   "selects". A branch whose arms all reach M first through one predecessor P cannot change the φ's value, because
   the value is `incoming[P]` and `walk` visits that separately. An empty E-set is also truly non-selecting, but
   counting it as selecting is the conservative direction. **Asserted, and sound by the argument above.** Every
   under-approximation ends at the check anyway.
3. **The climb** (predecessors beyond the direct ones, up to `idom(M)`). The comment says it is UNREACHABLE TODAY.
   **That is the asserted step, and it is false:** see F-r2-1.

## Findings

### F-r2-1 — P2 (unpinned conjunct with an unsound stated reason; the exhibit that pins it exists) — INTRODUCED (the comment is round 2's; the climb is 1b's)

The claim at `TaintPropagation.cpp` `LaterTaintOracle::walk`:

> *"THE CLIMB PAST `M`'s DIRECT PREDECESSORS IS UNPINNED AND, TODAY, UNREACHABLE … every growth channel whose tainted
> branch is not a direct predecessor of the merge … declines in round 1."*

**The claim is false for the `MergePhiPeel` channel.** Take an if/else diamond with two non-empty phase arms and two
pred-available merge φs, written as hand IR in `probes/ir/pkdC.s1.ll`. The two arms are `cq_phi(.2)` and
`cq_phi(.3); cq_phi(.1)`, and the φs are `y=[m|n]` and `z=[n|m]`. It feeds `t = h(q, y); if (t > 3) q2 =
cq_theta(q2, .2)`.

- It ACCEPTS on the subject, round 1b, the oracle and the composed binary. The stream is byte-identical across all
  four (`probes/results/pk_streams_vs_oracle.txt`).
- The tainted branch is **not** a direct predecessor of the merge: both predecessors are the arm blocks. At gen 0 the
  settle step flips `h(q, y)` only because the climb reaches the entry block's `br`.
- **Mutant C1**, which removes the climb, moves pkd ACCEPT → DECLINE
  `cq specialization: lifted callee returns a quantum register where propagation predicted a classical result`. The
  peel's growth drain leaves the site sticky, and the replanned clone returns y+1.
- The same mutant leaves pk1, pk2, lpp, r6b, l3 and fp1 accepting (`probes/results/mutant_C1_no_climb.txt`).

So the climb is **reachable and pinnable**. The retirement trigger the comment writes ("the day … the peel admits a
merge whose tainted branch is not a direct predecessor") is **already met**, at the IR level. The effect of breaking
the climb is a loud over-decline, never an accept.

The C spellings `pk1` and `pk2` fold to a triangle because `-O1` sinks the arms' common trailing `cq_phi` into the
merge with an angle φ. Their stream also equals the oracle's. **No C exhibit.**

**Fix:** add pkd as the climb's pin fixture and correct the sentence. The comment's list (`gie`, `gsw`, `ir_fwdC.ll`)
covers only 6.5 shapes.

Repro:
`scratchpad/r2_cepm/cq-opt.mutC1 -passes=cq-lowering -S probes/ir/pkdC.s1.ll -o /dev/null` gives exit 1 and the
string above. The same command with `build/ir-pass/cq-opt` gives exit 0.

### F-r2-2 — P3 — INTRODUCED — the two new accept fixtures misdescribe their hand-inlined twin

- `spec_accept_predicted_classical_measured_callee.ll:50` says the twin is `` `g(q); int t = m + 1;` ``, but `r6bT.c`
  is `int t = y + 1;`.
- `spec_accept_predicted_classical_loop_body_branch.ll:42` says the same, but `lppT.c` is `int t = i + m + 1;`.

The root cause is the `mkfix.py:71` `TWIN_SAME` template, which hard-codes round 1's twin line. It is correct for the
older `h(q, m)` fixtures (`ph1`, `yb`, `rt9`, `br` checked). **The twin-identity claims themselves hold.** I re-ran
both pairs: ACC-SAME on 3 argv sets and 2b STRICT clean, including on the composed binary.

### F-r2-3 — P3 — INTRODUCED — `ArmClassify.cpp` (K1)/(K5) corrections carry wrong grounds (L7 shape; conclusions stand)

- **(K1)** says *"since bd cepm that is FALSE for one op"*. The implication "a classical op reading a chain link is
  tainted" was already false before cepm for `cq_measure`, because the measure sink's result is untainted. The (K5)
  paragraph a few lines below says so: *"(K1) cannot see it"*. So the problem is neither new with cepm nor a single
  op. The code is safe because the explicit operand test and the chain `hasOneUse` check both refuse it.
- **(K5)** says *"(K2) refuses every C spelling (clang never marks such a callee `speculatable`)"*. `speculatable` is
  (K4)'s criterion. A callee that clang infers `memory(none) nounwind willreturn` passes (K2).

  The conclusion holds in C for a different reason. After `-O1`, a C callee that reads its argument live while
  returning a classical value needs a side effect, and that is what (K2) catches. (K4) refuses every C spelling in any
  case.

### F-r2-4 — P3 (Rule 12) — INTRODUCED — the INDIRECT-call half of the removed seed has no pin

`fp1` (an indirect call to a `cq_theta`-holding, measured-return callee) and `fp3` (an indirect call to
classical-only callees) put an indirect call in a Phase-6 site's argument slice.

- Round 1b and the oracle both decline them with `classical call result used as a quantum register`.
- Round 2 **accepts** them twin-identically, 2b STRICT clean, streams identical on the composed binary.

These are correct new accepts, and so is `l3` (lpp with a runtime trip count). None of them is in the implementer's
round1b→round2 A/B.

No fixture covers this shape. The implementer's R7 row re-adds "the syntactic callee seed" and is killed only by
`measured_callee`, which is the callee-name half. Re-adding the indirect half alone would be an over-decline no gate
sees. **Fix:** add `fp3` as a fixture.

### F-r2-5 — P3 — INTRODUCED — the "relaxed 3jru" retirement trigger rests on an unnamed premise

The oracle comment says *"Should the 3jru refusal ever be relaxed, a missed crossing still ends at the sticky rule +
`specialize()`'s check — loud."*

- **Crossing onto an ARGUMENT:** true.
- **Crossing onto the recorded SITE itself:** not covered by that mechanism.
  - `drainWorklist`'s 3jru branch inserts `CB` into `Tainted` directly, so it bypasses the sticky rule.
  - `ResultWasTainted` would then be true, so the check would not fire.

What keeps that path loud today is a different stage. `scanBody` refuses a callee that transitively holds a `cq_*`
primitive (`own`, `xc`, `xm`: `callee contains a quantum primitive (cq_*); only classical functions are lifted` on
all three binaries). So a lifted callee's `ret` has no source to grow from. **Fix:** name that premise in the trigger
(L1: one stage's conclusion as another's unstated premise).

## Items 1–4 of the brief, tested

**1. Removed callee/indirect rules.** No wrong accept.

| probe | shape | subject | 1b | oracle |
|---|---|---|---|---|
| `fp1` | indirect call → callee with `cq_theta`, measured return | ACC, twin-identical | DECL l3oi | DECL l3oi |
| `fp3` | indirect call → classical callees | ACC, twin-identical | DECL l3oi | DECL l3oi |
| `fp2` | indirect call → callee whose `ret` turns quantum in ROUND 2 (6.5 inside) | DECL 3jru (address taken) | same | same |
| `dc2`/`r6a` | direct call, same callee | DECL 3jru | same | same |
| `mem1` | `q` stored to a global by a callee, another callee reads it | DECL spec (memory access) | same | same |
| `mem2` | global written under quantum control, read by callee | DECL control flow | same | DECL *nested* control flow (string mover from round 1, not round 2) |
| `va1` | varargs callee | DECL (varargs) | same | same (twin accepts: pre-existing) |
| `st1` | aggregate return | DECL (fp/aggregate ABI) | same | same (pre-existing) |
| `own`/`xc`/`xm` | site's own callee holds / reaches a `cq_theta` | DECL (cq_* callee) | same | same |

**2. `selectsIncoming`.**

| probe | shape | result |
|---|---|---|
| `s1` | round-2 cascade through a second φ | DECL, same as 1b and oracle |
| `s6` | the %out itself as the site's argument | DECL on all three; twin accepts, pre-existing |
| `l2` | lpp with if/else phase arms | DECL on subject = 1b; oracle's string differs, a round-1 mover |
| `l3` | lpp with a guarded runtime trip count | **new D→A, twin-identical** |
| `l4` | loop exit selected by a round-2 rail | DECL, same as 1b and oracle |
| `pk1`, `pk2`, `pkd` | peel | ACC; C stream = 1b = oracle. C≠T is the known compiler-kept copy-out class (bd `ffir`); the extra rail is a function of the merge rail, equivalent under measurement |

Irreducible CFGs, `invoke` and `callbr` were argued rather than probed. `terminatorCondition` yields no condition for
`invoke`/`callbr`/`indirectbr`, and a tainted operand there is declined by the escape and literal-integrity guards.
Irreducible cycles are declined by the loop layer. Every under-approximation ends at the check in any case.
Duplicate switch successors give equal E-sets per duplicate, which is correct: two cases to one arm do not choose
between themselves.

**3. Fixtures.**

| fixture | subject | 1b | oracle | composed |
|---|---|---|---|---|
| `…_measured_callee` | PASS | red: DECL l3oi, as the header says | red: same | PASS |
| `…_loop_body_branch` | PASS | red: DECL Q+Q compare, as the header says | red: same | PASS |
| `…_round2_return_crossing` | PASS | PASS | PASS | PASS |
| `…_bank` (CHECK and MEAS) | PASS | PASS | red: DECL rail bank | PASS |

- `…_round2_return_crossing` is a string pin, not a red-green, as the TRACK says.
- The negatives are pure. The reject fixture is `RUN: not … 2>&1` with one `CHECK:` of the diagnostic. `MEAS` is a
  whole-file count followed by `MEAS-NOT`, and it catches an injected measure before or after the real one.
- The `CHECK-NOT: cq_template_icmp` in `measured_callee` sits between `br` and `ret`, where no icmp could appear, so
  it is decorative. The positive `icmp sgt i32 %T, 3` is what pins the property.
- Twin traces: I checked both pairs myself (F-r2-2).
- Spot-check of the mutation claims: the round-1b binary is S1 and R7 at once, and it fails both new accepts.

**4. Comment fixes checked TRUE:**
- `SpecPredictGeneration`'s new ground: `propagate()` builds a fresh `TaintSet` with one `propagateWorklist`, and the
  other three call sites (`:2330`, `:2466`, `:2628`) are all `skipRuntimeCalls=true`.
- `Specialization.cpp`'s "reached by a REPLANNED MASK", given the ordering above.
- The `TaintPropagation.h` peel paragraph. It still omits the older `skipRuntimeCalls` exception, which is not new and
  not relevant to a `select`.

**Checked FALSE or mis-grounded:** F-r2-1, F-r2-3, F-r2-5.

## Standing lessons

- **L1.** Round 2 adds no computation between the control rounds. The oracle runs at the end of each drain, on that
  drain's complete taint and the current CFG. A φ that a later CFG rewrite creates is invisible to it, but that is an
  under-approximation and ends at the loud check. The record (`SpecPredictedClassical`) and its re-ask (sticky +
  check) are round 1b's and unchanged. The 3jru bypass of the sticky rule is F-r2-5, closed today by `scanBody`.
- **L2.** When the seed set narrows, the sets over the same closure are the settle `Flip` set and
  `SpecPredictedClassical`. They stay consistent: a flipped site is erased from the record.
- **L3.** `predictReturnTainted`'s "(a) any tainted conditional terminator" asks a different question, about the
  callee body, so it needs no matching narrowing. No other predicate names "selects this φ's incoming".
- **L4.** `selectsIncoming` compares E-sets. It is not a return-first boolean. The climb returns on the first seed,
  which is correct for a monotone existence question.
- **L5.** Round 2 removes one syntactic answer. `selectsIncoming` answers a semantic question structurally, but it is
  conservative on every ambiguous shape and its misses are loud.
- **L7.** F-r2-1, F-r2-3, F-r2-5.
- **Rule 14.** One `terminatorCondition` (moved, not duplicated). No second spelling of "branch selects φ incoming"
  found.
- **Rule 12.**
  - The narrowing is paired with `…_round2_mask_growth{,_ry}`, which S2/S4 kill, and with the string pin.
  - Unpinned: the climb (F-r2-1, pkd pins it), the indirect half (F-r2-4, fp3 pins it), and S3/S5 (disclosed;
    conservative direction). One addition to S3: an empty E-set is provably non-selecting, so counting it as
    selecting can only over-decline relative to the twin, never under-report.

## Composition (rhk5 + z0re, `main` `ba4fdad4`)

All 23 battery programs give the same verdict on the composed binary as on the subject. Every accept (`fp1`, `fp3`,
`r6b`, `lpp`, `lpq`, `l3`, `pk1`, `pk2`, `pkd`) has a **byte-identical** stream to the subject's.

The four new/changed fixtures pass on the composed binary. `lpp`, `l3` and `r6b` exercise the composition directly:
a clone call (`__cq_q_h_01`) inside a rolled loop body next to a kickback. That is rhk5's discharge-window territory,
and nothing moved. The F-r1B-1/F-r1B-3 composition items stay the orchestrator's (landing order rhk5 → z0re → cepm).

## What I tested and did not break

Indirect calls, function pointers selected at run time, round-2 return crossings through direct and indirect calls,
memory channels (store-then-callee-read, and a store under quantum control), varargs, aggregate returns, a
cq_*-holding site callee (direct and transitive), round-2 cascades through a second φ, loop exits on a round-2 rail,
runtime-trip loops, if/else phase arms in a loop, and the peel with both a triangle and a diamond. No wrong accept,
no crash, and no verdict move from round 1b except the correct D→As: `fp1`, `fp3`, `l3`, and the implementer's `r6b`
and `lpp`.

Beads filed: none. All items are in-branch fixes.

Probes: `probes/src/` (C sources + `.libs` sets), `probes/ir/pkd{C,T}.s1.ll`, `probes/{gen,tw,twc}.sh`,
`probes/results/`.
