# Rule-13 review r1B — bd `test_C_libtooling-z0re` (Surface B: emitted circuits, the corpus movers, widths/fp/ABI, loops, composition)

- **Subject**: branch `worktree-agent-a284a60d747f2ed82`, commit `369c61b9`, diff range `9a230646..369c61b9`.
  `build/ir-pass/cq-opt` sha-256 `51b5f78d84de5c6befe82496d3e9126939b584a0347b25aff6ea39f596cc1e40`,
  `libCQPass.so` `fe42a1e8ad49bb261e64c86c…` (both re-hashed, match the brief). Runtime archives from that build.
- **Oracle**: `scratchpad/frozen/cq-opt.main_9a230646` sha-256 `3f6db37f5cf937b4d70f5736…` (re-hashed).
- **Reviewer**: r1B (independent; did not write the change). Surface A (F1/F2/L1 fence logic) is r1A's and is not duplicated here.
- **Time**: ~75 min wall clock (19:11–20:26), under a load average of 18–340 (other agents); one private build.
- **Probes**: `probes/src/*.c` (hand-written C, `atoi(argv[..])` runtime values — never `main(){return f(4);}`), one hand-IR
  (`probes/src/L2arr_V1_literal_seed_sext_cond.ll`); harness `probes/run.sh <S|O> <src.c> [lib.c] -- <args>` = stage 1
  (`clang -O1 -include CQ.h`, `llvm-link` a lib TU when given) → stage 2 (subject or oracle) → **stage 2b STRICT**
  (`tools/free_pairing_check.py`) → `clang -c` + `build/tests/e2e/cq_link.sh` → run. Raw outputs in `probes/results/`.

## What I ran, literally

1. **Polarity / stream by hand** — `probes/results/batch1_p1_polarity.txt`, `batch2.txt`: prep with `!=` and the theta in the ELSE arm
   and in the THEN arm; angle select with `!=`; subject vs a LITERAL-seed twin on the ORACLE.
2. **Angle-select fences with a runtime base** — `batch2.txt`: `__builtin_inf()`, `π`/`1e16`, a runtime arm, a bare `_Bool`
   condition, a compound condition, f64 base, a `1e-17`/`1.0` pair (and its register-base twin on the oracle).
3. **Widths** — `widths.sh` → `batch3.txt`: runtime seed at `_Bool`, `i8`, `u8`, `i16`, `u16`, `i64`, `u64`, f16, f32, f64
   (`-0.0`), f80, conditional prep on the subject vs the UNCONDITIONAL `cq_theta(s, θ)` on the ORACLE; angle-select base at
   f80 / `_Bool` / `i8` / f16 (`as_*.c`); i1 `trunc` seed (`i1t_*.c`); fp seeds NaN / −NaN / denormal / −0.0 / inf.
4. **Loops** — `loops.sh`, `l2b.sh` → `batch4.txt`: angle select after a loop on a loop-carried classical φ base (`L1as_exit`);
   in-loop prep with a per-trip LOADED seed, rolled vs hand-unrolled, and K=3 vs K=1000 (`L2b*`); a loop-carried classical
   FEED-FORWARD seed `s = cq_measure(r) + 1` rolled vs unrolled (`L6ff*`); an angle select after a measurement feed-forward loop
   (`L7as_ff`); loop-carried `r` read after the loop, fixed and runtime trip (`L3*`, `L4*`); angle select inside a loop (`L5`).
