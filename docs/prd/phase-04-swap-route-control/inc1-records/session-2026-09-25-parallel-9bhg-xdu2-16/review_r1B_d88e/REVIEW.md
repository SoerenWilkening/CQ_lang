# Rule-13 round r1B — bd `test_C_libtooling-d88e` (emitted circuits of what still accepts; the L2 stage enumeration)

Reviewer: independent agent, session 2026-09-25. Concurrent with r1A, which attacks the fence logic
and slot order. This round attacks the CIRCUITS: what still accepts after the change, what the
change moves, and whether any stage other than the lift rewrites IR on the premise "a spec-site
result is a register".

- **Subject:** commits `06148f3d` + `52d35e5d`, branch `worktree-agent-acf961e52a2f9e440`.
  `cq-opt` `e587c19152bf39e5`, copied to a private path before use; the subject's own `build/` was
  not touched. Re-hashed at the end: unchanged.
- **Oracle:** main `def1b088`, `cq-opt` `b1603d237fc3a739`.
- **Private instrumented build:** a detached worktree of `52d35e5d` under the scratchpad.
  - Null control: the unmutated rebuild hashed **bit-identical** to the subject (`e587c191…`).
  - It built two diagnostic mutants (§4, §5).
  - It has been removed (`git worktree list` shows no entry).
- **Runtime:** the subject's `build/runtime/*.a`, linked templates BEFORE runtime.
- **Shell:** every sweep ran under `bash`, not zsh. The zsh no-word-split trap hit this round twice
  (an unsplit `$Q` list and an unsplit `"5 7"` argv) and was caught both times before any number
  was recorded.

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1

The change's own circuits hold up:

- Over my 328-module battery (null control first: oracle vs oracle, **0 of 328** differ) the subject
  vs the oracle has **0 STREAM moves and 0 D→A**.
- There are 11 A→D and 2 DIAG. Every A→D is a module the oracle compiled to a **wrong** circuit, and
  every one now declines with stderr **byte-identical** to its hand-inlined twin.
- Every accept that survives is byte-identical to the oracle's.
- **All 106 accepted subject modules are stage-2b STRICT clean** (`0 violation(s), 0 unproven`).

I found **no second d88e-class rewrite** in the propagate→`specialize()` window (§6), and no wrong
unitary among the accepts I could construct (§1–§3). The items are pre-existing defects that this
round measured or sharpened, plus coverage and record gaps in the change itself.

| id | sev | what | attribution |
|---|---|---|---|
| F-DB-1 | P2 (keep) | bd `hgwx` **confirmed by mutation**. Two further facts: the `live derived record` warning cannot tell the dephased stream from a coherent one, and `priorUseIsSettled`'s (d)/(e) comments are false for a classical-verdict clone (L7). | PRE-EXISTING (oracle byte-identical); d88e does not change its population |
| F-DB-2 | P2 (owner Q, keep) | bd `z0re` **confirmed correct** on its 4 probes plus **6 new side-door members** (in-place ops after the prep, a second controlled arm, a classical lift after, angle select plus lift, an f64 runtime seed). No wrong unitary was found; the F2 hazard is unreachable at `-O1`. | PRE-EXISTING; d88e moves none |
| F-DB-3 | P3 | The d88e population is wider than "measurement deleted". `zlC` keeps **both** measurements on the oracle but orphans the classical arm's Ry on an unread rail; a measure-count metric and bd l3oi both miss it. d88e declines it. **No shipped fixture has this shape** (a lift whose φ feeds a round-1-emitted quantum-controlled region). | INTRODUCED coverage gap (the fix is right; the pin is missing) |
| F-DB-4 | P3 | bd `cepm`'s `a03C` fragility is **confirmed by mutation**. Also: the natural fix of a SEPARATE over-decline (`a03Q`, quantum verdict) IS the trigger, and stage 2b is blind to the resulting miscompile. | PRE-EXISTING → **NEW bd `test_C_libtooling-d152`** |
| F-DB-5 | P3 | Tainted i1/i8/i16/i64 spec arguments decline with a **"floating-point"** string. The d88e class is therefore C-reachable only at i32 and the fp widths. | PRE-EXISTING → **NEW bd `test_C_libtooling-mg6f`** |
| F-DB-6 | P3 | The new e2e goldens have two problems. `slice_spec_lift_quantum_base` pins a live-derived-record (lyyf-B, dephased) stream, and its header does not say so. `e2e-spec-lift-scrubbed-elsewhere-twin-identical` compares traces only, while the C side's stderr carries the spurious hgwx warning its twin does not. | INTRODUCED (headers and coverage) |
| F-DB-7 | P3 (unmeasured) | The moved 2qyz re-sweep now also iterates **clone bodies** (`inLowerOpsScope` keys on module `taint.Tainted.count(&I)`), so on `main`, where bd `j8sk` is unfixed, the allocator-aliasing exposure grows by one consumer. The direction is decline-only. | INTRODUCED exposure |

