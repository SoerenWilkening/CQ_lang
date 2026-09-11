# Brief — Track C: narrowing F2 by excluding the condition's own wire closure (bd `drbq.14`'s "i1 state-prep width is OUT" ruling, REVERSED by the owner 2026-09-11)

Written 2026-09-11 by the orchestrator (session `01NHxGVinGBKbb499HFCuwhT`). Owner ruling the same day,
verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also WE DO NOT WANT ANOTHER cq function. it should just be
an application of gates … I dont see the need for the over-decline."* The trade was put to the owner
plainly (a self-controlled in-place rotation written by mistake compiles as a prep instead of declining)
and was not vetoed. This increment is that narrowing. It is an ACCEPT-WIDENING of a Rule-13-core fence
that lost four adversarial rounds in a row (drbq Inc 4) — budget TWO rounds, and build it exactly as
`SCOPE_f2_i1.md` §5 says.

You are the IMPLEMENTATION agent. Model: opus. Worktree `/Users/sorenwilkening/Desktop/CQ_f2`, branch
`f2-condwire-narrowing` (from `main` 0c7380c), its OWN `build/`. **Never write under
`/Users/sorenwilkening/Desktop/CQ_lang/`** — its `build/ir-pass/cq-opt` + `libCQPass.so` are the frozen
ORACLE. Do NOT commit, do NOT push. Report only what you ran.

## 0. Read first

`SCOPE_f2_i1.md` beside this file, ALL of it (§0 measurements, §1 F2 as shipped with file:line, §2 the
fence audit — 32/32 unfolded self-controlled spellings decline today, and the theorem behind it:
`railWireClosure` inserts its seed first so `RotBase ∈ CondRails ⇒ R4 declines`, §3 the flip list — 19
flip / 21 stay, each confirmed by a one-value mutation, §5 the design, §6 hazards, §7 cost) and its
`probes/` README. Then `CLAUDE.md` (Prime Directive; Rules 1, 12, 13, 17, 19; the state-prep paragraph —
F1/F2, the four rounds, "THE `i1` STATE-PREP WIDTH IS OUT"; Build & Test), `control-in-place-PRD.md` §14,
`bd show test_C_libtooling-drbq.14`, bd memories `f2-syntactic-enumeration`, `control-in-place-drbq`.

## 1. The change (SCOPE §5.1 — do it THERE, not elsewhere)

- ONE new conjunct at the equality test (`ArmClassify.cpp` ≈`:1361`): a pinned value `V` is not a collider
  when `CondWire.count(V)`. **Exclude at the TEST, never at the ANCHOR** — SCOPE H-6 measured that
  excluding at the anchor flips all 40 (the forward evaluation would lose its seed).
- `CondWire` built at the caller (~6 lines) by CALLING R4's own `railWireClosure` / `condProvenance` —
  never a second spelling of "the condition's wire" (Rule 14; the drbq Inc-3 (b′) lesson).
- DELETE the now-dead literal fast path (≈`:3011-3028`, ~18 lines) — SCOPE says it is subsumed; prove it by
  measurement (with the fast path deleted and the conjunct absent, the same fixtures must go red).
- `DS_Warning` at the narrowed site: SCOPE §5.4 — implement what it recommends; if it recommends none,
  say so in IMPL §1 with the reason.
- The string `state prep seed is proven equal to the condition register` STAYS for the 21 non-wire
  colliders; do not rename it.

## 2. Rule 12 — the flip list is the test plan

- The 19 flipping fixtures (SCOPE §3 (A)): each is REWRITTEN as an ACCEPT under its existing name or a
  `git mv` to the accept name the family uses, with a header that (a) quotes the 2026-09-11 owner ruling,
  (b) states which reading the IR now gets (the prep) and which rival it silently absorbs (the
  self-controlled rotation / the pinned-edge alias), and (c) pins the emitted stream with count prefixes.
  The one-value MUTATIONS SCOPE used to confirm each flip become the family's decline discriminators
  where they are not already fixtures.
