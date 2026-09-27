# Rule-13 round r2B on bd `test_C_libtooling-9bhg` (composed branch `f2148d0a`): the specializer changes × bd 8e5r's self-cleaning containers × bd d88e's lift record

Reviewer r2B, 2026-09-26. Independent round, concurrent with r2A (accept surface, the window before
the late ask, slot order). Subject: branch `worktree-agent-a50057998e957b90e` at `f2148d0a`, net diff
vs `main` `aee8f4f8`. Nothing in the subject worktree was edited or rebuilt. Every build below is in a
private `git worktree` under the session scratchpad (removed at the end). Not committed.

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1, 0 P2, 3 P3

The specializer changes held on every axis I attacked. That covers the F-EB-9 deletion, both `WeakVH`
choices, the ordered scrub (shrink, skip, fp rebuild at f32/f64/f80, composition with the d88e lift),
allocator independence and use-after-free. No wrong circuit, crash, UAF or reopened l3oi was found.
Every new accept I built is trace-identical to its hand-inlined twin and byte-identical across four
allocator modes.

The items are one falsified claim with a C-reachable over-decline behind it, one coverage gap, and one
unstated contingent closure.

| id | sev | one line | attribution | bead |
|---|---|---|---|---|
| F-9D-1 | P3 | `plan6.Pending` is **not** in layout order. Round-2 `detectSpecializations(…, &live)` APPENDS its sites after round 1's, so a round-1 site reading a round-2 site's result is resolved first, from a stale mask, and the l3oi clone-reader clause declines. The trigger is **plain C** (6.5 arm → spec site → spec site). This falsifies three 9bhg source comments, the `_layout.ll` retirement trigger, and bd s07e's "IR-level only" framing and its RPO route | claims INTRODUCED (9bhg text); over-decline PRE-EXISTING (main and oracle decline too) | **NEW `3zr4`** |
| F-9D-2 | P3 | The ordered scrub's accept population is pinned by **2** i32 fixtures only. Reverting the ordered scrub (M3/M3b) moves **31** of 957 probe modules (30 A→D, 1 owner move). They include every fp mask-shrink-with-rebuild accept (f32/f64/f80), the d88e-lift composition and nested `n4`, and none of those is pinned by lit. Separately, the round-2-provisional return `R6` is unpinned against M1 | coverage of INTRODUCED behaviour | — |
| F-9D-3 | P3 | `declineScrubbedHandleReads` sees only `CallBase` readers. 9bhg GROWS the scrubbed population (skipped mask-0 sites and their cones). A non-`CallBase` reader decided on pre-scrub taint (φ incoming, bank store, lift base) is closed today by OTHER owners. The loop layer's refusal of a tainted carried seed is one of them (`Z5`). That is a contingent closure, stated nowhere | argued latent; closure measured | — |

## Binaries and instruments (sha-256 prefixes, re-measured)

- SUBJECT `cq-opt` `bfb441d3b9568bd1`, `cq-opt-debugalloc` `7ef9853f0eb3a528`. These are copies of the
  subject `build/`, and all measurements ran on the copies.
- `main` `aee8f4f8`: `cq-opt` `69250feaf68bbe49` (the frozen copy). ORACLE `983f9361`: `438c77bf45c02e3e`.
- **Build null control:** the private worktree's unmodified Release build is **bit-identical** to the
  subject (`bfb441d3`, `7ef9853f`). After the mutant matrix it was restored, and the restored build is
  bit-identical again.
- **ASan is UNUSABLE on this host, and that is measured, not assumed.** Any `-fsanitize=address`
  binary, including a 3-line hello-world, dies at `libsystem_pthread __pthread_init.cold.2` with
  `EXC_BAD_INSTRUCTION` ("PTHREAD_SELF TSD not initialized") before `main`. That holds for both the Apple
  clang 17 and the Homebrew LLVM 19 runtimes on macOS 26.6.2.
- **Substitute: Guard Malloc** (`DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`). It puts every
  allocation on its own VM page and unmaps the page on free, so a read of freed memory faults.
  - **Positive control:** the three shipped bd um24 UAF fixtures
    (`iosink_reject_mux_literal_callee`, `lowering_reject_break_uncollected_clone`,
    `lowering_reject_inplace_rail_stale_w1_xor_bareout`) exit **139, 3 of 3**, under Guard Malloc on the
    pre-8e5r oracle. The subject declines them cleanly (rc 1).
  - A hello-world UAF also exits 139 under it.
