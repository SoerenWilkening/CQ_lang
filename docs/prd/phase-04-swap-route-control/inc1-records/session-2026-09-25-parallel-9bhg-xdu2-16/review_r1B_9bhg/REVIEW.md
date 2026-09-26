# Rule-13 round r1B on bd `test_C_libtooling-9bhg` (commit `30529716`): specializer changes and emitted circuits

Reviewer r1B, 2026-09-25. Independent round. The concurrent round (r1A/9A) covers the taint fence
(`returnTaintIsSpecProvisional`, the early and late 3jru asks, the window between them); this
round covers the specializer changes and the circuits the change emits. Not committed.

## Verdict: **NOT-CLEAR**, and it is gated on one pre-existing bead (bd `8e5r`), not on 9bhg's own logic

9bhg's specializer logic held up everywhere I attacked it. The ordered scrub, the mask
recomputation, the mask-0 skip, the old-site pointer scrub and nested specialization all produced
correct streams on every accept I built. That is 40+ new two-TU and single-TU probes, each read by
hand or byte-identical to preE where preE was right.

It still cannot land by itself. **Landing it turns oracle LOUD DECLINES into SILENT
MISCOMPILES on plain-C programs** (F-9B-1). That happens through a pre-existing dangling-key defect,
which 9bhg did not introduce and which the oracle already exhibits. 9bhg widens its population.
Under the Prime Directive a decline→miscompile transition blocks a landing. The fix is small, in
another file, and a trial of it removed every exhibit (F-9B-1, "route"). Land bd `8e5r` first or in
the same change, then re-run the alias families below as the witness.

| id | sev | one line | bead |
|---|---|---|---|
| F-9B-1 | **P1** | Dangling `taint.Tainted` keys left by `lowerShadowMemory`/`lowerQramReads` are reused by a Phase-6 clone's CLASSICAL instruction. Module `lowerOps` then lowers it as quantum: `cq_template_mul_i32_hl(7 /*as a handle*/, m)`. That is a silent miscompile from plain C. It is pre-existing (oracle 28/30 runs), **and 9bhg adds customers**: `w12` is declined by the oracle 2/2 and miscompiled by the subject in 11/12 runs | **8e5r** (new) |
| F-9B-2 | P2 | 9bhg's headline accept depends on the allocator. The same producer's dangling key aliases the classical clone's `ret` value, and the NEW late re-ask then refuses a correct program: `v12` (f returns `h(q,m)`, h=k+1, plus a shadow array in `main`) gives 20/20 `quantum value returned across a function boundary`. The fp3 fix closes one producer, and the text claiming the aliasing is closed / unconstructed is falsified (L7) | 8e5r (same root) |
| F-9B-3 | P3 | M18 "MISSED — address reuse did not recur on the mutant build" is really a flake from one run to the next, not a build difference. My M18 build is killed 3/5 under the system allocator and 5/5 under a deterministic LIFO allocator. The fp3 fixture is a flaky pin | — |
| F-9B-4 | P2 (pre-existing) | `lowerLoops`' `AnyTainted` scan calls `I->getFunction()` on dangling `Tainted` keys, a UAF read. Under a LIFO allocator it SIGSEGVs on 4 shipped fixtures, on the oracle as well | **um24** (new) |
| F-9B-5 | P3 | Instrument: `probes/ab_sweep.py`'s docstring says `--null` runs the SUBJECT twice, but the code runs REF twice. The verdicts vary from run to run (F-9B-1), so a REF-only null cannot see flakiness in the subject. The corpus also has an empty quadrant for this class | — |

bd `j8sk` has a cross-reference note appended. It said "lowerOps … unconstructed, would be a
miscompile", and that case is now constructed.

## Binaries and instruments (hash prefixes; every one re-verified after the owner's pause)

- SUBJECT `cq-opt` `8b837d1f79574156` (frozen `cq-opt.new3`, which equals the worktree `build/`).
  ORACLE `983f9361` `438c77bf45c02e3e`. preE `aad63450` `63e2f0bbd3708c92`.
