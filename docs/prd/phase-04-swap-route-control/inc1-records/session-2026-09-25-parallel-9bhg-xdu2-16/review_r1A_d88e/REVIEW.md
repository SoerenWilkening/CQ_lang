# Rule-13 review r1A — bd `test_C_libtooling-d88e` (commits `06148f3d` + `52d35e5d`)

Reviewer r1A. Scope, as briefed: the FENCE LOGIC of `declineFalsifiedMergePhiLifts` and
the SLOT ORDER after `specialize()` (including the moved bd 2qyz re-sweep). A second
reviewer attacks the emitted circuits of what still accepts (z0re, hgwx, spec-quantum
lifts) and the stage enumeration; I say nothing about those except where a probe of mine
landed in them by accident, and then I say so.

Binaries (sha-256 prefix, checked before use):

| name | what | `cq-opt` |
|---|---|---|
| ORACLE | `main` `def1b088` (frozen) | `b1603d237fc3a739` |
| SUBJECT | `52d35e5d` (worktree build) | `e587c19152bf39e5` |
| my build of `52d35e5d` | private worktree `scratchpad/rA_d88e_wt` | `e587c19152bf39e5` — **bit-identical** (build null control) |
| INSTRUMENT | my build + `probes/ra_instrument.patch` (env-switched mutants) | `6c215158b89c8d4d` |
| 9BHG-ONLY | `30529716` (frozen by the 9bhg track) | `8b837d1f79574156` |
| COMPOSED | subject + 9bhg `983f9361..30529716` ir-pass diff (frozen by the implementer) | `242f8b61530623e9` |
| my build of COMPOSED | private worktree `scratchpad/rA_comp_wt`, same diff applied | `242f8b61530623e9` — **bit-identical**, so the implementer's composed binary is what it says it is |

No file in the subject worktree was edited or rebuilt. Both private worktrees are removed.

## Verdict: **CLEAR-WITH-ITEMS**

**0 P1, 0 P2, 4 P3.** I found no over-accept, no crash and no falsified SAFETY argument in
the fence logic or the slot order. What I found is three places where the change's own
prose states a reason or a scope that the code does not have (one of them hides an
unpinned load-bearing property), and one new member of an already-filed owner question.

The reason the fence holds is short and I re-derived it independently before measuring:
every recorded incoming is either the recorded base or a `cq_theta` call (conjunct (3)
admits nothing else), `cq_theta` results are `TaintedSources` and are never scrubbed, and
the only module-taint writes in the window are the scrub's erase and the ReturnTainted
re-insert (subject: `Specialization.cpp:635`, `:1218`; composed: those plus the j8sk
`erase(OldSite)`, all read by me). So the re-ask reduces to *"is the base still tainted,
or is every incoming the base?"* — which is exactly the premise `specialize()` can
falsify. M4 (conjunct 2 removed) is therefore equivalent and M7 (nulled handle) is
unreachable, as the record argues; I agree with both arguments.

## Findings

| id | sev | one line |
|---|---|---|
| F-DA-1 | P3 | The stated reason for `WeakTrackingVH` names a case that needs no tracking, and the case that DOES need it — a lift RECORDED with a merge φ as its base that a later-visited lift then RAUWs (reversed block layout) — is reachable, correct on the subject, and pinned by nothing: a WeakVH mutant over-declines it while the whole corpus stays green. |
| F-DA-2 | P3 | `resolveWireBase`'s header still says `SOLE CALLER: liftOneRegisterMergePhi (grep resolveWireBase — one call site …)`. The re-ask is a second caller (L7/L8: a stale source comment in a function whose retirement-trigger text is exactly where the next caller will look). |
| F-DA-3 | P3 | "the diagnostic is … the hand-inlined twin's, character-for-character" (`TaintPropagation.h`) and §6.3's "every decline is the twin's decline" hold for VERDICTS, not STRINGS, once a module has a second classical-mux offender: `r01` declines in `f2` on the subject and in `f1` on its twin. Safe direction; the claim needs its scope. |
| F-DA-4 | P3 (owner question, appended) | bd `z0re` has a composed member: `r03C` (runtime-seed prep on a spec-classical `t` under a tainted condition, then a classical one-register lift on the prepped rail) ACCEPTS on oracle, subject and composed; its twin declines at F1. Stream read: correct. It is z0re's class, not d88e's, but it shows the lift composes with z0re's accept. |