- `tools/stab.py` runs each module under `nofree` ×10, `lifo` ×10, the system allocator ×10 and Guard
  Malloc ×1.
  - The reference is the first `nofree` run.
  - "Variant" means any (rc, output-hash, first error) that differs from the reference.
  - **Positive control:** the oracle on `k65` gives `sys 10/10` differing, and the tool reports VAR.
  - The null control is the `nofree` runs against each other.
- `tools/ab.py` compares subject vs mutant per module and mode. Each module runs on the subject twice,
  so every A/B carries its own null count.
  - It was caught failing LOUDLY once: a missing `__main__` guard under macOS spawn gave
    `BrokenProcessPool`, not a "0 movers" pass.
  - It was fixed and smoke-tested on 2 modules before use.

## Attack 1 — the F-EB-9 deletion (`OldSite` erase + `plan.Pending[i].Site` update)

- **Every reader of `plan6` / `Pending`, enumerated by grep and read.**
  - `detectSpecializations` (the `shouldSpecialize` dedup), the `declineTaintEscapes` carve,
    `replanReseedSpecialization` and `adjudicateTaintDelta`'s re-detect: all run before `specialize()`.
  - After `specialize()`, neither `run()` (lines 868→end) nor `runOnFunction` names `plan6` again.
  - `lowerRotations(…, &plan)` takes the ControlPlan, and ignores it anyway (`(void)plan`).
  - None of the post-`specialize()` owners reads a `SpecPlan`: the d88e re-ask, the 2qyz re-sweep, the
    l3oi fence, the late 3jru ask and the 3d8q backstop.
  - Inside the loop, index `i` is read once, into a local `Cand` whose `Site` `resolveSite` updates by
    reference.
  - `plan6` dies at the end of the entry point, and its destructor dereferences nothing.
- **No later `Pending[j].Site` can be the freed one.** `retargetSite` erases only the site it
  retargets. Pending has no duplicates: round-2 detection dedups through `shouldSpecialize`. Every other
  mutation in `buildClone` is clone-scoped (`lowerCloneControl`, `lowerQramReads`/`lowerOps` over
  `cloneTaint`, the wrap, the twin).
- **Guard Malloc** over all **2320** lit fixtures × {subject, `main`}: **0** crashes (every rc is 0 or
  1). The only verdict movers are 9bhg's own 6 D→A fixtures. The 971 probe/family modules under Guard
  Malloc: 0 crashes.
- **M4** re-adds the erase-by-dead-pointer exactly as `30529716` had it. It builds **bit-identical** to
  the pre-F-EB-9 merge binary `766f31cdf3b688df` that TRACK_9BHG §11 records, so the restoration is
  faithful.
  - lit: **0** failures (MISSED).
  - A/B over 971 modules × {sys, lifo, nofree}: **0 movers**, null 0.
  - It is equivalent by construction. Nothing allocates between `retargetSite`'s `eraseFromParent` and
    the post-hoc erase: `NewCall` is created before the old call dies, and control returns straight to
    `specialize()`. The dead address therefore holds nothing live to remove.
  - The deletion is hygiene, as the implementer says, and needs no pin. **Agreed.**

## Attack 2 — the `WeakVH` choices

- **`ScrubbedByReturnTaint` (`WeakVH`, not tracking).** A recorded value would need a RAUW in the
  window. The only RAUW between a scrub and the fence is `retargetSite`'s rebuild of a site's OLD call.
  - A scrubbed site is always SKIPPED. The cone admits it only when every tainted operand is in the
    cone, so its recomputed mask is 0 and it is untainted.
  - A genuine rebuilt site enters `TaintedSources` before any later scrub, so it is never admitted.
  - A value is never deleted with users outstanding except through that RAUW, so the handle cannot null
    under a live reader.
  - **Built:** a scrubbed value as an ARGUMENT of a later REBUILT call. In `FA_{F32,F64,F80}`,
    `z = hf(y, x)` is classical and scrubbed, and `w = hfq(z, q)` is an fp return rebuilt to i32. The
    fence sees `z`'s reader as the NEW call to `__cq_q_hfq_10`, bit 0 clear, so it rightly does not
    fire.
  - The trace is **identical to the twin** (`z = x + 1`). The output is byte-identical across sys, lifo,
    nofree and Guard Malloc, and 2b STRICT is clean.
  - "The scrubbed value IS the rebuilt call" is unconstructible, for the two reasons above.
  - **M6** drops `TaintedSources.insert(Cand.Site)`: lit **0** failures. It is equivalent modulo the
    fence. A genuine site can be admitted into a later cone only if it reads the later site's result as
    its only tainted operand, i.e. it was resolved first with that operand MASKED. The fence then
    declines on the root, which is recorded first.