---

## 1. bd z0re accepts: correct unitaries, pre-existing, and a larger population

Every probe below is 2-TU with lib `h(a,k) = k + 1` (classical verdict), inputs derived from argv
(bd 46oo), and run under `"5 7"`. The unitaries are argued analytically; there is no simulator.

| probe | C shape (t = h(q,m) = m+1) | subject stream (key lines) | reading | oracle |
|---|---|---|---|---|
| `l12C` | `r=t; if(q2>3) r=θ(t,.2)` | flag `icmp_sgt(h1,3)`; `alloc(6)→h3`; `ry_controlled(flag,h3,.2)`; strip; free | Σ_{q2}\|q2⟩⊗(q2>3 ? Ry(.2)\|6⟩ : \|6⟩). Correct. | s2 byte-identical |
| `l17C` | bare `_Bool b` condition | `alloc(6)`; `ry_controlled(h1(b), h2, .2)`; b is never bracketed or freed | Correct. | identical |
| `a02C` | condition `q>3` on the spec argument's own register | flag reads h0 (q); prep on a fresh h2 | Correct: the prep is disjoint from q's wire. | identical |
| `a01C` | if/else Ry-stem angle select | `alloc(6)`, `Ry(.2)`, `ry_controlled(flag, .7−.2)` | Additivity of Ry, the shipped by-difference form. Correct. | identical |
| **`zcC`** (new) | prep, then `u=r+1` | prep, then `cqrt_addc_i32(h3,1)` in place | Correct. | identical |
| **`zfC`** (new) | prep, then a SECOND quantum arm `if(q3>2) s=θ(r,.4)` | prep on h4, then `ry_controlled(h5, h4, .4)`, flags stripped and freed | Correct: a controlled-in-place Ry on the prepped rail, disjoint from q3's wire. | identical |
| **`zjC`** (new) | prep, then unconditional `θ(r,.9)` | prep, then `ry(h3,.9)` | Correct. | identical |
| **`zkC`** (new) | prep, then a classical-condition lift `if(m>2) r=θ(r,.9)` | the lift's base is the hoisted gate, not `t`; `ry(h3,.9)` only when m>2 (checked with m=1: absent) | Correct. The d88e re-ask is not falsified because the base is a `cq_theta` result. | identical |
| **`zmC`** (new) | angle select, then a classical lift | `Ry(.5)`, `ry_controlled(-.3)`, `ry(.1)` | Correct. | identical |
| **`zxdC`** (new) | **f64** runtime-seed prep | `cqrt_alloc_f64(2.5)`, `cqrt_ry_f64_controlled` | Correct. The `-0.0` concern that motivates F1's `Constant` spelling does not arise under SSA identity. | identical |

**Is there a hazard hidden behind the scope fence?** The only hazard F2 exists for is `-O1` substituting
a register by the seed on an equality edge.

- `-O1` has no GVN, CVP or JumpThreading. The one probe that tries (`zdC`, `if (q2 == t) r = θ(q2,.2)`)
  shows the arm's `θ` still on `%11` (q2) in stage-1 IR.
- The only other way in is a condition that reads `t`, and conservative taint then puts `t` on the
  condition wire. `zdC` declines `condition predates a non-diagonal gate`, and so does its twin.
- The side-door readers of `t` after the prep decline at the stale fences:
  - `zaC` (`cq_measure(t)` after) and `zbC` (`θ(t,.4)` after) decline `stale rail record read past a controlled Ry`;
  - `ziC` (`+ t` after an angle select) declines `operand predates a non-diagonal gate`.

  All of these are safe-direction over-declines of bd `cepm`'s class.