### F-DA-1 (P3) — the WeakTrackingVH reason, and the unpinned case that needs it

`TaintPropagation.h:306-307` (the `LiftedMergePhi` comment):

> `WeakTrackingVH`, not `WeakVH`: the record must FOLLOW a later RAUW — a second lift
> whose incoming was an earlier lifted phi, and `retargetSite`'s rebuild of an
> fp-return spec site

The first case needs no tracking. When lift L2's φ has an incoming that was lift L1's φ,
L1 has already RAUW'd that φ onto its base before L2 is visited, so L2 records the base
directly and nothing in either record is RAUW'd afterwards. The implementer's own
mutation data agrees: M6 (`WeakVH`) turned only `_fp_rebuilt` red, not `_two_lifts`.

The case that does need tracking is the reverse ORDER. `declineClassicalMuxes` walks
blocks in LAYOUT order. If the outer diamond's merge is laid out first, the outer lift is
recorded with the inner merge φ as its base (`resolveWireBase` stops at a φ), and the
inner lift then RAUWs and erases that φ. Only a tracking handle carries the record onto
the real base.

- Probe: `probes/ir/rk04Q_rev.s1.ll` is `k04Q` (two chained lifts over a spec-QUANTUM `t`,
  lib `h = a + k`) after `opt -passes=instnamer`, with the four diamond blocks laid out
  `bb14, bb12, bb9, bb7`. `opt -passes=verify` clean.
- SUBJECT: exit 0; traces byte-identical to normal-layout `k04Q` under `5 7`, `9 1` and
  `2 2`. Correct.
- INSTRUMENT, `RA_WVH=1` (the re-ask reads `WeakVH` copies of the same record): **exit 1,
  `tainted value muxed by a classical-condition phi`** — an over-decline of a correct
  program. Normal-layout `k04Q` still accepts under `RA_WVH=1`.
- Corpus under `RA_WVH=1`: 1 mover of 2302, the fp-rebuilt fixture M6 already killed — the
  lit corpus cannot see this case (§3).

So WeakTrackingVH is right, for a reason the comment does not give, in a case no fixture
holds. Fix: correct the comment and ship `rk04Q_rev` (accept) — and `rk04C_rev`, its
spec-classical sibling, which declines with the twin's string on the subject — as the pin
M6 lacked. I did not find a C spelling that `-O1` lays out in reverse; the reachable
producers would be the pass's own block-creating stages, which I did not enumerate.

### F-DA-2 (P3) — `resolveWireBase` "SOLE CALLER"

`TaintPropagation.cpp:1429` on the subject still reads `SOLE CALLER: liftOneRegisterMergePhi
(grep resolveWireBase — one call site, and WireChain::Gates has exactly one reader …)`.
`declineFalsifiedMergePhiLifts` now calls it too. The second half (`Gates` has one reader)
is still true, because the re-ask reads only `.Base`. I asked the L3-mirror question the
header invites: its three reasons for the `ControlledRotations` STOP are about the lift's
record semantics, and they hold for the re-ask because `ControlledRotations` is not
written in the window (verified: `specialize()` does not touch it). So the answer is safe;
the comment should say "two callers, the lift and its re-ask, which must resolve
identically — that is why they share `collectLiftGateCalls`".

### F-DA-3 (P3) — twin parity is a verdict property, not a string property

`probes/src/r01C.c`: `f1` holds a d88e false lift (spec-classical `t`), `f2` a genuine
classical mux. Both are `noinline`, laid out `f1` then `f2`.