- The r1B private worktree `scratchpad/r1B_wt` sits at `30529716` plus an **inert-unless-env**
  instrumentation (`probes/tools/r1b_instrumentation.patch`):
  - `CQ_DANGLE`: a live-key detector at 16 checkpoints (module and clone taint). Every key of
    `Tainted`, `BirthOrder`, `HandleWidth`, `StaleDeclined` and 25 other side tables is checked
    against the set of live Values.
  - `CQ_ALIAS`: any instruction of a `__cq_q_*` function that is a key of the MODULE taint. This is
    impossible by C-Taint disjointness, so any hit is a reused dangling address.
  - `CQ_DELHOOK`: a `CallbackVH` on every key that reports deletion while it is still a key.
  - Allocator modes: `CQ_NOFREE` (no reuse, which is the reference), `CQ_REUSE` (a deterministic
    LIFO exact-size-class free list, i.e. maximal reuse) and `CQ_SCRIBBLE`.
- **Null control:** the instrumented build with no env set vs the subject over all 2288 fixtures
  gave **2288/2288 same**. The restored build after each mutant is bit-identical to the instrumented
  one (`137264c9…`, twice). One stale-rebuild artefact was caught: the build dir held the M18 binary
  after a same-second restore. It was re-measured before any use.
- **Positive control:** the M18 mutant (old-site pointer scrub deleted) on
  `spec_accept_fp_rebuilt_site_second_clone.ll`. `CQ_ALIAS` reports
  `__cq_q_lmix_11 … %cqq.out = call i32 @cqrt_alloc_f80` at post-specialize, and the module declines.
  The fix-present build reports nothing.
- `scratchpad/r1B_ora`: the oracle plus ONLY the allocator modes
  (`probes/tools/r1b_oracle_allocator_only.patch`). Every "pre-existing" below is attributed with it
  or with the frozen oracle and preE binaries.

## F-9B-1 (P1) — the dangling-key alias is a silent miscompile, and 9bhg adds customers

**Mechanism.** At `QramLowering.cpp` ~3174/3183 and ~3467–3496, the store, load and GEP that
`lowerQramReads`/`lowerShadowMemory` replace are erased with `eraseFromParent`. Only `DeadCast` is
erased from `taint.Tainted`. `specialize()` then allocates the clone bodies. A clone's classical
`mul nsw i32 %0, 7` (128 B, the same size class as the freed `StoreInst`) lands on a freed store's
address. The module-level `lowerOps(M, wd, taint)` walks clone bodies and lowers it.

The `CQ_DELHOOK` and `CQ_ALIAS` trace of `k65` shows the chain in full: `store i32 7`/`store i32 9`
are deleted after `pre-shadow`, and then `R1B-ALIAS stage=post-specialize fn=__cq_q_k1_10 …
%3 = mul nsw i32 %0, 7`.

**Repro, pre-existing** (`probes/alias_gen3/k65.c`, lib `int k1(int a,int b){return (a*7)+b;}`):

```c
int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
int arr[8] = {0}; arr[q2 & 7] = 7; arr[q & 7] = 9; int r1 = arr[(q2 + 1) & 7]; acc += cq_measure(r1);
int u = k1(m, q); int v = k1(n, q2);
return acc + cq_measure(u) + cq_measure(v) + cq_measure(q2) + cq_measure(q);
```

Emitted in `__cq_q_k1_10` (subject **30/30** runs, oracle 28/30, preE 29/30):

```llvm
%h_op1 = call i32 @cq_template_mul_i32_hl(i32 7, i32 %0)      ; the constant 7 used as a HANDLE
%h_op  = call i32 @cq_template_add_i32_hl(i32 %1, i32 %h_op1) ; a handle id used as the add's literal
```

The trace reads `cq_template_mul_i32_hl(h7, 5)`, applied to the rail h7, which is **already freed**.
It then reads `cq_template_add_i32_hl(h1, 10)` where the correct gate is `add_hl(h1, 35)`. The opt
exit code is 0, the module is verify-clean, and `free_pairing_check.py` STRICT reports
`3 verified, 0 violation(s)`. The no-reuse reference (`CQ_NOFREE`) and the oracle's minority output
(492b3bf852) are the correct stream (`probes/alias_gen3/k65.nofree.s2.ll`,
`k65.ora.*.s2.ll`).