- **`SpecHandleArgMask` (`ScrubMap` keyed by clone `Function`).** Nothing in the window erases or
  replaces a `Function`. The only `Function::eraseFromParent` calls in the pass are
  `lowerLateReassignments`' orphaned template DECLARATIONS and `eraseDeadDecls`, both after `uncompute`
  (`CQLoweringPass.cpp` :1034/:1135).
  - `lowerCloneControl` clones nothing: `CloneFunction*` appears only in `cloneFor` and
    `synthUncomputeTwin`.
  - A clone is built once per `(callee, mask)` through the cache, and the reclassified mask keys the
    cache the same way.
- **`LiftedMergePhis` (d88e, `WeakTrackingVH`), composed with the ordered scrub.**
  - `D1`: the lift base is a SKIPPED site's result (`u = g(t)`). The subject declines with the d88e
    re-ask's classical-mux string, byte-equal to the twin's. `main` declined at the l3oi fence, so
    the owner moved to the right one.
  - `D2`: the base is a mixed site whose scrubbed argument dropped out of the mask (`u = g2(t, q)`,
    11→10).
  - `D3`: fp, the base is a REBUILT site with a shrunk mask.
  - Both D2 and D3 are **new D→A** (`main`: l3oi decline), trace-identical to their twins and stable in
    all four modes.
  - d88e's taint-monotonicity enumeration (TRACK_D88E §6.1, owed "on the composed tree") re-checked on
    `f2148d0a`. `specialize()` still writes module taint at exactly three places: the scrub (erase),
    the ReturnTainted re-mark (an insert of an already-tainted site or its rebuild), and
    `HandleWidth`/`SpecHandleArgMask`.
  - The re-mark cannot re-taint a scrubbed value, because a scrubbed site is skipped before
    resolution. Module taint still only shrinks in the window.

## Attack 3 — the ordered scrub

- **Mask GROW: unconstructible, confirmed.**
  - Inside `specialize()`, the only insert re-marks an already-tainted call or the rebuild of one.
  - Between the last re-plan and `specialize()`, every insert replaces an already-tainted value: IO
    tape, QRAM/Shadow `Out`, promote. That is r1B's enumeration, re-read by me.
  - A shadow load at a CLASSICAL index would have grown a mask. By reading the code it declines at
    `kMsgQramMixed` ("mixes a tainted-index and a classical access"); I did not measure that. The
    bitcast and freeze folds RAUW onto a tainted source (read).
  - The reclassify branch is therefore reached only on shrink. On shrink, `classifyCandidate`'s (A)
    checks a subset of the slots and its (B) is mask-free, so it cannot newly reject: M10 is
    equivalent, as TRACK_9BHG says.
- **Mask SHRINK where an earlier gate assumed the larger mask.**
  - No gate before `specialize()` depends on a site's MASK.
  - A gate that read a site's argument or result as a handle reads a scrubbed, recorded value, and the
    l3oi fence sees it.
  - Probes: `a10`, `a11`, `c6`, `c8`, `n4` and `w7`–`w15` (r1B), `R3`, `FA`/`FB` ×3, `D2`, `D3`.
- **Layout vs dominance (bd s07e): no WRONG answer is constructible.** A stale-masked argument lost its
  taint only through a scrub. Every scrub records every value it removes, and the stale argument sits in
  a MASKED slot of a clone call, so the fence declines.
  - The one non-scrub route into the `mask 0 ∧ still tainted` branch would be an argument untainted by a
    RAUW onto an untainted value. That branch keeps the detection mask and relies on the fence, and the
    fence sees only SCRUBBED values.
  - I found no such RAUW among the window's `Tainted.erase`+RAUW sites I read: the bitcast and freeze
    folds, the d88e lift, QRAM/Shadow `Out`, promote, and the IO sink (a used result declines). This
    enumeration was by reading, not exhaustive over all 133 deleting sites. The source comment's "never
    an accept" carries that premise.
  - **I did find that the residual is reachable from C, by a mechanism no record names. That is
    F-9D-1.**
