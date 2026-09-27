# Rule-13 review r1A — bd `test_C_libtooling-9bhg`, commit `30529716`

Reviewer r1A. My scope was the taint-fence logic and pass ordering. Reviewer r1B
ran at the same time on the ordered scrub, the dangling `Tainted` keys and the
emitted circuits of multi-TU programs, so this review says nothing on those
three.

Binaries, checked by sha-256 prefix before and after the owner's pause:

| name | commit | `cq-opt` |
|---|---|---|
| subject | `30529716` | `8b837d1f79574156` |
| oracle | `983f9361` | `438c77bf45c02e3e` |
| preE | `aad63450` | `63e2f0bbd3708c92` |

For mutants I used a private worktree, `scratchpad/rev9A_wt`, at `30529716`,
with its own build. It was restored bit-identical to `8b837d1f` after every
mutant.

⚠ **The owner paused this review.** A null-control mutant was running at that
moment. It had written 0 bytes, so I discarded it and ran it again. No
measurement below was in flight during the pause.

## Verdict: **NOT-CLEAR**

**What holds.** The fence logic works as the record describes. I found no path
to lowering that skips the late ask. I could not construct S3. I found no crash
in the window, and no over-scrub of a return value. The implementer's claims
re-measure as stated.

**What fails.** The change's D→A population contains wrong programs. Before this
change the 3jru early refusal was the only thing that declined them, by
accident.

- **F-9A-1 (P1).** A pre-existing silent miscompile: the one-register merge-φ
  lift runs on a Phase-6 site result, and `specialize()` then scrubs it.
- Before `30529716`, this defect was reachable only in functions that do not
  return a Phase-6-derived value.
- `30529716` makes it reachable in functions that do return one, when those
  functions are called.
- Two programs the oracle declines now compile at exit 0 with the user's
  `cq_measure` deleted, and stage 2b STRICT reports them clean.

**Any fix of 9bhg's over-decline hits this, whichever route it takes.** The bead's
literal route (make the scrub cross returns, then move the refusal) accepts the
same modules. So the route deviation is not the cause, and I judge the deviation
itself justified (see §4). But 9bhg should not land until bd `d88e` is fixed or
fenced.

## Findings

| id | sev | one line |
|---|---|---|
| F-9A-1 | **P1** | bd `d88e` (new). A classical-condition one-register merge-φ lift over a Phase-6 site result, followed by `specialize()`'s classical scrub, deletes the user's `cq_measure`. The defect is pre-existing; 9bhg moves oracle DECLINES of it to silent ACCEPTS (`l09C`, `l10C`). |
| F-9A-2 | P2 | Two safety sentences are falsified by F-9A-1. §2's last row says "accept, preE's stream". The commit message says "programs aad63450 compiled correctly". preE is not a correctness oracle: it miscompiles `l09C`, and so does the subject. |
| F-9A-3 | P3 | Two more conjuncts of the change are pinned by nothing: the drain's re-decision of deferred functions (MRED) and the early slot's re-ask of the predicate (MNOREASK). Neither can move a verdict, only a slot or an owner, because the late ask is total. Add them to the record's list of MISSED mutants. |
| F-9A-4 | P3 | Comment precision. `CondLiteral.h`/`.cpp` say the late re-ask "refuses the module before anything lowers", and TRACK §4 S1 says "before any lowering stage". Both are false: round-1 control emission has already emitted gates (including the `_hl` literal from a provisional call result) by then. What is true: before `lowerRotations`/`lowerOps`/`lowerMeasures`, and before any output. |

### F-9A-1 (P1) — the lift, then the scrub (bd `test_C_libtooling-d88e`, filed)

**The mechanism: L1's STAGE species on the scrub side.**

1. `declineClassicalMuxes` runs between propagation and `specialize()`. There,
   `liftOneRegisterMergePhi` sees a classical-condition φ `phi(t, cq_theta(t, a))`.
