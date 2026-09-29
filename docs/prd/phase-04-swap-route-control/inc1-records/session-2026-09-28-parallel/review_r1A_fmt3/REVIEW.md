# Rule-13 review r1A — bd `test_C_libtooling-fmt3`, Surface A: is `nomerge` a complete and robust fix?

* **Subject**: worktree `agent-aea6988dda116aa5b`, commits `605f84ee` (Phase-1 record) + `c7890520` (Phase 2),
  diff `9a230646..c7890520`. The subject `build/ir-pass/cq-opt` is `3f6db37f5cf937b4…` = the frozen
  ORACLE `scratchpad/frozen/cq-opt.main_9a230646` (sha-256 re-measured, bit-identical). **Every verdict
  change is the header**, so every probe below is: stage 1 under the OLD header
  (`git show 9a230646:include/CQ.h` → `probes/oldinc/`) and under the NEW one (`probes/newinc/` = the
  subject's `include/CQ.h`), both through the one oracle `cq-opt`; ACCEPTs go through STRICT stage 2b,
  link (templates before runtime) and run with args `83 3`.
* Composition binary: `scratchpad/frozen/cq-opt.r2A_composed_rhk5r2_z0rer2_nlfd`.
* Time spent: ~75 min. Load on the box: 23–56 (five agents); I stayed at ≤ -j3.
* **What I ran, literally**: `probes/run.sh` (per-probe runner) over 78 C/C++/IR probes (`probes/src/`);
  `probes/runall.sh` → `probes/results.txt` (regenerates every verdict line quoted below); the
  implementer's `fmt3_probes/ab_hdr.py` as an instrument, twice: NULL (new vs new) and a MUTANT header
  (below); the frontend fixture's RUN line by hand under the old / new / mutant headers;
  `clang -O1 -mllvm -print-pipeline-passes`.
* **NOT run**: any lit / ctest / corpus sweep (no pass code changed — the binaries are the oracle's);
  the twin matrix; a private build (none needed: the only "conjuncts" of this change are header tokens,
  mutated without a build); the §9.4 in-loop accept (Surface B); the CONFIGURE_DEPENDS harness fix.

## Verdict: **CLEAR-WITH-ITEMS** for landing — and the answer to Surface A is **NO**

The change introduces **no wrong circuit**: every verdict it moves is a DECLINE of a wrong circuit, a
same-unitary restream, the §9.4 D→A (not my surface), or one of the two over-declines below. Land it.

But `nomerge` is **not a complete fix for the fmt3 class** and bd fmt3 must not be closed as "class
closed":

* **clang puts `nomerge` on the CALL SITE, never on the LLVM declaration** (measured:
  `declare i32 @cq_theta_si32(i32 noundef, double noundef) … #2`, and `#2` has no `nomerge`; the calls
  carry `#3 = { nomerge nounwind }`). Any spelling that does not call the attributed declaration BY NAME —
  a function pointer, `(&cq_theta_si32)(…)`, a higher-order helper — is promoted to a direct call by -O1
  **without** the attribute, and the exact fmt3 fold comes back byte-for-byte (F-r1A-1, P1).
* The fix's premise — "the evidence is erased only by a MERGE of two calls" — is too narrow. The same
  value-equality substitution erases register identity through a pure `select` fold with no second call
  at all, for two QUANTUM registers, and bd vsfp's own dead-cone stage performs that fold INSIDE the pass
  (F-r1A-2, P1). No header attribute can reach it.

Both P1s are **PRE-EXISTING** (identical on the old header) — the change does not make them worse; it
claims to have closed a class it has not closed.

**Beads filed by this review** (all `discovered-from: fmt3`): `test_C_libtooling-4e4p` (F-r1A-1, P1),
`test_C_libtooling-uw5u` (F-r1A-2, P1), `test_C_libtooling-cx6j` (F-r1A-3 + F-r1A-4, P2). A note was
appended to bd fmt3 (`--append-notes`). F-r1A-5…8 are for the implementer to take in the same change.

## Findings

### F-r1A-1 — P1, PRE-EXISTING (the fix does not reach it): the fmt3 fold through a function pointer

`probes/src/fp1.c` (n9 through a local pointer):
```c
int (*f)(int, double) = cq_theta_si32;
if (t == 5) r = f(t, .9); else r = f(5, .9);
return cq_measure(r) + cq_measure(t);
```
New header: stage 1 is `%7 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 9.0e-01) #4`
(`#4 = { nounwind }` — no `nomerge`), no branch; **ACCEPT**, 7 trace lines, STRICT 2b `0 violation`,
**trace byte-identical to `n9` on the OLD header** — a fresh |5⟩ prep, `t` measured unrotated.

| probe | spelling | old header | NEW header |
|---|---|---|---|
| `fp1` | local `int (*f)(int,double) = cq_theta_si32;` (n9) | ACCEPT 7 | **ACCEPT 7** (== n9[old]) |
| `fp2` | `static int (*const ROT)(int,double) = cq_theta_si32;` (n9) | ACCEPT 7 | **ACCEPT 7** |
| `fp3` | local pointer, **nested** (a6) | ACCEPT 13 | **ACCEPT 13** (== a6[old]) |
| `fp4` | `(&cq_theta_si32)(t,.9)` / `(*cq_theta_si32)(5,.9)` | ACCEPT 7 | **ACCEPT 7** |
| `fp5` | `static inline int apply(rot_fn f, …){return f(x,a);}` with `apply(cq_theta_si32, t, .9)` | ACCEPT 7 | **ACCEPT 7** |
| `fpzt_p1` | `zt_p1` (zt0b's runtime seed, no region — the accept the owner WITHDREW) through a pointer | ACCEPT 7 | **ACCEPT 7**, trace == `zt_p1[old]` (`zt_p1` itself: old ACCEPT → new DECLINE) |
| `fpzt_a1` | `zt_a1` (nested runtime seed) through a pointer, on the session's **composed** binary | ACCEPT | **ACCEPT** (`zt_a1` itself: old ACCEPT → new DECLINE `nested`; on the ORACLE both spellings F1-decline) |
| `fp6` | the Ry if/else through a pointer | select-angle, ACCEPT | still folds to the select-angle (harmless, but the "accepted cost" is spelling-dependent) |
| `rd2` | TU without CQ.h, user declares `int cq_theta_si32(int,double);` | ACCEPT 7 | ACCEPT 7 — outside the Rule-4 contract, noted only |

Controls that DO keep the attribute (all DECLINE on the new header): the `_Generic` macro (every probe),
`cq_ry` (`ry1`), the f80 and f16 rows (`f80`, `f16`), C++ (`cpp1`, `clang++`), a redeclaration without
the attribute AFTER CQ.h (`rd1` — clang inherits it), an inlined helper that calls `cq_theta` directly
(`h5` — the call-site attribute survives inlining).

`fp5` is the realistic one: any generic code that takes "a rotation" as a function pointer.

Repro: `cd …/review_r1A_fmt3/probes && ./run.sh fp1 83 3 && diff out/fp1.new.trace out/n9.old.trace`
(needs `./run.sh n9 83 3` first; both lines print, the diff is empty).

Remedy (implementer/owner call, not built): (a) header — make the per-type names non-addressable, e.g.
function-like macros over reserved-name declarations with `__asm__("cq_theta_si32")` labels, so
`&cq_theta_si32` / `f = cq_theta_si32` is a compile error; or (b) pass — a `@cq_theta_*` call site in a
clang-produced module that lacks `nomerge` DECLINES (every legitimate direct call has it; a merged product
of two attribute-less calls has it not). (b) also covers `rd2`. Either needs its own red-green pair.

### F-r1A-2 — P1, PRE-EXISTING (no header attribute can reach it): `select(t == s, t, s) → s` at `cq_theta` arg-0 over two QUANTUM registers — also performed INSIDE the pass

| probe | source | stage 1 (both headers) | old | NEW |
|---|---|---|---|---|
| `sel1` | `r = cq_theta((t == s) ? t : s, .9);` | `cq_theta_si32(%s, .9)` — the select, the compare and `t`'s use are GONE | ACCEPT 6 | **ACCEPT 6** |
| `sel2` | `if (t == s) a = t; else a = s; r = cq_theta(a, .9);` | same module | ACCEPT 6 | **ACCEPT 6** |
| `vol1` | `sel2` with a write-only non-escaping `volatile` local stored in each arm, so -O1 can NOT fold | diamond + `phi [t, s]` survives stage 1 | ACCEPT 6 | **ACCEPT 6**, trace == sel1's |
| `sel1_twin.ll` | sel1's stage 1 with the folded `icmp eq` + `select` put back | — | — | **DECLINE** `condition predates a non-diagonal gate` |
| `sel3` | unfoldable twin `(t > 3) ? t : s` | select kept | DECLINE (same string) | DECLINE |
| `sel4` | the if/else-of-two-thetas spelling (`if (t==s) r=cq_theta(t,.9); else r=cq_theta(s,.9);`) | old: merged → `cq_theta(s)`; new: two calls | ACCEPT 6 | DECLINE — **nomerge DOES close this spelling** |

CQ reads a `select` at arg-0 as a VALUE — a 4.4 controlled-copy mux into a FRESH rail — and rotates the
fresh rail; the twin with the select present declines. After the fold the pass rotates `s` IN PLACE. These
are different unitaries, analytically: the fresh rail is a basis copy of `s` (its reduced state is `s`
DEPHASED), so for a qubit of `s` prepared `Ry(.7)|0⟩`, the measured `r` has `P(1) = cos²(.35)sin²(.45) +
sin²(.35)cos²(.45) = 0.262` on the source's reading and `P(1) = sin²(.8) = 0.515` on the lowered circuit.
(For a LITERAL or CLASSICAL `s` the fold is harmless — a fresh |s⟩ either way — which is the case §9.6
argued.)

**The pass does it too** (`vol1`): bd vsfp's `DeadValueLiveness.cpp` deletes the unobservable volatile
stores, then mimics `FoldTwoEntryPHINode` and asks `simplifySelectInst(Cond, VT, VF, …)` (line 383), which
returns `VF` = `s`. The comment's "parity bar is SimplifyCFG + InstCombine" is honoured — `-O1` does the
same to `sel2` — so the pass is faithfully reproducing a wrong fold (Rule 14: a second spelling of the
`-O1` fold inherits its hazard). The pass-internal instance is fixable in the pass (accept a
`simplifySelectInst` result only when it is a Constant, `Cond`, or `VT == VF`), but that alone would only
move `vol1` to a decline while `sel2` still accepts.

**L7, record**: `TRACK_FMT3.md` §9.6 — *"a select written on ARG-0 (`cq_theta((q == s) ? q : s, θ)`) is a
VALUE … so InstSimplify folding it to `s` changes nothing observable"* — is FALSE whenever `s` is quantum.

Repro: `./run.sh sel1 83 3; ./run.sh vol1 83 3; HDRS=new ./run.sh sel1_twin 83 3; diff out/vol1.new.trace out/sel1.new.trace`.

### F-r1A-3 — P2, INTRODUCED: a CLASSICAL if/else of two in-place Ry on one register inside a loop now DECLINES

| probe | loop body | old header | NEW header |
|---|---|---|---|
| `cc3` | `if (i & 1) p = cq_theta(p,.9); else p = cq_theta(p,.3);` | ACCEPT 6 (`ry .2, .3, .9, .3` — correct) | **DECLINE** `cq loop lowering: loop-carried tainted value crosses iterations` |
| `cc3b` | `if (i == 0) … else …` (first-iteration special case) | ACCEPT 6 | **DECLINE** (same) |
| `cc3c` | loop-invariant runtime flag `if (k > 50) …` | ACCEPT 6 | **DECLINE** (same) |
| `cc3d` | Trotter-style `±th`, `th = atof(argv[1])/100` | ACCEPT 6 | **DECLINE** (same) |
| `cc3t` | the ternary spelling `p = cq_theta(p, (i & 1) ? .9 : .3)` | ACCEPT 6 | ACCEPT 6, trace == `cc3[old]` |
| `cc1` | the same classical if/else, straight-line | ACCEPT 4 | ACCEPT 4 |

The condition is CLASSICAL, so this is not the owner-priced cost ("the if/else of the Ry angle select …
lowers as two controlled Ry, the same unitary" — `docs/frontend.md` §3.1 and the CQ.h comment say exactly
that, and for these programs it is false: they decline). None of the implementer's instruments could see
it: the e2e A/B has no such slice (0 A→D of 613 + 32), and the twin matrix has no classical-condition
axis. Reproduced on the composed binary. **L2's shape**: the widened set (programs whose if/else survives
-O1) was re-asked of the predicates that assumed the merge on the quantum-condition side; the loop layer's
treatment of a CLASSICAL diamond of two chained thetas assumed it too.

Direction (not built): a pass-side re-fold of `br c; A: x1 = θ(x, a); B: x2 = θ(x, b); φ(x1, x2)` into
`θ(x, select(c, a, b))` **only when both arms' arg-0 is the SAME SSA value** is immune to fmt3 (the hazard
needs two arg-0 values -O1 PROVED equal, never one value) and subsumes bd `gjn2` as well.

Repro: `./run.sh cc3 83 3; ./run.sh cc3t 83 3; diff out/cc3.old.trace out/cc3t.new.trace`.

### F-r1A-4 — P2, INTRODUCED, inherent to option B: identical literal preps on both arms

`cc5`: `if (q > 3) { r = cq_theta(5, .9); b = cq_theta(b, .4); } else { r = cq_theta(5, .9); }` — old:
the prep is hoisted, `b` gets `cqrt_ry_i32_controlled` (ACCEPT 13, correct circuit); new: **DECLINE**
`control flow under quantum control`. This one cannot be recovered at IR: two literal-5 preps are exactly
what `n9`'s pinned pair looks like after IPSCCP. It belongs in the owner's cost statement. (`cc6`, the
identical in-place `Ry(a,.9)` on both arms, only restreams: 7 → 13 lines, `cRy(f,.9); X f; cRy(f,.9); X f`,
same unitary, STRICT 2b clean.)

### F-r1A-5 — P2, INTRODUCED: 15 of the 16 attribute tokens are UNPINNED

`tests/frontend/cq_theta_nomerge.c` exercises only `cq_theta_si32`. Mutant header `probes/mutinc/CQ.h` =
the committed header with `CQ_THETA_NOMERGE_` removed from every declaration except `cq_theta_si32`
(15 lines changed):

* the fixture's RUN line under the mutant: **GREEN** (positive control: under the OLD header it is RED);
* e2e header A/B (`ab_hdr.py newinc mutinc`, `probes/ab_MUT.txt`): **0 stage-1 movers, 0 verdict movers of 613** (25 multi-TU jobs not swept) — no e2e slice can see the 15 tokens go; NULL control
  (`newinc` vs `newinc`) first: `0 stage-1 movers, 0 verdict movers of 613` (`probes/ab_NULL.txt`);
* the ir-pass lit fixtures are header-independent by construction;
* and the mutant **re-opens the class** at four widths: `f80`, `f16`, `n5` (f64), `n6b` (i1) all ACCEPT
  under it (they DECLINE under the committed header).

So the whole suite would stay green if 15 of the 16 tokens were deleted. Fix: one function per width in
the frontend fixture (a macro over the 16 types makes it one line each).

### F-r1A-6 — P3: `…_nomerge_noregion_pin.ll` carries no retirement trigger

The other three new fixtures do. This one declines at `if/else state prep allocates two rails`; the day
that fence lifts (drbq.13 Q4 is an owner ruling that can be revisited, and bd `gjn2` works right next to
it) the module is two identical literal-5 preps under `(q & -4) == 20`, and it must still DECLINE because
the TRUE edge pins the live register `t` — i.e. F2 must be asked on each arm's edge. The trigger should say
that, or the fixture flips to the fmt3 accept with nobody told.

### F-r1A-7 — P3, L7: §9.6's reason for leaving `cq_measure` mergeable is narrower than what it clears

The stated reason is "the pin is EXACT, the measured register is in the eigenstate |5⟩". `mreg`
(`if (t == s) m = cq_measure(t); else m = cq_measure(s);`, two quantum registers) merges to an
unconditional `cq_measure(s)` and ACCEPTS on both headers — and there `t` is NOT in an eigenstate. The
merge is still sound under the coherent-control model (on `t == s`, `|k⟩⟨k|_t = |k⟩⟨k|_s`, so the coherent
sum of the two branches' projectors for outcome `k` is `|k⟩⟨k|_s`); what makes it sound is that LLVM merges
two measures only when their operand VALUES agree on every path. That is a modelling choice nobody has
ruled: under a model in which a measurement that fires on ONE branch leaves a which-branch record, the
merge (and the `m1` / flat-twin fold) removes a decoherence the source has. Belongs with bd `yiid`. The
conclusion (no `nomerge` on `cq_measure`) stands; the reason should be the right one. `mflat` / `munp`
(a measure on one arm only) decline `value-arm swap-route` on both headers.

### F-r1A-8 — P3, L7: text that over-claims, to correct AT THE SOURCE (L7's twist)

* `include/CQ.h`: "`nomerge` keeps both calls and the branch" — for DIRECT calls only (F-r1A-1).
* `docs/frontend.md` §3.1/§8: "CQ.h forbids it with `nomerge`" (same); "it stays an if/else and lowers
  as two controlled Ry, the same unitary" (false for a classical condition in a loop, F-r1A-3); the list of
  what `nomerge` costs omits F-r1A-3 and F-r1A-4.
* `TRACK_FMT3.md` §3 "closes the class? **YES**" and §9.6's ternary sentence (F-r1A-2).

## Questions from the brief, answered

1. **Other -O1 routes.** `cq_theta_*` declarations carry no memory attribute (`#2` is frame-pointer /
   target attributes only), so EarlyCSE cannot CSE them; the -O1 pipeline has no GVN, JumpThreading,
   GVNHoist/GVNSink or SpeculativeExecution (`-print-pipeline-passes`, measured); `FoldTwoEntryPHINode`
   needs speculatable arms and a call is not. `__builtin_assume` / `__builtin_unreachable` pins (`as1`,
   `un1`) decline `taint escape` (the assume reads a tainted compare). A register-register pin on a
   surviving edge (`rr1`) is not substituted at -O1. **What does get through: the `select` fold of F-r1A-2**
   (not a merge) and the function-pointer route of F-r1A-1.
2. **Ways around the attribute.** F-r1A-1. `_Generic`, `cq_ry`, f80, f16, C++, later redeclaration: kept.
3. **`cq_measure`.** F-r1A-7: conclusion holds under the coherent model, stated reason too narrow; I did
   not find a merged measure whose operand values differ between paths (LLVM does not merge those).
4. **Multi-function / inlining.** `nomerge` CANNOT change an -O1 inlining decision: the only
   hoist/sink-enabled SimplifyCFG is pipeline position 71, after the CGSCC inliner (positions 21–50), so
   the inliner sees byte-identical bodies under both headers. Measured: 20 helper sizes (`inl*`, `sinl*`,
   static and external, K if/else pairs + F plain rotations) — the call count of the helper in `main` is
   identical under both headers in every case. Non-inlined helpers that return a quantum value decline at
   the function boundary on both headers (`h1`–`h4`), so the merged-helper-call route (`rot(t)` /
   `rot(5)` merged) does not reach an accept today.
5. **Deeper nesting.** 3-deep (`d3`), pin on the OUTER edge (`d2o`), classical outer (`d2c`) all DECLINE;
   the four fixtures' trigger strings exist in `ArmClassify.cpp:5339-5340`; F-r1A-6 is the gap.

## Standing-lesson questions

* **L1** — no pass stage changed. N/A. (The pass-internal fold of F-r1A-2 is pre-existing, bd vsfp.)
* **L2** — the widened set was re-asked on the quantum-condition side; the loop layer's CLASSICAL diamond
  (F-r1A-3) and the hoisted identical prep (F-r1A-4) were not.
* **L3** — the narrowed set (programs reaching the angle select as one call) is re-widened by the pointer
  spelling (`fp6`): harmless, but it makes the "accepted cost" spelling-dependent.
* **L4** — no walker. N/A.
* **L5** — **the finding in one line**: the fix answers a SEMANTIC question (*did -O1 replace an arg-0 by a
  value-equal but identity-distinct one?*) with a SYNTACTIC prohibition at one syntactic site (a direct
  call naming the attributed declaration). F-r1A-1 and F-r1A-2 are two other syntactic answers.
* **L7** — F-r1A-7, F-r1A-8.
* **Rule 14** — `DeadValueLiveness`'s `FoldTwoEntryPHINode` mimic is a second spelling of -O1's fold and
  inherits its hazard (F-r1A-2; pre-existing).
* **Rule 12** — F-r1A-5 (15 unpinned tokens); F-r1A-6. The four decline fixtures' subjects exist (they
  are the new stage 1, re-derived by `run.sh` for `a6`/`n9`), negatives are pure.

## Composition (session binary `cq-opt.r2A_composed_rhk5r2_z0rer2_nlfd`)

`zt_a1`: old ACCEPT → new DECLINE `nested control flow` (the reversal the owner ruled). `fpzt_a1` (the
same program through a pointer): **ACCEPT on both headers** (the oracle F1-declines both; the accept is z0re's) — F-r1A-1 re-opens exactly the zt0b accept the
owner withdrew, on the binary that will ship. `fp1`/`fp3`/`sel1`/`vol1` accept; `cc3` / `cc5` over-decline
as on the oracle. (`probes/results.txt`, last block.)

## What I tested and did not break

The class members the change targets (`a6`, `n9` re-measured; `n12` legitimate control unchanged at
ACCEPT 13); all `_Generic` rows reached (`i32`, `i1`, `f64`, `f80`, `f16` via probes); `cq_ry`; C++;
redeclaration after CQ.h; inlined direct-call helpers; non-inlined / cross-TU helpers (decline at the
boundary on both headers); `assume` / `unreachable` pins; register-register edge pins; the inlining
question (structurally impossible at -O1, 20 sizes measured); nesting depth 3; `cq_measure` merges
(`m1`, `mreg`, `mflat`, `munp`); the frontend fixture is RED on the old header and GREEN on the new one.

## Probes

`probes/src/` (78 sources), `probes/run.sh` (runner), `probes/runall.sh` → `probes/results.txt`,
`probes/{old,new,mut}inc/CQ.h`, `probes/ab_{NULL,MUT}.txt`, `probes/out/` (stage-1 / stage-2 / traces).