**Verdict on z0re: the unitaries are correct, and the owner scope is bypassed.** The four named members
and all six new ones are byte-identical on `def1b088`, so d88e neither creates nor removes any of
them. Add the six new members to z0re: its population includes compositions (a second controlled
arm, a classical lift, in-place arithmetic) and the f64 width, not only the bare prep.

## 2. bd hgwx / `j02C`: severity, and the cause confirmed

`j02C` (`u = t + q; r = u; if (m>3) r = θ(u,.2); cq_measure(r)`):

- The subject lowers the add OUT of place, `add_hl(h0,6)→h1`, then `ry(h1,.2)`, and emits the
  warning.
- The twin lowers it IN place, `cqrt_addc_i32(h0,6)`, then `ry(h0,.2)`, with no warning.
- Both lowered modules are byte-identical on the oracle.

**The cause is CONFIRMED BY MUTATION.** Mutant B makes `priorUseIsSettled` (ArithLowering.cpp:562)
return true for any `__cq_q_*` callee. Under it, `j02C`'s trace is **byte-identical to `j02T`'s**,
and it is the **only mover of 330** probes. So M-C's G7 refuses the classical-verdict clone call
`__cq_q_h_01(h0, m)` as an unsettled prior use of q. (This mutant is diagnostic only. It is unsound
for a QUANTUM-verdict clone whose out rail's `_unc` re-reads P later. A real fix must consult the
verdict, not the name.)

**The difference is user-visible, analytically.**

- q = Ry(.5)^{⊗32}\|5⟩, and bit 0 of q is Ry(.5)\|1⟩. Adding 6 (even) leaves bit 0 alone and puts
  no carry into it.
- Coherent (twin): bit 0 → Ry(.7)\|1⟩, so P(bit0 = 0) = sin²(.35) ≈ **0.118**.
- Dephased (subject; h1's bit 0 is a CNOT copy of h0's):
  P = sin²(.25)cos²(.1) + cos²(.25)sin²(.1) ≈ **0.070**.

**Severity: keep P2, not P1.** It is warned, and it sits in the class owner ruling lyyf (B) accepted.
Two facts should go to the owner with it:

- **The warning cannot discriminate.** It fires on streams that are byte-identical to their
  warning-free twins: `rb08C`, `lbC`, the e2e `scrubbed_elsewhere` slice, and `j02C` itself **under
  mutant B, where the stream is the coherent one**. The one warning that marks a real divergence is
  indistinguishable from the noise. The source is the same misclassification that makes stage 2b's
  census count a classical clone call as a dirty template rail.
- **Two falsified comments (L7), in ArithLowering.cpp `priorUseIsSettled`.**
  - Arm (d) calls a `__cq_q_*` call "a RAIL-MINTING PRODUCER". A classical-verdict clone mints no rail.
  - Arm (e) says "refusing costs nothing but a kept ancestor rail". Under a later non-diagonal gate it
    costs coherence: 0.118 → 0.070 above.
- **Owner question.** Ruling (B) is grounded in "the user left the register entangled". Here only the
  compiler's own clone call keeps it live. Does (B) cover that?

**Population.** `j02C`'s lift is a TRUE lift (base `u = t + q` stays tainted), so d88e's re-ask never
fires on it and bd hgwx's population is unchanged by d88e.

**The spec-QUANTUM analogue.** `sqi1Q` vs the inline twin `sqi1U` shows the same dephased-vs-coherent
split. There the clone's Bennett copy-out leaves q live by construction. The hand-inlined twin is
therefore not a correctness oracle for spec programs in the lyyf class. It is a divergence detector.

## 3. Spec-QUANTUM lifts that still accept — the family

Generator: `probes/mk2.py`. Shapes 1–7 run at i1, i8, i16, i32, i64 and f64. Each shape has four
variants: C (classical verdict), Q (quantum verdict), T (C's twin, inlined `m+1`) and U (Q's twin,
inlined `q+m`). The seven shapes:

- **1** — base lift;
- **2** — `t` read after the merge;
- **3** — `t` measured on the untaken path;
- **4** — chained lifts;
- **5** — N-way switch lift;
- **6** — lift inside a loop body;
- **7** — `q` measured afterwards.

Results:

- **i1/i8/i16/i64:** every C and Q variant declines at Phase 6, `kMsgFpAbi`, with a misleading
  string. See F-DB-5 / bd `mg6f`. **The d88e class is not C-reachable at these widths today.**