2. `resolveWireBase` peels the theta to its tainted arg-0 `t`. At that point `t`
   is a Phase-6 site result that is still only CONSERVATIVELY tainted.
3. Both incomings resolve to base `t`, so the lift RAUWs the φ to `t` and erases
   the φ.
4. `specialize()` then proves `h`'s clone classical and scrubs `t`.
5. The consumer of the rotated value now reads the classical `t`:
   - the `cq_theta(t, a)` lowers as a SOURCE on a fresh rail that nothing reads,
     and the spine reverses and frees that rail;
   - the user's `cq_measure` takes the bd 21mg classical path and emits no gate
     and no trace line.

bd l3oi's fence cannot see this. It asks about EMITTED `cqrt_*`/`cq_template_*`
readers and clone-masked slots. Here the readers are an unlowered `cq_measure`
and `cq_theta`, reached through a RAUW. The premise "t is a register" was used
by a REWRITE, not by an emission.

**Measured.** Sources are in `probes/src/`. Lib TU `libC.c` is
`int h(int a, int k){return k+1;}`. Callers are built with `clang -O1` and
linked with `llvm-link`. "rc0" is `opt` exit 0.

| probe | shape | preE | oracle | subject | `cqrt_measure` in lowered IR (source has 1) |
|---|---|---|---|---|---|
| `l01C` | main, if-lift | rc0 | rc0 | rc0 | **0** on all three |
| `l08C` | non-main `f` returns `cq_measure(r)` (return untainted) | rc0 | rc0 | rc0 | **0** on all three |
| `l13C` | main, N-way `switch` lift | not run | rc0 | rc0 | **0** |
| `l18C`, `l22C` | two lifts / chained thetas in the arm | not run | rc0 | rc0 | **0** |
| **`l09C`** | `f` returns `t2 + cq_measure(r)`; `t2` is a second spec result, so the return is PROVISIONAL | rc0 | **DECLINE** (3jru) | **rc0** | **0** |
| **`l10C`** | `f` stores `cq_measure(r)` to a global and returns `t2` | rc0 | **DECLINE** (3jru) | **rc0** | **0** |
| `l09Q`, `l10Q` | the same with `h` quantum | rc0 | decline | decline (late ask) | — |

**`l09C` end to end on the subject.** Lowered `f`:

```
%h = cqrt_alloc_i32(m); cqrt_ry_i32(%h, .5)
%2 = __cq_q_h_01(%h, m); %4 = __cq_q_h_01(%h, m+2)
br (m>3) → { %h1 = cqrt_alloc_i32(%2); cqrt_ry_i32(%h1, .2); cqrt_ry_i32(%h1, -.2); cqrt_free(%h1) }
ret %2 + %4
```

- The user's rotation is uncomputed.
- The user's measurement is gone.
- For `m > 3` the source measures `Ry(.2)|t⟩`. The binary returns the constant
  `t + t2`: trace `exit=14` for `m=5`.
- `free_pairing_check.py`: `1 verified, 0 violation(s), 0 unproven`. STRICT is
  clean.

**Why this is 9bhg's finding and not only a pre-existing one.** "Pre-existing"
is true of the defect and FALSE of its population.

- The oracle's 3jru early refusal declined every module in which a function
  returning a Phase-6-derived value has a used call site. That accidentally
  covered this defect for exactly that population.
- 9bhg's whole purpose is to remove that refusal for a classical verdict, so it
  moves `l09C`/`l10C` from DECLINE to a silent wrong ACCEPT.
- The corpus A/B cannot see this. `ir-pass/test` has no module of this shape: 6
  D→A movers, all 9bhg's own. It is bd `1yeu`'s blind spot (one function per
  module) crossed with a two-stage premise.

**The route question.** TRACK §2 argues its route against the bead's. In both
routes the lift runs in `f`'s own body on `f`'s own conservative taint, and both
routes accept `l09C`. So the deviation neither causes nor cures F-9A-1.