5. **The 88 D→A movers** — `movers.sh` + `classify.py` over all 74 C/e2e movers (every probe/e2e row of `ab_v2.txt`; the 12 lit
   and 2 multi rows are the implementer's own fixtures, read, not re-run): subject accept + a structural check of WHY it accepts.
   `pairs.sh` → `pairs.txt`: 15 C/T pairs (a01 a02 l12 l17 r03 za zb zf zi zm zxd zj lv li zk) at TWO NEW argument vectors
   (`-3 11`, `40 1` — the implementer used `5 7`, `2 9`), trace-diff + STRICT 2b on both halves.
6. **Composition** — `comp.sh` → `batch5.txt`, `k1.txt`, `k3.txt`, `k4.txt`.
7. **Stream-mover spot check (ONE of the implementer's sweeps)**: every pre-existing `control_inplace_ry_stateprep*.ll`,
   `control_angle_select_ry*.ll`, `control_peel_*fp_stateprep*.ll` fixture (78, runtime-seed files excluded) through oracle and
   subject, sha of stdout+stderr: **0 of 78 moved**; positive control `control_angle_select_ry_runtime_base.ll` MOVES.
8. **Mutants** in a private worktree (`scratchpad/rev_r1B_z0re`, ONE build, env-selected; removed afterwards, patch kept as `probes/mutants.patch`) — five full `lit ir-pass/test` runs, §Mutants below.

**NOT run:** the full `ctest`; the implementer's corpus A/B, allocator sweeps and mutation matrix (read: `ab_v2.txt`,
`mutmatrix.txt`); any `-O2` pipeline; nothing on the implementer's build dir except the read-only binaries.

## Verdict: `CLEAR-WITH-ITEMS`

**0 P1.** The circuits the change emits are right in every shape I could construct from C: polarity, bracket convention,
flag strip before free, frozen rotated rail, seed value reaching `cqrt_alloc_<W>` unchanged at every width (modulo the
pre-existing ix2v trace print), angle difference computed in the orientation `-O1` actually leaves, every §12.3 fence still
firing with a runtime base, rolled == hand-unrolled for every in-loop accept, and each of the 74 C/e2e movers accepted
**for the runtime-seed reason and no other**. One P2 (a pre-existing P1 defect — bd `rhk5` — whose population this change
grows, measured from plain C) and five P3s.

---

## Findings

### F-r1B-1 — P2 · PRE-EXISTING defect (bd `rhk5`, P1 open), NEW POPULATION introduced by z0re · C-reachable, warned

A controlled **runtime-seed prep** is a new CONTROL CONSUMER for bd `rhk5`'s mechanism (a tainted-arg clone call scheduled
between a derived chain and that chain's control consumer leaves the chain's template rails DIRTY across a later Ry).

`probes/src/k3C.c` (+ `k3C.lib.c`: `int h(int a,int k){return k+1;}`):

```c
int m = atoi(v[1]); int t = atoi(v[2]);
int q = cq_theta(m & 7, 0.5);
int p = q * 3; int u = p ^ q;
int s = h(m, q);                                   // clone call between the chain and its consumer
int r = t; if (u == 10) r = cq_theta(t, 0.2);      // RUNTIME-seed prep, the consumer
int ms = cq_measure(s);
q = cq_theta(q, 0.7);                              // later non-diagonal gate on q
return ms + cq_measure(q) + cq_measure(r);
```

| program | binary | verdict | stream |
|---|---|---|---|
| `k3C` (runtime seed) | ORACLE | DECLINE `state prep seed does not match the merge incoming` | — |
| `k3C` (runtime seed) | SUBJECT | **exit 0**, `warning: non-diagonal gate over a live derived record`; 2b `0 violation(s)`, census `5 template rail mint(s) of which 2 left dirty` | `h1 = 3q`, `h2 = 3q^q` **never `_unc`'d**, alive across `cqrt_ry_i32(h0, 0.7)` |
| `k3T` (twin, `s = q + 1` inlined) | SUBJECT | exit 0, 0 warnings, census 0 dirty | `xor_unc`, `mul_unc`, both freed before the Ry |
| `k3L` (LITERAL seed 6, same program) | ORACLE **and** SUBJECT | exit 0, same warning, same 2 dirty rails | identical to `k3C`'s modulo the seed |

So the wrong unitary (Rule 8: `q` dephased by two entangled which-path rails) is **not** z0re's lowering — `k3L` produces it
on the oracle today — but **`k3C` moves D→A into it**, and the corpus A/B could not see it (no corpus program has a clone call
in front of a prep). *"Pre-existing" is true of the defect and false of its population.* Warned, not silent (the lyyf
policy-(B) warning). The angle-select consumer does not join the population: `k4C` (same program, angle select) declines at
2c on both binaries.

