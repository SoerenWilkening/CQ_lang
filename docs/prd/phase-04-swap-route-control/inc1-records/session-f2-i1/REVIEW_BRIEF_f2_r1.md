# Rule-13 review brief, round 1 — Track C: the F2 `CondWire` narrowing (bd `drbq.14`, owner ruling 2026-09-11)

Branch `f2-condwire-narrowing` (off `main` 0c7380c), worktree `/Users/sorenwilkening/Desktop/CQ_f2`, build in
its `build/` is current (DO NOT rebuild, DO NOT edit `ir-pass/`, `include/`, `tests/`, `tools/`). Tree state
under review: `IMPL_f2.md` beside this file. The ORACLE (pre-change) binary is
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so` (main 0c7380c; read-only).

## What changed (`git diff main -- ir-pass/src ir-pass/include`; one file, `ArmClassify.cpp`)

* `f2SeedPinnedByLiveRegister` (≈`:1301`) gains `const SmallPtrSetImpl<Value*> &CondWire`; at the equality
  TEST (≈`:1475`) a pinned value `V` is a collider only if `!CondWire.count(V)` (type equality and
  `f2Exact(V,S)==Seed` unchanged). The caller (≈`:3153`) builds `CondWire` by CALLING R4's own
  `railWireClosure(Region.Condition, BackwardOnly)` and the same over every `P` in `Prov` (≈`:2574`).
* The literal fast path (17 lines, ≈`:3011-3028` on `main`) is DELETED; measured subsumed (fast path deleted
  AND conjunct disabled ⇒ all 40 F2 fixtures still decline).
* No `DS_Warning` (it would fire on every narrowed accept, i.e. every Grover prep the ruling enables).
* 19 F2 fixtures `git mv`'d to accepts (IR byte-unchanged, verified 19/19), 21 byte-unchanged declines, 8 new
  fixtures (4 accept / 4 decline), 3 STRICT e2e slices. Corpus sweep over 1776 pre-existing fixtures:
  `RCDIFF=19 DIAGDIFF=0 OUTDIFF=0`, all 19 DECLINE→ACCEPT with the F2 string.

## The owner's ruling and the trade it accepts (challenge the ARGUMENT, not the ruling)

The owner (2026-09-11) refused the `int b1` workaround and a new `cq_*` prep function and asked for the
over-decline to go. The narrowing rests on TWO arguments of DIFFERENT kinds (IMPL §7 item 1 — attack them
separately):

* **α (arm-edge pin, the self-controlled rival).** `int r=k; if (q==k) r=cq_theta(q,θ);` is byte-identical
  after `-O1` to the genuine prep `int r=k; if (q==k) r=cq_theta(k,θ);`. The narrowing reads it as the prep.
  Argument: every UNFOLDED spelling of a rotation on the condition's wire is refused (SCOPE §2.2's theorem:
  `railWireClosure` inserts its seed first, so `RotBase ∈ CondRails ⇒ R4 declines`; measured 32/32 across
  four fences — 2c `condition predates a non-diagonal gate` fires FIRST for 14 of 15, R4 for the alias, F1
  for the mux form, `condition data use neither escaped nor measured` for rotating the flag), so the rival
  has no lowering CQ ever committed to and "decline → prep" converts nothing that compiled. **Attack:** find
  an unfolded self-controlled spelling that ACCEPTS today (plain C first — `-O1` sinking/hoisting, casts,
  in-place `add/xor` relabellings on the condition rail, a `select` spelling, the 6.5 arm, the switch, a
  clone with the register as argument, a loop). If one exists the theorem has a hole and the narrowing
  silently reinterprets a program CQ lowers.
* **β (straight-through-edge pin, the no-cloning-mux rival).** `int r=q; if (q!=k) r=cq_theta(k,θ);` folds
  the pred incoming `q` to `k` on the `q==k` edge and becomes the prep's IR. Argument (IMPL §7): LVI's edge
  range is a SOUND over-approximation, so a singleton means `q == k` on every execution taking that edge;
  on that flag subspace the rail is the product basis state |k⟩ with no superposition to clone; the rival's
  only reversible realisation (a controlled copy into a fresh |0⟩ rail) yields |k⟩⊗|k⟩ there — exactly
  what preparing |k⟩ yields; the other subspace is identical in both readings. **Attack:** this rests on
  LLVM's LVI being sound (the same assumption `-O1` used to fold) — construct edges where the pin is a
  singleton by LVI but the rail's basis label is NOT constant on that edge at RUN time under CQ's
  lowering (a rail relabelled in place between the compare and the branch; a compare on a DIFFERENT wire
  than the rail read at the merge; a register whose SSA value is pinned but whose PHYSICAL rail was
  RAUW'd to a shared handle by `lowerRotations` — the F-B1R1-1 name-vs-wire class; poison/undef incomings;
  a compare `-O1` rewrote sideways so LVI's subject is a sibling rail). Also: the alias reading makes `r`
  and `q` ONE physical register on that edge — is there any LATER consumer for which "one register named
  twice" and "two registers in |k⟩⊗|k⟩" differ (a later in-place gate on `r` that the alias reading would
  apply to `q`; `cq_measure(q)` after `r` was rotated; the whole-DAG spine's free of one but not the other)?
  Argue from the state vector, and say whether the pass's OWN downstream fences (3d8q's stale-reader hole is
  OPEN — a stale `cq_measure(q)` reader accepts today) would catch a divergence.

## Where to look

1. **`CondWire` is a strict SUPERSET of `{Cond} ∪ Prov`** (IMPL §7 item 3 — `railWireClosure` crosses a
   chained theta's arg-0 where `condProvenance` stops). Is it TOO wide? A register that is on the closure
   by a chained-theta hop but is NOT what the condition reads at the branch — pinned to the seed, rotated
   in the arm — now escapes F2. Construct it.
2. **`BackwardOnly`.** The closure is backward from the condition. A register FORWARD on the same wire
   (rotated after the compare, before the branch — 2c's territory) — does the narrowing depend on 2c firing
   first (IMPL §7 item 5: "a 2c widening can invalidate the narrowing")? Write the retirement trigger
   precisely and measure a mutant with 2c disabled.
3. **The forward evaluation half of F2** (abstract evaluation over the tainted user graph, `ConstantRange`,
   `ConstantFold*`, `KnownBits`, `kF2MaxSteps`): the exclusion is at the TEST — does a pinned value ON the
   wire still SEED the forward walk so that a NON-wire derived value (`t = q >> 31`) is still caught? IMPL
   §7 item 6 says the anchor mutant does not flip `nonwire_still_collides` "because LVI answers about the
   lshr pin directly" — is there a derived non-wire register LVI CANNOT pin directly that only the forward
   walk from a now-excluded seed would have reached? That would be a new over-accept.
4. **The fp anchor** (F-R4-1; `fcmp oeq/une` against a `ConstantFP`, ±0.0/NaN refused): the two flipped
   `fcmp_{oeq,une}_folded` fixtures — the fp register pinned by the region's own `fcmp` IS the condition's
   wire; fine. But an fp register on the wire pinned via `oeq` with a DERIVED fp value one hop forward
   (`fcmp_oeq_derived` stays a decline per IMPL) — confirm by measurement, and try a hop through `fneg`/`fabs`.
5. **i1.** Both edges of an `i1` condition pin; the i1 seed always collides with the condition — that is the
   whole point. But an i1 CONDITION that is a COMPARE FLAG (`_Bool c = (q==5); if (c) r = cq_theta(c,.9)`):
   `c` is a template rail, NOT the theta register `q`; is `c` on `CondWire` (it is the condition itself —
   yes); and `q`? If the seed collides with `q`'s pin (`q==5` on the edge, seed 5, `int r = 5`), `q` is in
   `Prov` — on the wire — excluded. The rival there is "rotate q under `c`" = rotate the register the flag
   was minted from, with the flag still live: R4? 2c? Measure the unfolded form.
6. **`-O1` reachability of every new/flipped accept**: write the plain-C spelling for each; for the 4 new
   declines confirm they are RED on the branch binary for the right reason (not pre-empted by an earlier
   fence — an earlier fence firing makes the fixture pin nothing about F2).
7. **The 25 MISSED / 1 DIRTY in the 34 PRE-EXISTING state-prep accepts** (IMPL §7 item 2; identical on the
   oracle): confirm the DIRTY is the harness, and say which of the 25 MISSED matter for THIS change (an
   injected uncontrolled `cqrt_ry` on the CONDITION register after the flag's free is the drbq F-C1D-4
   class — if any flipped accept is blind to it, that is a coverage item).
8. **Owner's file**: `V0.c` still `control flow` (bd `b6ap`); `C2.c`/`M1.c` `bare i1 register condition`
   (`l4x4`); `M2.c` (compare twin) rc 1 → 0. Re-measure and read `M2.c`'s trace line by line against the
   analytic prep stream.

## Method

Read `SCOPE_f2_i1.md`, `IMPL_f2.md`, `probes/README.md`; run the probe family and every touched fixture
yourself on BOTH binaries; write your own corpus under
`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/f2_review/`
(plain C at `-O1` first, hand IR second; recipe: `/usr/local/opt/llvm@19/bin/clang -Iinclude -include
CQ.h -O1 -emit-llvm -S`, then `build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so
-passes=cq-lowering -S`, link `libcq_templates.a` then `libcq_runtime.a`, run, `tools/free_pairing_check.py`).
Every accept you find must be argued from the state vector (Rule 2), never from `opt -verify`, trace
plausibility, or stage 2b. Grade each finding CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE /
LEAK / DOC with the exact program, both binaries' outputs and the analytic reason. Verdict: BLOCK (any
CONFIRMED miscompile), CLEAR-WITH-ITEMS, or CLEAR.

Also: the implementation agent's full `ctest -j6` was at 219/390 passed, 0 failed when it handed off, under
load. Check `ps` for a still-running ctest in this worktree; if none, run `ctest --test-dir build -j6
--output-on-failure` ONCE yourself at the START (it is the gate this branch still owes) and report the exact
pass line and wall time in the report's first section.

Write the report to `session-f2-i1/review_f2_r1.md` and your probes to `session-f2-i1/review_f2_r1_probes/`
(with a runner so round 2 can re-run them). Final message to the orchestrator ≤30 lines: the verdict, the
ctest line, each finding in one line with its grade, and the α/β attack outcomes.