**Fix directions (unruled; recorded in `d88e`):**

- (a) refuse the lift when its base is a potential Phase-6 site result, or is
  in the cone of one;
- (b) RECORD every lift whose base can later be scrubbed, and re-ask after
  `specialize()` beside the l3oi fence (L1's cure: record, then re-ask);
- (c) run the lift after `specialize()`.

Any of the three closes both populations. The minimal gate for landing 9bhg:
(a) or (b), plus `l09C` as a decline fixture or with a correct stream.

### F-9A-2 (P2) — two sentences F-9A-1 falsifies

- TRACK_9BHG §2, last row: "classical (as preE) → accept, preE's stream".
- §2 prose: "the window's stages see the caller exactly as preE did, which is
  the configuration they were built and tested against".
- Commit message: "an over-decline of programs aad63450 compiled correctly".

Each of these is true of the CALLER. None is true of the provisional function's
OWN body, where the window's stages still read the conservative taint.
**preE's stream is a regression baseline, not a correctness witness**, and
`l09C` is a preE miscompile that the subject reproduces byte-for-byte. The
"16 of 16 byte-identical to preE" measurement re-measures as true (§3). It shows
stability across binaries, not correctness: the same trap as the
`*_leak_control` headers in CLAUDE.md §5.

### F-9A-3 (P3) — two more unpinned conjuncts

Harness: `probes/mut.py`. Each mutant is a textual patch, a rebuild of `CQPass`
and `cq-opt`, the FULL `lit -s` run (denominator 2288), and my probe corpus
(179 modules) compared against the subject binary. Every row restored the build
to `8b837d1f`.

⚠ **My first batch parsed `lit -q` output and may have been blind to failures.**
I found this when positive control M4 was the first mutant run under the fixed
`-s` parser. Every row below comes from the re-run under the fixed parser, after
null and positive controls. The first batch is kept in
`probes/results/v1_q_parser/` and is not cited.

| mutant | removes | lit failures | probe movers | reading |
|---|---|---|---|---|
| N0 | nothing (a dead conjunct; binary changes) | 0 (2287 + 1 XFAIL) | 0 of 179 | null control |
| **M4** (positive control) | the late ask in `run()` | **2** (`taint_reject_spec_quantum_return_{branch,measure}`) | **25** (all `*Q` quantum-verdict probes, plus `rq1..3`, `rfq`) | KILLED; the harness can fail |
| M16 | the early skip's "no tainted caller" conjunct | 0 | 0 of 179 | MISSED, as the implementer measured |
| **MRED** | the drain's re-decision of deferred functions after a crossing batch | 0 | 0 of 179 | **MISSED (new)** |
| **MNOREASK** | the early slot's predicate re-ask (skip on the "no tainted caller" conjunct alone) | 0 | 0 of 179 | **MISSED (new)** |
| M11 | genuine sites as keep roots at resolution | 0 | 0 of 179 | MISSED, as the implementer measured |
| MSLOT | late ask moved from before `lowerRotations` to after `lowerMeasures` | 0 | 0 of 179 | equivalent: the return stays tainted through lowering (RAUW to a handle), so the refusal still fires, one slot later |

MRED and MNOREASK are not in the record's mutation matrix. Both are
slot/owner-only by the totality argument:

- a deferred function that is never re-decided is re-asked at the early slot;
- a function the early slot skips is refused at the late slot.

So neither is a soundness hole, but the record should list both with the other
MISSED conjuncts and not present them as load-bearing. The record calls the r65
re-ask necessary ("refused here"). Under MNOREASK, r65 is still refused, with the
same string, one slot later.

**M11: I agree it is equivalent, but only while l3oi holds.** A genuine site
enters a later scrub cone only when every one of its tainted arguments is in
that cone. Then its masked slots read scrubbed values, and
`declineScrubbedHandleReads` fires.

**M16: I agree it is unreachable. I tried to construct S3 and could not.** For a
crossed return to become provisional, its independent source must either join
the cone or leave `Tainted`. I checked each way in:

- **Thetas:** they are keep roots.
- **A crossed call `G(x)` becoming a root:** needs a tainted `x`. That makes
  `G(x)` a Phase-6 candidate whose callee holds a primitive, and detection
  declines it at round 1 or round 2. The round-2 reseed set is the full delta.
- **Direct-insert rails** (`%out`, `MuxOut`, promotion allocs): they have no
  tainted operands.
- **Erase sites:** I enumerated the `Tainted.erase` sites and every one either
  RAUWs to a still-tainted value or deletes. `liftOneRegisterMergePhi`'s base,
  `collapseRailPhisIn`'s root and the emitters' `%out`/`Q` are all tainted at the
  time.

## 1. Attack list, and what each attack measured

**1. The window with a QUANTUM verdict (crash or escape).**

- 31 caller contexts: `w01..w20`, `c01..c07`, `s05`, `s13`, `x09`, `x10`. Each
  was built twice, with a classical lib (`C`) and a quantum lib (`Q`).
- Contexts covered:
  - the xdu2.13 condition leaf in a tree (`w01`), a 4.4 select arm (`w02`) and a
    value arm (`w03`);
  - the angle operand (`w04`, `w06`) and the state-prep seed (`w05`, `w07`);
  - a loop bound (`w08`), an in-loop kickback (`w09`), a switch (`w10`), and a
    `printf` under control (`w11`);
  - a QRAM index (`w12`), a 6.5 arm (`w13`), a volatile store (`w14`), Q×C
    arithmetic (`w15`), a bool seed (`w16`), a classical condition around a
    rotation (`w17`), and an in-loop value arm (`w18`);
  - a Q==C compare (`w19`), a select over quantum arms (`w20`), a nested spec
    argument (`s05`), and calls under tainted control (`c01..c07`).
- Every `Q` variant exits 1 with a clean diagnostic: the late 3jru string, or an
  earlier owner.
- 0 crash signatures (`Stack dump`, `Assertion`, `Segmentation`, `UNREACHABLE`)
  across 150 subject runs and all oracle runs.
- M4 confirms the late ask is the owner for 20 of my `Q` probes: `w02 w03 w05
  w06 w08 w12..w20 s05 s13 x09 x10 l09 l10`. Removing the ask turns each of them
  into an exit 0.
- Every `C` variant that accepts is byte-identical to preE: `w02 w03 w05 w06 w08
  w12..w20`, 14 modules.

**2. Paths to lowering that skip the late ask.**

- `run()` and the `runOnFunction` shim both ask it, unconditionally, after
  `specialize()` and the l3oi fence.
- The passthrough early-out has no quantum surface.
- `lowerCloneControl` and the clone lowering run inside `specialize()`, before
  the late ask, and emit nothing observable before the module is refused.
- A clone never calls a provisional function directly: `scanBody` recurses and
  rejects the theta. For an indirect call, the address-taken rule refuses the
  function at the late ask.
- ⚠ `runOnFunction` is a dead shim (zero callers). Its `onlyInF(ThetaCalls)`
  makes `Keep` incomplete for both the new predicate and the real scrub, which
  is pre-existing for the scrub. Not reachable.

**3. S3, recursion, mixed returns and indirect calls.**

| probe | shape | subject |
|---|---|---|
| `s01` | self-recursive `fr` | declines (loop-carried) on all three binaries |
| `s02` | mutual `F`/`G` | declines at the classical-mux guard; the oracle declined with 3jru, so only the owner moved |
| `s04` | a spec result and a genuine rail on one return | 3jru decline, both lib variants |
| `s07`, `s11`, `s12`, `s14` | a provisional function as a spec callee, directly, indirectly, or via a classical helper | `callee contains a quantum primitive`, everywhere |
| `s09` | a spec site in a loop | declines (loop-carried) |
| `s13` | two chained spec sites | C accepts, Q declines late |
| `x01..x12` | a provisional function's own body: QRAM, store, `printf`, loop, classical mux, select, i64 return, 6.5, kickback on `t`, measure of `q`, theta on `t` | declines everywhere except `x10C` (accept, and correct) and `x12` (3jru) |
| `rb1..rb3` | a rail-bank cell load whose pointer derives from a spec result, the one taint source that is neither operand-derived nor a keep root | declines at the rail-bank carve on all three binaries |

For `rb1..rb3`: if a module of that shape ever passed the carve, the scrub would
also remove the loaded handle's taint. Treat it as a retirement trigger for the
rail bank's D5 allow-list, not as a finding.

**4. The taint-growth obligation (L1).** Every grower that crosses does so through
`propagateWorklist`: `propagate`, the two round-2 drains, and
`propagateFromSeeds`. The crossing loop decides only once the worklist is empty,
keeps deferred functions in the set, and re-decides them after every crossing
batch. Crossing is monotone, the loop terminates, and non-provisional status is
stable within a drain (argument above). Growth after the early slot can only
make a skipped function non-provisional, and the total late ask catches that.
What 9bhg changes about L1 is the SCRUB side, and that is F-9A-1.

**5. The implementer's claims, re-measured.**

- **Corpus A/B:** 2288 modules, null 0 of 2288, 6 D→A, all this change's own
  fixtures, and no other mover of any kind (`probes/results/ab_corpus_rev.txt`).
  **Confirmed.**
- **"16/16 accepts byte-identical to preE":** confirmed IDENT for rt1–3, ob1–8,
  rfc, rloop, rsel, fp2 and fp3, by rebuilding the implementer's sources.
  ob9/ya/yb DIFF, as stated. rq1–3, rfq, rx1, rp1, r65, r65c, rs1 and yc
  decline, as stated.
- **The MISSED mutants:** M11 and M16 are MISSED here too, and I agree with both
  arguments (above). M10 and M18 are r1B's area and I did not re-measure them.

## 2. On the deviation from the bead's route

I judge the deviation JUSTIFIED. The bead's route tells callers "quantum" through
round-1 control emission and then asks l3oi to take it back. For any caller that
branches on the result, that ends in a decline (at best) or an l3oi-class
miscompile. Not crossing a provisional return removes the premise instead of
repairing its consequences. The safety of that rests entirely on the late ask
being total, and it is: M4 kills 2 fixtures and 25 probes, and I found no bypass.

What the route does not address, and neither does the bead's, is the
provisional function's OWN body. There the window's stages still act on the
conservative taint. F-9A-1 is the first stage found doing so outside l3oi's
fence. `cepm` (over-decline) and `d88e` (over-accept) are the two faces of that
one residual.

## 3. What I did NOT attack

- The ordered scrub's mask recomputation (M10), the `retargetSite` rebuild
  (M18/fp3), dangling keys (`j8sk`), layout order (`s07e`) and the emitted
  multi-TU circuits: all r1B's scope.
- `invoke` call sites to a provisional function, `weak`/`available_externally`
  definitions (the analyzed body may not be the one that runs), and `+Asserts`.
- Other stages that REWRITE on the "t is a register" premise in the provisional
  function's own body. I found the one-register lift. `collapseRailPhisIn` and
  the in-loop rail machinery declined on every probe I built (`l11`, `l14`,
  `l16`, `l23`, `l24`). The M-C in-place re-verification and the state-prep
  RAUW (`l12`/`l17` are CORRECT: seeded fresh rail) were checked by probe only,
  not by reading every consumer. A full enumeration of rewrite stages between
  propagation and `specialize()` whose premise the scrub can falsify is owed by
  `d88e`'s fix.
- The e2e / multi-TU A/B sweeps (22 + 432): not re-run.
- G-13's rolled-vs-unrolled probe: not applicable. No condition fence was
  widened.