- The 21 staying fixtures (SCOPE §3 (B)): byte-unchanged, re-run, listed in IMPL §3 with rc.
- NEW: `..._stateprep_selfcontrolled_folded_as_prep.ll` (the H-1 shape `int r=k; if(q==k) r=cq_theta(q,θ);`
  — ACCEPT-AS-PREP, header states the trade and the 2026-09-11 ruling); `..._reject_stateprep_nonwire_still_collides.ll`
  (a register NOT on the wire pinned to the seed — the F-R1-1 `t = q>>31` shape — still DECLINES: the
  discriminator that the narrowing is the wire and not "everything"); the H-2 straight-through-edge shape
  from `bc1.c` (ACCEPT, header arguing from the state vector that a mux incoming pinned to a basis
  constant on its edge carries no superposition to clone — if you cannot make that argument hold, STOP and
  write it in IMPL §7); the i1 pair `..._i1_flag_pinned` / `..._i1_arm_flag` as accepts (the owner's
  shape); the owner's `M2.c` compare twin as an accept.
- Injection matrix over every new/flipped accept (an extra `cqrt_ry` on the CONDITION register, an extra
  `cqrt_free`, a `_controlled` on the wrong flag): whole-file count prefixes, MISSED/DIRTY reported, target 0/0.

## 3. e2e

`slice_control_inplace_ry_stateprep_bool.c`: `bool b = cq_theta(false,.5); bool r = 0; if (b == 1) …` —
NO: a rail condition still declines at `bare i1 register condition` (bd `l4x4`) — so the STRICT slices for
this increment are the COMPARE-conditioned bool prep (`int q = cq_theta(0,.5); bool r = 0; if (q == 1)
r = cq_theta(r, .9);` and its `!=` polarity twin) and the i32 `seed == k` prep
(`int r = 5; if (q == 5) r = cq_theta(5, θ);`) — each read line by line against the analytic stream
(`cqrt_alloc_<W>(seed)` at the hoisted theta, `cqrt_ry_<W>_controlled(f, h, θ)`, strip, free). Register
after the `inplace_ry_stateprep` group in `tests/e2e/CMakeLists.txt`.

## 4. Records the ruling must update (SCOPE §5.5) — in the worktree

- `CLAUDE.md`: the sentence "THE `i1` STATE-PREP WIDTH IS OUT, and it is the one capability this cost"
  and the two fixture mentions become dated HISTORY (do not delete the four-round story — add a dated
  ⚠ paragraph: what the owner ruled, what the narrowing is, what it silently absorbs, the 19/21 split).
- `control-in-place-PRD.md` §14: an ERRATA/ruling block dated 2026-09-11.
- The `f2SeedPinnedByLiveRegister` header comment: the new conjunct and WHY (the theorem from SCOPE §2.2).
- `IMPL_f2.md` in this dir: §0 measured before coding (re-run SCOPE §0's table on your build), §1 the
  change with file:line, §2 the fast-path deletion proof, §3 the 19+21 lists with rc on both binaries,
  §4 e2e, §5 corpus diff (`session-r9e5/IMPL_B1.md` §5 harness, in
  `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/f2/`:
  ACCEPT-MONOTONE — the only movers are DECLINE→ACCEPT with the F2 string, exactly the 19 plus any probe
  members, each listed), §6 the owner's file after this increment (measured string — expected still
  `control flow` on `main`'s shape, then `bare i1` — say what you measured), §7 open questions.

## 5. Gates (Rule 19), in order

1. `cd build && lit ir-pass/test --filter '<name>'` while iterating.
2. `ctest --test-dir build -R ir-pass-lit --output-on-failure`.
3. `ctest --test-dir build -j6 -R '^e2e-' --output-on-failure`; `git status --porcelain tests/`.
4. Full `ctest --test-dir build -j6 --output-on-failure` ONCE at the end (Rule 19 moments 1 and 5).
5. `cmake --build build --target cq-opt-equivalence-full` if any diagnostic string was added/moved.

## 6. Non-negotiables

- Build BOTH targets (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
  -DCMAKE_BUILD_TYPE=Release && cmake --build build -j8`), never `--target CQPass` alone. Two sibling
  worktrees are building too; be patient.
- The narrowing is the WIRE and nothing wider: every register not on the condition's wire keeps F2's
  decline; the 21 must not move.
- No new runtime symbol, no YAML, no `include/` change (the owner refused a new `cq_*` function).
- Do not commit, do not push, do not touch the primary checkout's `build/`.

Final message to the orchestrator (≤40 lines): the conjunct and caller (file:line), the fast-path proof,
the 19/21 outcome, the H-2 state-vector argument in three sentences, gate results verbatim, the owner's
file's measured next string, §7 open questions.