- SUBJECT: declines `in function f2 …: tainted value muxed by a classical-condition phi`.
  The lift in `f1` is PROVISIONAL, so `declineClassicalMuxes` walks on and fires on `f2`
  before `specialize()` ever runs.
- TWIN `r01T`: declines `in function f1 …` (the φ is a plain mixed mux there).
- Same verdict, different string, on subject and composed. Safe.

The same shape appears at earlier owners that read conservative taint (`r10`: C declines at
the classical-SELECT guard, twin at the φ; `r02`: C at the rail-bank reader, twin at the φ),
and would appear in `!dbg` for `rk04C_rev` if built with `-g` (C names the outer φ, which it
recorded first; the twin names the inner one). None of these is a verdict difference. The
prose (`TaintPropagation.h:311` "character-for-character", `CQLoweringPass.cpp` "the hand-inlined
twin's", TRACK §6.3) should say "the twin's verdict, and the twin's string when this φ is the
module's first classical-mux offender".

### F-DA-4 (P3, appended to bd z0re) — a lift on a z0re runtime-seed prep

`probes/src/r03C.c`: `t = h(q, m)` (k+1), `q2 = cq_theta(n, .3)`, `r = t; if (q2 > 3) r =
cq_theta(t, .2);` (z0re's `l12C`), then `s = r; if (m > 5) s = cq_theta(r, .4);` (a
CLASSICAL one-register lift on the prepped rail), `cq_measure(s) + cq_measure(q2)`.

ACCEPTS on oracle, subject and composed; `r03T` declines at F1 (`state prep seed does not
match the merge incoming under quantum control`). Lowered `main` (subject): `cqrt_alloc(t)
→ h2`, `cqrt_ry_i32_controlled(h_cmp, h2, .2)`, flag uncomputed and freed, then under the
classical branch `cqrt_ry_i32(h2, .4)`, measure `h2` and `h1`. The lift's base is the
controlled rotation (a `cq_theta`, never scrubbed), so the re-ask correctly says nothing.
Correct as far as I read it (no statevector, Rule 2). It is z0re's owner question with one
more customer; I record it there and file nothing new.

## 1. Attack list, item by item

**1. Is the re-ask TOTAL?**
- Lift sites: `liftOneRegisterMergePhi` has one caller, `declineClassicalMuxes`, which has
  two callers, `run()` and `runOnFunction()`. Nothing in `adjudicateTaintDelta`,
  `repropagateControlMerges`, the round-2 fixpoint, `specialize()`, `buildClone` or
  `lowerCloneControl` lifts. A clone cannot hold a lift anyway: a Phase-6 callee is
  pure-classical (no `cq_*`), and module taint never flows into formals.
- `runOnFunction` has no caller anywhere in `ir-pass/`, `tests/` or `tools/`; it carries
  the same slots by text (read).
- Every accept records (the push is on the accept path, before the RAUW). Paths from
  `specialize()` to lowering: one in each entry point, and the re-ask is the first
  statement after `specialize()` in both (read, subject and composed trees).
- Dangling records: base and incomings are `WeakTrackingVH`; the only erase of a caller
  value in the window is `retargetSite`'s, which RAUWs first. `L.F` is a raw `Function*`,
  and no function is erased in the window (grep: no `Function::eraseFromParent` in
  `Specialization.cpp`). The j8sk/8e5r dangling-KEY class does not reach the re-ask: it
  asks `Tainted.count` only of values that were live before `specialize()` (the record's
  own values and chain-gate arg-0s), so a freed-and-reused address cannot answer for them.
  It can still reach a LIFT (a pass-created classical value allocated on a stale key would
  look tainted at the lift AND at the re-ask); that is bd 8e5r's class, not made worse here.

**2. Is it asking the right question?** Yes, and nothing else can move (see the Verdict
paragraph). Specifically: the rotated operand of every chain gate is a chain member or the
base, so "base keeps taint, rotated operand turns classical" cannot happen; the φ's other
incomings are thetas; no terminator can become tainted because module taint does not grow
in the window. Growth sources named in the brief — round-2 reseed, IO-sink `MuxOut`,
3jru return closure, `MergePhiPeel` — all run BEFORE `declineClassicalMuxes`; the composed
tree's recomputed-mask path uses `const TaintSet &` (`taintArgMask`, `classifyCandidate`).
Under-scrub (a base that is classical in truth but keeps its taint bit) is the one thing an
observation cannot see; every route I tried ends at an earlier or later owner:
`r02` (rail-bank load base) → `unsupported reader of a rail-bank cell`; `r05` (base is a
spec site built pre-scrub with a masked classical argument) → l3oi on the subject, the
re-ask on the composed tree (ordered scrub); loop-carried scrub cycles cannot be a lift
base (the header φ is itself a classical mux, and a lifted φ is never a header φ by (7b)).

**3. The moved 2qyz re-sweep.** Argued and measured ACCEPT-direction only:
- Its verdict can only differ where post-scrub taint differs, and a lift-EXPOSED op reads
  the base, which is still tainted whenever the re-ask passes. Fewer seeds and shorter
  backward closures give a subset of the old gate sets, never a superset.
- Its domain grew: it now also walks clone bodies and rebuilt call sites. That is inert:
  `findNonDiagonalWireGate` looks for `cq_theta_*` users, and no clone contains one.
- What it gave up: with the re-ask removed, `g01C` ACCEPTS at the new slot
  (`RA_NOREASK=1`) where the old slot declined it — the re-sweep no longer backs up the
  re-ask for a false lift's manufactured staleness. That is the intended single-owner
  design, but it makes the re-ask the only line for that shape.
- Corpus: moving the re-sweep back (`RA_OLDSLOT=1`) moves 1 of 2302 (`_pure_consumer`,
  string only) and 2 of 501 probes (`g01C`, `r13C`, string only) — §3.

**4. Twin parity.** 45-pair battery re-measured (§2). Beyond it I built 18 more pairs
(`r01`–`r23`). No re-ask decline has an accepting twin. Verdict differences that exist are
all pre-existing and all belong to filed classes: `r07` (subject declines at l3oi, twin
accepts; the composed tree fixes it, ACC-SAME — 9bhg/cepm), `r03` (z0re, F-DA-4). String
differences: F-DA-3.

**5. Composition with 9bhg.** Composed binary reproduced bit-identically. `l09C`/`l10C`:
9BHG-ONLY exit 0 with 0 `cqrt_measure`; COMPOSED decline in `f` with the twin's string
(re-measured). Composed order after `specialize()` read in my composed tree: re-ask, 2qyz
re-sweep, l3oi, late 3jru ask. The 9bhg reviewers' probe families were run on all four
binaries (§2).

**6. The implementer's measurements.** Re-measured in §2–§3.

## 2. Measurements

All runs are `cq-opt -passes=cq-lowering -S` on the frozen copies, under bash, with the
denominator printed. The box was under heavy load from other agents (load average 84–393
during this review); no figure below is a timing.

**Corpus A/B, ORACLE vs SUBJECT, over `ir-pass/test/*.ll` (2302 modules).**
- NULL CONTROL FIRST, and on the SUBJECT (not the reference): SUBJECT vs SUBJECT, 0 movers
  of 2302 (rc, sha of stdout, sha of stderr with the path masked). The implementer's
  `ab.py` ran its null on REF only, which cannot see flakiness in SUB (the same gap bd
  9bhg's r1B named F-9B-5); this one can, and there was none.
- ORACLE vs SUBJECT: **12 movers of 2302 — 9 A→D, 3 DIAG, 0 D→A, 0 STREAM**, every one of
  them this change's own fixture (`results/ab_ora_new.txt`). ORACLE accepts 1149. That is
  the record's "11 of 2301" plus `_l3oi_owner.ll`, added after its sweep. **Re-measured as
  claimed.**

**Twin battery (the implementer's 45 pairs, re-run with my script).** ORACLE 14/45,
SUBJECT 29/45, COMPOSED 31/45 twin-identical; the non-identical rows on SUBJECT are exactly
the record's §5 classes (`a01 a02 l12 l17` C-accepts = z0re; `a03 a04 l19` T-accepts =
cepm; `h01 h02 l04 l05 l06 l09 l10` DECL-DIFF; `j02 l20` ACC-DIFF). COMPOSED differs from
SUBJECT only in `l09`, `l10` → DECL-SAME. **Re-measured as claimed** (the record's 28/42
and 30/42 plus `h03`, DECL-SAME on both).
⚠ The first run of this battery printed `denominator: 0 pairs` — zsh passed the pair list
as ONE word. The denominator line caught it (L10); every figure here is from the bash re-run.

**My 18 pairs (`src/r*.c`).** ORACLE 3/18, SUBJECT 12/18, COMPOSED 14/18.
- New d88e members, all silently wrong on ORACLE and DECL-SAME on SUBJECT: `r04` (the φ's
  only consumer is `main`'s `ret`), `r14` (a true lift and a false lift in one function —
  the re-ask walks past the true record), `r16` (the consumer is a chained `cq_theta`: the
  ORACLE keeps the measurement but applies `Ry(.9)` to a fresh `|t⟩` and `Ry(.2)` to an
  orphan rail — a wrong unitary with the measurement PRESENT, so "the measurement is
  deleted" undersells the class), `r17` (non-main `void` function), `r18` (3-way switch,
  two rotating edges and a default).
- DECL-DIFF on ORACLE → DECL-SAME on SUBJECT (a string the false lift manufactured, or an
  l3oi decline, replaced by the twin's): `r13` (false lift + a genuine 2qyz stale op in the
  same function), `r15` (the φ feeds another Phase-6 call), `r19` (the base feeds a
  constant-table read), `r20` (the φ feeds `printf`).
- `r21` (a TRUE lift feeding `printf`): ACC-SAME on all three.
- Remaining non-identical rows: `r01`, `r10`, `r02` (F-DA-3), `r03` (F-DA-4), `r05`
  (SUBJECT l3oi, COMPOSED DECL-SAME: the ordered scrub reaches the chained site), `r07`
  (SUBJECT l3oi decline vs twin accept, pre-existing; COMPOSED ACC-SAME).
- `r22`/`r23` (lifts inside a loop the pass does not unroll): decline identically at
  earlier walls on every binary — no information about the fence.

**The 9bhg reviewers' probe families on all four binaries** (`review_r1A_9bhg/probes/src`,
224 modules, and `review_r1B_9bhg/probes/battery`, 80 modules, each with its own library
TU; 304 measured, 0 missing; `results/batch_imp.tsv`).
- ORACLE→SUBJECT movers: `l01C l07C l08C l13C l18C l22C` A→D (each accepted with **0**
  `cqrt_measure` on ORACLE) and `l25C` DIAG. Nothing else moved, and nothing moved D→A.
- 9BHG-ONLY→COMPOSED movers: the same seven plus `l09C l10C` (A→D, 0 measures on 9BHG-ONLY).
- The whole r1B battery (80 modules): 0 movers in either comparison.

**Composition.** The implementer's COMPOSED binary is reproducible: applying `git diff
983f9361 30529716 -- ir-pass/include ir-pass/src ir-pass/test` to `52d35e5d` and building
gave `242f8b61530623e9`, bit-identical.

## 3. Instrument sweeps over the lit corpus

One build (`probes/ra_instrument.patch`, `cq-opt` `6c215158b89c8d4d`), four env switches,
so every mutant is the same binary. Denominator 2302 for each sweep; the comparison is
always against the same binary with no switch set.

- **NULL CONTROL: INSTRUMENT with no switch vs SUBJECT: 0 movers of 2302**, stdout included.
- **`RA_MC=1` (census: every recorded lift declines with its own string): 41 movers** —
  25 A→D and 16 DIAG. Of these, 18 are this change's own fixtures: 5 accept/true-lift
  controls A→D, 13 declines DIAG. The other **23 are pre-existing**: 20 shipped ACCEPTS
  that carry a TRUE lift through the re-ask (`control_*lifted_phi*` ×7,
  `control_classical_call_arm_accept_onward_phase_downstream_if`,
  `control_phase_kickback_rail_cross_block`, `control_swap_diamond_after_classical_lift`,
  `lowering_classical_mux_phi_onereg*` ×5, `_lift_{op,diaghop}_before_sibling`,
  `lowering_live_record_mb_router_phi_accept`, `lowering_reject_live_record_{anc_,}router_phi` —
  the last two exit 0 with the bd lyyf WARNING despite their names)
  and the 3 2qyz stale declines, which at the new slot reach the re-ask first. That is the
  record's "23 pre-existing, 20 accepts". **Re-measured as claimed**; the population the
  re-ask runs over is real (`results/sw_mc_movers.txt`).
- **`RA_OLDSLOT=1` (the 2qyz re-sweep back at its pre-d88e slot, M10): 1 mover of 2302** —
  `…_spec_scrubbed_base_pure_consumer.ll`, DIAG. No verdict moved in either direction. Over
  the 501-module probe set (every `p/*.s1.ll` of this review: the implementer's 157, my 38
  and the two reversed-layout modules, and the 304 imported 9bhg probes): **2 DIAG movers
  (`g01C`, `r13C`), 0 verdict movers.** The move is a string move on this population, as
  claimed.
- **`RA_WVH=1` (the re-ask reads `WeakVH` copies, M6′)**: corpus — **1 A→D of 2302,
  `lowering_classical_mux_phi_onereg_spec_quantum_base_fp_rebuilt.ll`** (the record's M6
  case, and nothing else); probes — **2 A→D of 501: `f01Q` (the same fp-rebuilt site) and
  `rk04Q_rev` (F-DA-1)**. So the one tracking case the corpus holds is the fp rebuild; the
  lift-order case is visible only to the hand-built probe.
- **`RA_NOREASK=1` (M1)**: corpus — **12 of 2302: 10 D→A, 2 DIAG**, all this change's own
  fixtures. Nine are the A→D set reverting. The tenth D→A is
  `…_spec_scrubbed_base_pure_consumer.ll`, which the ORACLE declined (at the re-sweep's old
  slot): without the re-ask, the MOVED re-sweep lets it through (item 3). The two DIAG are
  `_owner` (back to the 3d8q backstop) and `_l3oi_owner` (back to l3oi). Probes — **25 D→A
  and 7 DIAG of 501, every one a `*C` spec-classical variant or `rk04C_rev`; no `*Q` and no
  `*T` module moved**, so the re-ask fires only where the base really lost its taint. By
  hand: `g01C` **ACCEPTS**, `l25C` falls back to the 3d8q backstop, `r13C` to the re-sweep's
  own genuine stale op.

## 4. What I did NOT attack

- The EMITTED circuits of any accept (z0re, hgwx, spec-quantum lifts) beyond reading two
  streams (`r03C`, `r07C`) — the other reviewer's scope.
- A C spelling that reaches the reversed-layout lift of F-DA-1; the pass's own
  block-creating stages (unroller, PredMux, RegionFlatten) as producers of that layout.
- In-process hosts that continue past a `DS_Error`; `+Asserts`; `invoke`; `-g` builds.
- Allocator-dependent aliasing (bd 8e5r) against the lift itself — argued in item 1, not
  constructed.
- The full ctest suite (not run; this review changed no code). Every figure is a sweep of
  `cq-opt` over the lit corpus or over probes, as stated.