- **fp rebuild at f32/f64/f80.**
  - `FA_*`: a classical fp site feeds a quantum fp site, which is rebuilt.
  - `FB_*`: a rebuilt genuine site, then a genuine site on its result, then a classical site, then a
    rebuilt genuine site with a shrunk mask.
  - All six ACCEPT, where `main` declines at l3oi. All six are **trace-identical to their twins**, with
    2b STRICT clean (2 or 3 verified, 0 violations, 0 unproven), and output byte-identical across sys,
    lifo, nofree and Guard Malloc.
  - r1B's `s_f32`/`s_f64`/`s_f80` and `w_f*` are in the 916-module stability sweep: stable.
- **Recursion and clones of clones.** Covered by r1B (`b4`, `b5`, `n1`–`n5`). `n4` is one of the 31 M3
  movers. Inner drains run in program order in a clone that `lowerCloneControl`'s size-1 backstop has
  already made a single block, so no layout reversal exists inside a clone.
- **A provisional return whose taint arises only in ROUND 2** (`R6`: `f` holds a 6.5 arm feeding a
  round-2 site `h(y, m)`).
  - The subject accepts it, **trace-identical to the twin**, where `main` and the oracle refuse it with
    the 3jru string.
  - It is correct: round-2 `propagateWorklist` asks the same predicate, the round-2 site is a root, and
    the late ask passes on the clone's classical verdict.

## Attack 4 — allocator stability and use-after-free

| set | modules | runs per module | variant | crash | null (nofree self) |
|---|---|---|---|---|---|
| r1B's families `alias_gen` / `2` / `3` / `5` / `6` (regenerated by TRACK_9BHG's `merge11/setup.sh`) | 506 | 31 | 0 | 0 | 0 |
| r1A's battery and the d88e twins (`merge9/p`) | 330 | 31 | 0 | 0 | 0 |
| r1B's probes (`r1B/p`) | 80 | 31 | 0 | 0 | 0 |
| my probes (`probes/src`, every `.c` except `lib.c`/`libf.c`) | 55 | 31 | 0 | 0 | 0 |
| lit corpus under Guard Malloc, subject and `main` | 2320 × 2 | 1 | — | 0 | — |

That is 971 modules × (3 modes × 10 + Guard Malloc) = **30,101** runs with 0 variance and 0 crashes.
The positive control fired, as described above. With 8e5r's containers, fp rebuilds do behave
identically across allocator modes.

## Attack 5 — pins (mutation matrix on the private build; full lit each; null control = the unmodified build, 2319 + 1 XFAIL)