**9bhg's new population** (`probes/alias_gen6/`). `w12` is k65 plus the ya shape
`int t9 = h(q, m); int w9 = g(t9);`. The ORACLE declines it with `classical call result used as a
quantum register` (2/2). The SUBJECT accepts it and emits the wrong `mul_hl(7, m)` in 11/12 runs.
The same holds for `w9` (10/12) and `w15` (7/12). The ordered scrub is what turns the oracle's loud
decline into an accept, and the accept then runs into the pre-existing lottery. "Pre-existing" is
true of the defect and false of its population.

**Other symptoms, all nondeterministic from run to run on one binary:**
- 17/216 generated programs (`alias_gen/`) flip between accept, `cq uncompute: tainted handle
  reaches an unrecognized user`, and **exit 134**. The exit 134 is `VerifierPass` →
  `report_fatal_error`, because an aliased classical `sext`/`trunc` produced a broken module.
- 20/128 (`alias_gen3/`) yield two distinct ACCEPTED modules.
- `k74` (`alias_gen2/`) is miscompiled 19/20 on the oracle and the same on preE. The subject
  declines it 20/20 (F-9B-2).

**Why no gate saw it.** Over the corpus, 100 fixtures carry a dangling `Tainted` key at
`pre-specialize` (`results/dangle_corpus.tsv`). **None of them builds a clone** (measured). The
corpus A/B, the max-reuse sweep and the clone-alias sweep over all 2288 fixtures are therefore
clean in both allocator modes (`results/alias_corpus_*.tsv`: 0 hits). That cleanliness is evidence
about an empty quadrant, not about this class: §4k's lesson again, applied to bd 1yeu's shape.

**Route: a trial in the private build, NOT a clearance.** Erase `Tainted`/`BirthOrder`/
`HandleWidth`/`StaleDeclined` in the two `ToErase` loops. All **49** previously flaky or wrong
programs (gen, gen3, gen5, gen6, k65, k74, v12) then produce the no-reuse reference output
deterministically: 12 malloc runs plus 3 LIFO-reuse runs each, 0 mismatches
(`results/fixchk.txt`). The trial fix's corpus A/B vs the subject is in `results/ab_fix8e5r.txt`
(see the end of this file). The other producers the detector lists stay open under bd `j8sk`: the
cq_phi delete, the IO-sink erase, the control-emitter compare erase, the volatile dead store, and
the break `exit.cond` select.

## F-9B-2 (P2) — the headline accept is allocator-dependent; the "closed at its source" text is falsified

- `probes/alias_gen5/v12.c` is exactly the bead's headline, `f(m){q=θ(m); return h(q,m);}` with
  `h = k+1`, plus a two-store shadow array in `main`. The subject gives **20/20**
  `in function f: cq taint escape: quantum value returned across a function boundary`. The
  no-reuse reference compiles it.
- `CQ_ALIAS` shows why: `__cq_q_h_01 … %3 = add nsw i32 %1, 1`, the classical clone's RETURN
  value, is a key of the module taint. The new late `declineQuantumReturnCalls` reads it and refuses
  the clone's call site in `f`.
- `v1`, `v2`, `v10` and `v11` flip 5–11/12 in the same way. This is the fp3 mechanism through a
  producer the 9bhg fix does not touch.
- Two statements are falsified, and per L7 they should be corrected at the source when bd `8e5r`
  lands:
  - The `Specialization.cpp` comment *"Every stage after this one that reads `taint.Tainted` by
    pointer (`lowerOps` over the whole module) was exposed to the same aliasing before; it is
    closed here at its source"* is true of the one producer and false of the class.
  - TRACK_9BHG §3 item 6 and §7 item 6 say *"I did not construct a case where that aliasing
    miscompiles"*. F-9B-1 constructs one.
- The safe direction holds only for the re-ask. `lowerOps` is the unsafe reader (F-9B-1), exactly
  as §7 item 6 predicted.

## F-9B-3 (P3) — M18 is a flaky kill, and the fixture is a flaky pin

On the `spec_accept_fp_rebuilt_site_second_clone.ll` fixture, measured on my M18 build:

| binary | system malloc | LIFO reuse |
|---|---|---|
| M18 | `1 1 0 1 0` (killed 3/5) | `1 1 1 1 1` (killed 5/5) |
| fix present | 0/5 | 0/5 |