**Repro:** `probes/run.sh S probes/src/k3C.c probes/src/k3C.lib.c -- 13 6` (and `O … k3L.c k3L.lib.c`, `S … k3T.c`).
**Disposition:** append to bd `rhk5` as a customer (its fix — the clone-call read-only proof in flight this session — should
turn `k3C` clean; `k3C`/`k3T` are a ready red-green pair for it). Not a merge blocker for z0re on its own; the orchestrator
should know that landing z0re BEFORE rhk5 grows rhk5's C-reachable population.

### F-r1B-2 — P3 · INTRODUCED (defence-in-depth asymmetry, no reachable exhibit) · `AngleSelectEmit.cpp:358-364`

Step 0 of `emitAngleSelectRegion` admits an untainted base by **re-deriving** `isRuntimeStatePrepSeed(Base, taint)` at
emission time, while the L1 **record** two hundred lines below is keyed on the **classifier's verdict**
(`R.RuntimeSeedAdmitted`) — deliberately, because emission-time taint can differ from detection-time taint (the measured
failure of the first spelling, TRACK §5.4). The same argument applies to the admission: for a region the classifier accepted
with a **TAINTED** base (Inc 2b — S8/S9 proven over a register closure, `RuntimeSeedAdmitted == false`, **no record**), a base
that is untainted at emission used to decline `control flow` and now **passes step 0 and lowers as a fresh-rail prep with no
L1 record**. I found no stage between detection and emission that shrinks the taint of a live value (the only taint-shrinking
stage, `specialize()`'s scrub, runs after both control rounds — that is the pre-existing side door, correct), so this is
UNREACHABLE today; it is graded P3 as a Rule-14/L2 asymmetry, not a hole. Keying the admission on `R.RuntimeSeedAdmitted`
(`UntaintedBase && !R.RuntimeSeedAdmitted → decline`) restores the old decline for that transition and makes step 0 carry
the classifier's verdict exactly as the record does. MEASURED cost of that tightening: mutant `M-b` below.

### F-r1B-3 — P3 · PRE-EXISTING (bd `ix2v`), population grown — and the recorded population is incomplete

A negative narrow runtime seed reaches the runtime ZERO-extended: `cqrt_alloc_i8(253)` for `-3` **and
`cqrt_alloc_i16(65533)` for `-3`** (`batch3.txt`), on the controlled prep (subject) and on the runtime-base angle select
(`as_i8.c`), exactly as on the UNCONDITIONAL spelling on the oracle (`wu_i8`, `wu_i16`). The lowered IR is correct (the
8/16-bit pattern is the same basis state); the defect is the missing `signext` on the call vs the runtime's `int8_t`/`int16_t`
definition. bd `ix2v`'s z0re note records **i8 only**; **i16 is also affected** — append. `_Bool` (incl. an `i1` `trunc`
seed), `u8`, `u16`, `i64`, `u64` (prints signed, width-only ABI, identical on oracle), f16, f32, f64, f80 all trace the value
the source holds.

### F-r1B-4 — P3 · INTRODUCED record error · `tests/e2e/slice_z0re_runtime_seed_prep.c`

The slice header says *"the flag is stripped and freed (the one `cqrt_free`)"*; its golden has **two** `cqrt_free` — the dead
`q`'s rail is reverse-played (`ry(h0, -0.5)`) and freed first. The stream is fine (a product basis state, 2b `verified`) and
TRACK §8.5 describes it correctly; the header does not. Fix the comment at the source (L7).

### F-r1B-5 — P3 · record hygiene

Two fixtures are now ACCEPTs under a `_reject_` name (`control_inplace_ry_reject_stateprep_runtime_seed.ll`,
`spec_reject_dropped_arg_statepred_runtime_seed.ll`). Keeping the names is deliberate and each header says so (bd gahu
precedent, L8) — but **bd `gahu`**, which exists to track exactly these for the eventual rename, carries no z0re note. Append.

### F-r1B-6 — P3 · what the three new `*-twin-identical` gates witness