- **i32 and f64, Q variants:** 1, 3, 4, 5 and 7 accept on both binaries, s2 byte-identical.
  - The streams are `add_hl` + copy-out + `_unc` + free (the clone), then Ry chains in place on the
    clone's out rail under the classical conditions.
  - Paths were checked by re-running with other argv: `sqi4Q` m2 ∈ {2,4,6} gives 0, 1 and 2 Rys;
    `sqd5Q` m2 ∈ {1,7,9} gives Ry(.1), Ry(.7) and none; `sqd3Q` m2=2 measures `t` twice, correctly.
  - Each carries the lyyf-(B) warning, which is legitimate here (q is live).
- **Shape 2** declines `operand predates a non-diagonal gate` in C, Q and U alike. **Shape 6** (lift
  in a loop) declines `classical-condition phi` in all four variants. Earlier rows of the implementer's
  battery (`k01`–`k03`, `l11`, `l14`, `l16`) and my `rb13` agree.
- **C variants at i32/f64:** shapes 1, 3, 4, 5 and 7 are ACCEPT on the oracle with the measurement
  deleted, and DECLINE on the subject with twin-identical stderr (§4 of the A/B).
- **Stage 2b over all 106 accepted subject modules: STRICT, 0 violations, 0 unproven.**
  CENSUS: `results/census_2b_accepted_subject.txt`.
- The new accept fixtures (`…_spec_quantum_base_switch_nway`, `…_fp_rebuilt`, `…_degenerate`) were
  read at the emitted IR. Each is a chain of in-place Rys on the clone's out handle, or φ(t,t)→t.
  Correct.

## 4. The A/B (subject vs oracle over my whole battery)

`probes/ab.sh`. Result: `NULL CONTROL: denominator=328 oracle-vs-oracle diffs=0`, then
`A/B: denominator=328 A->D=11 D->A=0 DIAG=2 STREAM=0`. The full list is in
`results/ab_oracle_vs_subject.txt`.

- **A→D (11):**
  - `sqi{1,3,4,5,7}C` and `sqd{1,3,4,5,7}C`: the oracle deletes one or all measurements;
  - `zlC` (F-DB-3).

  Each subject stderr is byte-identical to its twin's `kMsgClassicalPhi`. New shapes beyond the
  implementer's battery:
  - shape 3 (`t` measured on the untaken path);
  - shape 7 (`q` also measured);
  - the f64 chain and switch;
  - `zlC`.
- **DIAG (2):** `laC` and `ldC`, a lifted φ feeding a SECOND spec site. On the oracle, bd l3oi's
  masked-clone-arg reader speaks. On the subject, the re-ask speaks with the twin's string.
- **Determinism:** 22 key probes × 6 runs gave 1 distinct output each (bd 8e5r check).

**F-DB-3: `zlC`, a d88e member that neither a measure count nor l3oi can see.**

```c
r = t; if (m > 2) r = cq_theta(t, .9); s = r; if (q2 > 3) s = cq_theta(r, .2);
return cq_measure(s) + cq_measure(q2);
```

The oracle stream is:

```
alloc(6)→h2; ry(h2,.9); … alloc(6)→h4; ry_controlled(flag,h4,.2) …; measure(h4); measure(h1)
```

- The user's Ry(.9) lands on an orphan rail h2 that nothing reads.
- The measured register h4 is a fresh prep that never saw it.
- **2 measurements in the source, 2 in the lowered module.** The record's `run.sh` metric
  (`measure=`) reads that as clean.
- l3oi misses it because the φ's consumer was a round-1-emitted in-place controlled arm whose hoisted
  `cq_theta` reads the base. It is not yet a `cqrt_*` call, so the fence has nothing to see.
- The subject declines it with the twin's string.
- **None of the 9 new decline fixtures has a lift whose φ feeds a quantum-controlled region.** Add
  `zlC` as a red-green fixture: ACCEPT (wrong) on the oracle, DECLINE on the subject. It pins the
  re-ask against the one consumer class l3oi cannot cover.

## 5. bd cepm `a03C`: fragility confirmed, and the trigger is armed (F-DB-4, NEW bd `d152`)