- The implementer's "did not recur on the mutant build" is consistent with one unlucky run.
- A harness that runs each fixture once scores this mutant KILLED or MISSED by lottery.
- A deterministic pin needs either scrub-on-erase with a live-key assertion at the late slot (what
  `CQ_DANGLE` does, which pins M18 as `4 dangling Tainted keys at post-specialize` against 0,
  whatever the allocation order), or a WeakVH/`CallbackVH`-keyed `Tainted`.

## F-9B-4 (P2, pre-existing) — the `lowerLoops` UAF read

- The per-function "cheap skip" at `LoopLowering.cpp` ~7074 dereferences every `Tainted` key.
- Under `CQ_REUSE` it gives EXC_BAD_ACCESS in `Instruction::getFunction` ← `cq::lowerLoops` on
  `iosink_reject_mux_literal_callee`, `lowering_reject_break_uncollected_clone` and
  `lowering_reject_inplace_rail_stale_w1_xor_{bareout,derived}`, with exit 139 on the oracle-only
  allocator build too. `lowering_io_controlled_putchar` crashes intermittently.
- The freed keys are the erased `putchar`/`printf` sink and the break `exit.cond` select
  (`CQ_DELHOOK`).
- These are the only 5 DIFFs in the 2288-fixture max-reuse sweep (`results/reuse_corpus.tsv`).

## What held: the specializer changes, attacked one by one

**(a) Ordered scrub and mask recomputation.**
- **Shrink, non-zero:**
  - `a10`: `h(q,m)`/`h(m,q2)`/`g2(t1,t2)`, mask 11→10. Stream `add_hl(q2,1)`, then
    `add_hl(·, 6)` = q2+1+6. Correct. preE passed 6 as a handle.
  - `a11`: `gfirst(t1,q)` flips to a CLASSICAL verdict, `cq_measure(u)` is deleted, exit 12.
    Correct.
  - `s_f64`/`s_f32`/`s_f80`: fp mask shrink with REBUILT sites. `fadd_f*_hl(h3, 6.0)` is correct,
    and **preE aborts (134) on all three**.
  - `c6`/`c8`: classical `u` feeding a select or an add. `addc(q2, 1)` and `addc(q2, 19)` are
    correct.
- **Grow:** no subject exists, by argument. Between the last re-plan (inside
  `repropagateControlMerges`) and `specialize()`, every `Tainted.insert` (IO tape, QRAM `Out`/`Ret`,
  shadow `Out`, promote) replaces an already-tainted value. Inside `specialize()` taint only shrinks,
  and a rebuilt call is re-inserted before the next site. A Pending site's arguments are values
  allocated before any free, so they cannot alias. M10's re-classification is reachable only on
  shrink, where it cannot newly reject; I agree it is equivalent.
- **Layout vs dominance (s07e):** I could NOT construct a WRONG answer. A site built from a stale
  mask has its stale argument in a MASKED slot. That argument lost its taint only through a scrub,
  and every scrub records every value it removes in `ScrubbedByReturnTaint`. So the clone-reader
  clause always sees it, and the worst case is a decline. M11 is equivalent for the same reason. For a loop-carried φ argument this is ARGUED, not
  constructed.
- **Mask-0 skip:** a site admitted into an earlier cone has no tainted operand left. A Phase-6
  callee has no quantum primitive (`scanBody`), so the call is really classical. The recorded result
  keeps any round-1 gate on it fenced (`c5`/`yc`/`xa`/`xb`/`xh` still decline at l3oi).
- **Nested specialization:** `n1`–`n5` are correct. For example, n4's
  `t = out3(q,n)` is classical 23 and `out1(q,t)` gives `add_hl(q,2)`/`add_hl(·,46)`. preE was
  wrong there.
- **Recursion and mutual recursion:** `b4` exits 30 (6+7+8+9) and `b5` exits 49, both correct. The
  quantum twins `b4q`/`b5q` are late-declined.
- **Same callee at several masks:** `a10`.
- **Widths:** i8/i16/i64/i1 spec sites decline on all three binaries at a pre-existing wall. fp
  provisional returns decline at `tainted value returned at non-i32 width` on all three. So 9bhg's
  accept surface is i32 returns only, plus fp inner sites reached through an i32 return (`b1`,
  byte-identical to preE, exit 42).

