# Track U — ADVERSARIAL REVIEW round 2 (Rule 13), bd `z9t1` — the UNATTACKED SHAPES

**Subject:** branch `undef-seed-zero`, tip `4044e49ea239bd4ce1a70457dbf5d17718714886`, worktree
`/Users/sorenwilkening/Desktop/CQ_undef`. Its binary: `cq-opt`
`a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff` — **bit-identical to the round-1
subject**, because the round-1 fix commit carries **no non-comment line** under `ir-pass/`.
**ORACLE** (main checkout `build/`): `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.

**YOUR FIRST ACT IS `shasum -a 256` ON BOTH.** A mismatch is a FINDING and you STOP.

## Why there is a round 2, and what it is NOT

Round 1 (`$SES/trackU/REVIEW_U_R1.md`, verdict CLEAR-WITH-ITEMS, 24 probes) attacked the predicate, the
`valueCarriesUndef`/`isa<UndefValue>` split, the L1/`specialize` argument, the flipped fixtures and the
corpus closure. Its one safety-direction finding (F-U1-1) has been **measured and HELD, not fixed** — the
measurements point away from restoring that decline and the disposition is with the owner. **Round 2 is not
a re-run of round 1** and is not about F-U1-1.

**Round 2 exists because the change's blast radius is module-wide and taint-independent.**
`collectAndSeed` normalizes **every** `@cq_theta_*` in **every** function **unconditionally**, before any
classification. Round 1 explicitly did not attack: **`cq_invert` / `EmitInverse`**, the **4.5 `switch`**,
**depth-2 nests**, the **6.5 classical-call arm**, **QRAM / I-O**, multi-function beyond two probes, and the
rail-bank composition beyond `_Bool b[2]`. `CLAUDE.md`'s measured hit rate is explicit that the next round
finds something, and that a round reviewing a *different* surface has found holes in an increment already
called cleared.

## Your role and limits (PROTOCOL.md matrix — reviewer row)

**NO build. NO suite.** At most ONE lit fixture re-run as a Rule-11 spot-check. Both binaries exist; measure
with them via the per-probe pipeline:
```
LLVM=/usr/local/opt/llvm@19/bin
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S p.c -o s1.ll
<BUILD>/ir-pass/cq-opt -load-pass-plugin <BUILD>/ir-pass/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll; echo exit=$?
python3 tools/free_pairing_check.py s2.ll
"$LLVM/clang" s2.ll <BUILD>/runtime/libcq_templates.a <BUILD>/runtime/libcq_runtime.a -o a && ./a
CQ_CTRL_DBG=1 <BUILD>/ir-pass/cq-opt … 2>&1 | head
```
Probes into `$SES/trackU/review_r2_probes/` in the MAIN checkout. Never write under
`ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Never relink under a running measurement; never
`pkill` by pattern. ⚠ Heavy concurrent load — slowness is contention, not a result, and is never a reason to
skip a probe and call the area clean.

## The rule being attacked (bd `z9t1`, five clauses)

1. An `undef`/`poison` **seed** at a **source** `cq_theta`'s arg-0 becomes a concrete zero at the allocation;
   CQ makes no claim about the C variable. 2. **Both** spellings compile (unconditional and in-region), which
   forces the EARLY placement. 3. **Silent.** 4. `cq_measure` of a never-quantum undef **keeps declining**.
   5. **Not total** — an undef through a phi not carrying this theta's result is untouched.

Implementation: `normalizeUndefRotationSeed` (`RotationLowering.cpp`), one call site in `collectAndSeed`'s
`IsTheta` arm. It **also** normalizes same-typed `UndefValue` incomings of any phi having this theta as an
operand. Read `$SES/trackU/IMPL_U.md` and `$SES/trackU/FIX_U_R1.md` in full first.

## The attack surface — leads, not a checklist (Rule 10: no bug here is shallow)

1. **`cq_invert` / `EmitInverse` — start here.** Rule 5 makes region-local reverse-play the on-demand undo,
   and an adjoint must reproduce the forward gate's operands exactly. Round 1's fix agent measured that a
   forward/adjoint pair is **two slots by itself** and still declines — good, but that is the *paired-undef*
   question. Yours is different: does normalizing a seed change what `EmitInverse` reproduces, or which rail
   it walks? Probe `cq_invert` over a normalized prep, over a chained theta on a normalized rail, and over a
   region whose arm theta was normalized.
2. **The 4.5 `switch`, depth-2 nests, the 6.5 classical-call arm.** Each claims a region and each has its own
   arm-classification path. A normalized seed is a `Constant` where an `UndefValue` stood — does any of them
   key on constant-ness, on `isa<UndefValue>`, or on pointer identity of the seed? bd `lo7u` is live in the
   switch path (eq-flags minted from a MEASURED scrutinee).
3. **`MergePhiPeel` and the round-2 fixpoint (L1).** The peel *manufactures* tainted values and
   `repropagateControlMerges` re-runs detection. The normalizer lives inside `propagate`, so it runs again —
   but does a phi **created by the peel** with an undef incoming now get normalized in round 2 when it did
   not exist in round 1? Is that a taint-GROWTH event owing `adjudicateTaintDelta`?
4. **F1 / F2 and the state-prep fences.** The record claims an undef seed is a `Constant`, so the rule can
   only ever produce a **FRESH prep**, which rules out the F2 α reading. **Attack that claim.** Can a
   normalized zero seed collide with a live value under F2 — i.e. become `state prep seed is proven equal to
   the condition register` — where the un-normalized module declined for a different reason or accepted?
   ⚠ Track F is landing a φ-descendant conjunct in F2 in parallel; you measure the **Track U binary only**,
   but say if you see an interaction the merge gate must test.
5. **Multi-function and QRAM / I-O.** The normalizer runs in every function including ones with no taint at
   all. Probe a module where the normalized theta is in a function that is later inlined, specialized, or
   cloned; and the QRAM / I-O sinks, which have their own recognizers.
6. **The rail bank composition.** Track L flagged `bool b[N]` uninitialized: today it declines at the store.
   Probe beyond `_Bool b[2]` and say what the composition will be when the bank lands.
7. **Widths and types.** Nine widths were checked at the accept level. Probe the fp widths under control, the
   `i128`/vector paths if reachable, and a type where `Constant::getNullValue` is not the obvious value.

## Verdict — `$SES/trackU/REVIEW_U_R2.md`

Per finding **F-U2-<n>**: one-line claim, the probe (path + exact commands + both verdicts), severity
(**over-ACCEPT / silent miscompile** · **over-DECLINE** · **fixture/record hygiene** · **documentation**),
minimal fix. End with **CLEAR** / **CLEAR-WITH-ITEMS** / **NOT CLEAR**, and say plainly what you did not
examine. Rule 2: verify-clean and "runs without crashing" are not evidence — read emitted STREAMS. A
clearance with no attack record is worth nothing.