Both halves of every new twin gate (and of the implementer's 13-pair C/T battery) take the **new** path, so they witness
side-door ≡ direct-path consistency, not correctness; a change that corrupted the runtime-seed stream identically in both
spellings would keep them green (the goldens would catch it, the twin gates would not). The **independent** witness is the
oracle-cleared literal-seed Inc-4 path run with the runtime input equal to the literal — measured here and TRACE-IDENTICAL:
`p1ne_else`/`p1ne_then` (subject, s=6) vs `*_lit` (oracle), `c2leaf` (prep merge φ as a kickback leaf, bd 3qps) and
`c3cascade` (prep → prep) vs their literal twins on the ORACLE. Suggest pinning one such cross-path pair as a gate.

---

## Mutants

The implementer's M0–M8 (`mutmatrix.txt`, 8 of 8 KILLED over the 21 z0re fixtures) cover every REACHABLE new conjunct; I
did not re-run them. I mutated the four conjuncts they did not: the emitter's step-0 re-ask and the two type/stem guards.
ONE private build (`scratchpad/rev_r1B_z0re`, `cq-opt` sha-256 `c42d4cf7c150fbf238cbfd39…`), the mutant selected at run time by
`R1B_MUT` (the patch is `git diff` in that worktree, 9 lines). **Boundary controls, run first:** (a) with `R1B_MUT` unset the
private binary is byte-identical in output to the subject on 35 fixtures (the 22 changed + 13 angle-select); (b) lit's
environment pass-through is proven by a throw-away `zz_r1b_envprobe.ll` (`RUN: test "$R1B_MUT" = 7`) that PASSES under
`R1B_MUT=7` and FAILS under `0` — so every full run below MUST show exactly that one FAIL, and does.

| mutant | edit | full `lit ir-pass/test` (2426 = 2425 + env probe) | 191 probe modules (74 movers + mine) |
|---|---|---|---|
| null (`0`) | — | 2424 PASS · 1 XFAIL · 1 FAIL (the env probe) | reference |
| M1 | `AngleSelectEmit` step 0 never declines an untainted base | **SURVIVED** (same 2424/1/1) | 0 differ |
| M2 | step 0 keyed on `R.RuntimeSeedAdmitted` (the F-r1B-2 tightening) | **SURVIVED** (same) | 0 differ |
| M3 | step 0 without `IsTheta &&` | **SURVIVED** (same) | 0 differ |
| M4 | `isRuntimeStatePrepSeed` type clause → always true | **SURVIVED** (same) | 0 differ |

All four are UNPINNED, and all four are UNREACHABLE by construction rather than by missing coverage — Rule 12 can supply no
fixture for them: M1/M2 guard a tainted→untainted transition between detection and emission that no stage produces (F-r1B-2);
M3 needs a register-carrying `cq_phi_<sfx>` stem, which is a reserved-name decline upstream; M4 needs a non-int/fp `cq_theta`
arg-0, which collection-time prototype validation refuses. Graded under F-r1B-2 (P3), not separately. M2 surviving is the
useful half: **the tightening F-r1B-2 proposes moves nothing measured.**

---

## What I attacked and did not break

**Stream correctness by hand (attack item 1).**
- `r = s; if (q != 3) {} else r = cq_theta(s,.2)` → `-O1` gives `icmp eq`; flag `eq`, controlled Ry directly on it (fires
  on `q == 3`) ✓. `if (q != 3) r = cq_theta(s,.2)` → flag `eq`, `cqrt_x`-bracketed on the ANCILLA (fires on `q != 3`) ✓.
  Both TRACE-IDENTICAL to the literal-seed spelling on the ORACLE at `s = 6`. The rotated rail is never freed or reverse-played
  (2b "left allocated"); the flag's `_unc` strip precedes its only `cqrt_free`; `s`'s runtime value is the alloc operand.
- Angle select `if (q != 3) r = cq_theta(t,.7); else r = cq_theta(t,.2)`: `-O1` leaves `select(q == 3, .2, .7)`, so A = .2,
  B = .7 and the stream is `alloc(t); ry(h,.7); ry_controlled(f_eq, h, −0.49999999999999994)` — f=0 (`q≠3`) Ry(.7), f=1
  Ry(.7 − .4999…) = Ry(.2 + 1 ulp) ✓. Its oracle-accepted twin (`r = cq_theta(t,.2); if (q != 3) r = cq_theta(r, .7-.2)`,
  in-place arm) emits the mirror stream `ry(.2); x; ry_controlled(+.4999…); x` — same unitary to 1 ulp, inside the owner's
  2^-40 fence.
- Fences with a runtime base: `__builtin_inf()` → `rotation angle` ✓; `π`/`1e16` → `rotation angle` ✓ (oracle too); a runtime
  arm → `rotation angle` ✓; bare `_Bool` condition → `bare i1 register condition` (a STRING move from the oracle's `rotation
  angle` — l4x4.a, correct); compound condition → `control flow` on both; `1e-17`/`1.0` accepts, the 2^-40 TwoSum residual is
  ~1e-17 and the register-base twin accepts identically on the oracle — the fence is the owner's tolerance, not exactness.

**S3's skip of S7-rail/S8/S9 (attack item 2).** What each protects: S8 — the rotated rail disjoint from every condition rail
(else the strip reads a relabelled basis); S9 — no read of the rotated register's pre-Ry name after the gate; S7-rail — the
rotated rail not a loop rail. For an untainted base the rotated rail is minted by `T0` *after* every condition register exists,
so it cannot be a condition rail, has no pre-Ry name anything can read (`T0`'s only user is `T`), and is not in a loop (S7's
anchor prong still refuses a `T`/`Sel`/`Cond` in any cycle). The only way "fresh" fails is the base turning quantum —
r1A's L1 re-ask. Measured: base = classical loop-carried φ, select in the exit block (`L1as_exit`, `alloc(49)` for
`t=5, n=2` ✓); base = measurement feed-forward φ (`L7as_ff`, `alloc(2)` ✓); angle select inside a loop declines `control flow
inside a loop body` (pre-existing flat-only policy). K-independence is not applicable (flat only).

**Widths / fp (items 3, 5).** Table in F-r1B-3. fp NaN/−NaN/denormal/−0.0/inf seeds are passed through untouched
(`cqrt_alloc_f64(nan|0x1p-1074|-0x0p+0|inf)`); no fence compares the seed's VALUE — F1 is SSA identity, the relational F2 half
is an `fcmp` polarity table over-approximating equality (NaN only makes it decline more). The trace prints −NaN as `nan`
(runtime `%a`, identical on the unconditional path) — a trace-fidelity note, not a compiler issue.

**In-loop runtime seed (item 6).** `L2b` (per-trip LOADED seed `s[k]`): rolled == hand-unrolled, 24 trace lines,
BYTE-IDENTICAL, STRICT 2b clean; lowered IR 106 lines at K=3 **and** K=1000. `L6ff` (seed carried as `s = cq_measure(r)+1`
across the back edge): rolled == unrolled, 24 lines. Oracle declines both at F1.
Loop-carried `r` read after the loop (`L3`, `L4`) declines on the subject (`iteration-local value read after the loop`) and
its unrolled twin declines too (`nested control flow`) — verdicts agree.

**The 88 movers (item 4).** All 74 C/e2e movers accept on the subject, and `classify.py` finds that **every**
`cqrt_ry_<W>_controlled` in every one of them targets a rail from `cqrt_alloc_<W>(<SSA value>)` — 84 controlled Rys, 84
RUNTIME, 0 LITERAL, 0 OTHER: none was accepted for a reason other than the runtime seed/base. The oracle's decline for all 88
is F1's (73) or S3's `rotation angle` (15). 15 C/T pairs × 2 new argument vectors: 30 of 30 TRACE-IDENTICAL, 60 of 60 STRICT
2b `0 violation(s), 0 unproven`. The 4 STRING movers are the three new decline fixtures + `e09`, all correct re-labellings.

**Composition (item 7).**
- **cepm + 3zr4** — `k1C` (the 3zr4 repro shape: `t = h(y, c)` with `y` a 6.5 `%out`, h ignoring `a`, a `puts` block, then a
  runtime-seed prep of `t`): exit 0, 23 lines, TRACE-IDENTICAL to the inlined twin `t = c + 1` (with `ext_f` linked; without the
  body the twin declines at the 6.5 arm — a harness point, not a finding). `k2C` (h READS `a`, so `t` is quantum at round 2):
  declines `state prep seed became quantum` from plain C, twin `k2T` (`t = y + c`) declines identically — the re-ask is
  load-bearing from C. ⚠ **Merge-order note for cepm**: cepm makes `t = h(q, m)` classical at propagation, which REMOVES the
  side door that l12C/l17C/a01C/a02C/r03C take today; without z0re those programs would move A→D under cepm. So cepm's A/B
  must be measured on a base that already contains z0re (or it will show those A→D movers and they will be real).
- **rhk5** — F-r1B-1: z0re grows rhk5's population; rhk5's fix should close `k3C`.
- **nlfd + ev3m** — no program: nlfd is IR-only (clang-19 emits only allowlisted attrs), and ev3m's musttail forward, once
  accepted, yields a classical `t` that enters exactly the direct-path prep measured above.
- Prep merge φ as a downstream condition (bd 3qps leaf, `c2leaf`) and a prep → prep cascade (`c3cascade`): TRACE-IDENTICAL to
  the literal-seed spelling on the ORACLE. A `cq_measure`-of-the-condition seed (`c7yiid`) declines `condition measured before
  the control route` on both binaries (the literal spelling too).

**Pre-existing, not z0re's, recorded for coverage (no grade):**
- `L2arr`: an in-loop prep whose condition is `q > k` with `k` an IV that `-O1` widened to i64 for a GEP
  (`icmp slt i64 %k, (sext %q)`) declines `control flow inside a loop body`; the LITERAL-seed hand-IR `L2arr_V1…ll` declines
  identically on the ORACLE; the hand-unrolled twin accepts. A condition-shape over-decline, seed-independent.
- `c1clone`: a function holding a runtime-seed prep called once with a classical and once with a quantum seed declines `cq
  specialization: callee contains a quantum primitive`; the inlined twin accepts (Phase-6 scope).
- `c10two`: two preps in one `-O1`-fused diamond decline `control flow` on both binaries (literal too); the unfused spelling
  accepts two rails.
- `c5inv`: `cq_invert_begin/_end` around a prep — opt exit 0, link fails — bd `ixao`, identical on the oracle.
- `spec_stateprep_runtime_seed_side_door.ll`'s census `1 left dirty` (TRACK item 8): the clone's branch-only read of `a` mints
  a dirty template rail entangled with `q`; `q` is never interfered in that module, so the prep's unitary is unaffected. Same
  class as F-r1B-1 (rhk5 family), pre-existing.

## Standing-lesson answers (Surface B)

- **L1**: r1A's. From C I measured the re-ask load-bearing (`k2C`) and not over-firing on a round-2 site that `specialize()`
  scrubs back (`k1C` accepts).
- **L2**: the sets computed over the angle-select base closure are S7-rail, S8, S9 (all read `BaseWireOrder`/`BaseWire`); all
  three are emptied together by `if (!IsPhase && !UntaintedBase)`, so none was left behind. `ChainWalk`'s freeze
  (`railCarriesControlledRotation`) applies to the fresh rail as to a literal prep (2b "left allocated", never `_unc`'d).
- **L3**: `R.RuntimeSeedAdmitted` (classifier verdict) vs the step-0 re-derivation — F-r1B-2.
- **L4 / L5**: nothing new in this surface.
- **L7**: F-r1B-4 (slice header). The S3 comment's "SimplifyCFG sinks a call only when at most ONE operand needs a φ" is
  MEASURED true here too (`c9twobase` stays two thetas and declines `if/else state prep allocates two rails` on both).
- **Rule 12**: every new negative is a bare `not … | FileCheck` or a separate prefix; no positive `-COUNT` sits inside a NEG
  prefix (checked all 22 changed fixtures).
- **Rule 14**: `isRuntimeStatePrepSeed` is the one spelling, called by F1, S3, the step-0 re-ask and the record gate ✓ (see
  F-r1B-2 for the one place a verdict is re-derived rather than carried).

## Beads

- Appended bd `rhk5` (F-r1B-1), bd `ix2v` (F-r1B-3, i16), bd `gahu` (F-r1B-5). None created; none closed.