| mutant | what | lit | killed by | A/B over the probe modules (M3/M3b/M3c: the 957 that existed then; M4/M6: all 971) |
|---|---|---|---|---|
| M1 | restore the early crossing (`propagateWorklist` crosses provisional returns) | **KILLED** 5 | the 4 `taint_accept_spec_classical_return*` fixtures and `…lift_owner_order` | — |
| M2 | drop the late 3jru ask (both entry points) | **KILLED** 2 | `taint_reject_spec_quantum_return_{branch,measure}` | — |
| M3 | revert the ordered scrub wholesale (`main`'s `Specialization.cpp`) | **KILLED** 2 | `taint_reject_scrubbed_handle_clone_arg{,_mixed}` | **31 movers** (30 A→D, `D1` owner move), null 0 |
| M3b | keep scrub-at-resolution, no mask recompute | **KILLED** 2 | same | the same 31, null 0 |
| M3c | remove the mask-0 skip | **KILLED** 1 | `…clone_arg` | 13 movers (12 A→D, `D1`), null 0 |
| M4 | re-add the `OldSite` erase-by-dead-pointer | MISSED | — (equivalent by construction, Attack 1) | **0 movers** over 971 modules × {sys, lifo, nofree}, null 0 |
| M6 | drop `TaintedSources.insert(Cand.Site)` | MISSED | — (equivalent modulo the fence, Attack 2) | **0 movers** over 971 modules (sys), null 0 |

- The `runOnFunction` shim has **no caller in the tree** (`grep`). A late-ask mutant confined to it is
  unpinnable by construction. This is PRE-EXISTING structure and is noted, not filed: every
  "both entry points" parity claim is about an entry point no test can reach.
- Mutant diffs are in `probes/mutants/`. Each binary's hash is in `probes/results/mutants.txt`.

## F-9D-1 (P3) — `Pending` is round-1 layout followed by the round-2 tail; the stale-mask residual is C-reachable

**Mechanism, measured with an instrumented private build** (`probes/mutants/Mdbg.diff` prints each
drain entry):
- `detectSpecializations` pushes the round-1 sites in layout order.
- `repropagateControlMerges` → `adjudicateTaintDelta` → `detectSpecializations(…, &live)` then
  **appends** every site whose argument became tainted only in round 2 (from a 6.5/4.5/controlled-IO
  merge `%out`, `SpecializeDetect.cpp:133`).
- `replanReseedSpecialization` grows the masks of the round-1 sites that read them.
- A round-1 site whose argument is a round-2 site's result is drained first, with that argument MASKED.
  When the round-2 site later proves classical, the scrub falsifies the mask, and the clone-reader
  clause declines.

**Repro** (`probes/src/R2.c` plus `lib.c`, two TUs, llvm-linked):

```c
int q = cq_theta(c, .5); int y = 0; if (q > 5) y = ext_f(7);   // 6.5 arm: y is round-2 taint
int t = h(y, c);            // round-2 site (h = k+1: classical verdict)
int u = g2(t, q);           // round-1 site, mask 01 -> replanned 11
return cq_measure(u) + cq_measure(q) + cq_measure(y);
```

| module | drain order | subject | `main` | oracle |
|---|---|---|---|---|
| `R2` | `[g2 det=11 now=11, h det=01]` | DECLINE `classical call result used as a quantum register` | same | same |
| `R3` (`h(q, c)`, h's argument round-1) | `[h, g2 det=11 now=10]` | ACCEPT | DECLINE | DECLINE |
| `R2T` (twin, `t = c + 1`) | — | ACCEPT | ACCEPT | ACCEPT |

- `R3`'s and `R2T`'s traces are **identical** (23 lines, 2b STRICT 3 verified, 0 violations). They
  compute the same program as `R2`.
- `R2Q` (round-2 site GENUINE, `hq = a + k`) accepts, with a stream byte-equal to `main`'s. There is no
  wrong-answer direction.

**What it falsifies (9bhg text, so the attribution is INTRODUCED):**
- `Specialization.cpp` ~1196: "`Pending` is in LAYOUT order (function, block, instruction) … a use laid
  out BEFORE its definition's block, or a loop-carried argument".
- `TaintPropagation.cpp` ~2920 (the clone-reader comment) and `TaintPropagation.h` ~1636 ("i.e. a use
  laid out before its definition").
- `taint_reject_scrubbed_handle_clone_arg_layout.ll`'s retirement trigger. An RPO drain would NOT
  retire the clone-reader clause's C population, and `R2` is a C-reachable subject for that clause.
- bd s07e's "(IR-level) … not observed from clang -O1" and its route "order the drain by per-function
  RPO". That route is insufficient: the round-2 tail must be merged into the dominance order.

The over-decline itself is PRE-EXISTING: `main` and the oracle decline `R2` as well. Filed as **bd
`test_C_libtooling-3zr4`** (P3, discovered-from 9bhg, related s07e). Correct the three comments in the
same change (L7: a record-only correction is not a correction).

## F-9D-2 (P3) — the ordered scrub's accept population is almost entirely unpinned

M3 (the ordered scrub reverted) and M3b (no mask recompute) are killed by exactly two lit fixtures,
both i32 `ya`/`yb` shapes. Over the 957 probe modules the same mutants move **31** modules, 30 of them
A→D (the 31st is `D1`, whose owner moves):
- `s_f32`, `s_f64` and `s_f80` (r1B), and `FA_*`/`FB_*` at three widths: fp mask shrink with a rebuilt
  downstream site;
- `D2` and `D3`: the d88e-lift composition;
- `R3`: a round-1 def;
- `n4`: nested;
- `a10`, `a11`, `c6`, `c8`, `own_ob9`, `s13C`;
- r1B's `w7`–`w15`, which are the former 8e5r-alias miscompile population.

M3c (no mask-0 skip) is killed by one fixture and moves 13 (12 A→D plus `D1`). Every mover is in the
SAFE direction. A regression is therefore an over-decline, not a miscompile, which is why this is P3.

The fp rebuild inside the ordered scrub, the one path the task singled out, has no fixture beyond
`spec_accept_fp_rebuilt_site_second_clone.ll`. M3 leaves that fixture green, because its mask never
changes. Suggested pins, each a two-TU accept with a twin-derived stream, `FA_F80`/`FB_F80` in three
allocator modes:
- `probes/src/FA_F80.c` or `FB_F80.c`;
- `D2.c`;
- `R6.c`. It is a provisional return whose taint arises only in the ROUND-2 `propagateWorklist` call.
  It ACCEPTS on the subject and declines under M1 (measured), so it would be the lit witness that the
  round-2 crossing decision also defers. M1 is killed today only by round-1 shapes.

## F-9D-3 (P3) — the l3oi fence's `CallBase`-only reader set is a contingent closure for 9bhg's larger scrubbed population

- `declineScrubbedHandleReads` asks only about `CallBase` users of a scrubbed value.
- 9bhg adds values to that population: every skipped mask-0 site and its cone (`u = g(t)`).
- A pre-`specialize()` stage that read such a value through a NON-call user on the conservative taint
  is not seen by the fence. The users in question are a loop-carried φ's entry incoming, a rail-bank
  store, a lift base, and a classical-condition mux.
- Each is closed today by another owner, measured:

| reader | probe | owner that declines |
|---|---|---|
| lift base | `D1` | d88e re-ask |
| rail-bank store | `B1` | `declineNonHandleBankStores` (`kMsgBankLiteralCell`), at run end (cepm's "FRAGILE") |
| rail-bank reader | `B2`, `B3` | `kMsgBankReader` (the D5 allow-list) |
| carried-handle seed | `Z5` (`a = g(t)` as the seed of the zujr cascade) | the loop layer, `loop-carried tainted value crosses iterations`; the twin with a classical seed is promoted and accepts |
| classical-cond mux | — | the pre-`specialize()` guard, on the conservative taint |

- None of these closures is stated at the fence, and none carries a trigger.
- The one to watch: the day the loop layer admits a TAINTED carried seed (today `Z3`,
  `a = cq_theta(c, .5)`, declines), `Z5` becomes an accept whose header φ carries the
  classical-verdict integer into trip 1, where it is read as a register. No promotion runs for it: the
  seed was tainted when `promoteLoopCarriedHandleSeeds` asked. The fence would not see it, because the
  scrubbed value's reader is the φ.
- Route:
  - either widen the fence to "any user that is itself still in `Tainted`", since a scrubbed operand of
    a tainted instruction is by definition a classical operand of a quantum op;
  - or write the trigger into `declineScrubbedHandleReads`' header and `loopCarriedHandlePhi`'s.

## Other probes (all in `probes/src/`, two-TU with `lib.c` or `libf.c`)

- `Z1`, `Z2` and `Z5` (loop-carried handle seeded by a spec result) and `L4` (a pre-loop Ry on a spec
  result) all DECLINE where their twins accept. These are new members of bd cepm's class
  (conservative taint read by a pre-`specialize()` stage), all safe-direction and identical on
  `main`/oracle.
- `L1`, `L2`, `L2b`, `L3`, `L5`, `R1` and `Z3` decline, and so do their twins.
- `R4`/`R5` (a 6.5 arm call that becomes a round-2 site) decline `control flow` at bd 35t0's precedence
  wall on every binary.

## What I did NOT attack

- r2A's surface: the circuits of the accept surface beyond twin-trace identity, the window before the
  late ask, and slot order.
- `invoke` sites; `cq_invert_*` escapes; `+Asserts`.
- A LOOP-carried stale-mask argument from C. Loops with Phase-6 sites decline at the loop layer first
  in every shape I built.
- 7.4 `BreakRegions`' raw fields (bd emof) holding a rebuilt fp site's OLD call. No break loop with a
  spec site reached that far.
- The ControlPlan's raw pointers after a rebuild: argued unread (`lowerRotations` ignores `plan`), not
  instrumented.
- A deterministic reuse instrument inside `specialize()` beyond `lifo`. Guard Malloc cannot see a read
  of a REUSED address, only of an unmapped one.
- I did not run the full `ctest`. lit ran in full on the null control and on each mutant, in the
  private build dir.
- ASan, for the platform reason above.