`isLoweredRailHandle` (RailBankPromote.cpp:1153) admits only `cqrt_alloc_*`/`cq_template_*` i32
calls, and φ/select/zext of them. No existing path admits a clone result. Probes: `ba` (select of
clone/theta) and `bc` (a clone stored into a theta bank) decline earlier. `bb` (`b[i] = θ(h(q,i),.1)`)
accepts twin-identically, because a theta over a scrubbed value is a SOURCE rail.

**Mutant A:** `isLoweredRailHandle` additionally admits `__cq_q_*`. Over 330 probes it moves exactly
2 modules:

- **`a03Q`** (quantum verdict; declines today, which is itself an OVER-DECLINE) becomes a
  **correct** accept that measures the clone out rails h2, h4, h6 and h8.
- **`a03C`** (classical verdict) becomes **exit 0**, stage-2b **STRICT clean**, with trace:

  ```
  alloc(5)→h0; ry(h0,.5); measure(h1); measure(h2); measure(h3); measure(h4)
  ```

  It measures handles that were **never allocated**: the classical values 1..4 read as handles. The
  twin returns 10 with no measurement.

So the natural fix of the `a03Q` over-decline IS the trigger bd `cepm` warned about.

**Stage 2b is blind to it.** `free_pairing_check.py` (~810) name-classifies every `__cq_q_*` result
as a template rail mint. That is the same misclassification behind bd hgwx's census noise, and here it
is load-bearing. Filed as **bd `test_C_libtooling-d152`**: the fix must key on the specializer's
verdict record, and the red-green is `a03Q` accept plus `a03C` decline.

## 6. The L2 enumeration, re-derived independently

For every stage in `run()` from `propagate` to `specialize()`, I asked two questions. Does it rewrite
IR or commit a record on the premise that a value is quantum? And if a spec-site result is that value
and is later scrubbed, what happens? The method was to enumerate every `replaceAllUsesWith`,
`setIncomingValue` and erase in the stage files, read each site, and probe each candidate from C.

| stage / rewrite | premise | if the value is a scrubbed spec result | probe |
|---|---|---|---|
| **one-register lift** (`declineClassicalMuxes`) | base is a register | **d88e** — fixed by the re-ask | 11 A→D above |
| M-β merge-φ RAUW to the hoisted gate (in-place Ry arm, state prep, Ry-stem) | arm register is the φ's register | The hoisted gate is **controlled**, so post-scrub it is a correct runtime-seed prep (z0re). Readers of `t` after it decline at the stale fences. | `l12C`, `zaC`/`zbC`/`zcC`/`zfC`/`zjC`/`zkC`/`zmC`, `zxdC` |
| identity-region RAUW φ(Q,Q)→Q (SwapRouteEmit:1366) | none (value identity) | exact | — |
| value arm (hoist chain + `select` + SelectMergeEmit), 4.4 data select, 4.5 switch | condition/data quantum | the emitted copy or compare reads `t` → l3oi | `rb02C`, `rb03C` (l3oi string), `rb04C` (routed base, earlier) |
| 6.5 classical-call arm | all args classical | a spec call has a tainted arg → never 6.5 → value arm → declines | `rb01C` (`value-arm swap-route`) |
| kickback (phase) with a condition or angle on `t` | condition quantum | flag compare reads `t` → l3oi; angle-select / region declines earlier | `rb09C`, `lcC`, `leC` |
| loop Case-A/B collapse, round-2 collapse (LoopLowering 2986, 3396, 3467), 7.4 break (2368/2373) | rail rooted at a **classical-operand `cq_theta` mint** | a root chained on a provisional `t` peels to `t` → no collapse → classical-mux decline (safe) | `rb13C`, `rb14C`, `a04C`, `rb12C` |
| zujr seed promotion (7001/7012) | seed **untainted** at round 1 | a provisional seed is not promoted → decline | — (read) |
| dtzb / M-C `InPlaceRailOps` commit | one classical immediate | two tainted operands at round 1 → not committed; re-verified at `lowerOps` on FINAL taint anyway | `rb17C` (twin-identical) |
| QRAM read / shadow memory / IO sink RAUW (Qram 3173/3477, IOSink 840) | index or data quantum | the emitted `cqrt_qram_*`/tape call reads `t` → l3oi; a store declines at the escape guard | `rb05C`, `rb06C`, `rb07C` |
| rail-bank promote (load→def forwarding) / mark (metadata taint) | cells hold rails | forwarding is value-preserving; the MARK path is guarded only by `declineNonHandleBankStores` (§5) | `a03C`, `bb`/`ba`/`bc`, mutant A |
| PredMux φ→select, residue simplify; MergePhiPeel; Ctlz closed form; unroll; freeze fold (TaintPropagation:1291); bitcast/volatile/fp80 folds; ByRefInline | none (value identity) | exact whatever the taint | `rb12C` (declines earlier), `rb18C` (twin-identical) |
| `cq_theta` angle from `t` | angle checked at FINAL taint | accepts, twin-identical (spurious hgwx warning) | `rb08C`, `lbC` |