**(b) The old-site pointer scrub.** Across 575 modules (my probes, the implementer's 31, and the
generated families), `specialize()` itself adds **0** dangling keys: the pre-specialize and
post-specialize counts are equal (`results/specialize_delta.txt`). No `BirthOrder` is ever
assigned to a Phase-6 site; I checked this by grep and it is true. No `Function` is ever erased, so
`SpecHandleArgMask`'s keys stay valid.

**(c) l3oi preservation.**
- The round-6/7 repros `xa`, `xb`, `xh` and `yc` still decline at the l3oi fence.
- `ya` and `yb` now accept, and I read the streams: they are correct.
- `xd`, `yn`, `spc` and `sye` are byte-identical oracle vs subject.
- I could not reopen l3oi one boundary out: a provisional return never taints its caller, so no
  round-1 gate is minted on it.
- `lit --filter 'scrubbed_handle|spec_classical_return|quantum_return|clone_arg'`: 35 passed.

**Emitted circuits of the new accepts** (traces in `probes/battery/`). Each item is byte-identical
to preE unless stated.
- a1: an angle from a classical return, `ry(h1, 0.6)`.
- a2: a QROM index from a classical return, `addc(q2,6)`/`and_hl`/`qram_load`.
- a5b: a kickback literal `icmp_sgt_hl(q2, 6)`.
- a6: a volatile store, then `addc(q2, 6)`.
- a7: a loop bound. f is called 7 times and allocates 7 fresh qubits; `addc(q2,3)` runs 6 times.
- c1: an in-place Ry arm on a classical spec result, which becomes state prep
  `alloc(6) + ry_controlled`. Correct, and the same on all three binaries.
- Every one is STRICT 2b clean (`0 violation(s), 0 unproven`). Where the CENSUS reports "left dirty"
  template rails, they are clone out-rails left allocated in `main` (the Rule-6 accepted leak, not
  freed). I did not compare them against preE cell by cell.
- The quantum-verdict twins (a1q, a2q, a5bq, a6q, a7q, b1q, b4q, b5q, n5, rq*) all decline with
  the 3jru string, with no crash.
- Switch scrutinee (a4), stored array index (a3) and 6.5 arm (a5): these decline at pre-existing
  walls on preE and on the subject.

**Re-measured claims (Rule 11), null control first:**
- Corpus A/B oracle vs subject: 2288, null 0, **6 D→A**, the own fixtures. Reproduced.
- Multi-TU: 22, null 0, 0 movers. Reproduced.
- Standalone e2e: 432, null 0, 0 movers. Reproduced.
- SUBJ vs SUBJ over 22+432: 0.

## What I did NOT attack

- The fence logic: `returnTaintIsSpecProvisional`, S1–S3 and the early-skip premise conjunct. That
  is the concurrent round's surface.
- `invoke` sites, `cq_invert_*` escapes of a provisional value, and composition with bd `xdu2.16`.
- I built no `+Asserts` or ASan binary. ASan's quarantine would SUPPRESS the reuse this class needs;
  the allocator modes plus the live-key and clone-alias detectors are the stronger instrument here.
- I did not re-run the full `ctest`. I ran `lit` only as the 35-fixture filter, and ran it in the
  subject's build dir (it writes `%t` there; no rebuild).
- I did not enumerate the other `j8sk` producers beyond the detector's list, and I did not trial-fix
  them.
- I did not search for a WRONG accept on 9bhg's population beyond gen6 (3/15 found).
- I did not construct a mask GROW or a layout WRONG answer. Both are argued unreachable above, and
  neither is proved.

## Addendum: the trial fix measured against the corpus

`results/ab_fix8e5r.txt` compares the subject (REF) against the trial fix build (the subject
sources plus the inert instrumentation plus the scrub in the two `ToErase` loops) over all 2288
fixtures. Null control: 0 of 2288. Movers: **0**.

That is the expected outcome, and it is NOT evidence that the fix is safe. The corpus has no member
of this class, so the only witnesses are the 49 alias-family programs above, which all move to the
reference output. The trial fix still owes its own Rule-13 round and a deterministic pin. The
candidate pin is a live-key assertion over `Tainted` at the late slot, which is what `CQ_DANGLE`
does.