**Conclusion:** I agree with the implementer that there is **no other silent miscompile** in the
window. The one refinement is §4's `zlC`: the lift's φ can be consumed by a round-1 EMITTED region
rather than by an unlowered `cq_measure`. l3oi cannot see that, and the re-ask does. It is covered
but unpinned (F-DB-3).

On the 2qyz move (the one accept-direction edge), I could not construct a module the move flips. For
a true lift, every op the lift makes stale reads the quantum base and stays tainted. Staleness on a
scrubbed operand's wire already exists before the lift, so the EARLY sweep declines it first. I agree
with §6.5 of the implementer's record, by argument.

**F-DB-7 (unmeasured).** Before the move, the re-sweep ran before any clone existed. Now it iterates
`__cq_q_*` bodies, and `inLowerOpsScope` asks `taint.Tainted.count(&I)`. On `main`, bd `j8sk`'s
dangling keys (an erased rebuilt fp site) remain, so a clone-body op allocated at a freed key would
be swept. The direction is decline-only and the likelihood is low: clone bodies are mostly calls,
and a size-class match is needed. It belongs in the record's §10 item 4 as a new consumer. It is not
a defect demonstrated here.

## 7. F-DB-6: the new e2e goldens

- **`slice_spec_lift_quantum_base`.** `opt` prints `non-diagonal gate over a live derived record`,
  because h0 stays entangled with the clone's out rail h2 when the arm's Ry fires. The golden
  therefore pins the lyyf-(B) **dephased** circuit. The header describes the stream ("the arm's Ry
  fires IN PLACE on the clone's returned handle") without saying so, and should.
- **`slice_spec_lift_scrubbed_elsewhere`.** The C side prints the same warning, and its `_twin` does
  not. That is bd hgwx's spurious warning. `e2e-spec-lift-scrubbed-elsewhere-twin-identical`
  compares traces only, so the gate is blind to the one divergence the pair actually has. Say so in
  the header, or compare stderr too.

## What I did NOT attack

- The fence logic and slot order of the re-ask. That is r1A's remit; I read the code only to the
  extent §6 needed.
- The 9bhg-composed tree. I did not rebuild it, and every number here is main + d88e only. The
  composition's `l09C`/`l10C` claim is the implementer's measurement, not mine.
- The `runOnFunction` entry point. It was not exercised separately.
- Hosts that continue past `DS_Error`, `+Asserts`, `invoke`, and `weak`/`available_externally`
  callees.
- `cq_invert` over a lifted or spec value. `EmitInverse` admits `__cq_q_*` by name, which is worth a
  look by someone.
- Multi-latch or irreducible loops around a lift.
- Allocator perturbation: no Guard Malloc and no heap shaping. F-DB-7 is argued, not measured.
- A statevector check of any stream (Rule 2). The unitaries are argued analytically.
- Widths i1/i8/i16/i64 beyond observing the Phase-6 decline. They are unreachable (F-DB-5).

## Reproduce

All scripts are in `probes/`, and their absolute scratchpad paths are named at the top of each.

- `gen.sh` builds stage 1 for each probe (2-TU via `llvm-link` when a `.lib.c` exists).
- `verd.sh` gives the oracle and subject verdicts plus s2 identity.
- `pipe.sh TAG "argv" name…` runs opt → 2b STRICT → link → run.
- `ab.sh` runs the null control plus the A/B.
- Generators: `mk.py` (rb*), `mk2.py` (width × shape), `mk3.py` (z*), `mk4.py` (b[a-e]), `mk5.py`
  (l[a-e]).
- `results/` holds the A/B, the width verdicts, the 2b census, the mutant-A/B mover lists and the
  traces cited above.
- No built executables are kept.
